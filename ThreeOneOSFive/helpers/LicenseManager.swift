import Foundation
import SwiftUI

class LicenseManager: ObservableObject {
    @Published var isActive: Bool {
        didSet {
            UserDefaults.standard.set(isActive, forKey: "isKeyAuthorized")
        }
    }
    
    @Published var message: String? = nil
    @Published var isBusy: Bool = false
    @Published var rememberKey: Bool = true
    @Published var contactOwner: String? = nil

    init() {
        self.isActive = UserDefaults.standard.bool(forKey: "isKeyAuthorized")
    }

    func activate(key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            self.message = "الرجاء إدخال المفتاح!"
            return
        }

        isBusy = true
        message = nil

        guard let url = URL(string: "https://keybot1-u5id.onrender.com/verify-key") else {
            isBusy = false
            message = "رابط السيرفر غير صالح"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["key": trimmedKey]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            isBusy = false
            message = "خطأ في تجهيز البيانات"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isBusy = false

                if let error = error {
                    self.message = "خطأ في الاتصال بالسيرفر: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self.message = "لم يتم استقبال استجابة من السيرفر"
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = json["success"] as? Bool {
                        
                        if success {
                            // ✅ تم التحقق وفتح التطبيق بنجاح
                            self.isActive = true
                            self.message = nil
                        } else {
                            // ❌ المفتاح غير صحيح أو منتهي
                            let serverMessage = json["message"] as? String ?? "المفتاح غير صحيح"
                            self.message = serverMessage
                        }
                    } else {
                        self.message = "رد غير متوقع من السيرفر"
                    }
                } catch {
                    self.message = "فشل في قراءة بيانات السيرفر"
                }
            }
        }.resume()
    }
}
