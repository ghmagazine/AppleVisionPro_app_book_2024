import SwiftUI

@main
struct MySpatialTimerApp: App {

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    @State private var appState = AppState()
    @State private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState, timerManager: timerManager)
        }
        .defaultSize(width: 400, height: 320)
        .onChange(of: scenePhase, initial: true) {
            dismissImmersiveSpaceIfNeeded(scenePhase: scenePhase)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(appState: appState, timerManager: timerManager)
        }
    }

    @MainActor
    private func dismissImmersiveSpaceIfNeeded(scenePhase: ScenePhase) {
        guard scenePhase != .active else { return }
        guard appState.immersiveSpaceOpened else { return }

        Task {
            await dismissImmersiveSpace()
            appState.didLeaveImmersiveSpace()
        }
    }
}
