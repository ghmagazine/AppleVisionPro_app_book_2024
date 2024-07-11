import ARKit
import RealityKit
import SwiftUI

public struct CustomPhysicsSimulationSystem: System {
    static let query = EntityQuery(where: .has(RealityKitContent.CustomPhysicsSimulationComponent.self))
    
    public init(scene: RealityKit.Scene) {
    }

    public mutating func update(context: SceneUpdateContext) {
        context.entities(matching: Self.query, updatingSystemWhen: .rendering).forEach { entity in
            guard
                let component = entity.components[RealityKitContent.CustomPhysicsSimulationComponent.self]
            else { return }
            if !entity.components.has(PhysicsSimulationComponent.self){
                entity.components.set(PhysicsSimulationComponent())
                entity.components[PhysicsSimulationComponent.self]?.gravity = component.gravity
            }
        }
    }
}
