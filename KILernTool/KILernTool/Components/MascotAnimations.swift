import SwiftUI

// MARK: - Book Reading Mascot

/// Mascot holding an open book in front, with a subtle page-turn animation.
struct BookReadingMascotView: View {
    var color: Color
    var size: CGFloat = 80

    @State private var rightPageAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            MascotView(color: color, mood: .thinking, size: size)
            openBook
                .offset(y: size * 0.08)
        }
        .frame(width: size, height: size * 1.22)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                rightPageAngle = 10
            }
        }
    }

    private var openBook: some View {
        let bW = size * 0.72
        let bH = size * 0.38
        return ZStack {
            // Shadow
            Ellipse()
                .fill(.black.opacity(0.09))
                .frame(width: bW * 0.85, height: 5)
                .offset(y: bH * 0.52 + 2)

            // Left page
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 2)
                .frame(width: bW * 0.46, height: bH)
                .overlay(
                    VStack(spacing: bH * 0.14) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule()
                                .fill(color.opacity(0.22))
                                .frame(height: 2.5)
                        }
                    }
                    .padding(.horizontal, 6).padding(.vertical, 8)
                )
                .rotationEffect(.degrees(-4), anchor: .trailing)
                .offset(x: -bW * 0.23)

            // Spine
            Rectangle()
                .fill(color.opacity(0.55))
                .frame(width: 3, height: bH)

            // Right page (subtle page-flip)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 2)
                .frame(width: bW * 0.46, height: bH)
                .overlay(
                    VStack(spacing: bH * 0.14) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule()
                                .fill(color.opacity(0.22))
                                .frame(height: 2.5)
                        }
                    }
                    .padding(.horizontal, 6).padding(.vertical, 8)
                )
                .rotationEffect(.degrees(4 + rightPageAngle), anchor: .leading)
                .offset(x: bW * 0.23)
        }
        .frame(width: bW, height: bH)
    }
}

// MARK: - Reading Lamp Mascot

/// Mascot beside a desk lamp that "turns on" and pulses softly.
struct LampMascotView: View {
    var color: Color
    var size: CGFloat = 80

    @State private var lightOn: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Glow cones behind mascot
            ForEach(0..<3) { i in
                Ellipse()
                    .fill(Color.yellow.opacity(lightOn ? (0.14 - Double(i) * 0.04) : 0))
                    .frame(
                        width: size * (0.52 + CGFloat(i) * 0.26),
                        height: size * (0.32 + CGFloat(i) * 0.16)
                    )
                    .offset(x: -size * 0.52, y: -size * 0.06)
                    .animation(
                        reduceMotion ? .none :
                            .easeInOut(duration: 0.85 + Double(i) * 0.3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.12),
                        value: lightOn
                    )
            }

            // Lamp (behind mascot)
            lampStructure
                .offset(x: -size * 0.70, y: 0)
                .zIndex(0)

            // Mascot in front
            MascotView(color: color, mood: .idle, size: size)
                .zIndex(1)
        }
        .frame(width: size * 1.75, height: size)
        .onAppear {
            guard !reduceMotion else {
                lightOn = true
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeIn(duration: 0.28)) { lightOn = true }
            }
        }
    }

    private var lampStructure: some View {
        let stemW  = size * 0.055
        let shadeW = size * 0.40
        let shadeH = size * 0.24
        return ZStack(alignment: .top) {
            // Lamp shade (trapezoid, wider at open end)
            LampShadeShape()
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                .frame(width: shadeW, height: shadeH)
                .overlay(
                    Circle()
                        .fill(Color.yellow.opacity(lightOn ? 0.88 : 0.0))
                        .frame(width: size * 0.13, height: size * 0.13)
                        .animation(.easeIn(duration: 0.28), value: lightOn)
                        .offset(y: shadeH * 0.22)
                )
                .offset(y: -size * 0.15)

            // Stem
            Capsule()
                .fill(Color(uiColor: .systemGray4))
                .frame(width: stemW, height: size * 0.44)
                .offset(y: size * 0.02)

            // Base
            Capsule()
                .fill(Color(uiColor: .systemGray3))
                .frame(width: size * 0.22, height: stemW * 1.3)
                .offset(y: size * 0.44)
        }
    }
}

