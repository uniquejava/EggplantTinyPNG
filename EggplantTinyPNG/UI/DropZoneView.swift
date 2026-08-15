import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let isCompact: Bool
    let isTargeted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if isCompact {
                    HStack(spacing: 10) {
                        icon
                            .frame(width: 26, height: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("继续添加图片")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(nsColor: .labelColor))
                            Text("拖放到此处或点「打开」")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 52)
                } else {
                    VStack(spacing: 8) {
                        icon
                            .frame(width: 44, height: 44)
                        Text("拖放图片到此处")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(nsColor: .labelColor))
                        Text("PNG · JPEG · WebP")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                        Text("或点击选择文件")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                    }
                    .frame(maxWidth: .infinity, minHeight: 168)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isCompact ? 8 : 12, style: .continuous)
                .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: isCompact ? 14 : 20, weight: .semibold))
                .foregroundStyle(isTargeted ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
        }
    }
}

struct FileDropModifier: ViewModifier {
    @Binding var isTargeted: Bool
    let onDrop: ([URL]) -> Void

    func body(content: Content) -> some View {
        content
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                Task { @MainActor in
                    var urls: [URL] = []
                    for provider in providers {
                        if let url = await loadFileURL(from: provider) {
                            urls.append(url)
                        }
                    }
                    if !urls.isEmpty {
                        onDrop(urls)
                    }
                }
                return true
            }
    }

    private func loadFileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                    return
                }
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
