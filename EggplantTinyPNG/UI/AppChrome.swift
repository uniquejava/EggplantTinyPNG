import AppKit
import SwiftUI

// MARK: - Themes

struct AppTheme: Identifiable, Hashable {
    enum ID: String, CaseIterable, Identifiable {
        case light
        case porcelain
        case mist
        case blue
        case cyan
        case green
        case purple
        case rose
        case orange
        case slate
        case dark
        case midnight

        var id: String { rawValue }
    }

    let id: ID
    let name: String
    let isDark: Bool
    /// Window / title fill (sRGB 0…1).
    let fillRGB: SIMD3<Double>
    let accentRGB: SIMD3<Double>
    let cardRGB: SIMD3<Double>
    let scrollerKnobRGB: SIMD3<Double>
    let scrollerTrackRGB: SIMD3<Double>

    var fill: Color { Self.color(fillRGB) }
    var accent: Color { Self.color(accentRGB) }
    var cardFill: Color { Self.color(cardRGB) }
    var cardBorder: Color { accent.opacity(isDark ? 0.28 : 0.14) }
    var hairline: Color { accent.opacity(isDark ? 0.32 : 0.18) }
    var primaryText: Color {
        isDark
            ? Color(red: 0.95, green: 0.96, blue: 0.97)
            : Color(red: 0.12, green: 0.14, blue: 0.16)
    }
    var secondaryText: Color {
        isDark
            ? Color(red: 0.70, green: 0.73, blue: 0.78)
            : Color(red: 0.35, green: 0.42, blue: 0.48)
    }

    var nsFill: NSColor { Self.nsColor(fillRGB) }
    var nsAccent: NSColor { Self.nsColor(accentRGB) }
    var nsScrollerKnob: NSColor { Self.nsColor(scrollerKnobRGB) }
    var nsScrollerTrack: NSColor { Self.nsColor(scrollerTrackRGB) }

    static let savings = Color(red: 0.14, green: 0.54, blue: 0.24)
    static let savingsDark = Color(red: 0.35, green: 0.82, blue: 0.48)

    var savingsColor: Color { isDark ? Self.savingsDark : Self.savings }

    /// Popular light + accent + dark themes (swatch order).
    static let all: [AppTheme] = [
        make(.light, "浅色", dark: false,
             fill: 0xF5F5F7, accent: 0x007AFF, card: 0xFFFFFF,
             knob: 0x8E8E93, track: 0xEBEBED),
        make(.porcelain, "Porcelain", dark: false,
             fill: 0xECF0F4, accent: 0x7594B3, card: 0xFFFFFF,
             knob: 0x8A9FAE, track: 0xF0F3F6),
        make(.mist, "Mist", dark: false,
             fill: 0xE0F1F8, accent: 0x50C7FC, card: 0xFFFFFF,
             knob: 0x7FA9BD, track: 0xE7F4FA),
        make(.blue, "蓝", dark: false,
             fill: 0xEAF2FF, accent: 0x3B82F6, card: 0xFFFFFF,
             knob: 0x7AA0D6, track: 0xE8F0FC),
        make(.cyan, "青", dark: false,
             fill: 0xE6F8F9, accent: 0x06B6D4, card: 0xFFFFFF,
             knob: 0x5FB8C4, track: 0xE4F4F6),
        make(.green, "绿", dark: false,
             fill: 0xEEFAF1, accent: 0x22C55E, card: 0xFFFFFF,
             knob: 0x6BBF86, track: 0xE8F5EC),
        make(.purple, "紫", dark: false,
             fill: 0xF4F0FF, accent: 0x8B5CF6, card: 0xFFFFFF,
             knob: 0xA78BDB, track: 0xEFEAFB),
        make(.rose, "红", dark: false,
             fill: 0xFFF1F3, accent: 0xF43F5E, card: 0xFFFFFF,
             knob: 0xE07A8C, track: 0xFCEAED),
        make(.orange, "橙", dark: false,
             fill: 0xFFF6EB, accent: 0xF97316, card: 0xFFFFFF,
             knob: 0xE09A5C, track: 0xFCEFDF),
        make(.slate, "灰青", dark: false,
             fill: 0xE0E6EA, accent: 0x7295A8, card: 0xFFFFFF,
             knob: 0x869CA8, track: 0xE7ECEF),
        make(.dark, "深色", dark: true,
             fill: 0x1C1C1E, accent: 0x0A84FF, card: 0x2C2C2E,
             knob: 0x636366, track: 0x2C2C2E),
        make(.midnight, "午夜", dark: true,
             fill: 0x14161C, accent: 0xBF5AF2, card: 0x22252E,
             knob: 0x6E6A78, track: 0x1E2129),
    ]

