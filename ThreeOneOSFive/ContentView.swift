import SwiftUI

struct ContentView: View {
    @State private var showMainApp = false
    
    // إنشاء URL آمن
    private let spotifyURL = URL(string: "https://open.spotify.com/intl-fr")

    var body: some View {
        ZStack {
            if showMainApp {
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
                ZStack(alignment: .topTrailing) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
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