private struct LampShadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let inset = rect.width * 0.20
            p.move(to: CGPoint(x: inset, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Spin Jump Mascot

/// Mascot that periodically jumps, does a full 360° spin in the air, then lands.
struct SpinJumpMascotView: View {
    var color: Color
    var size: CGFloat = 80

    @State private var offsetY: CGFloat = 0
    @State private var spinDeg: Double = 0
    @State private var jumpScale: CGFloat = 1.0
    @State private var shadowWidth: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.08))
                .frame(width: size * 0.55, height: size * 0.07)
                .scaleEffect(x: shadowWidth)
                .offset(y: 4)

            MascotView(color: color, mood: .happy, size: size)
                .offset(y: offsetY)
                .rotationEffect(.degrees(spinDeg))
                .scaleEffect(jumpScale)
        }
        .frame(width: size, height: size * 1.42)
        .onAppear { startLoop() }
    }

    private func startLoop() {
        guard !reduceMotion else { return }
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 750_000_000)

                // Lift off
                withAnimation(.easeOut(duration: 0.26)) {
                    offsetY     = -size * 0.64
                    jumpScale   = 1.10
                    shadowWidth = 0.44
                }
                // Spin in air
                withAnimation(.linear(duration: 0.55)) { spinDeg += 360 }
                try? await Task.sleep(nanoseconds: 545_000_000)

                // Land
                withAnimation(.spring(response: 0.27, dampingFraction: 0.58)) {
                    offsetY     = 0
                    jumpScale   = 1.0
                    shadowWidth = 1.0
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }
}

// MARK: - Computer Working Mascot

/// Mascot hunched over a pixel-art computer, bobbing as it "types". Shows optional progress text.
struct ComputerWorkingMascotView: View {
    var color: Color
    var size: CGFloat = 90
    var progressText: String = ""

    @State private var typingLean: Double = 0
    @State private var screenBright: Double = 0.72
    @State private var cursorOn: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: size * 0.05) {
            ZStack(alignment: .bottom) {
                computerDesk
                    .offset(y: size * 0.10)

                MascotView(color: color, mood: .thinking, size: size * 0.72)
                    .rotationEffect(.degrees(typingLean), anchor: .bottom)
                    .offset(y: -size * 0.03)
                    .zIndex(1)
            }
            .frame(width: size * 1.3, height: size * 1.15)

            if !progressText.isEmpty {
                Text(progressText)
                    .font(.system(size: size * 0.19, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                typingLean = 5
            }
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                screenBright = 1.0
            }
            Task {
                while true {
                    try? await Task.sleep(nanoseconds: 480_000_000)
                    cursorOn.toggle()
                }
            }
        }
    }

    private var computerDesk: some View {
        VStack(spacing: 2) {
            // Monitor
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                .frame(width: size * 0.95, height: size * 0.58)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.opacity(screenBright * 0.18))
                        .padding(5)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<5, id: \.self) { i in
                                    HStack {
                                        Capsule()
                                            .fill(
                                                color.opacity(
                                                    i == 4
                                                    ? (cursorOn ? 0.85 : 0.15)
                                                    : (0.42 + Double(i % 2) * 0.25)
                                                )
                                            )
                                            .frame(
                                                width: size * (0.26 + Double(i % 3) * 0.11),
                                                height: 3.5
                                            )
                                        Spacer()
                                    }
                                }
                            }
                            .padding(8)
                        )
                )

            // Stand
            Capsule()
                .fill(Color(uiColor: .systemGray4))
                .frame(width: size * 0.08, height: size * 0.09)

            // Keyboard
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: size * 0.82, height: size * 0.13)
                .overlay(
                    HStack(spacing: 2.5) {
                        ForEach(0..<7, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                                .frame(width: size * 0.085, height: size * 0.07)
                        }
                    }
                )
        }
    }
}

// MARK: - Sunglasses Celebration Mascot

/// One-shot celebration: sunglasses drop onto mascot's eyes → mascot jumps + spins 360° → lands → loops gentle bounce.
struct SunglassesMascotView: View {
    var color: Color
    var size: CGFloat = 100

    // Mascot eye-center sits at row 6.5/13 = exactly 0.5 of canvas height,
    // but visually the antenna rows push the face ~3% below geometric center.
    private var eyeY: CGFloat { size * 0.03 }