    static func named(_ id: ID) -> AppTheme {
        all.first { $0.id == id } ?? all.first { $0.id == .porcelain }!
    }

    private static func make(
        _ id: ID,
        _ name: String,
        dark: Bool,
        fill: UInt32,
        accent: UInt32,
        card: UInt32,
        knob: UInt32,
        track: UInt32
    ) -> AppTheme {
        AppTheme(
            id: id,
            name: name,
            isDark: dark,
            fillRGB: rgb(fill),
            accentRGB: rgb(accent),
            cardRGB: rgb(card),
            scrollerKnobRGB: rgb(knob),
            scrollerTrackRGB: rgb(track)
        )
    }

    private static func rgb(_ hex: UInt32) -> SIMD3<Double> {
        SIMD3(
            Double((hex >> 16) & 0xFF) / 255,
            Double((hex >> 8) & 0xFF) / 255,
            Double(hex & 0xFF) / 255
        )
    }

    private static func color(_ rgb: SIMD3<Double>) -> Color {
        Color(red: rgb.x, green: rgb.y, blue: rgb.z)
    }

    private static func nsColor(_ rgb: SIMD3<Double>) -> NSColor {
        NSColor(srgbRed: rgb.x, green: rgb.y, blue: rgb.z, alpha: 1)
    }
}

extension Notification.Name {
    static let appThemeDidChange = Notification.Name("click.yinsb.EggplantTinyPNG.appThemeDidChange")
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    private static let defaultsKey = "appThemeID"

    @Published var id: AppTheme.ID {
        didSet {
            guard oldValue != id else { return }
            UserDefaults.standard.set(id.rawValue, forKey: Self.defaultsKey)
            NotificationCenter.default.post(name: .appThemeDidChange, object: id.rawValue)
        }
    }

    var theme: AppTheme { AppTheme.named(id) }

    var fill: Color { theme.fill }
    var accent: Color { theme.accent }
    var cardFill: Color { theme.cardFill }
    var cardBorder: Color { theme.cardBorder }
    var hairline: Color { theme.hairline }
    var primaryText: Color { theme.primaryText }
    var secondaryText: Color { theme.secondaryText }
    var isDark: Bool { theme.isDark }
    var savingsColor: Color { theme.savingsColor }
    var nsFill: NSColor { theme.nsFill }
    var nsAccent: NSColor { theme.nsAccent }
    var nsScrollerKnob: NSColor { theme.nsScrollerKnob }
    var nsScrollerTrack: NSColor { theme.nsScrollerTrack }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let saved = AppTheme.ID(rawValue: raw) {
            id = saved
        } else {
            id = .porcelain
        }
    }
}

/// Title-bar theme chips — fill face + accent ring (single compact row).
struct ThemeSwatchBar: View {
    @ObservedObject private var themes = ThemeStore.shared

    var body: some View {
        HStack(spacing: 5) {
            ForEach(AppTheme.all) { theme in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        themes.id = theme.id
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.fill)
                        Circle()
                            .strokeBorder(
                                theme.accent,
                                lineWidth: themes.id == theme.id ? 1.8 : 1
                            )
                    }
                    .frame(width: 13, height: 13)
                    .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.10), radius: 0.8, y: 0.4)
                }
                .buttonStyle(.plain)
                .help(theme.name)
                .accessibilityLabel(theme.name)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        // Title-bar accessory height tracks the system title bar.
        .frame(height: 28)
        .fixedSize(horizontal: true, vertical: true)
    }
}

// MARK: - Scroller

/// Always-visible legacy scroller when content overflows; follows active theme.
final class AppChromeScroller: NSScroller {
    private static let trackWidth: CGFloat = 15
    private static let knobWidth: CGFloat = 9

