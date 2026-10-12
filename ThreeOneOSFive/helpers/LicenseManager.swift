import SwiftUI
import Combine
import Foundation
import Security

@MainActor
final class LicenseManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?

    @Published var rememberKey = true

    // MARK: - Keychain

    private let service = "com.VOLCANO.external-ios.activation"
    private let keyAccount = "license-key"

    private var lastAttemptAt: Date?

    // MARK: - Server

    private let verifyURL =
        "https://keybot1-u5id.onrender.com/verify-key"

    // MARK: - Init

    init() {
        checkSavedKeyOnStartup()
    }

    // MARK: - Public State

    var hasRememberedKey: Bool {
        rememberedKey() != nil
    }

    enum CircleState {
        case valid
        case invalid
        case checking
    }

    var circleState: CircleState {
        if isBusy {
            return .checking
        }

        if isActive {
            return .valid
        }

        return .invalid
    }

    // MARK: - Startup

    func checkSavedKeyOnStartup() {

        guard let savedKey = rememberedKey(),
              !savedKey.isEmpty else {

            isActive = false
            message = nil
            return
        }

        verify(
            key: savedKey,
            saveKey: false
        )
    }

    // MARK: - Launch Session

    func beginLaunchSession() {

        guard !isBusy else {
            return
        }

        if !isActive {
            checkSavedKeyOnStartup()
        }
    }

    // MARK: - Activate

    func activate(key: String) {

        let trimmed = key.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {

            isActive = false
            message = "Enter your access key"

            return
        }

        guard !isBusy else {
            return
        }

        if let lastAttemptAt,
           Date().timeIntervalSince(lastAttemptAt) < 1 {

            message = "Please wait a moment"

            return
        }

        lastAttemptAt = Date()

        verify(
            key: trimmed,
            saveKey: rememberKey
        )
    }

    // MARK: - Verify

    private func verify(
        key: String,
        saveKey: Bool
    ) {

        guard let url = URL(string: verifyURL) else {

            isBusy = false
            isActive = false
            message = nil

            return
        }

        isBusy = true

        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.timeoutInterval = 15

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: String] = [
            "key": key
        ]

        do {

            request.httpBody = try JSONSerialization.data(
                withJSONObject: body,
                options: []
            )

        } catch {

            isBusy = false
            isActive = false
            message = nil

            return
        }

        URLSession.shared.dataTask(
            with: request
        ) { [weak self] data, response, error in

            Task { @MainActor in

                guard let self else {
                    return
                }

                self.isBusy = false

                // لا نعتبر المفتاح صالحاً عند انقطاع الاتصال
                if error != nil {

                    self.isActive = false
                    self.message = nil

                    return
                }

                guard
                    let httpResponse =
                        response as? HTTPURLResponse,
                    (200...299).contains(
                        httpResponse.statusCode
                    ),
                    let data
                else {

                    self.isActive = false
                    self.message = nil

                    return
                }

                do {

                    guard
                        let json =
                            try JSONSerialization.jsonObject(
                                with: data,
                                options: []
                            ) as? [String: Any]
                    else {

                        self.isActive = false
                        self.message = nil

                        return
                    }

                    let success =
                        json["success"] as? Bool ?? false

                    if success {

                        self.isActive = true
                        self.message = nil

                        if saveKey {

                            self.save(
                                key,
                                for: self.keyAccount
                            )
                        }

                    } else {

                        self.isActive = false
                        self.message = nil

                        // حذف المفتاح المرفوض من الجهاز
                        self.delete(
                            self.keyAccount
                        )
                    }

                } catch {

                    self.isActive = false
                    self.message = nil
                }
            }

        }.resume()
    }

    // MARK: - Refresh

    func refresh() {
        checkSavedKeyOnStartup()
    }

    // MARK: - Deactivate

    func deactivate() {

        delete(keyAccount)

        isActive = false
        isBusy = false
        message = nil
    }

    // MARK: - Keychain Read

    func rememberedKey() -> String? {

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                keyAccount,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard
            status == errSecSuccess,
            let data = result as? Data
        else {
            return nil
        }

        return String(
            data: data,
            encoding: .utf8
        )
    }

    // MARK: - Keychain Save

    private func save(
        _ value: String,
        for account: String
    ) {

        let base: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        SecItemDelete(
            base as CFDictionary
        )

        var item = base

        item[kSecValueData as String] =
            Data(value.utf8)

        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemAdd(
            item as CFDictionary,
            nil
        )
    }

    // MARK: - Keychain Delete

    private func delete(
        _ account: String
    ) {

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        SecItemDelete(
            query as CFDictionary
        )
    }
}


// MARK: - License Status Circle

struct LicenseStatusCircle: View {

    let state: LicenseManager.CircleState

    var body: some View {

        ZStack {

            Circle()
                .fill(
                    Color(
                        red: 0.10,
                        green: 0.10,
                        blue: 0.10
                    )
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )

            switch state {

            case .valid:

                EmptyView()

            case .invalid:

                XShape()
                    .stroke(
                        Color.white,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .padding(18)

            case .checking:

                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(
                            tint: .white
                        )
                    )
            }
        }
        .frame(
            width: 84,
            height: 84
        )
    }
}


// MARK: - X Shape

struct XShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY
            )
        )

        path.move(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.maxY
            )
        )

        return path
    }
}


// MARK: - Volcano Top Bar

struct VolcanoTopBar: View {

    @ObservedObject var license: LicenseManager

    var body: some View {

        HStack {

            MenuTwoLinesButton()

            Spacer()

            HStack(spacing: 12) {

                Text("✦")
                    .font(
                        .system(
                            size: 30
                        )
                    )
                    .foregroundColor(.blue)

                Text("Mettre à niveau")
                    .font(
                        .system(
                            size: 24,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(
                        Color(
                            red: 0.10,
                            green: 0.10,
                            blue: 0.10
                        )
                    )
            )

            Spacer()

            LicenseStatusCircle(
                state: license.circleState
            )
        }
        .padding(.horizontal, 40)
        .padding(.top, 10)
    }
}


// MARK: - Menu Button

struct MenuTwoLinesButton: View {

    var body: some View {

        ZStack {

            Circle()
                .fill(
                    Color(
                        red: 0.10,
                        green: 0.10,
                        blue: 0.10
                    )
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )

            VStack(spacing: 9) {

                Capsule()
                    .fill(Color.white)
                    .frame(
                        width: 40,
                        height: 4
                    )

                Capsule()
                    .fill(Color.white)
                    .frame(
                        width: 40,
                        height: 4
                    )
            }
        }
        .frame(
            width: 84,
            height: 84
        )
    }
}
