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
                // الواجهة الرئيسية للتطبيق
                FilesTabSwitcher()
            } else {
                // عرض Spotify مع منطقة اللمس المخفية
                ZStack(alignment: .topLeading) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
                    // منطقة شفافة في الأعلى يساراً (ضغط 3 مرات للفتح)
                    Color.clear
                        .frame(width: 120, height: 90)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) {
                            showMainApp = true
                        }
                }
            }
        }
    }
}
