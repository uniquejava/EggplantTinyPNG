import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject private var themes: ThemeStore

    let isCompact: Bool
    let isTargeted: Bool
    let onTap: () -> Void

    private var activeFill: Color { themes.accent.opacity(themes.isDark ? 0.18 : 0.10) }

    var body: some View {
        Button(action: onTap) {
            Group {
                if isCompact {
                    HStack(spacing: 12) {
                        icon
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "drop.continue.title"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(themes.primaryText)
                            Text(String(localized: "drop.continue.subtitle"))
                                .font(.system(size: 11))
                                .foregroundStyle(themes.secondaryText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(spacing: 10) {
                        icon
                            .frame(width: 64, height: 64)
                        Text(String(localized: "drop.empty.title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themes.primaryText)
                        Text(String(localized: "drop.empty.formats"))
                            .font(.system(size: 13))
                            .foregroundStyle(themes.secondaryText)
                        Text(String(localized: "drop.empty.click"))
                            .font(.system(size: 12))
                            .foregroundStyle(themes.secondaryText.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTargeted ? activeFill : themes.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        themes.accent.opacity(isTargeted ? 0.95 : 0.55),
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
            .foregroundStyle(themes.accent)
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
