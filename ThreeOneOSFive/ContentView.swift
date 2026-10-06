import SwiftUI

struct ContentView: View {
    @State private var isInterfaceHidden = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture(count: 3) {
                    if isInterfaceHidden {
                        withAnimation { isInterfaceHidden = false }
                    }
                }

            if !isInterfaceHidden {
                VStack(spacing: 20) {
                    VStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("VOLCANO")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 3) {
                        withAnimation { isInterfaceHidden = true }
                    }
                    .padding(.top, 50)

                    Spacer()

                    Text("اضغط 3 مرات على الشعار لإخفاء الواجهة")
                        .foregroundColor(.gray)
                        .font(.footnote)

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
