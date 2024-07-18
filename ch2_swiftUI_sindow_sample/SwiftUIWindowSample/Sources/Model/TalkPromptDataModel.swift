public struct TalkPromptDataModel: Hashable, Codable {
    var prompt: String
    var firstMessage: String
    
    init(prompt: String, firstMessage: String) {
        self.prompt = prompt
        self.firstMessage = firstMessage
    }
}
