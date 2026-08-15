import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var session: CompressSession
    @State private var isDropTargeted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
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

                if session.isEmpty {
                    Text(session.autoExport
                          ? "拖入即压缩 · 保存为 原名-tiny-时间戳.ext"
                          : "拖入后手动导出 · 菜单栏可开自动导出")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if !session.isEmpty {
                    progressCard
                    queue
                    actions
                }
            }
            .padding(16)
        }
        // Hide SwiftUI's fading overlay; AppKit legacy scroller stays on when overflowing.
        .scrollIndicators(.hidden)
        .background(AppChrome.fill)
        .background(ScrollChromeConfigurator())
        .background(WindowChromeConfigurator(background: AppChrome.nsFill))
        .containerBackground(AppChrome.fill, for: .window)
        .frame(minWidth: 480, minHeight: 360)
        .onAppear { session.refreshToolStatus() }
    }

    private func warningBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var progressCard: some View {
        let done = !session.isCompressing && session.overallProgress >= 1
        return VStack(spacing: 8) {
            HStack {
                Text(done
                      ? "已完成 \(session.completedCount) / \(session.totalCount)"
                      : "正在压缩 \(session.completedCount) / \(session.totalCount)")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(Int(session.overallProgress * 100))%")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: session.overallProgress)
                .controlSize(.regular)
                .tint(AppChrome.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppChrome.cardBorder, lineWidth: 1)
                )
        )
        .opacity(done ? 0.9 : 1)
    }

    private var queue: some View {
        LazyVStack(spacing: 6) {
            ForEach(session.items) { item in
                CompressItemRow(item: item, autoExport: session.autoExport)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 16) {
            Spacer()
            if !session.autoExport,
               session.items.contains(where: {
                   if case .done = $0.status { return $0.outputURL == nil && $0.compressedData != nil }
                   return false
               }) {
                Button("全部导出") { session.exportSelectedManually() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppChrome.accent)
            }
            Button("清除列表") { session.clearAll() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
        .padding(.trailing, 2)
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
