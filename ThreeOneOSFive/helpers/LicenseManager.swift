import Combine
import Foundation
import Security

@MainActor
final class LicenseManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?
    @Published var rememberKey = true

    private let service = "com.VOLCANO.external-ios.activation"
    private let keyAccount = "license-key"
    private let deviceIdAccount = "device-uuid-identifier"
    private var lastAttemptAt: Date?

    init() {
        checkSavedKeyOnStartup()
    }

    private func getOrCreateDeviceId() -> String {
        if let existingId = string(for: deviceIdAccount) {
            return existingId
        }
        let newId = UUID().uuidString
        save(newId, for: deviceIdAccount)
        return newId
    }

    func checkSavedKeyOnStartup() {
        guard let savedKey = rememberedKey(), !savedKey.isEmpty else {
            isActive = false
            return
        }

        let deviceId = getOrCreateDeviceId()
        isBusy = true

        guard let url = URL(string: "https://keybot1-u5id.onrender.com/verify-key") else {
            isBusy = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "key": savedKey,
            "deviceId": deviceId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            isBusy = false
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBusy = false

                if error != nil {
                    self.isActive = true
                    return
                }

                guard let data = data else {
                    self.isActive = false
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        self.isActive = true
                    } else {
                        // إذا تم حذف المفتاح من ديسكورد، سيتم حذفه محلياً وإخراج العميل
                        self.isActive = false
                        self.delete(self.keyAccount)
                    }
                } catch {
                    self.isActive = false
                }
            }
        }.resume()
    }

    func activate(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isBusy else { return }
        
        if let lastAttemptAt, Date().timeIntervalSince(lastAttemptAt) < 1 {
            message = "Please wait a moment..."
            return
        }
        
        lastAttemptAt = Date()
        isBusy = true
        message = "Verifying key..."

        let deviceId = getOrCreateDeviceId()

        guard let url = URL(string: "https://keybot1-u5id.onrender.com/verify-key") else {
            isBusy = false
            message = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "key": trimmed,
            "deviceId": deviceId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            isBusy = false
            message = "Error preparing data"
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
                            if self.rememberKey {
                                self.save(trimmed, for: self.keyAccount)
                            }
                            self.isActive = true
                            self.message = "Activated successfully"
                        } else {
                            self.isActive = false
                            self.message = json["message"] as? String ?? "Invalid key"
                        }
                    }
                } catch {
                    self.message = "Parsing error"
                }
            }
        }.resume()
    }

    func rememberedKey() -> String? { string(for: keyAccount) }

    func deactivate() {
        delete(keyAccount)
        isActive = false
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
