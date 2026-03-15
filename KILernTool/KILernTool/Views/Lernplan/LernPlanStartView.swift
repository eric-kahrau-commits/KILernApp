import SwiftUI

struct LernPlanStartView: View {
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var selectedPlan: LernPlan? = nil
    @State private var showIntro = true

    private let gradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        createHeroButton
                        plansSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showCreator) {
            CreateLernPlanView { newPlan in
                showCreator = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedPlan = newPlan
                }
            }
            .environmentObject(lernPlanStore)
            .environmentObject(lernSetStore)
        }
        .fullScreenCover(item: $selectedPlan) { plan in
            LernPlanDetailView(planId: plan.id)
                .environmentObject(lernPlanStore)
                .environmentObject(lernSetStore)
        }

        if showIntro {
            SaschaIntroOverlay {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showIntro = false }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(20)
        }
        } // outer ZStack
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showIntro)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("KI-Lernplan")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Hero Button

    private var createHeroButton: some View {
        Button { showCreator = true } label: {
            HStack(spacing: 16) {
                MascotView(color: .white, mood: .happy, size: 48)
                    .frame(width: 48, height: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text("KI-Lernplan erstellen")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Fotos scannen → KI erstellt deinen Tagesplan")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.80))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: Color(red: 0.10, green: 0.48, blue: 0.92).opacity(0.42),
                            radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plans Section

    @ViewBuilder
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Lernpläne")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if lernPlanStore.plans.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "Noch kein Lernplan",
                    subtitle: "Erstelle deinen ersten KI-Lernplan und starte strukturiert."
                )
                .frame(height: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(lernPlanStore.plans) { plan in
                        planRow(plan)
                    }
                }
            }
        }
    }

    private func planRow(_ plan: LernPlan) -> some View {
        Button { selectedPlan = plan } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                     Color(red: 0.10, green: 0.48, blue: 0.92),
                                     Color(red: 0.10, green: 0.64, blue: 0.54)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 42, height: 42)
                    MascotView(color: .white, mood: .idle, size: 28)
                        .frame(width: 28, height: 32)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.titel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(plan.fach)
                        Text("·")
                        Text(daysLabel(plan))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                // Progress ring mini
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: plan.overallProgress)
                        .stroke(Color(red: 0.10, green: 0.48, blue: 0.92), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func daysLabel(_ plan: LernPlan) -> String {
        let d = plan.daysUntilTest
        if d < 0 { return "Test vorbei" }
        if d == 0 { return "Test heute!" }
        return "Noch \(d) Tag\(d == 1 ? "" : "e")"
    }
}

// MARK: - Sascha Intro Overlay

private struct SaschaIntroOverlay: View {
    let onDismiss: () -> Void

    private let fullText = "Hey! Ich bin **Sascha**, dein bunter KI-Lernplan-Assistent! 🌈\n\nIch erstelle dir einen persönlichen Tagesplan bis zu deinem Test – strukturiert, motivierend und genau auf dich zugeschnitten.\n\nFotografiere einfach dein Schulbuch oder nenn mir dein Thema – ich plane den Rest! ✨"

    private let rainbowColors: [Color] = [
        Color(red: 0.38, green: 0.18, blue: 0.90),
        Color(red: 0.10, green: 0.48, blue: 0.92),
        Color(red: 0.10, green: 0.64, blue: 0.54),
        Color(red: 0.86, green: 0.50, blue: 0.10),
        Color(red: 0.90, green: 0.28, blue: 0.50),
        Color(red: 0.55, green: 0.20, blue: 0.85),
    ]

    @State private var colorIndex: Int = 0
    @State private var displayedText: String = ""
    @State private var mascotMood: MascotMood = .talking
    @State private var isDone: Bool = false
    @State private var mascotScale: CGFloat = 0.6
    @State private var cardOffset: CGFloat = 80
    @State private var ringRotation: Double = 0

    private var currentColor: Color { rainbowColors[colorIndex] }

    var body: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    // Animated rainbow ring + mascot
                    ZStack {
                        // Outer rotating rainbow ring
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: rainbowColors + [rainbowColors[0]],
                                    center: .center
                                ),
                                lineWidth: 5
                            )
                            .frame(width: 148, height: 148)
                            .rotationEffect(.degrees(ringRotation))

                        // Inner colored circle
                        Circle()
                            .fill(currentColor.opacity(0.14))
                            .frame(width: 132, height: 132)

                        MascotView(color: currentColor, mood: mascotMood, size: 96)
                            .frame(width: 96, height: 110)
                    }
                    .scaleEffect(mascotScale)

                    // Name badge
                    HStack(spacing: 6) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(currentColor)
                        Text("SASCHA · KI-Lernplan-Assistent")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(currentColor)
                            .tracking(0.6)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(currentColor.opacity(0.10)))
                    .animation(.easeInOut(duration: 0.6), value: colorIndex)

                    // Typewriter text
                    Group {
                        if isDone {
                            Text(try! AttributedString(markdown: fullText,
                                 options: AttributedString.MarkdownParsingOptions(
                                     interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        } else {
                            Text(displayedText)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                    // Los geht's button
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Lernplan erstellen!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDone
                                      ? LinearGradient(
                                            colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                                     Color(red: 0.10, green: 0.48, blue: 0.92),
                                                     Color(red: 0.10, green: 0.64, blue: 0.54)],
                                            startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                                       startPoint: .leading, endPoint: .trailing))
                                .shadow(color: isDone ? currentColor.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isDone)
                    .animation(.easeInOut(duration: 0.6), value: isDone)
                }
                .padding(26)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.20), radius: 32, x: 0, y: -6)
                )
                .offset(y: cardOffset)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.68)) {
                mascotScale = 1.0
                cardOffset = 0
            }
            startRingRotation()
            startColorCycling()
            startTypewriter()
        }
    }

    private func startRingRotation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }

    private func startColorCycling() {
        Task {
            var idx = 0
            while !isDone {
                try? await Task.sleep(nanoseconds: 700_000_000)
                idx = (idx + 1) % rainbowColors.count
                withAnimation(.easeInOut(duration: 0.6)) { colorIndex = idx }
            }
        }
    }

    private func startTypewriter() {
        Task {
            var idx = fullText.startIndex
            while idx < fullText.endIndex {
                let remaining = fullText.distance(from: idx, to: fullText.endIndex)
                let step = min(3, remaining)
                let nextIdx = fullText.index(idx, offsetBy: step)
                displayedText = String(fullText[fullText.startIndex..<nextIdx])
                idx = nextIdx
                try? await Task.sleep(nanoseconds: 11_000_000)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                mascotMood = .celebrating
                isDone = true
            }
        }
    }
}
