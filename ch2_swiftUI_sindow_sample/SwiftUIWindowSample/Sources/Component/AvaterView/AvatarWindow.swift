import SwiftUI
import RealityKit

struct AvatarWindow: View {
    @Environment(SharedViewModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var animate = false
    @State private var avatar: Entity? = nil
    
    var body: some View {
        ZStack {
            RealityView { content in
                avatar = try? await Entity(named: "talking_women")
                if let avatar {
                    avatar.position = [0, -0.9, 0]
                    content.add(avatar)
                }
            }
            VStack {
                Text(model.latestAIMessage)
                    .font(.system(size: 48))
                    .lineLimit(2)
                    .frame(width: 700)
                    .padding()
                    .glassBackgroundEffect()
                Spacer()
            }
        }
        .onChange(of: model.latestAIMessage) { _, _ in
            guard let avatar,
                  let animation = avatar.availableAnimations.first?.repeat(count: 2) else { return }
            avatar.playAnimation(animation)
        }
        .onAppear {
            model.isShowingProgramWindow = true
        }
        .onDisappear {
            model.isShowingProgramWindow = false
            dismissWindow(id: "inputWindow")
            dismissWindow(id: "scriptWindow")
        }
    }
}

#Preview {
    AvatarWindow()
}
