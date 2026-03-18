import SwiftUI

// MARK: - NotificationPermissionSheet
//
// Beautiful in-app prompt that explains the value of notifications before
// forwarding the user to the system permission dialog.
// Shown: (1) on first launch, (2) after plan creation, (3) weekly if still denied.

struct NotificationPermissionSheet: View {
    var onAllow: () -> Void
    var onDismiss: () -> Void

    @State private var mascotAppeared = false
    @State private var contentAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let accent = AppColors.brandPurple

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.14),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                // MARK: Mascot section
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 130, height: 130)
                        .scaleEffect(mascotAppeared ? 1.0 : 0.6)

                    Circle()
                        .fill(accent.opacity(0.07))
                        .frame(width: 160, height: 160)
                        .scaleEffect(mascotAppeared ? 1.0 : 0.5)

                    // App icon badge (matches home-screen icon)
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.49, green: 0.23, blue: 0.93),
                                        Color(red: 0.18, green: 0.06, blue: 0.55)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: accent.opacity(0.55), radius: 20, x: 0, y: 10)

                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 68, height: 68)

                        MascotView(color: .white, mood: .happy, size: 70)
                    }
                    .scaleEffect(mascotAppeared ? 1.0 : 0.5)
                    .opacity(mascotAppeared ? 1 : 0)

                    // Bell badge
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(Circle().fill(Color(red: 0.95, green: 0.35, blue: 0.30)))
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                        .offset(x: 42, y: -42)
                        .scaleEffect(mascotAppeared ? 1.0 : 0.3)
                        .opacity(mascotAppeared ? 1 : 0)
                }
                .padding(.bottom, 28)

                // MARK: Headline
                VStack(spacing: 8) {
                    Text("Theo erinnert dich!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Aktiviere Benachrichtigungen, damit Theo\ndich motiviert und du keinen Tag verpasst.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 12)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                // MARK: Preview cards (mock notifications)
                VStack(spacing: 10) {
                    mockNotificationCard(
                        emoji: "🔥",
                        title: "Streak-Alarm! Noch 4 Std. übrig",
                        body: "Theo schläft gleich ein – kurz lernen und Streak retten!",
                        delay: 0.0
                    )
                    mockNotificationCard(
                        emoji: "📚",
                        title: "Theo hat deinen Plan für heute!",
                        body: "\u{201E}Mathe Kapitel 3\u{201C} wartet auf dich. Lass uns loslegen \u{1F4AA}",
                        delay: 0.08
                    )
                    mockNotificationCard(
                        emoji: "🤖",
                        title: "Guten Morgen! 7 Tage Streak 🎉",
                        body: "Eine Woche am Stück – du bist unaufhaltbar!",
                        delay: 0.16
                    )
                }
                .padding(.horizontal, 20)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)

                Spacer(minLength: 32)

                // MARK: Buttons
                VStack(spacing: 12) {
                    Button(action: onAllow) {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Benachrichtigungen einschalten")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .shadow(color: accent.opacity(0.40), radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    Button(action: onDismiss) {
                        Text("Später")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(contentAppeared ? 1 : 0)
            }
        }
        .onAppear {
            let dur = reduceMotion ? 0.0 : 0.55
            withAnimation(.spring(response: dur, dampingFraction: 0.72)) {
                mascotAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.20)) {
                withAnimation(.spring(response: 0.50, dampingFraction: 0.78)) {
                    contentAppeared = true
                }
            }
        }
    }

    // MARK: - Mock Notification Card

    private func mockNotificationCard(emoji: String, title: String, body: String,
                                       delay: Double) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // App icon mini
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.23, blue: 0.93),
                                Color(red: 0.18, green: 0.06, blue: 0.55)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                MascotView(color: .white, mood: .idle, size: 26)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Open Learn")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("jetzt")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Text(emoji + " " + title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}
