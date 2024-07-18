import SwiftUI

struct ScriptItemView: View {
    @Environment(SharedViewModel.self) private var model
    private var dataSet: MessageModel
    
    init(dataSet: MessageModel) {
        self.dataSet = dataSet
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(dataSet.sender == .ai ? "gemini" : "user")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                Text(dataSet.message)
                    .font(.system(size: 24))
                Spacer()
                Button(action: {
                    model.translate(messageModel: dataSet)
                }, label: {
                    Image(systemName: "textformat")
                })
            }
            if let translateMessage = dataSet.translateMessage {
                HStack {
                    Text(translateMessage)
                        .font(.system(size: 20))
                        .padding()
                    Spacer()
                }
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThickMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    ScriptItemView(dataSet: MessageModel(message: "", translateMessage: "", sender: .ai))
}
