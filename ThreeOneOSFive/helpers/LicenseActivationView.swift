import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let text: String
}

// MARK: - Key Status

enum ActivationKeyStatus {
    case empty     // دائرة فارغة (لم يُدخل مفتاح)
    case invalid   // علامة X (مفتاح خطأ)
    case valid     // خطين (مفتاح صحيح وتعمل الخلفية مثل WebDAV بصمت)
}

// MARK: - Main View

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var chatHistory: [ChatMessage] = []

    @State private var isWaitingForAI = false
    @State private var isAIActive = false
    @State private var keyStatus: ActivationKeyStatus = .empty

    @FocusState private var isFocused: Bool

    // ضع API Key هنا
    private let apiKey = "__GEMINI_API_KEY__"

    private let endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    // MARK: - Colors

    private let blue =
        Color(red: 0.10, green: 0.56, blue: 1.0)

    private let chipFill =
        Color(white: 0.105)

    private let strokeColor =
        Color.white.opacity(0.08)

    private let textGray =
        Color(white: 0.78)

    var body: some View {

        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // TOP
                topBar

                // CONTENT
                if isAIActive {
                    chatView
                } else {
                    Spacer(minLength: 0)

                    suggestions
                }

                // INPUT
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(
            .easeInOut(duration: 0.18),
            value: isFocused
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {

        HStack(spacing: 12) {

            // يسار: خطان (كما طلبت بقاؤها)
            Button {
                resetChat()
            } label: {

                MenuTwoLinesShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 2.4,
                            lineCap: .round
                        )
                    )
                    .frame(
                        width: 20,
                        height: 14
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

            // الوسط
            Button {
                // لا نغير الشاشة
            } label: {

                HStack(spacing: 8) {

                    FourPointStarShape()
                        .fill(blue)
                        .frame(
                            width: 22,
                            height: 22
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

            // يمين: الدائرة العلوية المتغيرة حسب حالة المفتاح
            ZStack {
                Circle()
                    .fill(chipFill)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))

                switch keyStatus {
                case .empty:
                    // دائرة فارغة تماماً
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)

                case .invalid:
                    // علامة X حمراء إذا كان المفتاح خطأ
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)

                case .valid:
                    // خطين إذا كان المفتاح صحيحاً وتعمل الخلفية (WebDAV) بصمت
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1)
                            .frame(width: 14, height: 2)
                        RoundedRectangle(cornerRadius: 1)
                            .frame(width: 14, height: 2)
                    }
                    .foregroundStyle(.green)
                }
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

                Image(
                    systemName: "photo"
                )
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
        .padding(.leading, 50)
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    private func suggestionRow<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {

        HStack(spacing: 28) {

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

        HStack(spacing: 10) {

            // PLUS
            Button {

            } label: {

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
            .font(
                .system(size: 17)
            )
            .foregroundStyle(.white)
            .submitLabel(.send)
            .onSubmit {
                handleUserInput()
            }

            if key.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {

                Button {

                } label: {

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

            } else {

                Button {
                    handleUserInput()
                } label: {

                    Image(systemName: "arrow.up")
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
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

            if key.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {

                Button {

                } label: {

                    Image(systemName: "waveform")
                        .font(
                            .system(
                                size: 15,
                                weight: .bold
                            )
                        )
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
        .padding(.horizontal, 24)
        .padding(.bottom, 13)
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
                            .font(
                                .system(size: 16)
                            )
                            .foregroundStyle(.white)
                            .padding(
                                .horizontal,
                                14
                            )
                            .padding(
                                .vertical,
                                10
                            )
                            .background(
                                isUser
                                ? chipFill
                                : Color.clear,
                                in:
                                    RoundedRectangle(
                                        cornerRadius: 20,
                                        style: .continuous
                                    )
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment:
                                    isUser
                                    ? .trailing
                                    : .leading
                            )
                            .id(chat.id)
                    }

                    if isWaitingForAI {

                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .onChange(
                of: chatHistory.count
            ) { _ in

                if let last =
                    chatHistory.last {

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

    // MARK: - Reset

    private func resetChat() {
        isAIActive = false
        chatHistory.removeAll()
        key = ""
        keyStatus = .empty
    }

    // MARK: - Input

    private func handleUserInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isWaitingForAI else { return }

        // التحقق مما إذا كان المدخل مفتاح ترخيص (يبدأ بـ VOLC)
        if trimmed.uppercased().hasPrefix("VOLC") {
            if trimmed.count >= 8 {
                // مفتاح صحيح: تتغير الأيقونة العلوية إلى خطين وتعمل الخلفية (WebDAV) بصمت
                keyStatus = .valid
                manager.activate(key: trimmed)
                isAIActive = true
                chatHistory.append(ChatMessage(sender: "ai", text: "تم تفعيل المفتاح بنجاح. خدمات الخلفية تعمل الآن بصمت."))
            } else {
                // مفتاح غير صالح: تظهر علامة X
                keyStatus = .invalid
                isAIActive = true
                chatHistory.append(ChatMessage(sender: "ai", text: "المفتاح المدخل غير صالح. يرجى التأكد من صحته."))
            }
            key = ""
            return
        }

        // محادثة عادية مع البقاء داخل واجهة ChatGPT تماماً
        isAIActive = true
        chatHistory.append(ChatMessage(sender: "user", text: trimmed))
        let userQuery = trimmed
        key = ""

        // رد محلي فوري لمنع أي مشاكل شبكة أو Timeout
        isWaitingForAI = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isWaitingForAI = false
            let reply = "سؤال رائع حول \"\(userQuery)\". أنا هنا لمساعدتك دائماً."
            chatHistory.append(ChatMessage(sender: "ai", text: reply))
        }
    }
}

// MARK: - Two Lines

struct MenuTwoLinesShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        let y1 =
            rect.midY
            - rect.height * 0.25

        let y2 =
            rect.midY
            + rect.height * 0.25

        path.move(
            to:
                CGPoint(
                    x: rect.minX,
                    y: y1
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: y1
                )
        )

        path.move(
            to:
                CGPoint(
                    x: rect.minX,
                    y: y2
                )
        )

        path.addLine(
            to:
                CGPoint(
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

        let center =
            CGPoint(
                x: rect.midX,
                y: rect.midY
            )

        let o =
            rect.width * 0.09

        let top =
            CGPoint(
                x: center.x,
                y: rect.minY
            )

        let right =
            CGPoint(
                x: rect.maxX,
                y: center.y
            )

        let bottom =
            CGPoint(
                x: center.x,
                y: rect.maxY
            )

        let left =
            CGPoint(
                x: rect.minX,
                y: center.y
            )

        var path = Path()

        path.move(to: top)

        path.addQuadCurve(
            to: right,
            control:
                CGPoint(
                    x: center.x + o,
                    y: center.y - o
                )
        )

        path.addQuadCurve(
            to: bottom,
            control:
                CGPoint(
                    x: center.x + o,
                    y: center.y + o
                )
        )

        path.addQuadCurve(
            to: left,
            control:
                CGPoint(
                    x: center.x - o,
                    y: center.y + o
                )
        )

        path.addQuadCurve(
            to: top,
            control:
                CGPoint(
                    x: center.x - o,
                    y: center.y - o
                )
        )

        path.closeSubpath()

        return path
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
                x:
                    rect.minX
                    + rect.width * x,

                y:
                    rect.minY
                    + rect.height * y
            )
        }

        var path = Path()

        path.move(
            to: pt(0.10, 0.90)
        )

        path.addLine(
            to: pt(0.166, 0.65)
        )

        path.addLine(
            to: pt(0.728, 0.088)
        )

        path.addLine(
            to: pt(0.912, 0.272)
        )

        path.addLine(
            to: pt(0.35, 0.834)
        )

        path.closeSubpath()

        path.move(
            to: pt(0.166, 0.65)
        )

        path.addLine(
            to: pt(0.35, 0.834)
        )

        return path
    }
}

// MARK: - Globe

struct GlobeShape: Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        path.addEllipse(
            in: rect
        )

        let inner =
            CGRect(
                x:
                    rect.midX
                    - rect.width * 0.20,

                y:
                    rect.minY,

                width:
                    rect.width * 0.40,

                height:
                    rect.height
            )

        path.addEllipse(
            in: inner
        )

        path.move(
            to:
                CGPoint(
                    x: rect.minX,
                    y: rect.midY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: rect.midY
                )
        )

        path.move(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.minY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.maxY
                )
        )

        return path
    }
}
