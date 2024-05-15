//
//  ContentView.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct WindowSizeView: View {
    var body: some View {
        RealityView { content in
            // Windowサイズピッタリだとウィンドウ外に行ってしまうため、0.8の補正をかけています。
            // 単位は メートル での指定になります。
            let ratio: Float = 0.8
            let width:Float = 1 * ratio
            let height:Float = 1 * ratio
            let depth:Float = 1 * ratio
            
            let sphere = MeshResource.generateSphere(radius: 0.1)
            let center = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            center.position += [0, 0, 0]
            content.add(center)
            
            let right = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            right.position += [width/2, 0, 0]
            content.add(right)
            let left = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            left.position -= [width/2, 0, 0]
            content.add(left)
            let top = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            top.position += [0, height/2, 0]
            content.add(top)
            let bottom = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            bottom.position -= [0, height/2, 0]
            content.add(bottom)
            let forward = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            forward.position += [0, 0, depth/2]
            content.add(forward)
            let backward = ModelEntity(mesh: sphere, materials: [SimpleMaterial()])
            backward.position -= [0, 0, depth/2]
            content.add(backward)
        }
    }
}

#Preview(windowStyle: .volumetric) {
    WindowSizeView()
}
