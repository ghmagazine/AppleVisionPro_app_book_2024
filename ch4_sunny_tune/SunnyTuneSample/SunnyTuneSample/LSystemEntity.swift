//
//  LSystemTree.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/31.
//

import CoreLocation
import SwiftUI
import RealityKit
import RealityKitContent

class EmbeddedModel {
    let vertices:[SIMD3<Float>]
    let normals:[SIMD3<Float>]
    let texcoord:[SIMD2<Float>]
    let indices:[UInt32]
    init(vertices: [SIMD3<Float>], normals: [SIMD3<Float>], texcoord: [SIMD2<Float>], indices: [UInt32]) {
        self.vertices = vertices
        self.normals = normals
        self.texcoord = texcoord
        self.indices = indices
    }
    static let leef: EmbeddedModel = EmbeddedModel(
        vertices: [[-0.5,0,0.01],[0.5,0,0.01],[-0.5,1,0.01],[0.5,1,0.01],[-0.5,0,-0.01],[0.5,0,-0.01],[-0.5,1,-0.01],[0.5,1,-0.01]],
        normals: [[0,0,-0.5],[0,0,-0.5],[0,0,-0.5],[0,0,-0.5],[0,0,0.5],[0,0,0.5],[0,0,0.5],[0,0,0.5]],
        texcoord: [[0,0],[1,0],[0,1],[1,1],[0,0],[1,0],[0,1],[1,1]],
        indices: [0,2,3,0,3,1,4,7,6,4,5,7]
    )
}


class LSystemEntity: Entity {
    
    struct Node {
        var startIndex: UInt32
        var center: SIMD3<Float>
        var angles: SIMD3<Float>
        var thickness: Float
    }
    
    public var growLength:Float = 0.02
    public var growThickness:Float = 0.02
    public var growAngle:Float = 20
    
    private(set) var model: ModelEntity? = nil
    private let subdivide: Int = 12
    private let thicknessAttenuation:Float = 0.9
    private let treeVRange: SIMD2<Float> = [0, 0.5]
    private let leefVRange: SIMD2<Float> = [0.51, 0.99]
    private let leefUWidth: Float = 0.5
    private var lsystem: LSystem = .init(initialSymbol: "X", rule: ["F":"FF", "X":"F[+X-X]L"])
    private var material: ShaderGraphMaterial? = nil
    
    /// セットアップ
    /// - Parameter lsystem: 使用するシステム
    func setup(lsystem:LSystem, material:ShaderGraphMaterial) async throws {
        self.lsystem = lsystem
        self.material = material
        try await updateModel()
    }
    
    /// 木を成長させる
    func grow() async throws {
        lsystem.grow()
        try await updateModel()
    }
    
    /// モデルの更新処理
    private func updateModel() async throws {

        let mesh = try await generateMesh()
        
        if self.model == nil {
            self.model = ModelEntity(mesh:mesh, materials: [self.material!])
            self.model?.setParent(self)
        } else {
            if let modelComponent = self.model?.components[ModelComponent.self] {
                try await modelComponent.mesh.replace(with: mesh.contents)
            }
        }
    }
    
