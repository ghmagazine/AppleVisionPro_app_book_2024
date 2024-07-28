import RealityKit

public struct CustomPhysicsSimulationComponent: Component, Codable {
    var gravity: SIMD3<Float> = SIMD3<Float>(x: 0, y: -9.8, z: 0)

    public init() {
    }
}
