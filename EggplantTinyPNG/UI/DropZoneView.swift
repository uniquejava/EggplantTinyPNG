import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let isCompact: Bool
    let isTargeted: Bool
    let onTap: () -> Void

    private static let idleFill = Color.white
    private static let activeFill = Color(red: 232 / 255, green: 246 / 255, blue: 252 / 255)
    private static let titleColor = Color(red: 0.12, green: 0.14, blue: 0.16)
    private static let subtitleColor = Color(red: 0.35, green: 0.42, blue: 0.48)

    var body: some View {
        Button(action: onTap) {
            Group {
                if isCompact {
                    HStack(spacing: 12) {
                        icon
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("继续添加图片")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Self.titleColor)
                            Text("拖放到此处，或点击选择")
                                .font(.system(size: 11))
                                .foregroundStyle(Self.subtitleColor)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(spacing: 10) {
                        icon
                            .frame(width: 64, height: 64)
                        Text("拖放图片到此处")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Self.titleColor)
                        Text("PNG · JPEG · WebP")
                            .font(.system(size: 13))
                            .foregroundStyle(Self.subtitleColor)
                        Text("或点击选择文件")
                            .font(.system(size: 12))
                            .foregroundStyle(Self.subtitleColor.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTargeted ? Self.activeFill : Self.idleFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        AppChrome.accent.opacity(isTargeted ? 0.95 : 0.55),
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
    }

    private var icon: some View {
        Image("DropGlyph")
            .resizable()
            .renderingMode(.template)
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppChrome.accent)
            .scaleEffect(isTargeted ? 1.04 : 1)
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
