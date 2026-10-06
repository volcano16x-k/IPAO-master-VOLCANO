import SwiftUI
import WebKit

// 1. WebView لعرض Spotify
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

// 2. الواجهة الرئيسية للتحكم
struct ContentView: View {
    @State private var showMainApp = false
    private let spotifyURL = URL(string: "https://open.spotify.com/intl-fr")

    var body: some View {
        ZStack {
            if showMainApp {
                // استدعاء واجهة التحكم والمستندات الأصلية للتطبيق
                FilesTabControls()
            } else {
                // عرض Spotify مع منطقة لمس شفافة فوق شعار Spotify (في الأعلى يساراً)
                ZStack(alignment: .topLeading) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
                    // زر شفاف (غير مرئي) يستجيب لـ 3 ضغطات متتالية
                    Color.clear
                        .frame(width: 130, height: 90)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) {
                            showMainApp = true
                        }
                }
            }
        }
    }
}