    @State private var glassesDropY: CGFloat = -55
    @State private var glassesOpacity: Double = 0
    @State private var spinDeg: Double = 0
    @State private var mascotOffsetY: CGFloat = 0
    @State private var mascotScale: CGFloat = 1.0
    @State private var shadowScale: CGFloat = 1.0
    @State private var mood: MascotMood = .happy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Ground shadow
            Ellipse()
                .fill(.black.opacity(0.07))
                .frame(width: size * 0.62, height: size * 0.07)
                .scaleEffect(x: shadowScale)
                .offset(y: size * 0.54 + mascotOffsetY * 0.25)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mascotOffsetY)

            // Mascot + sunglasses rotate together
            ZStack {
                MascotView(color: color, mood: mood, size: size)

                sunglasses
                    .offset(y: eyeY + glassesDropY)
                    .opacity(glassesOpacity)
            }
            .offset(y: mascotOffsetY)
            .rotationEffect(.degrees(spinDeg))
            .scaleEffect(mascotScale)
        }
        .frame(width: size * 1.15, height: size * 1.32)
        .task { await runSequence() }
    }

    private var sunglasses: some View {
        let d = size * 0.21
        let bW = size * 0.10
        return HStack(spacing: 0) {
            lens(d: d)
            Capsule()
                .fill(Color.black)
                .frame(width: bW, height: size * 0.038)
            lens(d: d)
        }
    }

    private func lens(d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.78))
                .frame(width: d, height: d)
            Circle()
                .stroke(.black, lineWidth: 2)
                .frame(width: d, height: d)
            // Shine highlight
            Circle()
                .fill(.white.opacity(0.24))
                .frame(width: d * 0.28, height: d * 0.28)
                .offset(x: -d * 0.18, y: -d * 0.18)
        }
    }

    private func runSequence() async {
        if reduceMotion {
            glassesDropY   = 0
            glassesOpacity = 1.0
            mood           = .celebrating
            return
        }
        try? await Task.sleep(nanoseconds: 300_000_000)

        // 1. Glasses drop
        withAnimation(.spring(response: 0.52, dampingFraction: 0.60)) {
            glassesDropY    = 0
            glassesOpacity  = 1.0
        }
        try? await Task.sleep(nanoseconds: 680_000_000)

        // 2. Jump
        withAnimation(.easeOut(duration: 0.30)) {
            mascotOffsetY = -size * 0.58
            mascotScale   = 1.12
            shadowScale   = 0.44
        }
        // 3. Spin
        withAnimation(.linear(duration: 0.65)) { spinDeg = 360 }
        try? await Task.sleep(nanoseconds: 650_000_000)

        // 4. Land
        withAnimation(.spring(response: 0.32, dampingFraction: 0.52)) {
            mascotOffsetY = 0
            mascotScale   = 1.0
            shadowScale   = 1.0
        }
        mood = .celebrating
        try? await Task.sleep(nanoseconds: 260_000_000)

        // 5. Gentle loop
        withAnimation(
            .spring(response: 0.52, dampingFraction: 0.50)
                .repeatForever(autoreverses: true)
        ) {
            mascotOffsetY = -size * 0.10
            mascotScale   = 1.06
        }
    }
}

// MARK: - Heart Pop Mascot

/// Theo bounces and hearts burst from its body — perfect for correct answers / rewards.
struct HeartPopMascotView: View {
    var color: Color = AppColors.brandPurple
    var size: CGFloat = 90

    private let heartColors: [Color] = [.red, .pink, Color(red: 1, green: 0.4, blue: 0.6),
                                         .orange, Color(red: 0.9, green: 0.2, blue: 0.5)]
    @State private var launched = false
    @State private var mascotOffsetY: CGFloat = 0
    @State private var mascotScaleX: CGFloat = 1.0
    @State private var mascotScaleY: CGFloat = 1.0
    @State private var shadowScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // 8 hearts at evenly spaced angles
    private let heartCount = 8
    private func angle(_ i: Int) -> Double { Double(i) * (360.0 / Double(heartCount)) }
    private func radius(_ i: Int) -> CGFloat { size * (0.72 + CGFloat(i % 3) * 0.15) }

    var body: some View {
        ZStack {
            // Ground shadow
            Ellipse()
                .fill(.black.opacity(0.07))
                .frame(width: size * 0.58, height: size * 0.07)
                .scaleEffect(x: shadowScale)
                .offset(y: size * 0.55 + mascotOffsetY * 0.3)
                .animation(.spring(response: 0.28, dampingFraction: 0.65), value: mascotOffsetY)

            // Hearts
            ForEach(0..<heartCount, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.18))
                    .foregroundStyle(heartColors[i % heartColors.count])
                    .offset(
                        x: launched ? cos(angle(i) * .pi / 180) * radius(i) : 0,
                        y: launched ? sin(angle(i) * .pi / 180) * radius(i) - size * 0.1 : 0
                    )
                    .scaleEffect(launched ? 0.0 : 0.0)
                    .opacity(launched ? 0 : 0)
                    .animation(
                        .spring(response: 0.48, dampingFraction: 0.55)
                            .delay(Double(i) * 0.04),
                        value: launched
                    )
            }

