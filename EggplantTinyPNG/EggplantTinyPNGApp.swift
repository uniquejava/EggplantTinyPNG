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
            Image("DropGlyph")
                .renderingMode(.template)
        }

        WindowGroup(id: "main") {
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
