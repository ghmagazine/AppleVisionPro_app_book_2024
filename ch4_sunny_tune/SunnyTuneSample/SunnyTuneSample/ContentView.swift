//
//  ContentView.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @EnvironmentObject var model: SunnyTuneSampleModel
    
    @State var time: Double = 0
    @State var cloud: Double = 0
    @State var windAngle: Double = 0
    @State var isUpdateTree: Bool = false
    @State var growCount: Int = 0
    
    var body: some View {
        ZStack {
            RealityView { content in
                // シーンの読み込み処理.
                // RealityKitContent内の Scene.usdz をロードしています.
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {

                    // 読み込んだシーンを元にモデルをセットアップします
                    try? await model.setup(scene: scene)
                    
                    // RealityViewContentに追加することでVolumeWindowに描画されます.
                    content.add(scene)
                }
            }
            VStack {
                // 時間の操作用のスライダー
                HStack {
                    Image(systemName:"clock.fill")
                    Slider(value: $time, in: 0...23)
                        .onChange(of: time) { oldValue, newValue in
                            let date = model.getTodayDate(hour: newValue)
                            try? model.updateTime(now: date)
                        }
                }
                // 雲の操作用のスライダー
                HStack {
                    Image(systemName: "cloud.fill")
                    Slider(value: $cloud, in: 0...1)
                        .onChange(of: cloud) { oldValue, newValue in
                            try? model.updateCloud(cloud: Float(newValue))
                        }
                }
                // 風の操作用のスライダー
                HStack {
                    Image(systemName: "wind")
                    Slider(value: $windAngle, in: 0...360)
                        .onChange(of: windAngle) { oldValue, newValue in
                            try? model.updateWind(angle: Angle(degrees: newValue))
                        }
                }
                // 木の成長用ボタン
                Button {
                    self.isUpdateTree = true
                    Task {
                        growCount += 1
                        try? await self.model.growTree()
                        self.isUpdateTree = false
                    }
                } label: {
                    Text("Grow Tree")
                }.disabled(self.isUpdateTree || growCount > 2)
            }
            .padding()
            .glassBackgroundEffect()
            .frame(width: 300)
            .offset(y: 250)
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
