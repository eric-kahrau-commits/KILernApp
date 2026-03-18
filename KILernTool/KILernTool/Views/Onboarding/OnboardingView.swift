import SwiftUI

// MARK: - Pre-Login Onboarding

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var page = 0

    private let slides = OnboardingSlide.all

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: slides[page].colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.55), value: page)

            // Subtle particle shimmer
            ShimmerOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if page < slides.count - 1 {
                        Button { withAnimation(.spring(response: 0.45)) { page = slides.count - 1 } } label: {
                            Text("Überspringen")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.white.opacity(0.18)))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                    } else {
                        Color.clear.frame(height: 52)
                    }
                }

                // Slide carousel
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                        OnboardingSlideView(
                            slide: slide,
                            isActive: page == i,
                            isLast: i == slides.count - 1,
                            onContinue: advance
                        )
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i == page ? 1.0 : 0.35))
                            .frame(width: i == page ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.38), value: page)
                    }
                }
                .padding(.bottom, 44)
            }
        }
    }

    private func advance() {
        if page < slides.count - 1 {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.85)) { page += 1 }
        } else {
            UserDefaults.standard.set(true, forKey: "ol_hasSeenOnboarding")
            withAnimation(.easeInOut(duration: 0.38)) { onComplete() }
        }
    }
}

// MARK: - Slide Data

struct OnboardingSlide {
    let title:    String
    let subtitle: String
    let mood:     MascotMood
    let colors:   [Color]
    let visual:   Visual

    enum Visual { case none, cards, bars, features }

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            title:    "Willkommen bei\nOpen Learn!",
            subtitle: "Lerne smarter – dein KI-Lernassistent\nist ab jetzt immer dabei.",
            mood:     .celebrating,
            colors:   [Color(red: 0.38, green: 0.18, blue: 0.90), Color(red: 0.18, green: 0.06, blue: 0.62)],
            visual:   .none
        ),
        OnboardingSlide(
            title:    "KI-Lernsets in\nSekunden",
            subtitle: "Gib ein Thema ein – die KI erstellt dir\nperfekte Lernkarten automatisch.",
            mood:     .happy,
            colors:   [Color(red: 0.22, green: 0.14, blue: 0.88), Color(red: 0.10, green: 0.48, blue: 0.92)],
            visual:   .cards
        ),
        OnboardingSlide(
            title:    "Nie mehr\nvergessen",
            subtitle: "Spaced Repetition merkt sich, wann\ndu genau wiederholen solltest.",
            mood:     .thinking,
            colors:   [Color(red: 0.10, green: 0.42, blue: 0.78), Color(red: 0.08, green: 0.58, blue: 0.48)],
            visual:   .bars
        ),
        OnboardingSlide(
            title:    "Alles in\neiner App",
            subtitle: "KI-Sets, Lernpläne, Vokabeln, Tests –\nkomplett an einem Ort.",
            mood:     .idle,
            colors:   [Color(red: 0.62, green: 0.12, blue: 0.42), Color(red: 0.85, green: 0.24, blue: 0.30)],
            visual:   .features
        ),
        OnboardingSlide(
            title:    "Bereit?\nLos geht's!",
            subtitle: "Erstelle deinen Account und starte\nsofort mit dem Lernen.",
            mood:     .celebrating,
            colors:   [Color(red: 0.36, green: 0.16, blue: 0.88), Color(red: 0.58, green: 0.10, blue: 0.70)],
            visual:   .none
        ),
    ]
}

// MARK: - Individual Slide View

private struct OnboardingSlideView: View {
    let slide:      OnboardingSlide
    let isActive:   Bool
    let isLast:     Bool
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Mascot zone ──
            mascotSection
                .frame(height: 230)

            // ── Feature visual ──
            Group {
                switch slide.visual {
                case .cards:    cardsVisual
                case .bars:     barsVisual
                case .features: featuresVisual
                default:        Color.clear.frame(height: 0)
                }
            }
            .frame(height: slide.visual == .none ? 0 : 106)
            .padding(.top, slide.visual == .none ? 0 : 14)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.12), value: appeared)

            Spacer()

            // ── Text ──
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.16), value: appeared)

                Text(slide.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 10)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.24), value: appeared)
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 36)

            // ── CTA Button ──
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text(isLast ? "Jetzt starten" : "Weiter")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Image(systemName: isLast ? "sparkles" : "chevron.right")
                        .font(.system(size: isLast ? 17 : 14, weight: .semibold))
                }
                .foregroundStyle(slide.colors.first ?? .purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.22), radius: 22, x: 0, y: 10)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)
            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.32), value: appeared)

            Spacer().frame(height: 18)
        }
        .onAppear { triggerAppear() }
        .onChange(of: isActive) { _, active in if active { triggerAppear() } }
    }

    private func triggerAppear() {
        appeared = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.74)) { appeared = true }
        }
    }

    // MARK: Mascot

    private var mascotSection: some View {
        ZStack {
            // Glow rings
            ForEach(0..<3) { i in
                Circle()
                    .fill(.white.opacity(0.065 - Double(i) * 0.018))
                    .frame(width: 140 + CGFloat(i) * 46, height: 140 + CGFloat(i) * 46)
                    .scaleEffect(appeared ? 1 : 0.65)
                    .animation(.easeOut(duration: 0.65).delay(Double(i) * 0.08 + 0.05), value: appeared)
            }

            // White halo behind mascot
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 140, height: 140)
                .scaleEffect(appeared ? 1 : 0.72)
                .animation(.spring(response: 0.58, dampingFraction: 0.72).delay(0.04), value: appeared)

            MascotView(color: .white, mood: slide.mood, size: 104)
                .scaleEffect(appeared ? 1 : 0.72)
                .animation(.spring(response: 0.58, dampingFraction: 0.68).delay(0.04), value: appeared)
        }
    }

    // MARK: Cards Visual (Slide 2)

    private var cardsVisual: some View {
        ZStack {
            // Back card
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.14))
                .frame(width: 145, height: 80)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Frage:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("Hauptstadt von Frankreich?")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                }
                .rotationEffect(.degrees(-9))
                .offset(x: -55, y: 10)

            // Front card
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.26))
                .frame(width: 158, height: 88)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.yellow)
                            Text("KI-Karte")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.yellow)
                        }
                        Text("Paris")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                }
                .rotationEffect(.degrees(5))
                .offset(x: 38, y: -4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Bars Visual (Slide 3)

    private var barsVisual: some View {
        let intervals: [(String, Double)] = [
            ("1T", 0.28), ("3T", 0.48), ("7T", 0.66), ("14T", 0.82), ("30T", 1.0)
        ]
        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(intervals.enumerated()), id: \.offset) { i, item in
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.75))
                        .frame(width: 38, height: 82 * item.1)
                    Text(item.0)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Features Visual (Slide 4)

    private var featuresVisual: some View {
        HStack(spacing: 14) {
            featurePill(icon: "brain",          label: "KI-Sets")
            featurePill(icon: "calendar",       label: "Lernplan")
            featurePill(icon: "textformat.abc", label: "Vokabeln")
            featurePill(icon: "doc.text",       label: "Tests")
        }
        .frame(maxWidth: .infinity)
    }

    private func featurePill(icon: String, label: String) -> some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(.white.opacity(0.22)).frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
    }
}

// MARK: - Shimmer Overlay

private struct ShimmerOverlay: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.04), .clear],
                startPoint: UnitPoint(x: phase,     y: 0),
                endPoint:   UnitPoint(x: phase + 1, y: 1)
            )
            .onAppear {
                withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
        }
    }
}
