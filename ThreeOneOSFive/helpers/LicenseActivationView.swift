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

    // الصق مفتاح Gemini هنا
    private let apiKey = "__GEMINI_API_KEY__"

    private let endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    private let blue = Color(red: 0.10, green: 0.56, blue: 1.0)
    private let chipFill = Color(white: 0.11)
    private let strokeColor = Color.white.opacity(0.08)
    private let textGray = Color(white: 0.78)

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // TOP BAR
                topBar

                if isAIActive {
                    chatView
                } else {
                    Spacer()
                    suggestions
                }

                // INPUT
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
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
                                isUser
                                ? chipFill
                                : Color.clear,
                                in: RoundedRectangle(
                                    cornerRadius: 20,
                                    style: .continuous
                                )
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: isUser
                                ? .trailing
                                : .leading
                            )
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

                    withAnimation {
                        proxy.scrollTo(
                            last.id,
                            anchor: .bottom
                        )
                    }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {

            // LEFT MENU - شطرتان
            Button(action: resetChat) {

                MenuTwoLinesShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 2.8,
                            lineCap: .round
                        )
                    )
                    .frame(width: 28, height: 18)
                    .frame(width: 42, height: 42)
                    .background(
                        chipFill,
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                strokeColor,
                                lineWidth: 1
                            )
                    )
            }

            // METTRE À NIVEAU
            Button(action: {}) {

                HStack(spacing: 8) {

                    FourPointStarShape()
                        .fill(blue)
                        .frame(
                            width: 20,
                            height: 20
                        )

                    Text("Mettre à niveau")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(blue)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    chipFill,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            strokeColor,
                            lineWidth: 1
                        )
                )
            }

            Spacer()

            // CHATGPT CIRCLE
            Button(action: resetChat) {

                ChatGPTLogoShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 2.4,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(
                        width: 25,
                        height: 25
                    )
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .background(
                        chipFill,
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                strokeColor,
                                lineWidth: 1
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Suggestions

    private var suggestions: some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            suggestionRow(
                title: "Créer une image ou un sticker"
            ) {

                Image(systemName: "photo")
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(textGray)
            }

            suggestionRow(
                title: "Écrire ou modifier"
            ) {

                PencilShape()
                    .stroke(
                        textGray,
                        style: StrokeStyle(
                            lineWidth: 1.8,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(
                        width: 20,
                        height: 20
                    )
            }

            suggestionRow(
                title: "Rechercher sur le Web"
            ) {

                GlobeShape()
                    .stroke(
                        textGray,
                        style: StrokeStyle(
                            lineWidth: 1.6,
                            lineCap: .round
                        )
                    )
                    .frame(
                        width: 20,
                        height: 20
                    )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.leading, 26)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func suggestionRow<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {

        HStack(spacing: 14) {

            icon()
                .frame(
                    width: 25,
                    height: 25
                )

            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .regular
                    )
                )
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {

        HStack(spacing: 12) {

            // PLUS
            Button(action: {}) {

                Image(systemName: "plus")
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 34,
                        height: 34
                    )
            }

            // TEXT FIELD
            TextField(
                "Demander à ChatGPT",
                text: $key
            )
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .submitLabel(.send)
            .onSubmit {
                handleUserInput()
            }

            // MICRO
            Button(action: {}) {

                Image(systemName: "mic")
                    .font(
                        .system(
                            size: 19,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 32,
                        height: 32
                    )
            }

            // SEND BUTTON
            Button(action: {
                handleUserInput()
            }) {

                Group {

                    if key.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {

                        // عندما لا توجد كتابة
                        Image(systemName: "waveform")
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )

                    } else {

                        // عند كتابة أي حرف → سهم
                        Image(systemName: "arrow.up")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                    }
                }
                .foregroundStyle(.white)
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    blue,
                    in: Circle()
                )
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 9)
        .frame(height: 47)
        .background(
            chipFill,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    strokeColor,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 13)
    }

    // MARK: - Logic

    private func resetChat() {

        isAIActive = false
        chatHistory.removeAll()
        key = ""
    }

    private func handleUserInput() {

        let trimmed = key.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty,
              !isWaitingForAI
        else {
            return
        }

        if trimmed.uppercased().hasPrefix("VOLC") {

            manager.activate(
                key: trimmed
            )

        } else {

            isAIActive = true

            chatHistory.append(
                ChatMessage(
                    sender: "user",
                    text: trimmed
                )
            )

            key = ""

            fetchAIResponse()
        }
    }

    // MARK: - API

    private enum AuthMode: String, CaseIterable {
        case header
        case bearer
        case query
    }

    private func send(
        contents: [[String: Any]],
        mode: AuthMode
    ) async throws -> (Int, [String: Any]?) {

        let cleanKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        var urlString = endpoint

        if mode == .query {

            let encoded =
                cleanKey.addingPercentEncoding(
                    withAllowedCharacters:
                        .urlQueryAllowed
                ) ?? cleanKey

            urlString += "?key=\(encoded)"
        }

        guard let url = URL(
            string: urlString
        ) else {
            throw URLError(.badURL)
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"
        request.timeoutInterval = 60

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        switch mode {

        case .header:

            request.setValue(
                cleanKey,
                forHTTPHeaderField:
                    "x-goog-api-key"
            )

        case .bearer:

            request.setValue(
                "Bearer \(cleanKey)",
                forHTTPHeaderField:
                    "Authorization"
            )

        case .query:
            break
        }

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "contents": contents
                ]
            )

        let (
            data,
            response
        ) = try await URLSession.shared.data(
            for: request
        )

        let code =
            (response as? HTTPURLResponse)?
                .statusCode ?? 0

        let json =
            try? JSONSerialization
                .jsonObject(
                    with: data
                ) as? [String: Any]

        return (
            code,
            json
        )
    }

    private func fetchAIResponse() {

        isWaitingForAI = true

        let contents:
            [[String: Any]] =
            chatHistory
            .suffix(20)
            .map {

                [
                    "role":
                        $0.sender == "user"
                        ? "user"
                        : "model",

                    "parts": [
                        [
                            "text":
                                $0.text
                        ]
                    ]
                ]
            }

        Task {

            var reply =
                "v4 | تعذر الحصول على رد."

            var attempts:
                [String] = []

            let cleanKey =
                apiKey.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            do {

                for mode in AuthMode.allCases {

                    let (
                        code,
                        json
                    ) = try await send(
                        contents: contents,
                        mode: mode
                    )

                    if code == 200,

                       let candidates =
                            json?["candidates"]
                            as? [[String: Any]],

                       let content =
                            candidates.first?["content"]
                            as? [String: Any],

                       let parts =
                            content["parts"]
                            as? [[String: Any]],

                       let text =
                            parts.first?["text"]
                            as? String {

                        reply = text
                        attempts = []

                        break
                    }

                    attempts.append(
                        "\(mode.rawValue):\(code)"
                    )

                    var message =
                        "رد غير متوقع"

                    if let err =
                        json?["error"]
                        as? [String: Any],

                       let m =
                        err["message"]
                        as? String {

                        message = m
                    }

                    reply =
                        "v4 | \(attempts.joined(separator: ", ")) | طول المفتاح \(cleanKey.count) | يبدأ بـ \(cleanKey.prefix(3)) | \(message)"

                    if code != 401 &&
                       code != 403 {

                        break
                    }
                }

            } catch {

                reply =
                    "v4 | خطأ شبكة: \(error.localizedDescription)"
            }

            await MainActor.run {

                finishWithReply(reply)
            }
        }
    }

    private func finishWithReply(
        _ text: String
    ) {

        isWaitingForAI = false

        chatHistory.append(
            ChatMessage(
                sender: "ai",
                text: text
            )
        )
    }
}

// MARK: - LEFT MENU

struct MenuTwoLinesShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var p = Path()

        let y1 =
            rect.minY + rect.height * 0.28

        let y2 =
            rect.minY + rect.height * 0.72

        p.move(
            to: CGPoint(
                x: rect.minX,
                y: y1
            )
        )

        p.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: y1
            )
        )

        p.move(
            to: CGPoint(
                x: rect.minX,
                y: y2
            )
        )

        p.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: y2
            )
        )

        return p
    }
}

