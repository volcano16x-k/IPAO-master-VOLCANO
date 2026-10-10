import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    @AppStorage("isButtonsUnlocked") private var isButtonsUnlocked = false
    @AppStorage("currentPassword") private var currentPassword = "123"
    
    // أسماء ملفات الـ 3105
    @AppStorage("regditFile") private var regditFile = "VOLCANO File (6).3105"
    @AppStorage("fpsFile") private var fpsFile = "VOLCANO File (7).3105"
    @AppStorage("plusFile") private var plusFile = "VOLCANO File (8).3105"
    
    // حالات الإظهار والإخفاء للأزرار
    @AppStorage("showRegditButton") private var showRegditButton = true
    @AppStorage("showFpsButton") private var showFpsButton = true
    @AppStorage("showPlusButton") private var showPlusButton = true
    
    @State private var showingPasswordAlert = false
    @State private var inputPassword = ""
    @State private var passwordError = false
    
    @State private var showingChangePasswordSheet = false
    @State private var newPasswordInput = ""
    
    // حالات لاختيار الملف المستهدف للرفع
    @State private var activeTargetButton: Int = 0
    @State private var showFileImporter = false

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

                // قسم إظهار/إخفاء ورفع ملفات الأزرار (.3105)
                if isButtonsUnlocked {
                    Section(header: Text("تخصيص ورفع ملفات الأزرار (.3105)")) {
                        // زر Regdit
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("إظهار زر Regdit", isOn: $showRegditButton)
                            HStack {
                                Text("الملف: \(regditFile)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button("رفع ملف .3105") {
                                    activeTargetButton = 1
                                    showFileImporter = true
                                }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        // زر 144fps
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("إظهار زر 144fps", isOn: $showFpsButton)
                            HStack {
                                Text("الملف: \(fpsFile)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button("رفع ملف .3105") {
                                    activeTargetButton = 2
                                    showFileImporter = true
                                }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        // زر Extra Patch
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("إظهار زر EXTRA PATCH", isOn: $showPlusButton)
                            HStack {
                                Text("الملف: \(plusFile)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button("رفع ملف .3105") {
                                    activeTargetButton = 3
                                    showFileImporter = true
                                }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
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
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.item], allowsMultipleSelection: false) { result in
                do {
                    guard let selectedFile = try result.get().first else { return }
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        let fileName = selectedFile.lastPathComponent
                        
                        // حفظ الملف في مجلد المستندات وتحديث الاسم
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let destinationURL = documentsPath.appendingPathComponent(fileName)
                        
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: selectedFile, to: destinationURL)
                        
                        DispatchQueue.main.async {
                            if activeTargetButton == 1 {
                                regditFile = fileName
                            } else if activeTargetButton == 2 {
                                fpsFile = fileName
                            } else if activeTargetButton == 3 {
                                plusFile = fileName
                            }
                        }
                    }
                } catch {
                    print("Error importing file: \(error.localizedDescription)")
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
                            showingChangeParserSheet = false
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
