import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var session: CompressSession
    @EnvironmentObject private var themes: ThemeStore
    @State private var isDropTargeted = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    // Loud banner only once the queue has files; empty state uses a quiet footnote.
                    if let msg = session.toolMissingMessage, !session.isEmpty {
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
                              ? String(localized: "hint.autoExport")
                              : String(localized: "hint.manualExport"))
                            .font(.system(size: 12))
                            .foregroundStyle(themes.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Spacer(minLength: 28)

                        if session.toolMissingMessage != nil {
                            brewFootnote
                        }
                    }

                    if !session.isEmpty {
                        progressCard
                        queue
                        actions
                    }
                }
                .padding(16)
                // Fill the viewport so the brew tip can sit in the empty lower area.
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
            // Hide SwiftUI's fading overlay; AppKit legacy scroller stays on when overflowing.
            .scrollIndicators(.hidden)
        }
        .background(themes.fill.ignoresSafeArea())
        .background(ScrollChromeConfigurator())
        .background(WindowChromeConfigurator(background: themes.nsFill))
        .containerBackground(themes.fill, for: .window)
        .preferredColorScheme(themes.isDark ? .dark : .light)
        .frame(minWidth: 480, idealWidth: 520, maxWidth: 720,
               minHeight: 360, idealHeight: 460)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { session.refreshToolStatus() }
    }

    /// Quiet empty-state footnote — gray, no card; only when pngquant is missing.
    private var brewFootnote: some View {
        VStack(spacing: 5) {
            Text(String(localized: "hint.brew.lead"))
                .font(.system(size: 11))
            Text(String(localized: "hint.brew.command"))
                .font(.system(size: 11, design: .monospaced))
        }
        .foregroundStyle(themes.secondaryText.opacity(0.55))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                      ? String(format: String(localized: "progress.done"),
                               locale: .current,
                               session.completedCount,
                               session.totalCount)
                      : String(format: String(localized: "progress.working"),
                               locale: .current,
                               session.completedCount,
                               session.totalCount))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(themes.primaryText)
                Spacer()
                Text("\(Int(session.overallProgress * 100))%")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(themes.secondaryText)
            }
            ProgressView(value: session.overallProgress)
                .controlSize(.regular)
                .tint(themes.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(themes.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(themes.cardBorder, lineWidth: 1)
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
                Button(String(localized: "action.exportAll")) { session.exportSelectedManually() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themes.accent)
            }
            Button(String(localized: "action.clearList")) { session.clearAll() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(themes.secondaryText)
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
