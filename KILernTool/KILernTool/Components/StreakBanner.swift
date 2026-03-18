import SwiftUI

// MARK: - Correct Answer Flash
// A brief green shimmer overlay shown for ~0.6s when a correct answer is given.

struct CorrectAnswerFlash: View {
    @Binding var isVisible: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Green halo ring
            Circle()
                .stroke(Color.green.opacity(0.35), lineWidth: 3)
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
                .opacity(opacity)

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.green)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                scale = 1.0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 0
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isVisible = false
                    scale = 0.5
                }
            }
        }
    }
}

// MARK: - Streak Banner
// Duolingo-style banner that slides in from the top after 5 correct answers in a row.
// Auto-dismisses after 2 seconds.

struct StreakBanner: View {
    let streak: Int
    var color: Color = AppColors.brandQuick
    @Binding var isVisible: Bool

    @State private var offsetY: CGFloat = -120
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var message: String {
        switch streak {
        case 5:  return "5 richtig in Folge! 🔥"
        case 10: return "10 in Folge! Unglaublich! 🚀"
        default: return "\(streak) richtig in Folge! 🔥"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            SpinJumpMascotView(color: color, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Weiter so – du bist auf Feuer!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: color.opacity(0.25), radius: 14, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            withAnimation(reduceMotion ? nil : AppAnimation.emphasized) {
                offsetY = 0
                opacity = 1
            }
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(reduceMotion ? nil : .easeIn(duration: AppAnimation.exitDuration)) {
                    offsetY = -120
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + AppAnimation.exitDuration) {
                    isVisible = false
                }
            }
        }
        .allowsHitTesting(false)
    }
}
