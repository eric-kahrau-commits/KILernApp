import SwiftUI

// MARK: - Mood

enum MascotMood: Equatable {
    case idle, talking, happy, thinking, celebrating
}

// MARK: - Pixel Art Mascot

/// A pixel-art space invader style mascot, fully color-parameterized and animated.
/// Moods .happy and .celebrating use full Duolingo-style squash & stretch sequences.
struct MascotView: View {
    var color: Color = Color(red: 0.38, green: 0.18, blue: 0.90)
    var mood: MascotMood = .idle
    var size: CGFloat = 60

    // Animation state
    @State private var floatY: CGFloat = 0
    @State private var tilt: Double = 0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var blink: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Pixel grid: 13 cols × 13 rows
    // 0=clear, 1=body, 2=shadow, 3=highlight, 4=eyeDark, 5=eyeWhite
    private let pixels: [[UInt8]] = [
        [0,0,0,1,0,0,0,0,0,1,0,0,0],
        [0,0,0,1,0,0,0,0,0,1,0,0,0],
        [0,1,1,1,1,1,1,1,1,1,1,1,0],
        [1,1,1,3,1,1,1,1,1,3,1,1,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,1,4,4,4,1,1,1,4,4,4,1,1],
        [1,1,4,5,4,1,1,1,4,5,4,1,1],
        [1,1,4,4,4,1,1,1,4,4,4,1,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,1,2,2,1,1,1,1,2,2,1,1,1],
        [0,1,1,1,1,1,1,1,1,1,1,1,0],
        [1,1,0,0,0,0,0,0,0,0,0,1,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,1],
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
        .scaleEffect(x: scaleX, y: scaleY)
        .onAppear { applyLoopAnimation(mood) }
        .onChange(of: mood) { _, newMood in
            withAnimation(.linear(duration: 0.01)) {
                floatY = 0; tilt = 0; scaleX = 1.0; scaleY = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                applyLoopAnimation(newMood)
            }
        }
        // Squash-stretch task for .happy and .celebrating
        .task(id: mood) {
            guard !reduceMotion else { return }
            guard mood == .happy || mood == .celebrating else { return }
            let intensity: CGFloat = mood == .celebrating ? 1.35 : 1.0
            let pauseNs: UInt64 = mood == .celebrating ? 320_000_000 : 520_000_000
            while !Task.isCancelled {
                await squashBounceCycle(intensity: intensity)
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: pauseNs)
            }
        }
        // Blink loop
        .task {
            guard !reduceMotion else { return }
            while true {
                let waitNs = UInt64.random(in: 2_800_000_000...5_500_000_000)
                try? await Task.sleep(nanoseconds: waitNs)
                // Fast close
                withAnimation(.easeIn(duration: 0.06)) { blink = true }
                try? await Task.sleep(nanoseconds: 60_000_000)
                // Slow open — like real eyes
                withAnimation(.easeOut(duration: 0.12)) { blink = false }
            }
        }
    }

    // MARK: - Simple loop animations (idle, talking, thinking)

    private func applyLoopAnimation(_ m: MascotMood) {
        guard !reduceMotion else { return }
        switch m {
        case .idle:
            // Two independent timings → organic, never perfectly periodic
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatY = -6
            }
            withAnimation(.easeInOut(duration: 3.7).repeatForever(autoreverses: true)) {
                tilt = 3.5
            }
        case .talking:
            withAnimation(.easeInOut(duration: 0.36).repeatForever(autoreverses: true)) {
                floatY = -4; tilt = 6
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                floatY = -2; tilt = -12
            }
        case .happy, .celebrating:
            break // handled by .task(id: mood)
        }
    }

    // MARK: - Squash & Stretch bounce (Duolingo-style)

    private func squashBounceCycle(intensity: CGFloat) async {
        // 1. Anticipation — squash down
        withAnimation(.easeIn(duration: 0.09)) {
            scaleX = 1.0 + 0.13 * intensity
            scaleY = 1.0 - 0.18 * intensity
            floatY = size * 0.04 * intensity
        }
        try? await Task.sleep(nanoseconds: 90_000_000)
        guard !Task.isCancelled else { return }

        // 2. Launch — stretch upward
        withAnimation(.easeOut(duration: 0.22)) {
            scaleX = 1.0 - 0.11 * intensity
            scaleY = 1.0 + 0.19 * intensity
            floatY = -(size * 0.42 * intensity)
            tilt = Double(intensity) * Double.random(in: -5...5)
        }
        try? await Task.sleep(nanoseconds: 220_000_000)
        guard !Task.isCancelled else { return }

        // 3. Apex — normalize briefly
        withAnimation(.easeInOut(duration: 0.08)) {
            scaleX = 1.0; scaleY = 1.0
        }
        try? await Task.sleep(nanoseconds: 80_000_000)
        guard !Task.isCancelled else { return }

        // 4. Land — squash hard
        withAnimation(.easeIn(duration: 0.09)) {
            scaleX = 1.0 + 0.18 * intensity
            scaleY = 1.0 - 0.23 * intensity
            floatY = 0
            tilt = 0
        }
        try? await Task.sleep(nanoseconds: 90_000_000)
        guard !Task.isCancelled else { return }

        // 5. Spring settle
        withAnimation(.spring(response: 0.32, dampingFraction: 0.50)) {
            scaleX = 1.0; scaleY = 1.0; floatY = 0; tilt = 0
        }
    }
}

// MARK: - Small Mascot Icon (for lists/grids, animated)

struct MascotIconView: View {
    var color: Color = Color(red: 0.38, green: 0.18, blue: 0.90)
    var size: CGFloat = 40
    var cornerRadius: CGFloat = 10
    var mood: MascotMood = .idle

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

            MascotView(color: .white, mood: mood, size: size * 0.76)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        MascotView(color: Color(red: 0.38, green: 0.18, blue: 0.90), mood: .idle,       size: 80)
        MascotView(color: .teal,                                        mood: .happy,      size: 80)
        MascotView(color: .orange,                                      mood: .celebrating, size: 80)
    }
    .padding(40)
}
