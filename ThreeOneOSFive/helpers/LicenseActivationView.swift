import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let text: String
}

// MARK: - License Activation View

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isAIActive = false
    @State private var isWaitingForAI = false

    @FocusState private var isFocused: Bool

    // ضع مفتاح Gemini هنا إذا كنت تستخدمه مباشرة
    private let apiKey = "__GEMINI_API_KEY__"

    private let endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    private let blue =
        Color(red: 0.10, green: 0.56, blue: 1.0)

    private let chipFill =
        Color(white: 0.11)

    private let strokeColor =
        Color.white.opacity(0.08)

    private let textGray =
        Color(white: 0.78)

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

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
        .animation(
            .easeInOut(duration: 0.25),
            value: isFocused
        )
    }

    // MARK: - Chat View

    private var chatView: some View {
        ScrollViewReader { proxy in

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 16
                ) {

                    ForEach(chatHistory) { chat in

                        let isUser =
                            chat.sender == "user"

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

            // MARK: Left button - two lines

            Button(action: resetChat) {

                MenuTwoLinesShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 2.8,
                            lineCap: .round
                        )
                    )
                    .frame(
                        width: 30,
                        height: 18
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

            // MARK: Upgrade button

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

            // MARK: Right custom Chat icon

            Button(action: resetChat) {

                CustomChatIcon(
                    size: 42,
                    strokeColor: .white,
                    lineWidth: 2.8
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
            spacing: 22
        ) {

            suggestionRow(
                title: "Créer une image ou un sticker"
            ) {

                Image(systemName: "photo")
                    .font(
                        .system(
                            size: 17,
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
                            lineWidth: 1.7,
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
                            lineWidth: 1.5,
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
                        size: 15,
                        weight: .regular
                    )
                )
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {

        HStack(spacing: 12) {

            // Plus

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

            // Text field

            TextField(
                "Demander à ChatGPT",
                text: $key
            )
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(
                .system(size: 17)
            )
            .foregroundStyle(.white)
            .submitLabel(.send)
            .onSubmit {
                handleUserInput()
            }

            // Microphone

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

            // MARK: Send button

            Button(action: {
                handleUserInput()
            }) {

                ZStack {

                    Circle()
                        .fill(blue)

                    if key
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty {

                        // No text = waveform

                        Image(systemName: "waveform")
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)

                    } else {

                        // Text exists = arrow ↑

                        Image(systemName: "arrow.up")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                    }
                }
                .frame(
                    width: 34,
                    height: 34
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

    // MARK: - Reset

    private func resetChat() {

        isAIActive = false
        chatHistory.removeAll()
        key = ""
    }

    // MARK: - User Input

    private func handleUserInput() {

        let trimmed =
            key.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !trimmed.isEmpty,
            !isWaitingForAI
        else {
            return
        }

        // License activation

        if trimmed
            .uppercased()
            .hasPrefix("VOLC") {

            manager.activate(
                key: trimmed
            )

            key = ""

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

    // MARK: - API Authentication

    private enum AuthMode: String, CaseIterable {
        case header
        case bearer
        case query
    }

    // MARK: - Send API Request

    private func send(
        contents: [[String: Any]],
        mode: AuthMode
    ) async throws
        -> (Int, [String: Any]?) {

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

        guard let url =
                URL(string: urlString)
        else {
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

        let (data, response) =
            try await URLSession.shared.data(
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

        return (code, json)
    }

    // MARK: - Fetch AI Response

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
                                "text": $0.text
                            ]
                        ]
                    ]
                }

        Task {

            var reply =
                "v4 | تعذر الحصول على رد."

            var attempts: [String] = []

            let cleanKey =
                apiKey.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            do {

                for mode in AuthMode.allCases {

                    let (code, json) =
                        try await send(
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
                        "v4 | " +
                        "\(attempts.joined(separator: ", ")) | " +
                        "طول المفتاح \(cleanKey.count) | " +
                        "يبدأ بـ \(cleanKey.prefix(3)) | " +
                        message

                    if code != 401 &&
                       code != 403 {
                        break
                    }
                }

            } catch {

                reply =
                    "v4 | خطأ شبكة: " +
                    error.localizedDescription
            }

            await MainActor.run {

                finishWithReply(reply)
            }
        }
    }

    // MARK: - Finish Reply

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

// MARK: - Custom Chat Icon
// الأيقونة الموجودة أعلى اليمين

struct CustomChatIcon: View {

    var size: CGFloat = 42
    var strokeColor: Color = .white
    var lineWidth: CGFloat = 2.8

    var body: some View {

        ZStack {

            // الدائرة الداكنة

            Circle()
                .fill(
                    Color(
                        red: 0.10,
                        green: 0.10,
                        blue: 0.10
                    )
                )
                .frame(
                    width: size,
                    height: size
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )

            GeometryReader { geometry in

                let center =
                    CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )

                let radius =
                    (
                        min(
                            geometry.size.width,
                            geometry.size.height
                        ) / 2
                    ) * 0.55

                Path { path in

                    // القوس العلوي

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-120),
                        endAngle: .degrees(-10),
                        clockwise: false
                    )

                    // القوس الأيمن

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(10),
                        endAngle: .degrees(110),
                        clockwise: false
                    )

                    // القوس السفلي الأيسر

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(130),
                        endAngle: .degrees(190),
                        clockwise: false
                    )

                    // ذيل المحادثة

                    let tailTip =
                        CGPoint(
                            x: center.x -
                                radius * 1.3,
                            y: center.y +
                                radius * 0.3
                        )

                    let tailReturn =
                        CGPoint(
                            x: center.x -
                                radius * 0.8,
                            y: center.y -
                                radius * 0.4
                        )

                    path.addLine(
                        to: tailTip
                    )

                    path.addLine(
                        to: tailReturn
                    )
                }
                .stroke(
                    strokeColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(
                width: size,
                height: size
            )
        }
        .frame(
            width: size,
            height: size
        )
    }
}

// MARK: - Two Lines Menu

struct MenuTwoLinesShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        let y1 =
            rect.midY -
            rect.height * 0.25

        let y2 =
            rect.midY +
            rect.height * 0.25

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: y1
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: y1
            )
        )

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: y2
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: y2
            )
        )

        return path
    }
}

