import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let text: String
}

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isAIActive = false
    @State private var isWaitingForAI = false
    @FocusState private var isFocused: Bool

    // الصق مفتاحك هنا بين علامتي التنصيص بدون مسافات
    private let apiKey = "__GEMINI_API_KEY__"

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    private let blue = Color(red: 0.10, green: 0.56, blue: 1.0)
    private let chipFill = Color(white: 0.11)
    private let strokeColor = Color.white.opacity(0.08)
    private let textGray = Color(white: 0.78)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if isAIActive {
                    chatView
                } else {
                    Spacer()
                    suggestions
                }

                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }

    // MARK: - Chat

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(chatHistory) { chat in
                        let isUser = chat.sender == "user"
                        Text(chat.text)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                isUser ? chipFill : Color.clear,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                            .id(chat.id)
                    }

                    if isWaitingForAI {
                        ProgressView()
                            .tint(.white)
                            .id("loading")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .onChange(of: chatHistory.count) { _ in
                if let last = chatHistory.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: resetChat) {
                MenuTwoLinesShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 20, height: 10)
                    .frame(width: 42, height: 42)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            Button(action: {}) {
                HStack(spacing: 8) {
                    FourPointStarShape()
                        .fill(blue)
                        .frame(width: 20, height: 20)
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

            Button(action: resetChat) {
                ChatRingShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
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
            suggestionRow(title: "Créer une image ou un sticker") {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(textGray)
            }

            suggestionRow(title: "Écrire ou modifier") {
                PencilShape()
                    .stroke(textGray, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
            }

            suggestionRow(title: "Rechercher sur le Web") {
                GlobeShape()
                    .stroke(textGray, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .frame(width: 20, height: 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 26)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func suggestionRow<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        HStack(spacing: 14) {
            icon().frame(width: 25, height: 25)
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
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
                .submitLabel(.send)
                .onSubmit { handleUserInput() }

            Button(action: {}) {
                Image(systemName: "mic")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }

            Button(action: { handleUserInput() }) {
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

    // MARK: - Logic

    private func resetChat() {
        isAIActive = false
        chatHistory.removeAll()
    }

    private func handleUserInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isWaitingForAI else { return }

        if trimmed.uppercased().hasPrefix("VOLC") {
            manager.activate(key: trimmed)
        } else {
            isAIActive = true
            chatHistory.append(ChatMessage(sender: "user", text: trimmed))
            key = ""
            fetchAIResponse()
        }
    }

    private enum AuthMode: String, CaseIterable {
        case header
        case bearer
        case query
    }

    private func send(contents: [[String: Any]], mode: AuthMode) async throws -> (Int, [String: Any]?) {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        var urlString = endpoint

        if mode == .query {
            let encoded = cleanKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanKey
            urlString += "?key=\(encoded)"
        }

        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch mode {
        case .header:
            request.setValue(cleanKey, forHTTPHeaderField: "x-goog-api-key")
        case .bearer:
            request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        case .query:
            break
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: ["contents": contents])

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (code, json)
    }

    private func fetchAIResponse() {
        isWaitingForAI = true

        let contents: [[String: Any]] = chatHistory.suffix(20).map {
            ["role": $0.sender == "user" ? "user" : "model",
             "parts": [["text": $0.text]]]
        }

        Task {
            var reply = "v4 | تعذر الحصول على رد."
            var attempts: [String] = []
            let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                for mode in AuthMode.allCases {
                    let (code, json) = try await send(contents: contents, mode: mode)

                    if code == 200,
                       let candidates = json?["candidates"] as? [[String: Any]],
                       let content = candidates.first?["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        reply = text
                        attempts = []
                        break
                    }

                    attempts.append("\(mode.rawValue):\(code)")

                    var message = "رد غير متوقع"
                    if let err = json?["error"] as? [String: Any],
                       let m = err["message"] as? String {
                        message = m
                    }

                    reply = "v4 | \(attempts.joined(separator: ", ")) | طول المفتاح \(cleanKey.count) | يبدأ بـ \(cleanKey.prefix(3)) | \(message)"

                    if code != 401 && code != 403 { break }
                }
            } catch {
                reply = "v4 | خطأ شبكة: \(error.localizedDescription)"
            }

            await MainActor.run { finishWithReply(reply) }
        }
    }

    private func finishWithReply(_ text: String) {
        isWaitingForAI = false
        chatHistory.append(ChatMessage(sender: "ai", text: text))
    }
}

// MARK: - Shapes

struct MenuTwoLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.65, y: rect.maxY))
        return p
    }
}

struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let o = rect.width * 0.09
        let top = CGPoint(x: c.x, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: c.y)
        let bottom = CGPoint(x: c.x, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: c.y)
        var p = Path()
        p.move(to: top)
        p.addQuadCurve(to: right, control: CGPoint(x: c.x + o, y: c.y - o))
        p.addQuadCurve(to: bottom, control: CGPoint(x: c.x + o, y: c.y + o))
        p.addQuadCurve(to: left, control: CGPoint(x: c.x - o, y: c.y + o))
        p.addQuadCurve(to: top, control: CGPoint(x: c.x - o, y: c.y - o))
        p.closeSubpath()
        return p
    }
}

struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var p = Path()
        p.move(to: pt(0.10, 0.90))
        p.addLine(to: pt(0.166, 0.65))
        p.addLine(to: pt(0.728, 0.088))
        p.addLine(to: pt(0.912, 0.272))
        p.addLine(to: pt(0.35, 0.834))
        p.closeSubpath()
        p.move(to: pt(0.166, 0.65))
        p.addLine(to: pt(0.35, 0.834))
        return p
    }
}

struct GlobeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        let inner = CGRect(x: rect.midX - rect.width * 0.2, y: rect.minY, width: rect.width * 0.4, height: rect.height)
        p.addEllipse(in: inner)
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

struct ChatRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        func point(_ deg: Double, _ radius: CGFloat) -> CGPoint {
            let a = deg * .pi / 180
            return CGPoint(x: c.x + radius * CGFloat(cos(a)), y: c.y + radius * CGFloat(sin(a)))
        }
        var p = Path()
        p.addArc(center: c, radius: r, startAngle: .degrees(195), endAngle: .degrees(335), clockwise: false)
        p.addArc(center: c, radius: r, startAngle: .degrees(5), endAngle: .degrees(85), clockwise: false)
        p.move(to: point(100, r))
        p.addLine(to: CGPoint(x: rect.minX + r * 0.05, y: rect.maxY - r * 0.02))
        p.addLine(to: point(150, r))
        return p
    }
}