    override class var isCompatibleWithOverlayScrollers: Bool { true }

    override class func scrollerWidth(
        for controlSize: NSControl.ControlSize,
        scrollerStyle style: NSScroller.Style
    ) -> CGFloat {
        trackWidth
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        ThemeStore.shared.nsScrollerTrack.setFill()
        slotRect.fill()
    }

    override func drawKnob() {
        let knob = rect(for: .knob)
        guard knob.width > 0, knob.height > 0 else { return }
        let dx = max(0, (knob.width - Self.knobWidth) / 2)
        let inset = knob.insetBy(dx: dx, dy: 2)
        guard inset.width > 0, inset.height > 0 else { return }
        let radius = min(inset.width, inset.height) / 2
        let path = NSBezierPath(roundedRect: inset, xRadius: radius, yRadius: radius)
        ThemeStore.shared.nsScrollerKnob.setFill()
        path.fill()
    }
}

/// Finds SwiftUI's underlying `NSScrollView` and installs `AppChromeScroller`.
struct ScrollChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ScrollChromeHostView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollChromeHostView)?.applySoon()
    }
}

private final class ScrollChromeHostView: NSView {
    private var pending = false
    private var themeObserver: NSObjectProtocol?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if themeObserver == nil {
            themeObserver = NotificationCenter.default.addObserver(
                forName: .appThemeDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.applySoon()
                self?.window?.contentView?.needsDisplay = true
                Self.scrollViews(in: self?.window?.contentView).forEach {
                    $0.verticalScroller?.needsDisplay = true
                }
            }
        }
        applySoon()
    }

    deinit {
        if let themeObserver {
            NotificationCenter.default.removeObserver(themeObserver)
        }
    }

    override func layout() {
        super.layout()
        applySoon()
    }

    func applySoon() {
        guard !pending else { return }
        pending = true
        DispatchQueue.main.async { [weak self] in
            self?.pending = false
            self?.apply()
        }
    }

    private func apply() {
        guard let root = window?.contentView else { return }
        for scroll in Self.scrollViews(in: root) {
            Self.install(on: scroll)
            scroll.verticalScroller?.needsDisplay = true
        }
    }

    private static func scrollViews(in root: NSView?) -> [NSScrollView] {
        guard let root else { return [] }
        var found: [NSScrollView] = []
        var stack: [NSView] = [root]
        while let view = stack.popLast() {
            if let scroll = view as? NSScrollView {
                found.append(scroll)
            }
            stack.append(contentsOf: view.subviews)
        }
        return found
    }

    private static func install(on scrollView: NSScrollView) {
        if !(scrollView.verticalScroller is AppChromeScroller) {
            let scroller = AppChromeScroller()
            scroller.controlSize = .regular
            scrollView.verticalScroller = scroller
        }
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        if scrollView.scrollerStyle != .legacy {
            scrollView.scrollerStyle = .legacy
        }
        if scrollView.autohidesScrollers {
            scrollView.autohidesScrollers = false
        }
        scrollView.scrollerKnobStyle = .default
        scrollView.horizontalScrollElasticity = .none
    }
}

// MARK: - Window chrome

