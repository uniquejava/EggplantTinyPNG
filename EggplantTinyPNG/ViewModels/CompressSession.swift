import AppKit
import Foundation
import SwiftUI

@MainActor
final class CompressSession: ObservableObject {
    @Published var items: [CompressItem] = []
    @Published var isCompressing = false
    @Published var overallProgress: Double = 0
    @Published var completedCount = 0
    @Published var totalCount = 0
    @Published var toolMissingMessage: String?

    @AppStorage("quality") var quality = 80

    private var compressTask: Task<Void, Never>?

    var isEmpty: Bool { items.isEmpty }

    var totalOriginalBytes: Int {
        items.reduce(0) { $0 + $1.originalBytes }
    }

    var totalCompressedBytes: Int {
        items.compactMap(\.compressedBytes).reduce(0, +)
    }

    var totalSavedBytes: Int {
        let done = items.filter {
            if case .done = $0.status { return true }
            return false
        }
        return done.reduce(0) { acc, item in
            guard let c = item.compressedBytes else { return acc }
            return acc + max(0, item.originalBytes - c)
        }
    }

    var averageSavingsFraction: Double? {
        let done = items.compactMap(\.savingsFraction)
        guard !done.isEmpty else { return nil }
        return done.reduce(0, +) / Double(done.count)
    }

    func refreshToolStatus() {
        if ToolFinder.find("pngquant") == nil {
            toolMissingMessage = "未找到 pngquant。请先执行：brew install pngquant oxipng"
        } else {
            toolMissingMessage = nil
        }
    }

    func addURLs(_ urls: [URL]) {
        let images = urls.filter { ImageCompressor.isSupported($0) }
        guard !images.isEmpty else { return }

        for url in images {
            let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            // Avoid duplicate pending same path.
            if items.contains(where: {
                $0.sourceURL == url && ($0.status == .queued || $0.status == .compressing)
            }) {
                continue
            }
            items.append(CompressItem(sourceURL: url, originalBytes: max(bytes, 0)))
        }
        startIfNeeded()
    }

    func clearFinished() {
        items.removeAll {
            switch $0.status {
            case .done, .failed: return true
            default: return false
            }
        }
        recomputeOverall()
    }

    func clearAll() {
        compressTask?.cancel()
        compressTask = nil
        items.removeAll()
        isCompressing = false
        overallProgress = 0
        completedCount = 0
        totalCount = 0
    }

    func revealInFinder() {
        let urls = items.compactMap(\.outputURL)
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    /// Replace the source file with compressed bytes; remove any `-tiny` sidecar.
    func overwriteOriginal(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              case .done = items[index].status,
              let out = items[index].outputURL
        else { return }

        let source = items[index].sourceURL
        if out == source { return }

        do {
            let data = try Data(contentsOf: out)
            try data.write(to: source, options: .atomic)
            try? FileManager.default.removeItem(at: out)
            items[index].outputURL = source
        } catch {
            items[index].status = .failed(error.localizedDescription)
        }
    }

    private func startIfNeeded() {
        guard compressTask == nil else { return }
        compressTask = Task { await runQueue() }
    }

    private func runQueue() async {
        refreshToolStatus()
        isCompressing = true
        defer {
            isCompressing = false
            compressTask = nil
            // Kick again if new items arrived while finishing.
            if items.contains(where: { $0.status == .queued }) {
                startIfNeeded()
            }
        }

        while let index = items.firstIndex(where: { $0.status == .queued }) {
            if Task.isCancelled { break }
            await compressOne(at: index)
        }
        recomputeOverall()
    }

    private func compressOne(at index: Int) async {
        items[index].status = .compressing
        items[index].progress = 0.05
        recomputeOverall()

        let source = items[index].sourceURL
        let quality = self.quality

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try ImageCompressor.compress(fileURL: source, quality: quality)
            }.value

            guard !Task.isCancelled else { return }

            items[index].progress = 0.9
            items[index].compressedBytes = result.bytes

            let dest = OutputPathResolver.autoExportURL(for: source)
            try result.data.write(to: dest, options: .atomic)
            items[index].outputURL = dest

            items[index].progress = 1
            items[index].status = .done
        } catch {
            items[index].status = .failed(error.localizedDescription)
            items[index].progress = 0
        }

        recomputeOverall()
    }

    private func recomputeOverall() {
        let relevant = items.filter {
            switch $0.status {
            case .queued, .compressing, .done, .failed: return true
            }
        }
        totalCount = relevant.count
        completedCount = relevant.filter {
            if case .done = $0.status { return true }
            if case .failed = $0.status { return true }
            return false
        }.count

        if totalCount == 0 {
            overallProgress = 0
            return
        }
        let sum = items.reduce(0.0) { acc, item in
            switch item.status {
            case .done, .failed: return acc + 1
            case .compressing: return acc + item.progress
            case .queued: return acc
            }
        }
        overallProgress = sum / Double(totalCount)
    }
}
