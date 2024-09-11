//
//  ImmersiveView.swift
//  Piano
//
//  Created by 守下誠 on 2024/08/11.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            
            _ = content.subscribe(to: CollisionEvents.Began.self){event in
                AudioPlaySystem.onCollisionBegan(event: event)
                PianoKeyAnimationSystem.onCollisionBegan(event: event)
            }
            
            _ = content.subscribe(to: CollisionEvents.Updated.self)
            { event in
                PianoKeyAnimationSystem.onCollisionUpdated(event: event)
            }
            
            _ = content.subscribe(to: CollisionEvents.Ended.self)
            { event in
                PianoKeyAnimationSystem.onCollisionEnded(event: event)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
