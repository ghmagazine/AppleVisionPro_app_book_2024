import SwiftUI

struct ProgramDetailPageView: View {
    @Environment(SharedViewModel.self) private var sharedViewModel
    @State var path = NavigationPath()
    
    private var dataSet: ProgramDataSet
    private var selected: () -> Void
    
    init(dataSet: ProgramDataSet, selected: @escaping () -> Void) {
        self.dataSet = dataSet
        self.selected = selected
    }
    
    var body: some View {
        @Bindable var sharedViewModel = sharedViewModel
        GeometryReader { proxy in
            let textWidth = min(max(proxy.size.width * 0.4, 300), 500)

            ZStack {
                VStack {
                    HStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(dataSet.title)
                                .font(.system(size: 40, weight: .bold))
                                .padding(.bottom, 15)
                            
                            Text(dataSet.description)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 30)
                        }
                        .frame(width: textWidth, alignment: .leading)
                        
                        Image(dataSet.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(32)
                            .padding()
                    }
                    .offset(y: -30)

                    Button {
                        selected()
                    } label: {
                        Text("このプログラムを開始する")
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(30)
    }
}
