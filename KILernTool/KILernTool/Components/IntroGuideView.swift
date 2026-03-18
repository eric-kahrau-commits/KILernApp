import SwiftUI

// MARK: - Waving Mascot

/// MascotView with an animated waving arm, body tilt, and gentle float.
struct WavingMascotView: View {
    var color: Color = AppColors.brandPurple
    var size: CGFloat = 100

    @State private var waveAngle: Double = 115
    @State private var bodyTilt: Double = 0
    @State private var floatY: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            MascotView(color: color, mood: .talking, size: size)
                .rotationEffect(.degrees(bodyTilt))
                .offset(y: floatY)

            // Arm: capsule at right shoulder, pivoting from top.
            Capsule()
                .fill(color)
                .frame(width: size * 0.16, height: size * 0.28)
                .rotationEffect(.degrees(waveAngle), anchor: .top)
                .offset(x: size * 0.46, y: -size * 0.02)
        }
        .frame(width: size * 1.4, height: size)
        .onAppear {
            guard !reduceMotion else {
                waveAngle = 140
                return
            }
            // Arm waves at fast rate
            withAnimation(.easeInOut(duration: 0.38).repeatForever(autoreverses: true)) {
                waveAngle = 155
            }
            // Body counter-tilts for natural weight shift (different timing)
            withAnimation(.easeInOut(duration: 0.76).repeatForever(autoreverses: true)) {
                bodyTilt = 4
            }
            // Gentle float (independent timing)
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                floatY = -6
            }
        }
    }
}

// MARK: - Speech Bubble Triangle

private struct BubbleTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Mode Intro View

/// Full-page first-time intro shown once per mode (persisted via UserDefaults).
/// Presents a gradient background, waving mascot, typewriter speech bubble,
/// and a "Loslegen!" CTA that calls `onLoslegen` and marks the intro as seen.
struct ModeIntroView: View {
    let characterName: String
    let characterRole: String
    let gradientTop: Color
    let gradientBottom: Color
    let mascotColor: Color
    let introText: String
    let defaultsKey: String
    let onLoslegen: () -> Void

    @State private var displayed: String = ""
    @State private var textDone = false

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(colors: [gradientTop, gradientBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Mascot + glow rings
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(.white.opacity(0.07 - Double(i) * 0.02))
                            .frame(width: 160 + CGFloat(i) * 38,
                                   height: 160 + CGFloat(i) * 38)
                    }
                    WavingMascotView(color: mascotColor, size: 110)
                }

                Spacer().frame(height: 18)

                // Name badge
                HStack(spacing: 6) {
                    Text(characterName.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("· \(characterRole)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.18)))

                Spacer().frame(height: 24)

                // Speech bubble
                VStack(spacing: -1) {
                    // Small triangle pointing up toward mascot
                    BubbleTriangle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: 22, height: 12)

                    // Bubble card
                    ZStack(alignment: .topLeading) {
                        // Invisible full text sets stable frame height
                        Text(introText)
                            .font(.system(size: 15))
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                            .opacity(0)

                        // Typewriter text
                        Text(attributedDisplayed)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                            .animation(nil, value: displayed)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 8)
                    )
                }

                Spacer().frame(height: 22)

                // Loslegen button
                Button(action: loslegen) {
                    HStack(spacing: 10) {
                        Text("Loslegen!")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(gradientTop)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)
                .opacity(textDone ? 1.0 : 0.42)

                Spacer().frame(height: 44)
            }
            .padding(.horizontal, 28)
        }
        .task { await typeText() }
    }

    // MARK: - Helpers

    private var attributedDisplayed: AttributedString {
        (try? AttributedString(
            markdown: displayed,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(displayed)
    }

    private func loslegen() {
        UserDefaults.standard.set(true, forKey: defaultsKey)
        onLoslegen()
    }

    private func typeText() async {
        // Short pause so the view settles before typing starts
        try? await Task.sleep(nanoseconds: 450_000_000)
        for char in introText {
            displayed.append(char)
            // Slower at word boundaries (after space/newline) for dramatic effect
            let isBreak = char == " " || char == "\n"
            let ns: UInt64 = isBreak ? 55_000_000 : 22_000_000
            try? await Task.sleep(nanoseconds: ns)
        }
        withAnimation(.easeIn(duration: 0.3)) { textDone = true }
    }
}
