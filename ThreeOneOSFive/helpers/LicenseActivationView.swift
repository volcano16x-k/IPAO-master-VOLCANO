import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color(.systemGray6).opacity(0.3), in: Circle())
                    }

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                            Text("Mettre à niveau")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6).opacity(0.3), in: Capsule())
                    }

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color(.systemGray6).opacity(0.3), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "photo")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                        Text("Créer une image ou un sticker")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                        Text("Écrire ou modifier")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                        Text("Rechercher sur le Web")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)

                if let message = manager.message {
                    Text(message)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.bottom, 10)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        manager.activate(key: key)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5).opacity(0.4), in: Circle())
                    }

                    TextField("Demander à ChatGPT", text: $key)
                        .focused($isFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit {
                            manager.activate(key: key)
                        }

                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    Button(action: {
                        manager.activate(key: key)
                    }) {
                        Image(systemName: "waveform")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.blue, in: Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6).opacity(0.25), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.bottom, 15)
            }
        }
        .preferredColorScheme(.dark)
    }
}
