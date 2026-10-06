import SwiftUI
import WebKit

// تعريف الـ WebView في نفس الملف لتجنب خطأ الربط
struct SpotifyWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @State private var showMainApp = false
    private let spotifyURL = URL(string: "https://open.spotify.com/intl-fr")

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
                // عرض شاشة Spotify
                ZStack(alignment: .topTrailing) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
                    // زر مخفي في الأعلى للرجوع للتطبيق
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
