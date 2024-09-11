import RealityKit
import SwiftUI

public struct AudioPlaySystem: System {
    
    static let query = EntityQuery(where: .has(RealityKitContent.AudioSourceComponent.self))
    
    private var audioResources: [Entity: AudioResource] = [:]

    public init(scene: RealityKit.Scene) {
        _ = scene.subscribe(to: SceneEvents.DidAddEntity.self){event in
            print(event.entity.name)
        }
    }
    
    static public func onCollisionBegan(event: CollisionEvents.Began){
        guard
            event.entityA.components.has(RealityKitContent.AudioTriggerComponent.self),
            let audioSource = event.entityB.components[RealityKitContent.AudioSourceComponent.self]
        else { return }
        audioSource.play()
    }
    
    public mutating func update(context: SceneUpdateContext) {
        context.entities(matching: Self.query, updatingSystemWhen: .rendering).forEach { entity in
            
            guard let audioSource = entity.components[RealityKitContent.AudioSourceComponent.self]
            else { return }
            
            if audioResources[entity] == nil{
                audioResources[entity] = try? AudioFileResource.load(named: makeObjectPathFromRoot(target: entity)+audioSource.resourcePath, from: "Immersive.usda", in: realityKitContentBundle)
            }
            
            guard let resource = audioResources[entity]
            else { return }
            
            if audioSource.willPlay {
                entity.playAudio(resource)
                audioSource.willPlay = false
            }
        }
    }
    
    private func makeObjectPathFromRoot(target: Entity) -> String{
        var path = "/" + target.name
        var current = target
        while (current.parent != nil) {
            current = current.parent!
            path = "/" + current.name + path
            if current.name == "Root" { break }
        }
        return path
    }
}
