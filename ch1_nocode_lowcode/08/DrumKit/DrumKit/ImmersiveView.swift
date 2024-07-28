//
//  ImmersiveView.swift
//  DrumKit
//
//  Created by 守下誠 on 2024/07/11.
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
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
