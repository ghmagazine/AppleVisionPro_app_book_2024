//
//  SunnyTuneSampleApp.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/24.
//

import SwiftUI

@main
struct SunnyTuneSampleApp: App {
    var model: SunnyTuneSampleModel = .init()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
        .defaultSize(width: 1000, height: 1000, depth: 1000)
        .windowStyle(.volumetric)
    }
}
