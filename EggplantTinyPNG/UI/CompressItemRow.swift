import AppKit
import SwiftUI

struct CompressItemRow: View {
    @EnvironmentObject private var themes: ThemeStore

    let item: CompressItem
    let autoExport: Bool

    private var revealURL: URL {
        item.outputURL ?? item.sourceURL
    }

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(themes.primaryText)
                    .lineLimit(1)
                subtitle
            }

            Spacer(minLength: 8)

            statusBadge

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([revealURL])
            } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(item.outputURL == nil
                  ? String(localized: "reveal.original")
                  : String(localized: "reveal.result"))
            .accessibilityLabel(String(localized: "reveal.accessibility"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(themes.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(themes.cardBorder, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var subtitle: some View {
        switch item.status {
        case .queued:
            Text(autoExport
                  ? String(format: String(localized: "status.willWrite"),
                           locale: .current,
                           OutputPathResolver.predictedFileName(for: item.sourceURL))
                  : String(localized: "status.queued"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .compressing:
            ProgressView(value: item.progress)
                .controlSize(.small)
        case .done:
            Text(doneSubtitle)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .failed(let message):
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private var doneSubtitle: String {
        let from = ByteCountFormatter.string(fromByteCount: Int64(item.originalBytes), countStyle: .file)
        let toBytes = item.compressedBytes ?? item.originalBytes
        let to = ByteCountFormatter.string(fromByteCount: Int64(toBytes), countStyle: .file)
        if let name = item.outputURL?.lastPathComponent {
            return "→ \(name) · \(from)→\(to)"
        }
        return "\(from) → \(to)"
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .queued:
            Text(String(localized: "status.waiting"))
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(themes.fill))
                .foregroundStyle(.secondary)
        case .compressing:
            Text(String(localized: "status.compressing"))
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(themes.accent.opacity(0.14)))
                .foregroundStyle(themes.accent)
        case .done:
            if let s = item.savingsFraction {
                Text(String(format: "−%.0f%%", s * 100))
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(themes.savingsColor.opacity(0.12)))
                    .foregroundStyle(themes.savingsColor)
            }
        case .failed:
            Text(String(localized: "status.failed"))
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.red.opacity(0.12)))
                .foregroundStyle(.red)
        }
    }

    private var thumbnail: some View {
        AsyncImage(url: item.sourceURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color(nsColor: .controlBackgroundColor)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
}
