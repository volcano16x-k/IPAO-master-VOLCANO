import SwiftUI

// MARK: - Main View

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var keyStatus: ActivationKeyStatus = .empty
    @State private var statusMessage = ""
    @FocusState private var isFocused: Bool

    enum ActivationKeyStatus {
        case empty     // دائرة فارغة (لم يُدخل مفتاح)
        case invalid   // علامة X (مفتاح خطأ)
        case valid     // خطين (مفتاح صحيح وتعمل الخلفية بصمت)
    }

    // MARK: - Colors

    private let blue = Color(red: 0.10, green: 0.56, blue: 1.0)
    private let chipFill = Color(white: 0.105)
    private let strokeColor = Color.white.opacity(0.08)
    private let textGray = Color(white: 0.78)

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP BAR
                topBar

                Spacer(minLength: 0)

                // واجهة الاقتراحات ثابتة تماماً في المنتصف دون أي انتقال لشاشات أخرى
                suggestions

                Spacer(minLength: 0)

                // رسالة الحالة في الأسفل جهة اليسار فوق شريط الكتابة مباشرة
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(keyStatus == .valid ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                }

                // INPUT BAR (شريط الكتابة)
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // يسار: خطان
            Button {
                resetState()
            } label: {
                MenuTwoLinesShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 20, height: 14)
                    .frame(width: 42, height: 42)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            // الوسط
            Button {} label: {
                HStack(spacing: 8) {
                    FourPointStarShape()
                        .fill(blue)
                        .frame(width: 22, height: 22)

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

            // يمين: الدائرة العلوية المتغيرة حسب حالة المفتاح دون أي انتقال لشاشات أخرى
            ZStack {
                Circle()
                    .fill(chipFill)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))

                switch keyStatus {
                case .empty:
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                case .invalid:
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                case .valid:
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1).frame(width: 14, height: 2)
                        RoundedRectangle(cornerRadius: 1).frame(width: 14, height: 2)
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
        VStack(alignment: .leading, spacing: 24) {
            suggestionRow(title: "Créer une image ou un sticker") {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(textGray)
            }

            suggestionRow(title: "Écrire ou modifier") {
                PencilShape()
                    .stroke(
                        textGray,
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 20, height: 20)
            }

            suggestionRow(title: "Rechercher sur le Web") {
                GlobeShape()
                    .stroke(
                        textGray,
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                    )
                    .frame(width: 20, height: 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 50)
        .padding(.trailing, 20)
    }

    private func suggestionRow<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        HStack(spacing: 28) {
            icon()
                .frame(width: 25, height: 25)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(textGray)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {} label: {
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
                .onSubmit {
                    handleKeyInput()
                }

            if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {} label: {
                    Image(systemName: "mic")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                }
            } else {
                Button {
                    handleKeyInput()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(blue, in: Circle())
                }
            }

            if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {} label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(blue, in: Circle())
                }
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 9)
        .frame(height: 47)
        .background(chipFill, in: Capsule())
        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.bottom, 13)
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

        // إرسال المفتاح إلى LicenseManager للتحقق الحقيقي عبر السيرفر
        manager.activate(key: trimmed)

        // التحقق من حالة التفعيل وتحديث واجهة الشات بصمت
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if manager.isActive {
                keyStatus = .valid
                statusMessage = manager.message ?? "تم تفعيل المفتاح وتعمل الخلفية بصمت."
            } else {
                keyStatus = .invalid
                statusMessage = manager.message ?? "المفتاح غير صالح."
            }
        }
        key = ""
    }
}

// MARK: - Shapes

struct MenuTwoLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y1 = rect.midY - rect.height * 0.25
        let y2 = rect.midY + rect.height * 0.25

        path.move(to: CGPoint(x: rect.minX, y: y1))
        path.addLine(to: CGPoint(x: rect.maxX, y: y1))
        path.move(to: CGPoint(x: rect.minX, y: y2))
        path.addLine(to: CGPoint(x: rect.maxX, y: y2))
        return path
    }
}

struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let o = rect.width * 0.09
        let top = CGPoint(x: center.x, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: center.y)
        let bottom = CGPoint(x: center.x, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: center.y)

        var path = Path()
        path.move(to: top)
        path.addQuadCurve(to: right, control: CGPoint(x: center.x + o, y: center.y - o))
        path.addQuadCurve(to: bottom, control: CGPoint(x: center.x + o, y: center.y + o))
        path.addQuadCurve(to: left, control: CGPoint(x: center.x - o, y: center.y + o))
        path.addQuadCurve(to: top, control: CGPoint(x: center.x - o, y: center.y - o))
        path.closeSubpath()
        return path
    }
}

struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: pt(0.10, 0.90))
        path.addLine(to: pt(0.166, 0.65))
        path.addLine(to: pt(0.728, 0.088))
        path.addLine(to: pt(0.912, 0.272))
        path.addLine(to: pt(0.35, 0.834))
        path.closeSubpath()
        path.move(to: pt(0.166, 0.65))
        path.addLine(to: pt(0.35, 0.834))
        return path
    }
}

struct GlobeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        let inner = CGRect(x: rect.midX - rect.width * 0.20, y: rect.minY, width: rect.width * 0.40, height: rect.height)
        path.addEllipse(in: inner)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
