import SwiftUI

@main
struct EggplantTinyPNGApp: App {
    @StateObject private var session = CompressSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Toggle("自动导出", isOn: $session.autoExport)
                    .keyboardShortcut("e", modifiers: [.command])
            }
            CommandGroup(replacing: .saveItem) {
                Button("清除列表") {
                    session.clearAll()
                }
                .keyboardShortcut("k", modifiers: [.command])
                .disabled(session.isEmpty)
            }
        }
    }
}
