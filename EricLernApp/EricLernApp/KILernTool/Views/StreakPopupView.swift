import SwiftUI
import UIKit

struct StreakPopupView: View {
    let streak: Int
    let onDismiss: () -> Void

    @State private var cardScale: CGFloat = 0.72
    @State private var cardOpacity: Double = 0
    @State private var flameScale: CGFloat = 0.5
    @State private var flameRotation: Double = -8
    @State private var numberScale: CGFloat = 0.5
    @State private var numberOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    private let orange = Color(red: 0.96, green: 0.52, blue: 0.08)

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { animateDismiss() }

            // Card
            VStack(spacing: 0) {
                // Flame + glow area
                ZStack {
                    // Soft glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [orange.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 72
                            )
                        )
                        .frame(width: 144, height: 144)
                        .opacity(glowOpacity)

                    Text("🔥")
                        .font(.system(size: 72))
                        .scaleEffect(flameScale)
                        .rotationEffect(.degrees(flameRotation))
                }
                .padding(.top, 32)
                .padding(.bottom, 8)

                // Streak number
                Text("\(streak)")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.62, blue: 0.10), orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(numberScale)
                    .opacity(numberOpacity)

                Text(streak == 1 ? "Tag in Folge" : "Tage in Folge")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)

                // Label block
                VStack(spacing: 5) {
                    Text("Daily Streak")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Du lernst jeden Tag – weiter so!")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // Dismiss button
                Button(action: animateDismiss) {
                    Text("Super, weiter!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.60, blue: 0.08), orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(orange.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: orange.opacity(0.22), radius: 40, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 6)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear { animateIn() }
    }

    private func animateIn() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        withAnimation(.spring(response: 0.48, dampingFraction: 0.70)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.60).delay(0.08)) {
            flameScale = 1.0
            flameRotation = 0
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.18)) {
            numberScale = 1.0
            numberOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            glowOpacity = 1.0
        }
    }

    private func animateDismiss() {
        withAnimation(.easeIn(duration: 0.18)) {
            cardScale = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
