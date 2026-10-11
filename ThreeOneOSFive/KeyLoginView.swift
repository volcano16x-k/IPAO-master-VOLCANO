import SwiftUI

struct KeyLoginView: View {
    @AppStorage("isKeyAuthorized") private var isKeyAuthorized = false
    @State private var enteredKey = ""
    @State private var statusMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("VOLCANO ACCESS")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("ENTER YOUR LICENSE KEY TO CONTINUE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                }

                VStack(spacing: 14) {
                    SecureField("License Key", text: $enteredKey)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
                        .autocapitalization(.allCharacters)

                    Button {
                        validateKey()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        } else {
                            Text("ACTIVATE KEY")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(enteredKey.isEmpty || isLoading)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(TextAlignment.center)
                }
            }
            .padding(24)
        }
    }

    private func validateKey() {
        isLoading = true
        statusMessage = ""

        // ضع هنا رابط السيرفر الخاص بك الذي يستضيف الـ API
        guard let url = URL(string: "https://your-server-url.com/verify-key") else {
            isLoading = false
            statusMessage = "رابط الخادم غير صالح"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["key": enteredKey]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                guard let data = data, error == nil else {
                    statusMessage = "فشل الاتصال بالخادم، تحقق من الإنترنت."
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        isKeyAuthorized = true // فتح التطبيق بنجاح
                    } else {
                        let message = json["message"] as? String ?? "مفتاح غير صحيح"
                        statusMessage = message
                    }
                } catch {
                    statusMessage = "حدث خطأ في قراءة بيانات الخادم."
                }
            }
        }.resume()
    }
}
