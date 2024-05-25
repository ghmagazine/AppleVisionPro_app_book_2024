import SwiftUI
import RealityKit

struct ContentView: View {

    var appState: AppState
    var timerManager: TimerManager

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    @State private var presentConfirmationDialog = false

    var body: some View {

        @Bindable var appState = appState

        VStack(spacing: 20) {
            Button("Remove All Timers", systemImage: "trash") {
                presentConfirmationDialog = true
            }
            .confirmationDialog("Remove all timers?", isPresented: $presentConfirmationDialog) {
                Button("Remove All", role: .destructive) {
                    timerManager.clearAllData()
                }
            }

            Button(appState.isAppendMode ? "Hide Marker" : "Show Marker", systemImage: "target") {
                appState.isAppendMode.toggle()
            }
            .disabled(!appState.immersiveSpaceOpened)

            if !appState.immersiveSpaceOpened {
                Button("Enter") {
                    Task {
                        switch await openImmersiveSpace(id: "ImmersiveSpace") {
                        case .opened:
                            break
                        case .error:
                            print("An error occurred when trying to open the immersive space")
                        case .userCancelled:
                            print("The user declined opening immersive space")
                        @unknown default:
                            break
                        }
                    }
                }
            } else {
                Button("Leave") {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
            }
        }
        .padding()
        .fixedSize()
        .onChange(of: appState.immersiveViewModel?.providersStoppedWithError, { _, providersStoppedWithError in
            guard let providersStoppedWithError else { return }
            // Immediately close the immersive space if there was an error.
            if providersStoppedWithError {
                if appState.immersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
                appState.immersiveViewModel?.resetProvidersStoppedWithError()
            }
        })
        .task {
            await appState.immersiveViewModel?.monitorSessionEvents()
        }
    }
}
