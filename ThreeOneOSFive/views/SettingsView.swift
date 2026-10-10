import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    // المتغيرات الجديدة الخاصة بالتحكم بالأزرار وكلمة المرور
    @AppStorage("isButtonsUnlocked") private var isButtonsUnlocked = false
    @AppStorage("currentPassword") private var currentPassword = "123" // كلمة المرور الافتراضية الأولية
    
    @State private var showingPasswordAlert = false
    @State private var inputPassword = ""
    @State private var passwordError = false
    
    @State private var showingChangePasswordSheet = false
    @State private var newPasswordInput = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("VOLCANO").font(.headline)
                            Text(language.text("common.version", appVersion))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // قسم الأمان وحماية الأزرار الجديد
                Section(header: Text("إعدادات التحكم والأمان")) {
                    Toggle(isOn: Binding(
                        get: { isButtonsUnlocked },
                        set: { newValue in
                            if newValue {
                                // عند محاولة التفعيل، اطلب كلمة المرور
                                showingPasswordAlert = true
                            } else {
                                // عند الإيقاف، إغلاق القفل وإخفاء الأزرار
                                isButtonsUnlocked = false
                            }
                        }
                    )) {
                        Text("تفعيل إظهار وتخصيص الأزرار")
                    }
                    
                    if isButtonsUnlocked {
                        Button(action: {
                            showingChangePasswordSheet = true
                        }) {
                            Text("تغيير كلمة المرور الحالية")
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }

                Section(language.text("settings.language")) {
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

            }
            .tint(AppTheme.accent)
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            // نافذة إدخال كلمة المرور عند تفعيل الزر
            .alert("أدخل كلمة المرور للتفعيل", isPresented: $showingPasswordAlert) {
                SecureField("كلمة المرور", text: $inputPassword)
                Button("تأكيد") {
                    if inputPassword == currentPassword {
                        isButtonsUnlocked = true
                        passwordError = false
                    } else {
                        isButtonsUnlocked = false
                        passwordError = true
                    }
                    inputPassword = ""
                }
                Button("إلغاء", role: .cancel) {
                    isButtonsUnlocked = false
                    inputPassword = ""
                }
            } message: {
                Text(passwordError ? "كلمة المرور غير صحيحة. حاول مرة أخرى." : "يرجى إدخال كلمة المرور للوصول إلى التحكم بالأزرار.")
            }
            // شاشة تغيير كلمة المرور
            .sheet(isPresented: $showingChangePasswordSheet) {
                VStack(spacing: 20) {
                    Text("تغيير كلمة المرور").font(.headline)
                    SecureField("كلمة المرور الجديدة", text: $newPasswordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("حفظ كلمة المرور") {
                        if !newPasswordInput.isEmpty {
                            currentPassword = newPasswordInput
                            newPasswordInput = ""
                            showingChangePasswordSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("إلغاء") {
                        showingChangePasswordSheet = false
                    }
                    .foregroundColor(.red)
                }
                .padding()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(language.text("accessibility.open_profile", name))
        }
    }
}
