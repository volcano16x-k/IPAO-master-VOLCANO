import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @State private var showKeyInput = false
    @FocusState private var keyFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // شريط العلوية (Modifier / FaceTime)
                HStack {
                    Button(action: {}) {
                        Text("Modifier")
                            .font(.system(size: 17))
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Text("FaceTime")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 15)

                // الأزرار الرئيسية (Créer un lien و Nouveau FaceTime)
                HStack(spacing: 12) {
                    Button(action: {}) {
                        VStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                            Text("Créer un lien")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(Color(.systemGray6).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button(action: {
                        showKeyInput = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                            Text("Nouveau FaceTime")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()
            }
        }
        .sheet(isPresented: $showKeyInput) {
            NewKeyInputView(manager: manager, isPresented: $showKeyInput)
        }
        .preferredColorScheme(.dark)
    }
}

// شاشة إدخال المفتاح عند الضغط على زر Nouveau FaceTime
struct NewKeyInputView: BindingView, View {
    @ObservedObject var manager: LicenseManager
    @Binding var isPresented: Bool
    @State private var key = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // شريط الإلغاء
                HStack {
                    Spacer()
                    Button("Annuler") {
                        isPresented = false
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(.green)
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)

                Text("Nouveau FaceTime")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // حقل الإدخال مع علامة الزائد (+)
                HStack(spacing: 12) {
                    Text("À :")
                        .font(.system(size: 17))
                        .foregroundStyle(.gray)

                    TextField("", text: $key)
                        .focused($fieldFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit {
                            manager.activate(key: key)
                        }

                    Button(action: {
                        manager.activate(key: key)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 25)

                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if let message = manager.message {
                    Text(message)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                }

                Spacer()
            }
        }
        .onAppear {
            fieldFocused = true
        }
        .preferredColorScheme(.dark)
    }
}
