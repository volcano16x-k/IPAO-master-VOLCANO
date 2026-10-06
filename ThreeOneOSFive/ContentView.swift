import SwiftUI
import WebKit

// WebView لعرض Spotify
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
                // استدعاء واجهة التطبيق الأصلية بالتنشيط والميزات
                AppTabView()
            } else {
                // عرض Spotify مع المنطقة التفاعلية المخفية
                ZStack(alignment: .topLeading) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
                    // ضغط 3 مرات في الزاوية العلوية اليسرى لفتح التطبيق الاصلي
                    Color.clear
                        .frame(width: 100, height: 80)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) {
                            showMainApp = true
                        }
                }
            }
        }
    }
}
