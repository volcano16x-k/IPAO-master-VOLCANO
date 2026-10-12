import SwiftUI

// MARK: - Main View

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var keyStatus: ActivationKeyStatus = .empty
    @State private var statusMessage = ""
    @FocusState private var isFocused: Bool
    
    // شاشة كتابة الملاحظات الجديدة
    @State private var isWritingNote = false
    @State private var noteContent = ""
    @FocusState private var isNoteFocused: Bool

    enum ActivationKeyStatus {
        case empty
        case invalid
        case valid
    }

    // MARK: - Colors

    private let chipFill = Color(white: 0.105)
    private let strokeColor = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP BAR
                topBar

                // العنوان الرئيسي (Notes)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Notes")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    HStack {
                        Text("Aucune note")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer(minLength: 0)

                // المنتصف (أيقونة Aucune note)
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.gray)

                    Text("Aucune note")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(keyStatus == .valid ? .green : .red)
                            .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 0)

                // BOTTOM BAR (شريط البحث وزر الكتابة)
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: isFocused)
        .sheet(isPresented: $isWritingNote) {
            noteEditorView
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // زر الرجوع في اليسار
            Button {
                resetState()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            Spacer()

            // زر الخيارات في اليمين
            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // شريط البحث
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                TextField("Recherche", text: $key)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit {
                        handleKeyInput()
                    }

                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .frame(height: 47)
            .background(chipFill, in: Capsule())
            .overlay(Capsule().stroke(strokeColor, lineWidth: 1))

            // زر الكتابة في أقصى اليمين
            Button {
                isWritingNote = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 47, height: 47)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 13)
    }

    // MARK: - Note Editor View

    private var noteEditorView: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    TextEditor(text: $noteContent)
                        .focused($isNoteFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                        .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isWritingNote = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {} label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                        Button {} label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.white)
                        }
                        Button {
                            isWritingNote = false
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 30, height: 30)
                                .background(Color.yellow, in: Circle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func resetState() {
        key = ""
        keyStatus = .empty
        statusMessage = ""
    }

    private func handleKeyInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.uppercased().hasPrefix("VOLC") {
            if trimmed.count >= 8 {
                keyStatus = .valid
                manager.activate(key: trimmed)
                statusMessage = "تم تفعيل مفتاح Nots. تعمل مزامنة الملاحظات في الخلفية."
            } else {
                keyStatus = .invalid
                statusMessage = "المفتاح المدخل غير صالح."
            }
        } else {
            keyStatus = .invalid
            statusMessage = "يرجى إدخال مفتاح ترخيص صحيح يبدأ بـ VOLC."
        }
        key = ""
    }
}
