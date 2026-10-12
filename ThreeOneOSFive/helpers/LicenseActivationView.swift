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

            Button(action: {}) {
                ChatRingShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
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

// MARK: - Menu icon (two lines)

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

// MARK: - Four point star

struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let o = w * 0.09

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
        _ = h
        return p
    }
}

// MARK: - Pencil

struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x,
                    y: rect.minY + rect.height * y)
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

// MARK: - Globe

struct GlobeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)

        let inner = CGRect(
            x: rect.midX - rect.width * 0.2,
            y: rect.minY,
            width: rect.width * 0.4,
            height: rect.height
        )
        p.addEllipse(in: inner)

        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))

        return p
    }
}

// MARK: - Chat ring icon

struct ChatRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2

        func point(_ deg: Double, _ radius: CGFloat) -> CGPoint {
            let a = deg * .pi / 180
            return CGPoint(x: c.x + radius * CGFloat(cos(a)),
                           y: c.y + radius * CGFloat(sin(a)))
        }

        var p = Path()

        p.addArc(center: c, radius: r,
                 startAngle: .degrees(160), endAngle: .degrees(330),
                 clockwise: false)

        p.addArc(center: c, radius: r,
                 startAngle: .degrees(20), endAngle: .degrees(110),
                 clockwise: false)

        p.move(to: point(112, r))
        p.addLine(to: CGPoint(x: rect.minX + r * 0.1, y: rect.maxY))
        p.addLine(to: point(148, r))

        return p
    }
}
