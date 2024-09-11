import RealityKit

public struct PianoKeyComponent: Component, Codable {
    
    public var strokeKey: [String] = []
    public var strokeValue: [Float] = []

    public init() {
    }
}
