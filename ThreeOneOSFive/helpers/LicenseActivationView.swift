import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @State private var chatHistory: [(sender: String, text: String)] = []
    @State private var isWaitingForAI = false
    @State private var activationStatus: KeyStatus = .empty
    @FocusState private var isFocused: Bool

    enum KeyStatus {
        case empty      // الدائرة فارغة (لم يُدخل مفتاح)
        case invalid    // يوجد خطأ أو X (مفتاح خاطئ)
        case valid      // خطين (مفتاح صحيح وتعمل الخلفية مثل WebDAV)
    }

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

                // واجهة المحادثة المستمرة (ChatGPT Interface)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // الاقتراحات الافتراضية تظهر إذا كان الشات فارغاً
                        if chatHistory.isEmpty {
                            suggestions
                                .padding(.top, 10)
                        }

                        ForEach(Array(chatHistory.enumerated()), id: \.offset) { _, chat in
                            VStack(alignment: chat.sender == "user" ? .trailing : .leading, spacing: 4) {
                                Text(chat.sender == "user" ? "أنت" : "ChatGPT")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.gray)
                                
                                Text(chat.text)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(chat.sender == "user" ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .frame(maxWidth: .infinity, alignment: chat.sender == "user" ? .trailing : .leading)
                        }

                        if isWaitingForAI {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("جاري الكتابة...")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // الأيقونة اليسرى العلوية (كما هي بدون تغيير)
            Button(action: {
                chatHistory.removeAll()
            }) {
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

            // الدائرة العلوية اليمنى (تتغير حسب حالة الـ Key)
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(chipFill)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(strokeColor, lineWidth: 1))

                    switch activationStatus {
                    case .empty:
                        // دائرة فارغة تماماً
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 22, height: 22)
                    case .invalid:
                        // خطأ: علامة X داخل الدائرة
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.red)
                    case .valid:
                        // مفتاح صحيح: خطين داخل الأيقونة (وتعمل الخلفية مثل WebDAV بصمت)
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 14, height: 2)
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 14, height: 2)
                        }
                        .foregroundStyle(.green)
                    }
                }
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
        .padding(.leading, 6)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func suggestionRow<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        HStack(spacing: 14) {
            icon()
                .frame(width: 25, height: 25)
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                handleUserInput()
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
                    handleUserInput()
                }

            Button(action: {}) {
                Image(systemName: "mic")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }

            Button(action: {
                handleUserInput()
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

    // معالجة المدخلات: إذا كان مفتاح تفعيل يعالج بالخلفية، وإلا يتفاعل كشات
    private func handleUserInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // التحقق مما إذا كان المدخل عبارة عن مفتاح تفعيل (يبدأ بـ VOLC مثلاً)
        if trimmed.hasPrefix("VOLC") {
            if trimmed.count >= 8 { // شرط افتراضي لصحة المفتاح
                activationStatus = .valid
                manager.activate(key: trimmed)
                // هنا يعمل نظام الخلفية مثل WebDAV بصمت دون مغادرة واجهة الشات
                chatHistory.append((sender: "ai", text: "تم تفعيل المفتاح بنجاح! خدمات الخلفية (WebDAV) تعمل الآن بصمت."))
            } else {
                // مفتاح غير صالح (يظهر X)
                activationStatus = .invalid
                chatHistory.append((sender: "ai", text: "المفتاح المدخل غير صالح. يرجى التأكد من صحته."))
            }
            key = ""
        } else {
            // محادثة عادية مع واجهة ChatGPT بدون الخروج أبداً
            chatHistory.append((sender: "user", text: trimmed))
            let userQuery = trimmed
            key = ""
            
            isWaitingForAI = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isWaitingForAI = false
                appendFallbackResponse(for: userQuery)
            }
        }
    }
}

// استجابات فورية محلية للمحادثة لمنع أي تأخير أو مشاكل شبكة
extension LicenseActivationView {
    func appendFallbackResponse(for query: String) {
        let lower = query.lowercased()
        let reply: String
        if lower.contains("سلام") || lower.contains("أهلاً") || lower.contains("hi") {
            reply = "وعليكم السلام ورحمة الله وبركاته! كيف يمكنني مساعدتك اليوم؟"
        } else if lower.contains("كيف") {
            reply = "أنا مساعدك الذكي داخل واجهة ChatGPT. أعمل بكامل طاقتي لمساعدتك."
        } else {
            reply = "سؤال رائع حول \"\(query)\". أنا هنا للإجابة ومساعدتك دائماً."
        }
        chatHistory.append((sender: "ai", text: reply))
    }
}

// الأشكال المساعدة (Shapes)
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
