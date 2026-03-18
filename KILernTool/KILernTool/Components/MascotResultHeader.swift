import SwiftUI

// MARK: - Mascot Result Header
// Score-dependent mascot card at the top of every result/Auswertung screen.
//
// 100%      → SunglassesMascot + confetti rain + "PERFEKT! 🌟"
// 80–99%    → MascotView(.celebrating) + "Sehr gut! 👏"
// 60–79%    → MascotView(.happy)       + "Gut gemacht! 💪"
// 40–59%    → MascotView(.thinking)    + "Noch ein bisschen üben! 📚"
// <40%      → MascotView(.idle)        + "Kopf hoch! Weiter üben! 🎯"

struct MascotResultHeader: View {
    let percentage: Double   // 0–100
    var color: Color = AppColors.brandPurple

    @State private var appeared = false
    @State private var confettiParticles: [ConfettiParticle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Score-based config

    private var mascotMood: MascotMood {
        if percentage >= 80 { return .celebrating }
        if percentage >= 60 { return .happy }
        if percentage >= 40 { return .thinking }
        return .idle
    }

    private var headlineText: String {
        if percentage == 100 { return "PERFEKT!" }
        if percentage >= 80  { return "Sehr gut!" }
        if percentage >= 60  { return "Gut gemacht!" }
        if percentage >= 40  { return "Nicht schlecht!" }
        return "Kopf hoch!"
    }

    private var subtitleText: String {
        if percentage == 100 { return "Alles richtig – du bist der Beste! 🌟" }
        if percentage >= 80  { return "Fast perfekt – weiter so! 👏" }
        if percentage >= 60  { return "Solide Leistung – noch etwas üben! 💪" }
        if percentage >= 40  { return "Noch ein bisschen Übung hilft! 📚" }
        return "Übung macht den Meister – nicht aufgeben! 🎯"
    }

    private var gradeColor: Color {
        if percentage >= 80 { return .green }
        if percentage >= 60 { return Color(red: 0.10, green: 0.64, blue: 0.54) }
        if percentage >= 40 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [gradeColor.opacity(0.13), gradeColor.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(gradeColor.opacity(0.15), lineWidth: 1)
                )

            // Confetti (100% only)
            if percentage == 100 && !reduceMotion {
                ConfettiView(particles: confettiParticles)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                // Mascot
                ZStack {
                    if percentage == 100 {
                        SunglassesMascotView(color: gradeColor, size: 90)
                    } else {
                        MascotView(color: gradeColor, mood: mascotMood, size: 80)
                    }
                }
                .padding(.top, 8)

                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: appeared ? CGFloat(percentage / 100) : 0)
                        .stroke(
                            gradeColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.9, dampingFraction: 0.75).delay(0.2),
                            value: appeared
                        )
                    VStack(spacing: 0) {
                        Text("\(Int(percentage.rounded()))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(gradeColor)
                        if percentage == 100 {
                            Text("🌟")
                                .font(.system(size: 12))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.5), value: appeared)
                }

                // Message
                VStack(spacing: 4) {
                    Text(headlineText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(gradeColor)
                    Text(subtitleText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.88)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(reduceMotion ? nil : AppAnimation.emphasized) {
                appeared = true
            }
            if percentage == 100 && !reduceMotion {
                confettiParticles = ConfettiParticle.generate(count: 60)
            }
        }
    }
}

// MARK: - Confetti

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat        // start X (0–1 normalized)
    let color: Color
    let size: CGFloat
    let speed: Double     // animation duration
    let delay: Double
    let rotation: Double

    static func generate(count: Int) -> [ConfettiParticle] {
        let colors: [Color] = [.yellow, .green, .blue, .red, .purple, .orange, .pink]
        return (0..<count).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...1),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...11),
                speed: Double.random(in: 1.4...2.6),
                delay: Double.random(in: 0...0.8),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

private struct ConfettiView: View {
    let particles: [ConfettiParticle]

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                ConfettoPiece(particle: p, height: geo.size.height)
                    .position(x: p.x * geo.size.width, y: -10)
            }
        }
    }
}

private struct ConfettoPiece: View {
    let particle: ConfettiParticle
    let height: CGFloat
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.5)
            .rotationEffect(.degrees(rotation))
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.speed).delay(particle.delay)
                ) {
                    offsetY = height + 20
                    rotation = particle.rotation + 360
                }
                withAnimation(
                    .easeIn(duration: 0.4).delay(particle.delay + particle.speed * 0.6)
                ) {
                    opacity = 0
                }
            }
    }
}
