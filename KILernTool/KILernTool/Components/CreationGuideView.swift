import SwiftUI

// MARK: - Guide Animation Style

enum MascotGuideStyle: CaseIterable {
    case reading, lamp, spinning
}

// MARK: - Mascot Guide Banner

/// Reusable in-creation guide banner.
/// Shows one of three animated mascot styles (randomly chosen on appear).
/// Typewriter-animates `text` whenever it changes.
struct MascotGuideBanner: View {
    let color: Color
    let characterName: String
    let text: String

    @State private var style: MascotGuideStyle = .reading
    @State private var displayed: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Animated mascot (one of 3 styles, chosen once on appear)
            Group {
                switch style {
                case .reading:
                    BookReadingMascotView(color: color, size: 56)
                        .frame(width: 56, height: 68)
                case .lamp:
                    LampMascotView(color: color, size: 52)
                        .frame(width: 72, height: 60)
                case .spinning:
                    MascotView(color: color, mood: .talking, size: 54)
                        .frame(width: 54, height: 60)
                        .scaleEffect(style == .spinning ? 1.0 : 1.0)
                }
            }
            .frame(width: 72, height: 72, alignment: .center)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                // Character name badge
                Text(characterName.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .tracking(1.5)

                // Stable-height ghost + typewriter overlay
                ZStack(alignment: .topLeading) {
                    // Invisible full text anchors the frame height
                    Text(attributed(text))
                        .font(.system(size: 13))
                        .lineSpacing(2)
                        .opacity(0)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Typewritten text
                    Text(attributed(displayed))
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil, value: displayed)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(color.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.16), lineWidth: 1)
                )
        )
        .onAppear {
            style = MascotGuideStyle.allCases.randomElement() ?? .reading
        }
        // Re-typewrite whenever `text` changes — word by word to prevent mid-word wrap jumps
        .task(id: text) {
            if reduceMotion {
                displayed = text
                return
            }
            displayed = ""
            try? await Task.sleep(nanoseconds: 60_000_000)
            // Split on spaces but keep newlines as tokens
            let tokens = text.components(separatedBy: " ")
            for (i, token) in tokens.enumerated() {
                guard !Task.isCancelled else { return }
                displayed += (i == 0 ? "" : " ") + token
                let isNewline = token.contains("\n")
                try? await Task.sleep(nanoseconds: isNewline ? 30_000_000 : 65_000_000)
            }
        }
    }

    private func attributed(_ str: String) -> AttributedString {
        (try? AttributedString(
            markdown: str,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(str)
    }
}

// MARK: - Creation Progress Bar

/// Thin animated progress bar placed below the nav bar of a create view.
struct CreationProgressBar: View {
    let progress: Double  // 0.0 ... 1.0
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.10))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.68)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(0, geo.size.width * CGFloat(min(progress, 1.0))),
                        height: geo.size.height
                    )
                    .animation(.spring(response: 0.55, dampingFraction: 0.78), value: progress)
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
    }
}