// MARK: - CHATGPT LOGO

struct ChatGPTLogoShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var p = Path()

        let w = rect.width
        let h = rect.height

        // الشكل الدائري المتقطع المشابه
        // للدائرة التي أرسلتها

        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        let r = min(w, h) * 0.39

        // القوس العلوي
        p.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(205),
            endAngle: .degrees(325),
            clockwise: false
        )

        // القوس الأيمن
        p.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(325),
            endAngle: .degrees(65),
            clockwise: false
        )

        // الجزء السفلي
        p.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(65),
            endAngle: .degrees(155),
            clockwise: false
        )

        // اليسار
        p.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(155),
            endAngle: .degrees(205),
            clockwise: false
        )

        // تفاصيل صغيرة تعطي شكل الشعار
        let leftPoint = CGPoint(
            x: rect.minX + w * 0.28,
            y: rect.midY + h * 0.12
        )

        let bottomPoint = CGPoint(
            x: rect.midX - w * 0.05,
            y: rect.maxY - h * 0.18
        )

        p.move(
            to: leftPoint
        )

        p.addLine(
            to: CGPoint(
                x: rect.minX + w * 0.24,
                y: rect.maxY - h * 0.18
            )
        )

        p.move(
            to: bottomPoint
        )

        p.addLine(
            to: CGPoint(
                x: rect.midX + w * 0.14,
                y: rect.maxY - h * 0.24
            )
        )

        return p
    }
}

