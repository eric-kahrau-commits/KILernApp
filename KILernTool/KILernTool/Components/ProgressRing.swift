import SwiftUI

/// A circular progress ring with optional center label.
///
/// Supports single-color and gradient strokes. Used in StatsView (80pt)
/// and plan-row cells (32pt mini).
struct ProgressRing: View {
    let progress: Double       // 0.0 – 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    var color: Color = .accentColor
    var gradient: [Color]? = nil
    var centerLabel: String? = nil
    var centerSubLabel: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var springAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(response: 0.7, dampingFraction: 0.8)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Fill — gradient or solid
            if let grad = gradient {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(colors: grad, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(springAnimation, value: progress)
            } else {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(springAnimation, value: progress)
            }

            // Center text
            // Gradient rings use .primary label; solid rings use the stroke color
            if centerLabel != nil || centerSubLabel != nil {
                VStack(spacing: 0) {
                    if let label = centerLabel {
                        Text(label)
                            .font(.system(
                                size: size >= 60 ? 16 : 7,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundStyle(gradient != nil ? AnyShapeStyle(.primary) : AnyShapeStyle(color))
                    }
                    if let sub = centerSubLabel {
                        Text(sub)
                            .font(.system(size: size >= 60 ? 10 : 7, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(centerSubLabel.map { $0 + ": " } ?? "")\(Int(progress * 100)) Prozent")
        .accessibilityValue(centerLabel ?? "\(Int(progress * 100))%")
    }
}
