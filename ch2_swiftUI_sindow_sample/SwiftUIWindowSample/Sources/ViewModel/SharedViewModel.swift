import AVFoundation
import GoogleGenerativeAI
import SwiftUI

@Observable
class SharedViewModel {
    let geminiRepository = GeminiRepository()
    let translateRepository = TranslateRepository()
    let synthesizer = AVSpeechSynthesizer()

    var situationContents: [ProgramDataSet] = ProgramContentsRepository().situationContents
    var latestAIMessage: String = ""
    var translateTask: Task<Void, Error>?
    var isShowingProgramWindow: Bool = false
    var messageDataSets: [MessageModel] = []
    
    func sendMessage(message: String, sender: MessageModel.Sender) {
        let allMessages = messageDataSets.map {
            ModelContent(role: $0.role, $0.message)
        }
        messageDataSets.append(MessageModel(message: message, sender: sender))

        Task {
            do {
                let response = try await geminiRepository.request(allMessages: allMessages, sendMessage: message)
                latestAIMessage = response
                messageDataSets.append(MessageModel(message: response, sender: .ai))
                text2speech(text: response)
            }
            catch {
                print(error)
            }
        }
    }
    
    func translate(messageModel: MessageModel) {
        // 既存のタスクがあればキャンセル
        translateTask?.cancel()
        let translateMessage = messageModel.message
        translateTask = Task {
            do {
                let result = try await translateRepository.request(text: translateMessage, source: "en", target: "ja")
                if let index = messageDataSets.firstIndex(where: { $0.id == messageModel.id }) {
                    var model = messageDataSets[index]
                    model.translateMessage = result
                    messageDataSets[index] = model
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func text2speech(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-GB_compact")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
