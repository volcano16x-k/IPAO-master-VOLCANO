import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @FocusState private var isFocused: Bool

    // MARK: - Colors

    private let background = Color.black
    private let surface = Color(red: 0.105, green: 0.105, blue: 0.105)
    private let secondarySurface = Color(red: 0.145, green: 0.145, blue: 0.145)

    private let primaryText = Color.white
    private let secondaryText = Color(white: 0.70)
    private let accent = Color(red: 0.25, green: 0.72, blue: 0.38)

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                header

                Spacer(minLength: 20)

                if !isFocused && key.isEmpty {
                    welcomeContent
                        .transition(.opacity)
                }

                Spacer(minLength: 12)

                if let message = manager.message,
                   !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 8)
                }

                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(
            .easeInOut(duration: 0.2),
            value: isFocused
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {

            Button {
                // Menu action
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(primaryText)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("ChatGPT")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(primaryText)

            Spacer()

            Button {
                // New chat / options action
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(primaryText)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .frame(height: 54)
    }

    // MARK: - Welcome

    private var welcomeContent: some View {
        VStack(spacing: 0) {

            Image(systemName: "sparkles")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(primaryText)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(secondarySurface)
                )
                .padding(.bottom, 22)

            Text("How can I help you?")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 20) {
                suggestion(
                    icon: "photo",
                    title: "Create an image"
                )

                suggestion(
                    icon: "pencil",
                    title: "Write or edit"
                )

                suggestion(
                    icon: "globe",
                    title: "Search the web"
                )
            }
            .padding(.top, 34)
        }
        .frame(maxWidth: .infinity)
    }

    private func suggestion(
        icon: String,
        title: String
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(secondaryText)
                .frame(width: 25)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(secondaryText)

            Spacer()
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {

            // Plus button
            Button {
                // Attachment / plus action
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(primaryText)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            // Text field
            TextField(
                "Message ChatGPT",
                text: $key
            )
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .font(.system(size: 17))
            .foregroundStyle(primaryText)
            .tint(primaryText)
            .submitLabel(.send)
            .onSubmit {
                activate()
            }

            // Microphone
            Button {
                // Microphone action
            } label: {
                Image(systemName: "mic")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(primaryText)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Send
            Button {
                activate()
            } label: {

                Image(
                    systemName: key.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                    ? "waveform"
                    : "arrow.up"
                )
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(
                    key.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                    ? primaryText
                    : Color.black
                )
                .frame(width: 34, height: 34)
                .background(
                    key.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                    ? secondarySurface
                    : Color.white,
                    in: Circle()
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 7)
        .frame(minHeight: 50)
        .background(
            surface,
            in: RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 1
            )
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Activation

    private func activate() {
        let cleanKey = key.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanKey.isEmpty else {
            return
        }

        manager.activate(key: cleanKey)
    }
}
