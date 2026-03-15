import SwiftUI

// MARK: - Mood

enum MascotMood: Equatable {
    case idle, talking, happy, thinking, celebrating
}

// MARK: - Pixel Art Mascot

/// A pixel-art space invader style mascot, fully color-parameterized and animated.
struct MascotView: View {
    var color: Color = Color(red: 0.38, green: 0.18, blue: 0.90)
    var mood: MascotMood = .idle
    var size: CGFloat = 60

    // Animation state
    @State private var floatY: CGFloat = 0
    @State private var tilt: Double = 0
    @State private var bodyScale: CGFloat = 1.0
    @State private var blink: Bool = false

    // Pixel grid: 13 cols × 13 rows
    // 0=clear, 1=body, 2=shadow, 3=highlight, 4=eyeDark, 5=eyeWhite
    private let pixels: [[UInt8]] = [
        [0,0,0,1,0,0,0,0,0,1,0,0,0], // row  0: antennae
        [0,0,0,1,0,0,0,0,0,1,0,0,0], // row  1: antennae
        [0,1,1,1,1,1,1,1,1,1,1,1,0], // row  2: head top
        [1,1,1,3,1,1,1,1,1,3,1,1,1], // row  3: highlights
        [1,1,1,1,1,1,1,1,1,1,1,1,1], // row  4: body
        [1,1,4,4,4,1,1,1,4,4,4,1,1], // row  5: eyes top
        [1,1,4,5,4,1,1,1,4,5,4,1,1], // row  6: eyes + whites
        [1,1,4,4,4,1,1,1,4,4,4,1,1], // row  7: eyes bottom
        [1,1,1,1,1,1,1,1,1,1,1,1,1], // row  8: body
        [1,1,2,2,1,1,1,1,2,2,1,1,1], // row  9: shadow detail
        [0,1,1,1,1,1,1,1,1,1,1,1,0], // row 10: body lower
        [1,1,0,0,0,0,0,0,0,0,0,1,1], // row 11: legs
        [1,0,0,0,0,0,0,0,0,0,0,0,1], // row 12: feet
    ]

    private let cols = 13
    private let rows = 13

    var body: some View {
        Canvas { ctx, canvasSize in
            let pw = canvasSize.width / CGFloat(cols)
            let ph = canvasSize.height / CGFloat(rows)

            for (r, rowData) in pixels.enumerated() {
                for (c, px) in rowData.enumerated() {
                    guard px != 0 else { continue }
                    let rect = CGRect(x: CGFloat(c) * pw, y: CGFloat(r) * ph,
                                     width: pw + 0.5, height: ph + 0.5)
                    let path = Path(rect)
                    let isEyeRow = (r == 5 || r == 6 || r == 7)

                    switch px {
                    case 1:
                        ctx.fill(path, with: .color(color))
                    case 2:
                        ctx.fill(path, with: .color(color))
                        ctx.fill(path, with: .color(.black.opacity(0.28)))
                    case 3:
                        ctx.fill(path, with: .color(color))
                        ctx.fill(path, with: .color(.white.opacity(0.45)))
                    case 4:
                        if blink && isEyeRow {
                            ctx.fill(path, with: .color(color))
                            ctx.fill(path, with: .color(.black.opacity(0.18)))
                        } else {
                            ctx.fill(path, with: .color(.black.opacity(0.88)))
                        }
                    case 5:
                        if blink && isEyeRow {
                            ctx.fill(path, with: .color(color))
                        } else {
                            ctx.fill(path, with: .color(.white))
                        }
                    default:
                        ctx.fill(path, with: .color(color))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .offset(y: floatY)
        .rotationEffect(.degrees(tilt))
        .scaleEffect(bodyScale)
        .onAppear { applyAnimation(mood) }
        .onChange(of: mood) { _, newMood in
            // Reset then re-animate
            withAnimation(.linear(duration: 0.01)) { floatY = 0; tilt = 0; bodyScale = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { applyAnimation(newMood) }
        }
        .task {
            while true {
                let waitNs = UInt64.random(in: 2_800_000_000...5_500_000_000)
                try? await Task.sleep(nanoseconds: waitNs)
                withAnimation(.easeInOut(duration: 0.07)) { blink = true }
                try? await Task.sleep(nanoseconds: 130_000_000)
                withAnimation(.easeInOut(duration: 0.07)) { blink = false }
            }
        }
    }

    private func applyAnimation(_ m: MascotMood) {
        switch m {
        case .idle:
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                floatY = -5; tilt = 0; bodyScale = 1.0
            }
        case .talking:
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                floatY = -3; tilt = 5; bodyScale = 1.0
            }
        case .happy:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.4).repeatForever(autoreverses: true)) {
                floatY = -14; tilt = 0; bodyScale = 1.07
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                floatY = -2; tilt = -11; bodyScale = 1.0
            }
        case .celebrating:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.38).repeatForever(autoreverses: true)) {
                floatY = -20; tilt = 0; bodyScale = 1.12
            }
        }
    }
}

// MARK: - Small Mascot Icon (for lists/grids, no animation)

struct MascotIconView: View {
    var color: Color = Color(red: 0.38, green: 0.18, blue: 0.90)
    var size: CGFloat = 40
    var cornerRadius: CGFloat = 10

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)

            MascotView(color: .white, mood: .idle, size: size * 0.76)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        MascotView(color: Color(red: 0.38, green: 0.18, blue: 0.90), mood: .idle, size: 80)
        MascotView(color: .red, mood: .happy, size: 80)
        MascotView(color: .teal, mood: .celebrating, size: 80)
    }
    .padding(40)
}
