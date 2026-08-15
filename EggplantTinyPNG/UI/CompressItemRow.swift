import AppKit
import SwiftUI

struct CompressItemRow: View {
    let item: CompressItem
    let autoExport: Bool

    private var revealURL: URL {
        item.outputURL ?? item.sourceURL
    }

    var body: some View {
        HStack(spacing: 8) {
            thumbnail
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                subtitle
            }

            Spacer(minLength: 6)

            statusBadge

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([revealURL])
            } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 15))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(item.outputURL == nil ? "在访达中显示原图" : "在访达中显示压缩结果")
            .accessibilityLabel("在访达中显示")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var subtitle: some View {
        switch item.status {
        case .queued:
            Text(autoExport ? "将写入 \(OutputPathResolver.predictedFileName(for: item.sourceURL))" : "排队中")
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
            Text("等待")
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color(nsColor: .controlBackgroundColor)))
                .foregroundStyle(.secondary)
        case .compressing:
            Text("压缩中")
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                .foregroundStyle(Color.accentColor)
        case .done:
            if let s = item.savingsFraction {
                Text(String(format: "−%.0f%%", s * 100))
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .foregroundStyle(Color(red: 0.14, green: 0.54, blue: 0.24))
            }
        case .failed:
            Text("失败")
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
