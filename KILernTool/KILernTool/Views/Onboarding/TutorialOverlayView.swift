import SwiftUI

// MARK: - Tutorial Overlay

struct TutorialOverlayView: View {
    @ObservedObject var manager: TutorialManager

    /// Called when overlay triggers the hamburger-menu tap (step 1).
    let onHamburgerTap: () -> Void
    /// Called when overlay triggers the Neu-item tap (step 2).
    let onNeuTap: () -> Void

    @State private var arrowOffset: CGFloat = 0
    @State private var pulseScale:  CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var cardVisible = false

    private let purple = AppColors.brandPurple

    var body: some View {
        GeometryReader { geo in
            if manager.isActive {
                let frame    = manager.currentFrame
                let padded   = paddedFrame(frame, padding: 14)
                let step     = manager.step
                let isStep3  = step == .kiLernsetCard

                ZStack {
                    // ── 1. Tap absorber (blocks everything except step-3 spotlight) ──
                    if !isStep3 {
                        Rectangle()
                            .fill(Color.black.opacity(0.001))
                            .ignoresSafeArea()
                            .onTapGesture {} // swallow stray taps
                    }

                    // ── 2. Dark scrim with spotlight cutout ──
                    scrim(spotlight: padded)

                    // ── 3. Pulsing highlight ring ──
                    if padded != .zero {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: padded.width  + (pulseScale - 1) * 22,
                                   height: padded.height + (pulseScale - 1) * 22)
                            .position(x: padded.midX, y: padded.midY)
                            .opacity(pulseOpacity)
                            .allowsHitTesting(false)
                    }

                    // ── 4. Tap zone (steps 1 & 2 only) ──
                    if !isStep3, padded != .zero {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.001))
                            .frame(width: padded.width + 8, height: padded.height + 8)
                            .position(x: padded.midX, y: padded.midY)
                            .onTapGesture { performAction() }
                    }

                    // ── 5. Tutorial card + mascot ──
                    if cardVisible, padded != .zero {
                        tutorialCard(in: geo, spotlight: padded, step: step)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .center)))
                    }

                    // ── 6. Skip button ──
                    if cardVisible {
                        VStack {
                            HStack {
                                Spacer()
                                Button("Überspringen") { manager.skip() }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .padding(.trailing, 20)
                                    .padding(.top, 16)
                            }
                            Spacer()
                        }
                        .allowsHitTesting(true)
                    }
                }
                .transition(.opacity)
                .onAppear {
                    startAnimations()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                            cardVisible = true
                        }
                    }
                }
                .onChange(of: manager.step) { _, _ in
                    withAnimation(.easeOut(duration: 0.18)) { cardVisible = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        startAnimations()
                        withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                            cardVisible = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Scrim

    @ViewBuilder
    private func scrim(spotlight: CGRect) -> some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            if spotlight != .zero {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .frame(width: spotlight.width, height: spotlight.height)
                    .position(x: spotlight.midX, y: spotlight.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Tutorial Card

    private func tutorialCard(in geo: GeometryProxy, spotlight: CGRect, step: TutorialStep) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        let isBelow = spotlight.midY < h * 0.48 // card goes below spotlight
        let arrowUp = !isBelow                   // arrow points up when card is below

        let cardY: CGFloat = isBelow
            ? min(spotlight.maxY + 190, h - 140)
            : max(spotlight.minY - 190, 180)

        return VStack(spacing: 0) {
            // Arrow above card
            if !arrowUp {
                bounceArrow(up: false)
                    .padding(.bottom, 10)
            }

            // Card
            HStack(alignment: .center, spacing: 16) {
                // Mascot circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [purple, Color(red: 0.22, green: 0.08, blue: 0.65)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 72, height: 72)
                        .shadow(color: purple.opacity(0.55), radius: 16, x: 0, y: 6)
                    MascotView(color: .white, mood: step.mood, size: 52)
                }

                // Text
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.instruction)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(step.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 12))
                        Text(step == .kiLernsetCard ? "Tippe auf die Karte!" : "Tippe auf den Bereich!")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(purple.opacity(0.10)))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.24), radius: 30, x: 0, y: 12)
            )

            // Arrow below card
            if arrowUp {
                bounceArrow(up: true)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 22)
        .position(
            x: clamp(value: spotlight.midX, lo: w * 0.38, hi: w * 0.62),
            y: cardY
        )
    }

    // MARK: - Arrow

    private func bounceArrow(up: Bool) -> some View {
        Image(systemName: up ? "arrow.up" : "arrow.down")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.30), radius: 5, x: 0, y: 3)
            .offset(y: up ? -arrowOffset : arrowOffset)
    }

    // MARK: - Animations

    private func startAnimations() {
        arrowOffset = 0
        pulseScale  = 1.0
        withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
            arrowOffset = 11
        }
        withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
            pulseScale   = 1.32
            pulseOpacity = 0.15
        }
    }

    // MARK: - Action

    private func performAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch manager.step {
        case .hamburgerMenu:
            onHamburgerTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { manager.advance() }
        case .neuSidebarItem:
            onNeuTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { manager.advance() }
        case .kiLernsetCard:
            // Handled directly in NewView; should not reach here.
            manager.complete()
        }
    }

    // MARK: - Helpers

    private func paddedFrame(_ frame: CGRect, padding: CGFloat) -> CGRect {
        guard frame != .zero else { return .zero }
        return CGRect(
            x: frame.minX - padding,
            y: frame.minY - padding,
            width: frame.width  + padding * 2,
            height: frame.height + padding * 2
        )
    }

    private func clamp(value: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        min(max(value, lo), hi)
    }
}
