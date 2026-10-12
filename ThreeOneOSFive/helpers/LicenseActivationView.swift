import Foundation
import SwiftUI

class LicenseManager: ObservableObject {
    @Published var isActive: Bool {
        didSet {
            UserDefaults.standard.set(isActive, forKey: "isKeyAuthorized")
        }
    }
    
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    init() {
        // قراءة حالة التفعيل المحفوظة مسبقاً
        self.isActive = UserDefaults.standard.bool(forKey: "isKeyAuthorized")
    }

    func verifyKey(_ key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            self.errorMessage = "الرجاء إدخال المفتاح!"
            return
        }

        isLoading = true
        errorMessage = nil

        // الرابط السحابي الحقيقي لسيرفرك على Render
        guard let url = URL(string: "https://keybot1-u5id.onrender.com/verify-key") else {
            isLoading = false
            errorMessage = "رابط السيرفر غير صالح"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["key": trimmedKey]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            isLoading = false
            errorMessage = "خطأ في تجهيز البيانات"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "خطأ في الاتصال بالسيرفر: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "لم يتم استقبال استجابة من السيرفر"
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = json["success"] as? Bool {
                        
                        if success {
                            // ✅ المفتاح صحيح وسليم، يتم فتح التطبيق بنجاح
                            self.isActive = true
                            self.errorMessage = nil
                        } else {
                            // ❌ المفتاح خطأ أو منتهي أو مستخدم مسبقاً
                            let message = json["message"] as? String ?? "المفتاح غير صحيح"
                            self.errorMessage = message
                        }
                    } else {
                        self.errorMessage = "رد غير متوقع من السيرفر"
                    }
                } catch {
                    self.errorMessage = "فشل في قراءة بيانات السيرفر"
                }
            }
        }.resume()
    }

    func beginLaunchSession() {
        // أي عمليات إضافية عند بدء التشغيل إذا لزم الأمر
    }
}