// MARK: - STAR

struct FourPointStarShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        let c = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        let o =
            rect.width * 0.09

        let top = CGPoint(
            x: c.x,
            y: rect.minY
        )

        let right = CGPoint(
            x: rect.maxX,
            y: c.y
        )

        let bottom = CGPoint(
            x: c.x,
            y: rect.maxY
        )

        let left = CGPoint(
            x: rect.minX,
            y: c.y
        )

        var p = Path()

        p.move(to: top)

        p.addQuadCurve(
            to: right,
            control: CGPoint(
                x: c.x + o,
                y: c.y - o
            )
        )

        p.addQuadCurve(
            to: bottom,
            control: CGPoint(
                x: c.x + o,
                y: c.y + o
            )
        )

        p.addQuadCurve(
            to: left,
            control: CGPoint(
                x: c.x - o,
                y: c.y + o
            )
        )

        p.addQuadCurve(
            to: top,
            control: CGPoint(
                x: c.x - o,
                y: c.y - o
            )
        )

        p.closeSubpath()

        return p
    }
}

// MARK: - PENCIL

struct PencilShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        func pt(
            _ x: CGFloat,
            _ y: CGFloat
        ) -> CGPoint {

            CGPoint(
                x: rect.minX + rect.width * x,
                y: rect.minY + rect.height * y
            )
        }

        var p = Path()

        p.move(
            to: pt(0.10, 0.90)
        )

        p.addLine(
            to: pt(0.166, 0.65)
        )

        p.addLine(
            to: pt(0.728, 0.088)
        )

        p.addLine(
            to: pt(0.912, 0.272)
        )

        p.addLine(
            to: pt(0.35, 0.834)
        )

        p.closeSubpath()

        p.move(
            to: pt(0.166, 0.65)
        )

        p.addLine(
            to: pt(0.35, 0.834)
        )

        return p
    }
}

// MARK: - GLOBE

struct GlobeShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var p = Path()

        p.addEllipse(
            in: rect
        )

        let inner =
            CGRect(
                x: rect.midX - rect.width * 0.2,
                y: rect.minY,
                width: rect.width * 0.4,
                height: rect.height
            )

        p.addEllipse(
            in: inner
        )

        p.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.midY
            )
        )

        p.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.midY
            )
        )

        p.move(
            to: CGPoint(
                x: rect.midX,
                y: rect.minY
            )
        )

        p.addLine(
            to: CGPoint(
                x: rect.midX,
                y: rect.maxY
            )
        )

        return p
    }
}
