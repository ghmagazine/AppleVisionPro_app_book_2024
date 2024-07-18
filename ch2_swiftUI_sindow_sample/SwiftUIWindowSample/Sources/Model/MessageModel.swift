import Foundation

public struct MessageModel: Hashable {
    enum Sender {
        case ai
        case user
        case system
    }
    
    var id: UUID
    var message: String
    var translateMessage: String?
    var sender: Sender
    
    init(
        message: String,
        translateMessage: String? = nil,
        sender: Sender
    ) {
        self.id = UUID()
        self.message = message
        self.translateMessage = translateMessage
        self.sender = sender
    }
}

extension MessageModel {
    var role: String {
        switch sender {
        case .ai:
            return "model"
            
        case .user:
            return "user"
            
        case .system:
            return "user"
        }
    }
}
