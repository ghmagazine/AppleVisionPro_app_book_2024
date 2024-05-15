//
//  Extensions.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/31.
//

import Foundation
import RealityKit
import SwiftUI

public extension Entity {

    /// マテリアルの更新
    /// - Parameter handler: マテリアルのパラメータ変更を行う関数
    func updateMaterial(_ handler: (inout ShaderGraphMaterial) throws -> Void) rethrows {
        
        guard var modelComponent = components[ModelComponent.self] else { return }
        guard var material = modelComponent.materials.first as? ShaderGraphMaterial else { return }

        try handler(&material)
        
        modelComponent.materials = [material]
        components.set(modelComponent)
    }
}

public extension CGColor {
    
    /// 2つのカラーをMixする
    /// - Parameters:
    ///   - color1: 1つ目のカラー
    ///   - color2: 2つ目のカラー
    ///   - ratio: ブレンド率
    /// - Returns: 混ぜ合わせた結果
    static func mix(_ color1: CGColor, _ color2:CGColor,_ ratio:CGFloat) -> CGColor? {
        guard let components1 = color1.components, let components2 = color2.components, components1.count == 4, components2.count == 4 else {
            return nil
        }
        
        let r:CGFloat = components1[0] * (1.0 - ratio) + components2[0] * ratio
        let g:CGFloat = components1[1] * (1.0 - ratio) + components2[1] * ratio
        let b:CGFloat = components1[2] * (1.0 - ratio) + components2[2] * ratio
        let a:CGFloat = components1[3] * (1.0 - ratio) + components2[3] * ratio
        
        return CGColor(red: r, green: g, blue: b, alpha: a)   
    }
}
