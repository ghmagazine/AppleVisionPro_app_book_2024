import SwiftUI
import RealityKit

struct ImmersiveView: View {

    var appState: AppState
    var timerManager: TimerManager

    @State private var immersiveViewModel = ImmersiveViewModel()

    var body: some View {

        RealityView { content, attachments in
            content.add(immersiveViewModel.setup(appState: appState, timerManager: timerManager))
            immersiveViewModel.addMarker()

            Task {
                await immersiveViewModel.runARKitSession()
            }
        } update: { update, attachments in
            for timerModel in timerManager.timerModels {
                if let attachment = attachments.entity(for: timerModel.id),
                   let placeHolder = immersiveViewModel.getTargetEntity(name: timerModel.id.uuidString) {

                    if !placeHolder.children.contains(attachment) {
                        placeHolder.addChild(attachment)
                    }
                }
            }

        } attachments: {
            ForEach(timerManager.timerModels) { timerModel in
                Attachment(id: timerModel.id) {
                    TimerView(immersiveViewModel: immersiveViewModel, timerManager: timerManager, timerModel: timerModel)
                }
            }
        }
        .task {
            // Works only on device
            await immersiveViewModel.processWorldAnchorUpdates()
        }
        .task {
            await immersiveViewModel.processDeviceAnchorUpdates()
        }
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { _ in
                immersiveViewModel.addPlaceHolder()
            })
        .onAppear() {
            appState.immersiveSpaceOpened(with: immersiveViewModel)
        }
        .onDisappear() {
            timerManager.saveTimerModels()
            appState.didLeaveImmersiveSpace()
        }
    }
}
