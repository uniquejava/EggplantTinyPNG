import Foundation

enum CompressItemStatus: Equatable {
    case queued
    case compressing
    case done
    case failed(String)
}

struct CompressItem: Identifiable, Equatable {
    let id: UUID
    let sourceURL: URL
    let originalBytes: Int
    var status: CompressItemStatus
    var progress: Double
    var compressedBytes: Int?
    var outputURL: URL?
    var compressedData: Data?

    var displayName: String { sourceURL.lastPathComponent }

    var savingsFraction: Double? {
        guard let compressedBytes, originalBytes > 0 else { return nil }
        return 1 - (Double(compressedBytes) / Double(originalBytes))
    }

    init(sourceURL: URL, originalBytes: Int) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.originalBytes = originalBytes
        self.status = .queued
        self.progress = 0
    }
}
