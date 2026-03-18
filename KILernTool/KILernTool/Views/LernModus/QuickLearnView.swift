import SwiftUI

struct QuickLearnView: View {
    let lernSet: LernSet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LernSetStore

    @State private var shuffledCards: [LernSetCard] = []
    @State private var currentIndex: Int = 0
    @State private var choices: [String] = []
    @State private var selectedAnswer: String? = nil
    @State private var correctCount: Int = 0
    @State private var isFinished: Bool = false

    // Retry round tracking
    @State private var round1Wrong: [LernSetCard] = []
    @State private var round1Correct: Int = 0
    @State private var retryCorrect: Int = 0
    @State private var isInRetryRound: Bool = false
    @State private var showStreakPopup: Bool = false

    // In-session streak (correct in a row)
    @State private var sessionStreak: Int = 0
    @State private var showCorrectFlash: Bool = false
    @State private var showStreakBanner: Bool = false

    private var currentCard: LernSetCard? {
        guard currentIndex < shuffledCards.count else { return nil }
        return shuffledCards[currentIndex]
    }

    private let accent = AppColors.brandQuick

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if isFinished {
                QuickLearnResultsView(
                    round1Correct: round1Correct,
                    round1Total: lernSet.cards.count,
                    retryCorrect: retryCorrect,
                    retryTotal: round1Wrong.count,
                    hadRetry: !round1Wrong.isEmpty,
                    wrongCards: round1Wrong,
                    isAISet: lernSet.isKIGenerated || lernSet.isScanResult,
                    subject: lernSet.subject,
                    onRestart: restart,
                    onBack: { dismiss() }
                )
            } else if let card = currentCard {
                VStack(spacing: 0) {
                    progressBar
                    questionContent(card: card)
                }
            }

            // Correct answer flash
            if showCorrectFlash {
                CorrectAnswerFlash(isVisible: $showCorrectFlash)
                    .zIndex(8)
            }

