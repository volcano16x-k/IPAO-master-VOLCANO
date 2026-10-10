import Foundation
import Network

class WebServerManager {
    static let shared = WebServerManager()
    private var listener: NWListener?
    
    // تشغيل السيرفر على منفذ معين (مثلاً 8080)
    func startServer() {
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: 8080)!)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("السيرفر يعمل الآن وجاهز للاستقبال.")
                case .failed(let error):
                    print("فشل السيرفر: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { connection in
                self.handleConnection(connection)
            }
            
            listener?.start(queue: .global())
        } catch {
            print("خطأ في بدء السيرفر: \(error)")
        }
    }
    
    // التعامل مع طلب متصفح Safari وإرسال الواجهة
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
            if let data = data, let requestString = String(data: data, encoding: .utf8) {
                print("تم استلام طلب: \n\(requestString)")
                
                // صفحة الـ HTML التي ستظهر عند كتابة الـ IP في Safari
                let htmlResponse = """
                <!DOCTYPE html>
                <html lang="ar" dir="rtl">
                <head>
                    <meta charset="UTF-8">
                    <title>إدارة ملفات التطبيق</title>
                    <style>
                        body { font-family: sans-serif; background: #0f172a; color: #fff; text-align: center; padding-top: 50px; }
                        .card { background: #1e293b; padding: 30px; border-radius: 12px; display: inline-block; box-shadow: 0 4px 20px rgba(0,0,0,0.5); }
                        h1 { color: #38bdf8; }
                    </style>
                </head>
                <body>
                    <div class="card">
                        <h1>مرحباً بك في لوحة تحكم التطبيق!</h1>
                        <p>أنت متصل الآن بنجاح عبر متصفح Safari.</p>
                    </div>
                </body>
                </html>
                """
                
                let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(htmlResponse.utf8.count)\r\nConnection: close\r\n\r\n\(htmlResponse)"
                
                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }
    
    // إيقاف السيرفر
    func stopServer() {
        listener?.cancel()
        listener = nil
        print("تم إيقاف السيرفر.")
    }
}
