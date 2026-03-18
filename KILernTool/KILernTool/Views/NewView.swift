import SwiftUI

struct NewView: View {
    @EnvironmentObject var store: LernSetStore
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @State private var showKILernset = false
    @State private var showLernPlan = false
    @State private var showTestErstellen = false
    @State private var showScannen = false
    @State private var showVokabel = false
    @State private var selectedOption: CreateOption? = nil
    @State private var showCardSetStart = false
    @State private var cardsAppeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero Banner
                TheoCreateHeroBanner()
                    .padding(.top, 4)

                VStack(spacing: 14) {
                    ForEach(Array(CreateOption.all.enumerated()), id: \.element.id) { index, option in
                        CreateOptionCard(option: option, index: index, reportTutorialFrame: index == 0) {
                            switch option.title {
                            case "KI Lernset":
                                // Complete tutorial when user taps KI-Lernset (step 3)
                                if TutorialManager.shared.isActive &&
                                   TutorialManager.shared.step == .kiLernsetCard {
                                    TutorialManager.shared.complete()
                                }
                                showKILernset = true
                            case "Lern Plan":
                                showLernPlan = true
                            case "Test erstellen":
                                showTestErstellen = true
                            case "Scannen":
                                showScannen = true
                            case "Vokabelset":
                                showVokabel = true
                            case "Karteikartenset":
                                showCardSetStart = true
                            default:
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    selectedOption = option
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .fullScreenCover(isPresented: $showKILernset) {
            KILernsetStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showLernPlan) {
            LernPlanStartView()
                .environmentObject(lernPlanStore)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showTestErstellen) {
            TestErstellenStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showCardSetStart) {
            CardSetStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showScannen) {
            ScanStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showVokabel) {
            VokabelStartView()
                .environmentObject(store)
        }
        .sheet(item: $selectedOption) { option in
            CreateDetailView(option: option)
        }
    }
}

// MARK: - Theo Create Hero Banner

private struct TheoCreateHeroBanner: View {
    private let accent = AppColors.brandPurple
    private let greetings = [
        "Hey! Was erstellen wir heute? ✨",
        "Bereit zum Lernen? Los geht's! 🚀",
        "Ich helfe dir – was brauchst du? 📚",
        "Ein neues Lernset? Gerne! 🎯",
    ]
    @State private var displayedText = ""
    @State private var appeared = false

    private var greeting: String { greetings[Calendar.current.component(.hour, from: Date()) % greetings.count] }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Waving Theo — fixed frame prevents layout shifts
            Group {
                WavingMascotView(color: accent, size: 64)
            }
            .frame(width: 78, height: 72, alignment: .center)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text("Was möchtest du \(Text("erstellen?").foregroundStyle(LinearGradient(colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)], startPoint: .leading, endPoint: .trailing)))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Typed greeting from Theo
                Text(displayedText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(minHeight: 18, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: accent.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) { appeared = true }
            try? await Task.sleep(nanoseconds: 400_000_000)
            await typeGreeting()
        }
    }

    private func typeGreeting() async {
        let words = greeting.components(separatedBy: " ")
        for (i, word) in words.enumerated() {
            guard !Task.isCancelled else { return }
            displayedText += (i == 0 ? "" : " ") + word
            try? await Task.sleep(nanoseconds: 70_000_000)
        }
    }
}

// MARK: - Create Option Card

struct CreateOptionCard: View {
    let option: CreateOption
    let index: Int
    var reportTutorialFrame: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                // Animated mascot icon — mood cycles by index for variety
                MascotIconView(
                    color: option.mascotColor,
                    size: 56,
                    cornerRadius: 14,
                    mood: [.idle, .happy, .talking, .thinking, .celebrating, .idle][index % 6]
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(option.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))     { isPressed = false } }
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .background(
            Group {
                if reportTutorialFrame {
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            TutorialManager.shared.reportFrame(
                                geo.frame(in: .global), for: .kiLernsetCard
                            )
                        }
                    }
                }
            }
        )
        .onAppear {
            withAnimation(
                .spring(response: 0.55, dampingFraction: 0.78)
                    .delay(Double(index) * 0.07 + 0.15)
            ) {
                appeared = true
            }
        }
    }
}
