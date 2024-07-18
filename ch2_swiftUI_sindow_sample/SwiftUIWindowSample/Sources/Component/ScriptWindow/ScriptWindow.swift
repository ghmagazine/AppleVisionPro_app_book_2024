import SwiftUI

struct ScriptWindow: View {
    @Environment(SharedViewModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Script")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.top, 24)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    ForEach(model.messageDataSets, id: \.self) { dataSet in
                        if dataSet.sender != .system {
                            ScriptItemView(dataSet: dataSet)
                                .environment(model)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                model.isShowingProgramWindow = true
            }
            .onDisappear {
                model.isShowingProgramWindow = false
                dismissWindow(id: "inputWindow")
                dismissWindow(id: "avatarWindow")
            }
        }
    }
}

#Preview {
    ScriptWindow()
}
