import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var session: CompressSession
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                VStack(spacing: 8) {
                    if let msg = session.toolMissingMessage {
                        warningBanner(msg)
                    }

                    DropZoneView(
                        isCompact: !session.isEmpty,
                        isTargeted: isDropTargeted,
                        onTap: openPanel
                    )
                    .modifier(FileDropModifier(isTargeted: $isDropTargeted) { urls in
                        session.addURLs(urls)
                    })

                    if session.autoExport && session.isEmpty {
                        Text("自动导出已开 · 保存为 原名-tiny-时间戳.ext")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    if !session.isEmpty {
                        progressCard
                        summaryHeader
                        queue
                        actions
                    }
                }
                .padding(12)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 480, minHeight: 420)
        .onAppear { session.refreshToolStatus() }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Toggle("自动导出", isOn: $session.autoExport)
                .toggleStyle(.switch)
                .controlSize(.small)
                .help("开启后拖入即压缩，结果写到原图旁：原名-tiny-yyyyMMdd-HHmmss.ext")

            Spacer()

            Button("打开…") { openPanel() }
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func warningBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var progressCard: some View {
        VStack(spacing: 6) {
            HStack {
                Text("正在压缩 \(session.completedCount) / \(session.totalCount)")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int(session.overallProgress * 100))%")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: session.overallProgress)
                .controlSize(.small)
                .tint(Color.accentColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(session.isCompressing || session.overallProgress < 1 ? 1 : 0.85)
    }

    private var summaryHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(session.autoExport ? "已节省 · 已自动导出" : "已节省")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(session.totalSavedBytes), countStyle: .file))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0.14, green: 0.54, blue: 0.24))
                    if let avg = session.averageSavingsFraction {
                        Text(String(format: "· %.0f%%", avg * 100))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(red: 0.14, green: 0.54, blue: 0.24))
                    }
                }
            }
            Spacer()
            Text("\(session.items.count) 张")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private var queue: some View {
        LazyVStack(spacing: 5) {
            ForEach(session.items) { item in
                CompressItemRow(item: item, autoExport: session.autoExport)
            }
        }
    }

    private var actions: some View {
        HStack {
            Spacer()
            if session.items.contains(where: { $0.outputURL != nil }) {
                Button("在访达中显示") { session.revealInFinder() }
                    .controlSize(.small)
            }
            if !session.autoExport,
               session.items.contains(where: {
                   if case .done = $0.status { return $0.outputURL == nil && $0.compressedData != nil }
                   return false
               }) {
                Button("全部导出") { session.exportSelectedManually() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            Button("清除列表") { session.clearAll() }
                .controlSize(.small)
        }
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg, .webP]
        panel.begin { response in
            guard response == .OK else { return }
            session.addURLs(panel.urls)
        }
    }
}
