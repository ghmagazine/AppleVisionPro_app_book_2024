import RealityKit

public struct PianoKeyAnimationSystem: System {
    
    static let query = EntityQuery(where: .has(RealityKitContent.PianoKeyComponent.self))
    
    static public func onCollisionBegan(event: CollisionEvents.Began){
        guard
            event.entityA.components[RealityKitContent.AudioTriggerComponent.self] != nil,
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] != nil
        else {return}
        
        if var pianoKeyComponent = event.entityB.components[RealityKitContent.PianoKeyComponent.self]{
            pianoKeyComponent.strokeKey.append(event.entityA.name)
            pianoKeyComponent.strokeValue.append(min(event.entityA.position(relativeTo: nil).y - event.entityB.position(relativeTo: nil).y, 0))
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] = pianoKeyComponent
        }
    }
    
    static public func onCollisionUpdated(event: CollisionEvents.Updated){
        guard
            event.entityA.components[RealityKitContent.AudioTriggerComponent.self] != nil,
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] != nil
        else {return}
        
        if var pianoKeyComponent = event.entityB.components[RealityKitContent.PianoKeyComponent.self]{
            if let index = pianoKeyComponent.strokeKey.firstIndex(of: event.entityA.name){
                pianoKeyComponent.strokeValue[index] = min(event.entityA.position(relativeTo: nil).y - event.entityB.position(relativeTo: nil).y, 0)
            }
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] = pianoKeyComponent
        }
    }
    
    static public func onCollisionEnded(event: CollisionEvents.Ended){
        guard
            event.entityA.components[RealityKitContent.AudioTriggerComponent.self] != nil,
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] != nil
        else {return}
        
        if var pianoKeyComponent = event.entityB.components[RealityKitContent.PianoKeyComponent.self]{
            if let index = pianoKeyComponent.strokeKey.firstIndex(of: event.entityA.name){
                pianoKeyComponent.strokeKey.remove(at: index)
                pianoKeyComponent.strokeValue.remove(at: index)
            }
            event.entityB.components[RealityKitContent.PianoKeyComponent.self] = pianoKeyComponent
        }
    }

    public init(scene: Scene) {
    }
    
    public func update(context: SceneUpdateContext) {
        
        context.scene.performQuery(Self.query).forEach { entity in
            if let pianoKeyComponent = entity.components[RealityKitContent.PianoKeyComponent.self]{
                
                if let key = entity.findEntity(named: "Key"){
                    if pianoKeyComponent.strokeValue.isEmpty {
                        key.position = SIMD3<Float>(0, lerp(start: key.position.y, end: 0, value: 0.3), 0)
                    }else{
                        let stroke = pianoKeyComponent.strokeValue.min()!
                        key.position = SIMD3<Float>(0, lerp(start: key.position.y, end: stroke / key.scale(relativeTo: nil).y, value: 0.3), 0)
                    }
                }
                
                entity.components[RealityKitContent.PianoKeyComponent.self] = pianoKeyComponent
            }
        }
    }
    
    private func lerp(start: Float, end: Float, value: Float) -> Float{
        return start + (end - start) * value
    }
}
