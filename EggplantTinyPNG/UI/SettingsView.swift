import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themes = ThemeStore.shared

    var body: some View {
        TabView {
            GeneralSettingsPane(themes: themes)
                .tabItem {
                    Label(L10n.tr("settings.general"), systemImage: "gearshape")
                }

            AboutView()
                .tabItem {
                    Label(L10n.tr("settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 440, height: 400)
    }
}

private struct GeneralSettingsPane: View {
    @ObservedObject var themes: ThemeStore
    @State private var selectedLanguage = AppLanguage.preference

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 10), count: 6)

    var body: some View {
        Form {
            Section {
                Picker(L10n.tr("settings.language"), selection: $selectedLanguage) {
                    ForEach(AppLanguagePreference.allCases) { preference in
                        Text(preference.menuTitle).tag(preference)
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    AppLanguage.setPreferenceAndRelaunch(newValue)
                }

                Text(L10n.tr("settings.language.hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text(L10n.tr("settings.theme"))
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AppTheme.all) { theme in
                        Button {
                            themes.id = theme.id
                        } label: {
                            ThemeChip(theme: theme, selected: themes.id == theme.id, size: 36)
                        }
                        .buttonStyle(.plain)
                        .help(theme.name)
                        .accessibilityLabel(theme.name)
                    }
                }
                .padding(.vertical, 4)

                Text(L10n.tr("settings.theme.hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .onAppear {
            selectedLanguage = AppLanguage.preference
        }
    }
}