// MARK: - Four Point Star

struct FourPointStarShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        let c =
            CGPoint(
                x: rect.midX,
                y: rect.midY
            )

        let o =
            rect.width * 0.09

        let top =
            CGPoint(
                x: c.x,
                y: rect.minY
            )

        let right =
            CGPoint(
                x: rect.maxX,
                y: c.y
            )

        let bottom =
            CGPoint(
                x: c.x,
                y: rect.maxY
            )

        let left =
            CGPoint(
                x: rect.minX,
                y: c.y
            )

        var p = Path()

        p.move(to: top)

        p.addQuadCurve(
            to: right,
            control:
                CGPoint(
                    x: c.x + o,
                    y: c.y - o
                )
        )

        p.addQuadCurve(
            to: bottom,
            control:
                CGPoint(
                    x: c.x + o,
                    y: c.y + o
                )
        )

        p.addQuadCurve(
            to: left,
            control:
                CGPoint(
                    x: c.x - o,
                    y: c.y + o
                )
        )

        p.addQuadCurve(
            to: top,
            control:
                CGPoint(
                    x: c.x - o,
                    y: c.y - o
                )
        )

        p.closeSubpath()

        return p
    }
}

// MARK: - Pencil

struct PencilShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        func pt(
            _ x: CGFloat,
            _ y: CGFloat
        ) -> CGPoint {

            CGPoint(
                x: rect.minX +
                    rect.width * x,
                y: rect.minY +
                    rect.height * y
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

// MARK: - Globe

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
                x: rect.midX -
                    rect.width * 0.2,
                y: rect.minY,
                width:
                    rect.width * 0.4,
                height:
                    rect.height
            )

        p.addEllipse(
            in: inner
        )

        p.move(
            to:
                CGPoint(
                    x: rect.minX,
                    y: rect.midY
                )
        )

        p.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: rect.midY
                )
        )

        p.move(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.minY
                )
        )

        p.addLine(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.maxY
                )
        )

        return p
    }
}

// MARK: - End
