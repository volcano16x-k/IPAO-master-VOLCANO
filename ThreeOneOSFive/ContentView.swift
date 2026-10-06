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
                // الواجهة الرئيسية للتطبيق (VOLCANO)
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
                // عرض Spotify مع المنطقة التفاعلية المخفية
                ZStack(alignment: .topLeading) {
                    if let url = spotifyURL {
                        SpotifyWebView(url: url)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("تعذر تحميل الرابط")
                    }
                    
                    // منطقة شفافة تماماً في الأعلى يساراً (تستجيب للضغط 3 مرات)
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
