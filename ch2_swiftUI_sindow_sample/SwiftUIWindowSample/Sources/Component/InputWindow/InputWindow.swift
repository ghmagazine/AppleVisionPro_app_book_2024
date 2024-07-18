import SwiftUI

struct InputWindow: View {
    @Environment(SharedViewModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @State var input = ""
    let promptMessage = "You are an English teacher. I am a student and we practice conversation in various situations. You return in natural English. You will return conversations in 20 words or less."

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
                .frame(width: 50)
            TextField("会話を入力", text: $input)
                .font(.system(size: 32))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .frame(width: 1000, height: 50)
            Button(action: {
                model.sendMessage(message: input, sender: .user)
                input = ""
            }, label: {
                Image(systemName: "paperplane.fill")
            })
            .frame(width: 50, height: 50)
            .contentShape(.circle)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassBackgroundEffect(displayMode: .implicit)
        .cornerRadius(50)
        .onAppear {
            model.isShowingProgramWindow = true
            model.sendMessage(message: promptMessage, sender: .system)
        }
        .onDisappear {
            model.isShowingProgramWindow = false
            dismissWindow(id: "avatarWindow")
            dismissWindow(id: "scriptWindow")
        }
    }
}

#Preview {
    InputWindow()
}
