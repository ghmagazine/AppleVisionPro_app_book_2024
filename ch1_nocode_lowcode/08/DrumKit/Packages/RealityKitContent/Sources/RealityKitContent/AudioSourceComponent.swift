import RealityKit

public class AudioSourceComponent: Component, Codable{
    public var resourcePath = "/Audio"
    public var willPlay: Bool = false

    public init() {
    }
    
    public func play(){
        willPlay = true
    }
}
