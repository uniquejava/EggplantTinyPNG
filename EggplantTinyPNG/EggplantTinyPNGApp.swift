import AppKit
import SwiftUI

extension Notification.Name {
    static let openAppPreferences = Notification.Name("click.yinsb.EggplantTinyPNG.openAppPreferences")
}

@main
struct EggplantTinyPNGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = CompressSession()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuContent(session: session)
                .background(PreferencesEnvironmentBridge())
                .background(WindowOpenerBridge())
        } label: {
            // Lucide `image` template; ~16pt so it matches neighboring status items.
            Image("MenuBarGlyph")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
        }

        // Singular Window (not WindowGroup) so Show Window reuses one instance.
        Window("EggplantTinyPNG", id: "main") {
            ContentView(session: session)
                .environmentObject(ThemeStore.shared)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Toggle(L10n.tr("menu.autoExport"), isOn: $session.autoExport)
                    .keyboardShortcut("e", modifiers: [.command])
            }
            CommandGroup(replacing: .saveItem) {
                Button(L10n.tr("action.clearList")) {
                    session.clearAll()
                }
                .keyboardShortcut("k", modifiers: [.command])
                .disabled(session.isEmpty)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(ThemeStore.shared)
        }
    }
}

private struct WindowOpenerBridge: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                MainWindowGateway.shared.open = { [openWindow] in
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    if MainWindowGateway.frontExistingMainWindow() {
                        return
                    }
                    openWindow(id: "main")
                }
                // Open compressor once at launch (not every status-menu open).
                if !MainWindowGateway.shared.didOpenAtLaunch {
                    MainWindowGateway.shared.didOpenAtLaunch = true
                    DispatchQueue.main.async {
                        MainWindowGateway.shared.open?()
                    }
                }
            }
    }
}

@MainActor
enum MainWindowGateway {
    static let shared = Gateway()
    final class Gateway {
        var open: (() -> Void)?
        var didOpenAtLaunch = false
    }

    /// Bring an already-created main window forward (incl. miniaturized / hidden).
    @discardableResult
    static func frontExistingMainWindow() -> Bool {
        let candidates = NSApp.windows.filter { isMainCompressorWindow($0) }
        guard let window = candidates.first(where: \.isVisible)
                ?? candidates.first(where: \.isMiniaturized)
                ?? candidates.first
        else { return false }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private static func isMainCompressorWindow(_ window: NSWindow) -> Bool {
        if window is NSPanel { return false }
        if window.frame.width < 80 || window.frame.height < 80 { return false }
        if window.identifier?.rawValue == "main" { return true }
        // Title is set by WindowChromeConfigurator once attached.
        return window.title == "EggplantTinyPNG"
    }
}

private struct PreferencesEnvironmentBridge: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                OpenSettingsGateway.shared.open = { [openSettings] in
                    openSettings()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openAppPreferences)) { _ in
                OpenSettingsGateway.shared.open?()
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}

@MainActor
enum OpenSettingsGateway {
    static let shared = Gateway()
    final class Gateway {
        var open: (() -> Void)?
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let open = MainWindowGateway.shared.open {
            open()
        } else {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }
}
