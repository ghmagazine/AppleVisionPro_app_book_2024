import ARKit
import RealityKit
import SwiftUI

@available(visionOS 2.0, *)
public final class HandTrackingSystem: System {
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    private let arkitSession = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()

    public init(scene: RealityKit.Scene) {
        setupSession()
    }

    func setupSession() {
        Task {
            do {
                try await arkitSession.run([handTrackingProvider])
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        let handAnchors = handTrackingProvider.handAnchors(at: CACurrentMediaTime())
        
        context.entities(matching: Self.query, updatingSystemWhen: .rendering).forEach { entity in
            guard
                let component = entity.components[RealityKitContent.HandTrackingComponent.self],
                let handAnchor = getAnchor(handAnchors: handAnchors, chirality: component.chirality),
                handAnchor.isTracked,
                let joinName = component.jointName.Convert(),
                let joint = handAnchor.handSkeleton?.joint(joinName),
                joint.isTracked
            else {
                entity.isEnabled = false
                return
            }
            
            entity.isEnabled = true
            let scale = entity.scale
            entity.setTransformMatrix(handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform, relativeTo: nil)
            entity.scale = scale
        }
    }
    
    func getAnchor(handAnchors: (leftHand: HandAnchor?, rightHand: HandAnchor?), chirality: HandTrackingComponent.Chirality) -> HandAnchor?{
        var anchor: HandAnchor? = nil
        switch chirality {
        case .left:
            anchor = handAnchors.leftHand
        case .right:
            anchor = handAnchors.rightHand
        }
        return anchor
    }
}

@available(visionOS 1.0, *)
public final class HandTrackingSystemV1: System {
    static let query = EntityQuery(where: .has(RealityKitContent.HandTrackingComponent.self))
    
    private let arkitSession = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()
    private var latestAnchors: HandAnchors  = .init(left: nil, right: nil)
    
    struct HandAnchors {
        var left: HandAnchor?
        var right: HandAnchor?
        
        mutating func setAnchor(chirality: HandAnchor.Chirality, anchor: HandAnchor){
            switch chirality {
            case .left:
                left = anchor
            case .right:
                right = anchor
            }
        }
        
        func getAnchor(chirality: HandAnchor.Chirality) -> HandAnchor?{
            switch chirality {
            case .left:
                return left
            case .right:
                return right
            }
        }
    }

    public init(scene: RealityKit.Scene) {
        setupSession()
    }

    func setupSession() {
        Task {
            do {
                try await arkitSession.run([handTrackingProvider])
                for await update in handTrackingProvider.anchorUpdates {
                    switch update.event {
                    case .updated:
                        latestAnchors.setAnchor(chirality: update.anchor.chirality, anchor: update.anchor)
                    default:
                        break
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        context.entities(matching: Self.query, updatingSystemWhen: .rendering).forEach { entity in
            guard
                let component = entity.components[RealityKitContent.HandTrackingComponent.self],
                let handAnchor = latestAnchors.getAnchor(chirality: component.chirality.Convert()),
                handAnchor.isTracked,
                let joinName = component.jointName.Convert(),
                let joint = handAnchor.handSkeleton?.joint(joinName),
                joint.isTracked
            else {
                entity.isEnabled = false
                return
            }
            
            entity.isEnabled = true
            let scale = entity.scale
            entity.setTransformMatrix(handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform, relativeTo: nil)
            entity.scale = scale
        }
    }
}