    /// メッシュ生成処理
    /// - Returns: 生成したメッシュ
    private func generateMesh() async throws -> MeshResource {

        var positions:[SIMD3<Float>] = []
        var normals:[SIMD3<Float>] = []
        var texcoords:[SIMD2<Float>] = []
        var indices:[UInt32] = []
        
        var node: Node = .init(startIndex: 0, center: [0,0,0], angles: [0,0,0], thickness: self.growThickness)
        var stack:[Node] = []

        // 最初の頂点を作成する
        node = appendBranchVertics(positions: &positions, normals: &normals, texcoords: &texcoords, indices: &indices, node:node, length: 0)
        
        for c in lsystem.symbol {
            switch(c)
            {
            case "p":
                node.angles.x += self.growAngle
                break
            case "P":
                node.angles.x -= self.growAngle
                break
            case "y":
                node.angles.y += self.growAngle
                break
            case "Y":
                node.angles.y -= self.growAngle
                break
            case "+":
                node.angles.z += self.growAngle
                break
            case "-":
                node.angles.z -= self.growAngle
                break
            case "[":
                stack.append(node)
                break
            case "]":
                node = stack.last!
                stack.removeLast()
                break
            case "L":
                // 葉っぱ用の頂点を追加する
                appendLeefVertices(positions: &positions, normals: &normals, texcoords: &texcoords, indices: &indices, node:node)
                break
            default:
                // 枝用の頂点を追加する
                node = appendBranchVertics(positions: &positions, normals: &normals, texcoords: &texcoords, indices: &indices, node:node, length: self.growLength)
                node.thickness *= thicknessAttenuation
                break
            }
        }
        
        // 追加した頂点を元にメッシュを作成する.
        var meshDescriptor:MeshDescriptor = .init()
        meshDescriptor.positions = MeshBuffers.Positions(positions)
        meshDescriptor.primitives = .triangles(indices)
        meshDescriptor.normals = MeshBuffers.Normals(normals)
        meshDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(texcoords)
        return try await MeshResource(from: [meshDescriptor])
    }
    
    
    /// 枝用の頂点を追加する
    /// - Parameters:
    ///   - positions: 頂点配列
    ///   - normals: 法線配列
    ///   - texcoords: テクスチャ座標配列
    ///   - indices: 頂点インデックス配列
    ///   - center: 頂点の中心座標
    ///   - angles: 頂点の角度
    ///   - length: 枝の長さ
    ///   - thickness: 枝の太さ
    /// - Returns: 新しいNode
    private func appendBranchVertics(
        positions:inout [SIMD3<Float>],
        normals:inout [SIMD3<Float>],
        texcoords:inout [SIMD2<Float>],
        indices:inout [UInt32],
        node:Node,
        length:Float) -> Node
    {
        // 開始時点の頂点インデックス
        let startIndex = UInt32(positions.endIndex)
        // 前回の頂点が開始したインデックス
        let lastStartIndex = node.startIndex
        
        // 角度から回転用のQuaternionを作成
        var rotation = simd_quatf(angle:node.angles.z * .pi / 180.0, axis: [0,0,1])
        rotation *= simd_quatf(angle:node.angles.y * .pi / 180.0, axis: [0,1,0])
        rotation *= simd_quatf(angle:node.angles.x * .pi / 180.0, axis: [1,0,0])
        
        // 分割数に合わせてどれだけ角度をずらしていくか計算.
        let stepRadian = 2.0 * .pi / Float(subdivide)
        for i in 0..<subdivide {
            
            // Yを軸に円周上の頂点の位置を計算.
            let radian = stepRadian * Float(i)
            let sin = sinf(radian)
            let cos = cosf(radian)
            let x:Float = sin * node.thickness
            let z:Float = cos * node.thickness
            let y:Float = length
            
            // 回転を加えて前回の中心位置に足して位置を決める
            let position = rotation.act([x,y,z])
            positions.append(node.center + position)
            
            // 回転を加えて法線を計算する
            let normal = (simd_quatf(angle: radian, axis:[0,1,0]) * rotation).act([0,0,1])
            normals.append(normal)
            
            // UV座標の計算.
            // U は 円周をぐるっと一周するようにしている.
            // V は Y座標によって割り当てつつ fmod で 木の幹部分を繰り返すようにしている.
            texcoords.append([Float(i)/Float(subdivide), fmod(y, treeVRange.y)])
        }
        
        // 頂点インデックスの設定
        // 前回生成した頂点と結合していく.
        for i in 0..<subdivide-1 {
            let index = UInt32(i)
            indices.append(startIndex+index)
            indices.append(lastStartIndex+index)
            indices.append(lastStartIndex+index+1)
            
            indices.append(startIndex+index)
            indices.append(lastStartIndex+index+1)
            indices.append(startIndex+index+1)
        }
        
        // 最後は最初の頂点と結合させる
        let endIndex = startIndex+UInt32(subdivide-1)
        indices.append(endIndex)
        indices.append(lastStartIndex+UInt32(subdivide-1))
        indices.append(lastStartIndex)
        
        indices.append(endIndex)
        indices.append(lastStartIndex)
        indices.append(startIndex)
        
        // 頂点追加後の状態を返す
        return Node(
            startIndex: startIndex,
            center: node.center + rotation.act([0,length,0]),
            angles: node.angles,
            thickness: node.thickness)
    }
    
    
    
    /// 葉っぱ用の頂点を追加する
    /// - Parameters:
    ///   - positions: 頂点配列
    ///   - normals: 法線配列
    ///   - texcoords: テクスチャ座標配列
    ///   - indices: 頂点インデックス配列
    ///   - center: 頂点の中心座標
    ///   - angles: 頂点の角度
    private func appendLeefVertices(
        positions:inout [SIMD3<Float>],
        normals:inout [SIMD3<Float>],
        texcoords:inout [SIMD2<Float>],
        indices:inout [UInt32],
        node:Node)
    {
        let leef = EmbeddedModel.leef
        let startIndex = UInt32(positions.count)
        
        var rotation = simd_quatf(angle:node.angles.z * .pi / 180.0, axis: [0,0,1])
        rotation *= simd_quatf(angle:node.angles.y * .pi / 180.0, axis: [0,1,0])
        rotation *= simd_quatf(angle:node.angles.x * .pi / 180.0, axis: [1,0,0])

        let offsetU = 0
        for i in 0..<leef.vertices.count {
            let position = rotation.act(leef.vertices[i] * 0.1)
            positions.append(node.center + position)
            normals.append(rotation.act(leef.normals[i]))
            
            // ２枚葉っぱの画像を並べているので どの位置の画像を使うか計算
            let u = (leef.texcoord[i].x * leefUWidth) + Float(offsetU) * leefUWidth
            // Vの長さを計算.
            let vLength = leefVRange.y - leefVRange.x
            // texcoord.yの0~1をVの位置に合わせる
            let v = (leef.texcoord[i].y * vLength + leefVRange.x)
            texcoords.append([u,v])
        }
        
        for i in 0..<leef.indices.count {
            indices.append(startIndex + leef.indices[i])
        }
    }
}
