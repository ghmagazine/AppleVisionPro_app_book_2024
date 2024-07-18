import SwiftUI

struct MainWindow: View {
    @Environment(SharedViewModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var selectedPage: PageType? = .home
    @State var path = NavigationPath()
    @State var input = ""
    @State var isPause: Bool = true
    
    var body: some View {
        NavigationSplitView {
            List(PageType.allCases, id: \.self, selection: $selectedPage) { page in
                HStack {
                    Image(systemName: page.iconName)
                    Text(page.title)
                }
            }
            .navigationTitle("Vision English")
        } detail: {
            switch selectedPage {
            case .home:
                NavigationStack(path: $path) {
                    HomePageView() { dataSet in
                        path.append(HomeScreen.programDetail(dataSet))
                    }
                    .environment(model)
                    .navigationDestination(for: HomeScreen.self) { screen in
                        switch screen {
                        case .programDetail(let dataSet):
                            ProgramDetailPageView(dataSet: dataSet) {
                                if !model.isShowingProgramWindow {
                                    openWindow(id: "inputWindow")
                                    openWindow(id: "scriptWindow")
                                    openWindow(id: "avatarWindow")
                                }
                            }
                            .environment(model)
                        }
                    }
                    .navigationBarHidden(false)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            makeNavigationBarLeadingSection()
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            makeNavigationBarTrailingSection()
                        }
                    }
                    .ornament(attachmentAnchor: .scene(.bottom)) {
                        #warning("Mock")
                        makeOrnamentSection(imageName: "cafe", title: "カフェで注文しよう", description:"カフェで注文を完了させよう")
                    }
                }
                
            case .setting:
                SettingPageView()
                    .environment(model)
                    .navigationTitle("Setting")
                
            case .none:
                Text("Error")
            }
        }
    }
    
    #warning("Mock")
    private func makeNavigationBarLeadingSection() -> some View {
        VStack(alignment: .leading) {
            Text("Home")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)
            Text("プログラムを選択")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
    
    #warning("Mock")
    private func makeNavigationBarTrailingSection() -> some View {
        HStack(alignment: .center, spacing: 16) {
            TextField("プログラムを検索", text: $input)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .contentShape(.capsule)

            Button(action: {
                print("検索", input)
            }, label: {
                Image(systemName: "magnifyingglass")
                    
            })
            .contentShape(.circle)
        }
    }
    
    private func makeOrnamentSection(imageName: String, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(4)
                .padding(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, .zero)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .frame(minWidth: 500)
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
            Toggle(isOn: $isPause){
                isPause ?  Image(systemName: "play.fill") : Image(systemName: "pause.fill")
            }
            .toggleStyle(.button)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 32)
        .glassBackgroundEffect()
    }
}

#Preview {
    MainWindow()
}
