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
        Window("EggplantTinyPNG", id: "main") {
            ContentView(session: session)
                .environmentObject(ThemeStore.shared)
                .background(PreferencesEnvironmentBridge())
                .background(WindowOpenerBridge())
        }
        .windowStyle(.automatic)
        // Not .contentSize — queue growth would stretch the window endlessly.
        .windowResizability(.automatic)
        .defaultSize(width: 520, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}
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
                    NSApp.activate(ignoringOtherApps: true)
                    if MainWindowGateway.frontExistingMainWindow() {
                        return
                    }
                    openWindow(id: "main")
                }
            }
    }
}

@MainActor
enum MainWindowGateway {
    static let shared = Gateway()
    final class Gateway {
        var open: (() -> Void)?
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
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag { return true }
        if let open = MainWindowGateway.shared.open {
            open()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the Dock icon; quit only via ⌘Q / Quit menu (standard macOS apps).
        false
    }
}