            // 5-in-a-row streak banner
            if showStreakBanner {
                VStack {
                    StreakBanner(streak: sessionStreak, color: accent, isVisible: $showStreakBanner)
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(9)
            }

            if showStreakPopup {
                StreakPopupView(streak: StreakManager.shared.currentStreak) {
                    showStreakPopup = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationTitle(isInRetryRound ? "Wiederholung" : "Schnell lernen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setup() }
        .onChange(of: isFinished) { _, finished in
            if finished {
                let incremented = StreakManager.shared.markActivity()
                if incremented { showStreakPopup = true }
                store.saveSessionResult(
                    lernSetId: lernSet.id,
                    score: Double(round1Correct) / Double(max(1, lernSet.cards.count)),
                    mode: "schnell"
                )
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isInRetryRound ? Color.orange : accent)
                    .frame(
                        width: max(0, geo.size.width * CGFloat(currentIndex) / CGFloat(max(1, shuffledCards.count))),
                        height: 6
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    // MARK: - Question Content

    @ViewBuilder
    private func questionContent(card: LernSetCard) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Retry round banner
                if isInRetryRound {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Wiederholung – \(shuffledCards.count) \(shuffledCards.count == 1 ? "Frage" : "Fragen")")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
                    .padding(.top, 8)
                }

                Text("\(currentIndex + 1) / \(shuffledCards.count)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, isInRetryRound ? 0 : 8)

                // Question card
                VStack(spacing: 12) {
                    Text(card.question)
                        .font(.system(.title3).weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    if let data = card.frontImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 8)

                // Answer choices
                VStack(spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        choiceButton(choice: choice, correctAnswer: card.answer)
                    }
                }
                .padding(.horizontal, 8)

                // Weiter button
                if selectedAnswer != nil {
                    Button(action: advance) {
                        Text(currentIndex + 1 < shuffledCards.count ? "Weiter" : "Auswertung")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isInRetryRound ? Color.orange : accent)
                            )
                    }
                    .accessibilityLabel("Weiter")
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 40)
            .padding(.top, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedAnswer)
        }
    }

    // MARK: - Choice Button

    private func choiceButton(choice: String, correctAnswer: String) -> some View {
        let isSelected = selectedAnswer == choice
        let isCorrectChoice = choice == correctAnswer
        let hasAnswered = selectedAnswer != nil

        let bgColor: Color
        if hasAnswered {
            if isCorrectChoice { bgColor = Color.green.opacity(0.15) }
            else if isSelected { bgColor = Color.red.opacity(0.12) }
            else { bgColor = Color(uiColor: .secondarySystemGroupedBackground) }
        } else {
            bgColor = Color(uiColor: .secondarySystemGroupedBackground)
        }

        let borderColor: Color
        if hasAnswered {
            if isCorrectChoice { borderColor = Color.green.opacity(0.7) }
            else if isSelected { borderColor = Color.red.opacity(0.5) }
            else { borderColor = Color.clear }
        } else {
            borderColor = Color.clear
        }

        return Button {
            guard selectedAnswer == nil else { return }
            let isCorrect = choice == correctAnswer
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedAnswer = choice
                if isCorrect {
                    correctCount += 1
                    sessionStreak += 1
                    showCorrectFlash = true
                    if sessionStreak % 5 == 0 {
                        showStreakBanner = true
                    }
                } else {
                    sessionStreak = 0
                }
            }
        } label: {
            HStack(spacing: 12) {
                if hasAnswered && isCorrectChoice {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.system(size: 18, weight: .semibold))
                } else if hasAnswered && isSelected && !isCorrectChoice {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red).font(.system(size: 18, weight: .semibold))
                } else {
                    Circle().stroke(Color(uiColor: .tertiaryLabel), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
                Text(choice)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(bgColor)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func setup() {
        shuffledCards = lernSet.cards.shuffled()
        loadChoices()
    }

    private func loadChoices() {
        guard currentIndex < shuffledCards.count else { return }
        choices = shuffledCards[currentIndex].shuffledAnswers(fallbackFrom: lernSet.cards)
    }

    private func advance() {
        // Track wrong cards for retry (round 1 only)
        if !isInRetryRound, let card = currentCard, selectedAnswer != card.answer {
            round1Wrong.append(card)
        }

        if currentIndex + 1 < shuffledCards.count {
            currentIndex += 1
            selectedAnswer = nil
            loadChoices()
        } else {
            if isInRetryRound {
                retryCorrect = correctCount
                isFinished = true
            } else {
                round1Correct = correctCount
                if round1Wrong.isEmpty {
                    isFinished = true
                } else {
                    // Start retry round
                    isInRetryRound = true
                    shuffledCards = round1Wrong.shuffled()
                    currentIndex = 0
                    selectedAnswer = nil
                    correctCount = 0
                    loadChoices()
                }
            }
        }
    }

    private func restart() {
        shuffledCards = lernSet.cards.shuffled()
        currentIndex = 0
        selectedAnswer = nil
        correctCount = 0
        isFinished = false
        round1Wrong = []
        round1Correct = 0
        retryCorrect = 0
        isInRetryRound = false
        sessionStreak = 0
        loadChoices()
    }
}

// MARK: - Results View

private struct QuickLearnResultsView: View {
    let round1Correct: Int
    let round1Total: Int
    let retryCorrect: Int
    let retryTotal: Int
    let hadRetry: Bool
    let wrongCards: [LernSetCard]
    let isAISet: Bool
    let subject: String
    let onRestart: () -> Void
    let onBack: () -> Void

    @State private var circleTrim: CGFloat = 0
    @State private var labelOpacity: Double = 0
    @State private var showExplainer: Bool = false

    private var percentage: Double {
        round1Total == 0 ? 0 : Double(round1Correct) / Double(round1Total) * 100
    }

    private let accent = AppColors.brandQuick

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Mascot result header (score-dependent animation)
                MascotResultHeader(percentage: percentage, color: accent)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                // Stats breakdown — round details
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 14)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: circleTrim * CGFloat(percentage / 100))
                        .stroke(
                            percentage >= 80 ? Color.green : (percentage >= 50 ? Color.orange : Color.red),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(round(percentage))) %")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .opacity(labelOpacity)
                }
                .padding(.vertical, 12)

                // Stats breakdown
                VStack(spacing: 10) {
                    roundStatRow(
                        label: "1. Durchlauf",
                        correct: round1Correct,
                        total: round1Total,
                        color: accent
                    )
                    if hadRetry {
                        roundStatRow(
                            label: "Wiederholung",
                            correct: retryCorrect,
                            total: retryTotal,
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 18)

                // Buttons
                VStack(spacing: 12) {
                    if isAISet && !wrongCards.isEmpty {
                        Button {
                            showExplainer = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 24, alignment: .center)
                                Text("Fehler erklären lassen")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(Color.purple)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.purple.opacity(0.10))
                            )
                        }
                        .accessibilityLabel("Fehler erklären")
                        .buttonStyle(.plain)
                    }
                    resultButton(title: "Nochmal", icon: "arrow.clockwise", action: onRestart)
                        .accessibilityLabel("Neu starten")
                    resultButton(title: "Zurück", icon: "chevron.left", action: onBack)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showExplainer) {
            ErrorExplainerView(
                wrongCards: wrongCards,
                subject: subject,
                onDismiss: { showExplainer = false }
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                circleTrim = 1.0
                labelOpacity = 1.0
            }
        }
    }

    private func roundStatRow(label: String, correct: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color.opacity(0.18)).frame(width: 8, height: 8)
            Text(label)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 4) {
                Text("\(correct)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.green)
                Text("richtig")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(total - correct)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(total - correct > 0 ? .red : .secondary)
                Text("falsch")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private func resultButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                    .frame(width: 24, alignment: .center)
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}
