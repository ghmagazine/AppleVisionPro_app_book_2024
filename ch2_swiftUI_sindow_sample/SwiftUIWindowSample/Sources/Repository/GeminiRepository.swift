import GoogleGenerativeAI
import Foundation

final class GeminiRepository {
    let model = GenerativeModel(
        name: "gemini-pro",
        apiKey: "API Key",
        generationConfig: GenerationConfig(temperature: 1, maxOutputTokens: 1000)
    )
    
    public func request(allMessages: [ModelContent], sendMessage: String) async throws -> String {
        do {
            let chat = model.startChat(history: allMessages)
            let response = try await chat.sendMessage(sendMessage)
            return response.text ?? ""
        }
        catch {
            throw error
        }
    }
}
