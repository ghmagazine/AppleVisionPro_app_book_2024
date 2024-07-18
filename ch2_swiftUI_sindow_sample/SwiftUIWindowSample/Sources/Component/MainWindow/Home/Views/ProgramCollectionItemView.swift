import SwiftUI

struct ProgramCollectionItemView: View {
    private var dataSet: ProgramDataSet
    
    init(dataSet: ProgramDataSet) {
        self.dataSet = dataSet
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(dataSet.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 190, height: 190)
                .clipped()
                .cornerRadius(10)
                .padding(8)
            Text(dataSet.title)
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.bottom, .zero)
                .lineLimit(1)
            Text(dataSet.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary) // 基本的に色はつけないでsecondaryとかで分ける
                .padding(.horizontal, 8)
                .lineLimit(1)
        }
        .padding(8)
        .contentShape(.interaction, .rect) // 当たり判定の幅をコントロールするmodifire
        .contentShape(.hoverEffect, .rect(cornerRadius: 16)) // hoverEffectのcornerRadiusを設定できる
        .hoverEffect() // hoverEffect追加用
    }
}

#Preview {
    ProgramCollectionItemView(
        dataSet: ProgramDataSet(
            id: "s1",
            title: "カフェで注文しよう",
            description: "あなたが訪れたのはニューヨークの人気カフェ、飲み物や食べ物の注文をしてみましょう！",
            imageName: "cafe",
            difficulty: 1,
            talkPromptData: TalkPromptDataModel(
                prompt: "You are a barista and I am a customer ordering drinks and snacks at the New York Cafe, which has its own on-site bakery.",
                firstMessage: "Welcome, would you like to order?"
            )
        )
    )
}