            // Mascot
            MascotView(color: color, mood: .happy, size: size)
                .scaleEffect(x: mascotScaleX, y: mascotScaleY)
                .offset(y: mascotOffsetY)
        }
        .frame(width: size * 2.2, height: size * 2.0)
        .task { await runSequence() }
    }

    private func runSequence() async {
        if reduceMotion {
            launched = true
            return
        }

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Anticipation squash
            withAnimation(.easeIn(duration: 0.09)) {
                mascotScaleX = 1.18; mascotScaleY = 0.78
                mascotOffsetY = size * 0.05
            }
            try? await Task.sleep(nanoseconds: 90_000_000)

            // Launch + hearts burst
            withAnimation(.easeOut(duration: 0.22)) {
                mascotScaleX = 0.85; mascotScaleY = 1.22
                mascotOffsetY = -size * 0.50
                shadowScale = 0.38
            }
            // Hearts appear immediately
            withAnimation(.easeOut(duration: 0.15)) {
                launched = true
            }
            // Override opacity/scale via separate animation
            try? await Task.sleep(nanoseconds: 200_000_000)

            // Apex normalize
            withAnimation(.easeInOut(duration: 0.08)) {
                mascotScaleX = 1.0; mascotScaleY = 1.0
            }
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Land squash
            withAnimation(.easeIn(duration: 0.09)) {
                mascotScaleX = 1.22; mascotScaleY = 0.74
                mascotOffsetY = 0; shadowScale = 1.0
            }
            try? await Task.sleep(nanoseconds: 90_000_000)

            // Settle
            withAnimation(.spring(response: 0.30, dampingFraction: 0.50)) {
                mascotScaleX = 1.0; mascotScaleY = 1.0
            }
            // Hearts fade out
            withAnimation(.easeOut(duration: 0.45).delay(0.3)) {
                launched = false
            }

            try? await Task.sleep(nanoseconds: 1_400_000_000)
        }
    }
}

// MARK: - Shake Mascot

/// Theo shakes left-right rapidly — for wrong answers, errors, or playful "no!".
struct ShakeMascotView: View {
    var color: Color = AppColors.brandPurple
    var size: CGFloat = 80
    /// If true, the shake plays once automatically on appear.
    var autoPlay: Bool = true
    /// Called after each shake cycle finishes.
    var onShakeComplete: (() -> Void)? = nil

    @State private var tilt: Double = 0
    @State private var offsetX: CGFloat = 0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MascotView(color: color, mood: .idle, size: size)
            .rotationEffect(.degrees(tilt))
            .offset(x: offsetX)
            .scaleEffect(x: scaleX, y: scaleY)
            .task {
                guard autoPlay, !reduceMotion else { return }
                try? await Task.sleep(nanoseconds: 250_000_000)
                await shakeOnce()
            }
    }

    func shakeOnce() async {
        guard !reduceMotion else { return }
        // 5 rapid left-right shakes
        let shakes = 5
        for i in 0..<shakes {
            let direction: CGFloat = i % 2 == 0 ? 1 : -1
            withAnimation(.easeInOut(duration: 0.07)) {
                tilt = direction * 16
                offsetX = direction * size * 0.12
                scaleX = 1.08; scaleY = 0.94
            }
            try? await Task.sleep(nanoseconds: 75_000_000)
        }
        // Settle with overshoot
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            tilt = 0; offsetX = 0; scaleX = 1.0; scaleY = 1.0
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        onShakeComplete?()
    }
}

// MARK: - Pulse Glow Mascot

/// Mascot that pulses a soft colored glow ring — ideal for loading, focus, or feature highlights.
struct PulseGlowMascotView: View {
    var color: Color = AppColors.brandPurple
    var size: CGFloat = 80

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.55
    @State private var floatY: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size * 1.55, height: size * 1.55)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)

            // Middle ring
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: size * 1.22, height: size * 1.22)
                .scaleEffect(1.0 + (glowScale - 1.0) * 0.55)
                .opacity(glowOpacity * 0.75)

            MascotView(color: color, mood: .idle, size: size)
                .offset(y: floatY)
        }
        .frame(width: size * 1.7, height: size * 1.7)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glowScale = 1.18
                glowOpacity = 0.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatY = -6
            }
        }
    }
}
