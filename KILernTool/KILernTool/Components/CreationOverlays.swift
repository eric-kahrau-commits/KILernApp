import SwiftUI

// MARK: - Generating Progress Overlay

/// Full-screen overlay shown while AI is generating content.
/// Shows a computer-working mascot, animated percentage ring, and simulated progress.
struct GeneratingProgressOverlay: View {
    let color: Color
    let characterName: String
    var message: String = "Wird erstellt …"

    /// Pass a real 0.0–1.0 binding, or use the auto-simulating init.
    @Binding var progress: Double

    @State private var displayedPct: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).opacity(0.97).ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Computer mascot
                ComputerWorkingMascotView(color: color, size: 100)

                // Percentage ring
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.14), lineWidth: 9)
                        .frame(width: 96, height: 96)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.45, dampingFraction: 0.78), value: progress)

                    Text("\(displayedPct)%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35), value: displayedPct)
                }

                VStack(spacing: 6) {
                    Text(message)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("\(characterName) arbeitet für dich …")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .onChange(of: progress) { _, newVal in
            withAnimation(.spring(response: 0.4)) {
                displayedPct = Int(newVal * 100)
            }
        }
        .onAppear {
            displayedPct = Int(progress * 100)
        }
    }
}

// MARK: - Simulated Progress Overlay

/// Convenience overlay that auto-simulates progress from 0 → 95 %,
/// then jumps to 100 % when `isComplete` becomes true and auto-dismisses.
struct SimulatedGeneratingOverlay: View {
    let color: Color
    let characterName: String
    var message: String = "Wird erstellt …"
    let isComplete: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var progress: Double = 0.0

    var body: some View {
        GeneratingProgressOverlay(
            color: color,
            characterName: characterName,
            message: message,
            progress: $progress
        )
        .onAppear { simulateProgress() }
        .onChange(of: isComplete) { _, done in
            guard done else { return }
            withAnimation(.spring(response: 0.4)) { progress = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onDismiss?() }
        }
    }

    private func simulateProgress() {
        Task {
            // Ramp quickly to 30 %
            for i in 1...30 {
                try? await Task.sleep(nanoseconds: 30_000_000)
                await MainActor.run {
                    progress = Double(i) / 100.0
                }
            }
            // Slow crawl to 70 %
            for i in 31...70 {
                try? await Task.sleep(nanoseconds: 55_000_000)
                await MainActor.run {
                    progress = Double(i) / 100.0
                }
            }
            // Very slow to 95 % (never reaches 100 % naturally)
            for i in 71...95 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run {
                    progress = Double(i) / 100.0
                }
            }
        }
    }
}

// MARK: - Save Celebration Overlay

/// Full-screen celebration shown after saving.
/// Features `SunglassesMascotView` (sunglasses + spin) on a gradient background.
/// Auto-dismisses after 2.5 s (no button) or 4 s (with button).
/// Pass `onStartLearning` to show a "Jetzt starten →" button.
struct SaveCelebrationOverlay: View {
    let color: Color
    let characterName: String
    var onStartLearning: (() -> Void)? = nil
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [color, color.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Glow rings
            ForEach(0..<3) { i in
                Circle()
                    .fill(.white.opacity(0.06 - Double(i) * 0.015))
                    .frame(
                        width: 220 + CGFloat(i) * 65,
                        height: 220 + CGFloat(i) * 65
                    )
            }

            VStack(spacing: 32) {
                Spacer()

                SunglassesMascotView(color: .white, size: 130)

                VStack(spacing: 8) {
                    Text("Gespeichert! 🎉")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(characterName) ist stolz auf dich!")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.82))
                }

                if let startAction = onStartLearning {
                    Button(action: startAction) {
                        HStack(spacing: 8) {
                            Text("Jetzt starten")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(color)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(.white))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
        .task {
            let delay: UInt64 = onStartLearning == nil ? 2_500_000_000 : 4_000_000_000
            try? await Task.sleep(nanoseconds: delay)
            onDismiss()
        }
    }
}

// MARK: - Error Overlay

/// Full-screen error feedback shown when AI generation fails.
/// Shows a thinking mascot with a gentle shake, the error message, and a retry button.
struct ErrorOverlay: View {
    let color: Color
    let characterName: String
    let message: String
    var onRetry: (() -> Void)? = nil
    var onDismiss: () -> Void

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).opacity(0.97).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                MascotView(color: color, mood: .thinking, size: 100)
                    .offset(x: shakeOffset)

                VStack(spacing: 8) {
                    Text("Etwas ist schiefgelaufen 😓")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Text("\(characterName) entschuldigt sich!")
                        .font(.system(size: 13))
                        .foregroundStyle(color.opacity(0.8))
                }

                VStack(spacing: 12) {
                    if let retry = onRetry {
                        Button(action: retry) {
                            Text("Nochmal versuchen")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(color)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Button(action: onDismiss) {
                        Text("Abbrechen")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            // Gentle head-shake
            let spring = Animation.spring(response: 0.15, dampingFraction: 0.3)
            withAnimation(spring) { shakeOffset = -12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(spring) { shakeOffset = 10 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(spring) { shakeOffset = -7 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(spring) { shakeOffset = 0 }
                    }
                }
            }
        }
    }
}
