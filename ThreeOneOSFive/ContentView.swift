import SwiftUI

struct ContentView: View {
    @State private var showMainApp = false

    var body: some View {
        ZStack {
            if showMainApp {
                // الواجهة الرئيسية لتطبيقك (VOLCANO)
                VStack(spacing: 20) {
                    Text("أهلاً بك في VOLCANO")
                        .font(.largeTitle)
                        .bold()
                    
                    Button("العودة إلى Spotify") {
                        showMainApp = false
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                // عرض موقع Spotify
                ZStack(alignment: .topTrailing) {
                    SpotifyWebView(url: URL(string: "https://open.spotify.com/intl-fr")!)
                        .edgesIgnoringSafeArea(.all)
                    
                    // زر مخفي في الأعلى للرجوع إلى تطبيقك
                    Button(action: {
                        showMainApp = true
                    }) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
            }
        }
    }
}
