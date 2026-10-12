import Combine
import Foundation
import Security

@MainActor
final class LicenseManager: ObservableObject {
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?
    @Published private(set) var contactOwner: String?
    @Published var rememberKey = true

    private let service = "com.VOLCANO.external-ios.activation"
    private let keyAccount = "license-key"
    private var lastAttemptAt: Date?

    init() {
        isActive = false
    }

    var hasRememberedKey: Bool { string(for: keyAccount) != nil }

    func beginLaunchSession() {
        isActive = hasRememberedKey
        message = isActive ? "Ready to use" : "Key required — enter your access key"
    }

    func activate(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isBusy else { return }
        
        if let lastAttemptAt, Date().timeIntervalSince(lastAttemptAt) < 1 {
            message = "Please wait a moment before trying again"
            return
        }
        
        lastAttemptAt = Date()
        isBusy = true
        message = "Checking access key..."

        // الاتصال بالسيرفر السحابي على Render
        guard let url = URL(string: "https://keybot1-u5id.onrender.com/verify-key") else {
            isBusy = false
            message = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["key": trimmed]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            isBusy = false
            message = "Failed to prepare request data"
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBusy = false

                if let error = error {
                    self.message = "Connection error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self.message = "No response from server"
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = json["success"] as? Bool {
                        
                        if success {
                            // ✅ المفتاح صحيح
                            if self.rememberKey {
                                self.save(trimmed, for: self.keyAccount)
                            }
                            self.isActive = true
                            self.message = "Activated successfully"
                        } else {
                            // ❌ المفتاح خطأ أو مستخدم
                            self.isActive = false
                            let serverMsg = json["message"] as? String ?? "Invalid access key"
                            self.message = serverMsg
                        }
                    } else {
                        self.message = "Unexpected server response"
                    }
                } catch {
                    self.message = "Failed to parse server response"
                }
            }
        }.resume()
    }

    func rememberedKey() -> String? { string(for: keyAccount) }

    func refresh() {
        isActive = hasRememberedKey
        message = isActive ? "Ready to use" : "Key required — enter your access key"
    }

    func deactivate() {
        delete(keyAccount)
        isActive = false
        message = "Activation removed from this device"
    }

    private func string(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func save(_ value: String, for account: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
