import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @FocusState private var isFocused: Bool

    private let blue = Color(red: 0.10, green: 0.56, blue: 1.0)
    private let chipFill = Color(white: 0.11)
    private let strokeColor = Color.white.opacity(0.08)
    private let textGray = Color(white: 0.78)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                suggestions

                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Mettre à niveau")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(blue)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(chipFill, in: Capsule())
                .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Suggestions

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 24) {
            suggestionRow(icon: "photo", title: "Créer une image ou un sticker")
            suggestionRow(icon: "pencil.line", title: "Écrire ou modifier")
            suggestionRow(icon: "globe", title: "Rechercher sur le Web")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 26)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func suggestionRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(textGray)
                .frame(width: 25)
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                manager.activate(key: key)
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
            }

            TextField("Demander à ChatGPT", text: $key)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .submitLabel(.done)
                .onSubmit {
                    manager.activate(key: key)
                }

            Button(action: {}) {
                Image(systemName: "mic")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }

            Button(action: {
                manager.activate(key: key)
            }) {
                Image(systemName: "waveform")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(blue, in: Circle())
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 9)
        .frame(height: 47)
        .background(chipFill, in: Capsule())
        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
        .padding(.horizontal, 12)
        .padding(.bottom, 13)
    }
}
