import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    @AppStorage("isButtonsUnlocked") private var isButtonsUnlocked = false
    @AppStorage("currentPassword") private var currentPassword = "123"
    
    // أسماء ملفات الـ 3105 القابلة للتعديل والتغيير من الإعدادات
    @AppStorage("regditFile") private var regditFile = "VOLCANO File (6).3105"
    @AppStorage("fpsFile") private var fpsFile = "VOLCANO File (7).3105"
    @AppStorage("plusFile") private var plusFile = "VOLCANO File (8).3105"
    
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

                Section(header: Text("إعدادات التحكم وأمان الأزرار")) {
                    Toggle(isOn: Binding(
                        get: { isButtonsUnlocked },
                        set: { newValue in
                            if newValue {
                                showingPasswordAlert = true
                            } else {
                                isButtonsUnlocked = false
                            }
                        }
                    )) {
                        Text("قفل / فتح تعديل وتغيير الأزرار")
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

                // قسم تعديل ملفات الأزرار يظهر فقط بعد إدخال كلمة المرور الصحيحة وفتح القفل
                if isButtonsUnlocked {
                    Section(header: Text("تخصيص وتعديل ملفات الأزرار (.3105)")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ملف زر Regdit").font(.caption).foregroundColor(.secondary)
                            TextField("اسم الملف", text: $regditFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ملف زر 144fps").font(.caption).foregroundColor(.secondary)
                            TextField("اسم الملف", text: $fpsFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ملف زر EXTRA PATCH").font(.caption).foregroundColor(.secondary)
                            TextField("اسم الملف", text: $plusFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
                Text(passwordError ? "كلمة المرور غير صحيحة. حاول مرة أخرى." : "يرجى إدخال كلمة المرور للوصول إلى تعديل الأزرار.")
            }
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
}
