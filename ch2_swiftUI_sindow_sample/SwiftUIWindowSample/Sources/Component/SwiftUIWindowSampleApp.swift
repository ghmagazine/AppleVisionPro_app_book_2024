import SwiftUI

@main
struct SwiftUIWindowSampleApp: App {
    @State private var sharedViewModel = SharedViewModel()

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            MainWindow()
                .environment(sharedViewModel)
        }
        
        WindowGroup(id: "inputWindow") {
            InputWindow()
                .environment(sharedViewModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        WindowGroup(id: "scriptWindow") {
            ScriptWindow()
                .environment(sharedViewModel)
        }
        .defaultSize(width: 500, height: 1000)
        
        WindowGroup(id: "avatarWindow") {
            AvatarWindow()
                .environment(sharedViewModel)
        }
        .defaultSize(width: 2500, height: 2500, depth: 1000)
        .windowStyle(.volumetric)
    }
}
