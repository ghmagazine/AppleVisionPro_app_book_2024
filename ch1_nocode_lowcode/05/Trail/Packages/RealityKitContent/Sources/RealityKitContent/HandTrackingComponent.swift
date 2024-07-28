import RealityKit
import ARKit

public struct HandTrackingComponent: Component, Codable {
    var chirality: Chirality = .left
    var jointName: JointName = .wrist

    public init() {
    }

    public enum Chirality: String, Codable, CaseIterable {
        case left
        case right
        
        public func Convert() -> HandAnchor.Chirality{
            switch self {
            case .left:
                return HandAnchor.Chirality.left
            case .right:
                return HandAnchor.Chirality.right
            }
        }
    }

    public enum JointName: String, Codable, CaseIterable {
        case wrist
        case thumbKnuckle
        case thumbIntermediateBase
        case thumbIntermediateTip
        case thumbTip
        case indexFingerMetacarpal
        case indexFingerKnuckle
        case indexFingerIntermediateBase
        case indexFingerIntermediateTip
        case indexFingerTip
        case middleFingerMetacarpal
        case middleFingerKnuckle
        case middleFingerIntermediateBase
        case middleFingerIntermediateTip
        case middleFingerTip
        case ringFingerMetacarpal
        case ringFingerKnuckle
        case ringFingerIntermediateBase
        case ringFingerIntermediateTip
        case ringFingerTip
        case littleFingerMetacarpal
        case littleFingerKnuckle
        case littleFingerIntermediateBase
        case littleFingerIntermediateTip
        case littleFingerTip
        case forearmWrist
        case forearmArm
        
        public func Convert() -> HandSkeleton.JointName?{
            return HandSkeleton.JointName.from(string: self.rawValue)!
        }
    }
}

extension CaseIterable {
    static func from(string: String) -> Self? {
        return Self.allCases.first { string == "\($0)" }
    }
    func toString() -> String { "\(self)" }
}