/// Standard title bar + traffic lights, tinted to the active theme fill.
struct WindowChromeConfigurator: NSViewRepresentable {
    var background: NSColor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true
        context.coordinator.background = background
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.background = background
        context.coordinator.attach(to: nsView)
        context.coordinator.paint()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var background: NSColor = ThemeStore.shared.nsFill
        private weak var hostView: NSView?
        private weak var observedWindow: NSWindow?
        private var observers: [NSObjectProtocol] = []
        private var findAttempts = 0
        private var themeAccessory: NSTitlebarAccessoryViewController?

        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }

        func attach(to view: NSView) {
            hostView = view
            findAttempts = 0
            resolveWindow()
        }

        private func resolveWindow() {
            guard let view = hostView else { return }
            if let window = view.window {
                bind(window: window)
                paint()
                return
            }
            findAttempts += 1
            guard findAttempts < 30 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.resolveWindow()
            }
        }

        private func bind(window: NSWindow) {
            guard observedWindow !== window else { return }
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
            observedWindow = window

            let names: [Notification.Name] = [
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification,
                NSWindow.didBecomeMainNotification,
                NSWindow.didResignMainNotification,
                NSWindow.didResizeNotification,
                NSWindow.didMoveNotification,
                NSWindow.willStartLiveResizeNotification,
                NSWindow.didEndLiveResizeNotification,
                .appThemeDidChange,
            ]
            for name in names {
                observers.append(NotificationCenter.default.addObserver(
                    forName: name,
                    object: name == .appThemeDidChange ? nil : window,
                    queue: .main
                ) { [weak self] _ in
                    self?.paintSoon()
                })
            }
        }

        private func paintSoon() {
            paint()
            DispatchQueue.main.async { [weak self] in self?.paint() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.paint() }
        }

        func paint() {
            guard let window = observedWindow ?? hostView?.window else { return }
            if observedWindow == nil { bind(window: window) }

            window.styleMask.formUnion([.titled, .closable, .miniaturizable, .resizable])
            window.styleMask.remove(.fullSizeContentView)
            window.title = "EggplantTinyPNG"
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.isOpaque = true
            window.backgroundColor = background
            window.toolbar = nil

            for kind: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                window.standardWindowButton(kind)?.isHidden = false
                window.standardWindowButton(kind)?.alphaValue = 1
            }

            installThemeAccessory(on: window)
            paintTitlebar(window)
        }

        private func installThemeAccessory(on window: NSWindow) {
            if themeAccessory == nil {
                let host = NSHostingView(rootView: ThemeSwatchBar())
                host.translatesAutoresizingMaskIntoConstraints = false
                let size = host.fittingSize
                host.frame = NSRect(origin: .zero, size: size)

                let accessory = NSTitlebarAccessoryViewController()
                accessory.layoutAttribute = .trailing
                accessory.view = host
                themeAccessory = accessory
            }

            guard let accessory = themeAccessory else { return }
            if !window.titlebarAccessoryViewControllers.contains(where: { $0 === accessory }) {
                // Drop any stale theme accessories from prior configurators.
                for (idx, existing) in window.titlebarAccessoryViewControllers.enumerated().reversed()
                where existing.view is NSHostingView<ThemeSwatchBar> {
                    window.removeTitlebarAccessoryViewController(at: idx)
                }
                window.addTitlebarAccessoryViewController(accessory)
            }

            if let host = accessory.view as? NSHostingView<ThemeSwatchBar> {
                host.rootView = ThemeSwatchBar()
                let size = host.fittingSize
                host.frame.size = size
            }
        }

        private func paintTitlebar(_ window: NSWindow) {
            guard let button = window.standardWindowButton(.closeButton),
                  let buttonBar = button.superview,
                  let titlebar = buttonBar.superview
            else { return }

            let cg = background.cgColor
            for view in [titlebar, buttonBar] {
                view.wantsLayer = true
                view.layer?.backgroundColor = cg
            }
            if let content = window.contentView {
                content.wantsLayer = true
                content.layer?.backgroundColor = cg
            }

            // Keep accessory chrome transparent so theme fill shows through.
            for accessory in window.titlebarAccessoryViewControllers {
                accessory.view.wantsLayer = true
                accessory.view.layer?.backgroundColor = .clear
                accessory.view.superview?.wantsLayer = true
                accessory.view.superview?.layer?.backgroundColor = cg
            }

            let separatorClass = NSClassFromString("NSTitlebarSeparatorView")
            var stack = titlebar.subviews
            while let sub = stack.popLast() {
                stack.append(contentsOf: sub.subviews)
                if let effect = sub as? NSVisualEffectView {
                    effect.alphaValue = 0
                    effect.wantsLayer = true
                    effect.layer?.backgroundColor = cg
                }
                let isSep = separatorClass.map { sub.isKind(of: $0) } ?? false
                let isHair = sub.bounds.height > 0 && sub.bounds.height <= 1.5
                    && sub.bounds.width >= titlebar.bounds.width - 8
                if isSep || isHair {
                    sub.isHidden = true
                    sub.alphaValue = 0
                }
            }
            window.titlebarSeparatorStyle = .none
        }
    }
}
