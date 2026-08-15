import SwiftUI

@main
struct EggplantTinyPNGApp: App {
    @StateObject private var session = CompressSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
