//
//  PianoApp.swift
//  Piano
//
//  Created by 守下誠 on 2024/08/11.
//

import SwiftUI
import RealityKitContent

@main
struct PianoApp: App {
    
    init() {
        RealityKitContent.HandTrackingComponent.registerComponent()
        RealityKitContent.HandTrackingSystem.registerSystem()
        RealityKitContent.AudioTriggerComponent.registerComponent()
        RealityKitContent.AudioSourceComponent.registerComponent()
        RealityKitContent.AudioPlaySystem.registerSystem()
        RealityKitContent.PianoKeyComponent.registerComponent()
        RealityKitContent.PianoKeyAnimationSystem.registerSystem()
    }

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
