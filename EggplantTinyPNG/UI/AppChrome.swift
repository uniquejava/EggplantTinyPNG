import AppKit
import SwiftUI

/// L1 Mist Cyan — unified window / title bar / content fill.
enum AppChrome {
    static let fill = Color(red: 238 / 255, green: 248 / 255, blue: 252 / 255)
    static let nsFill = NSColor(srgbRed: 238 / 255, green: 248 / 255, blue: 252 / 255, alpha: 1)

    static let accent = Color(red: 80 / 255, green: 199 / 255, blue: 252 / 255)
    static let nsAccent = NSColor(srgbRed: 80 / 255, green: 199 / 255, blue: 252 / 255, alpha: 1)
    /// Soft blue-gray knob — sits on mist chrome without the neon progress accent.
    static let nsScrollerKnob = NSColor(srgbRed: 130 / 255, green: 168 / 255, blue: 186 / 255, alpha: 1)
    static let nsScrollerTrack = NSColor(srgbRed: 226 / 255, green: 240 / 255, blue: 246 / 255, alpha: 1)
    static let cardBorder = Color(red: 80 / 255, green: 199 / 255, blue: 252 / 255).opacity(0.14)
    static let hairline = Color(red: 80 / 255, green: 199 / 255, blue: 252 / 255).opacity(0.18)
    static let savings = Color(red: 0.14, green: 0.54, blue: 0.24)
}

/// Always-visible legacy scroller when content overflows; muted mist-cyan chrome.
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
        AppChrome.nsScrollerTrack.setFill()
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
        AppChrome.nsScrollerKnob.setFill()
        path.fill()
    }
}

/// Finds SwiftUI's underlying `NSScrollView` and installs `AppChromeScroller`.
struct ScrollChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ScrollChromeHostView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollChromeHostView)?.applySoon()
    }
}

private final class ScrollChromeHostView: NSView {
    private var pending = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applySoon()
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
        }
    }

    private static func scrollViews(in root: NSView) -> [NSScrollView] {
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
        // Legacy + never autohide: show whenever content is taller than the viewport.
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

/// Standard title bar + traffic lights, tinted mist cyan (re-paint on focus / drag).
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
        var background: NSColor = AppChrome.nsFill
        private weak var hostView: NSView?
        private weak var observedWindow: NSWindow?
        private var observers: [NSObjectProtocol] = []
        private var findAttempts = 0

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
            ]
            for name in names {
                observers.append(NotificationCenter.default.addObserver(
                    forName: name,
                    object: window,
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

            paintTitlebar(window)
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
