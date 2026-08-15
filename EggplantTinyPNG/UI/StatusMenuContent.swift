import AppKit
import SwiftUI

struct StatusMenuContent: View {
    @ObservedObject var session: CompressSession

    var body: some View {
        Button(L10n.tr("menu.showWindow")) {
            MainWindowGateway.shared.open?()
        }

        Divider()

        Toggle(L10n.tr("menu.autoExport"), isOn: $session.autoExport)

        Button(L10n.tr("action.clearList")) {
            session.clearAll()
        }
        .disabled(session.isEmpty)

        Divider()

        Menu(L10n.tr("menu.language")) {
            ForEach(AppLanguagePreference.allCases) { preference in
                Button {
                    AppLanguage.setPreferenceAndRelaunch(preference)
                } label: {
                    Text(preference == AppLanguage.preference
                         ? "✓ \(preference.menuTitle)"
                         : preference.menuTitle)
                }
            }
        }

        SettingsLink {
            Text(L10n.tr("menu.preferences"))
        }
        .keyboardShortcut(",", modifiers: [.command])
        .simultaneousGesture(TapGesture().onEnded {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        })

        Divider()

        Button(L10n.tr("menu.quit")) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
