import SwiftUI

// MARK: - Grade Helper

func schulnote(from percentage: Double) -> Int {
    switch percentage {
    case 90...100: return 1
    case 80..<90:  return 2
    case 67..<80:  return 3
    case 50..<67:  return 4
    case 30..<50:  return 5
    default:       return 6
    }
}

// MARK: - Data Types

struct TestEvalEntry: Identifiable {
    let id = UUID()
    let card: LernSetCard
    let userAnswer: String
    let correct: Bool
    let correction: String?
}

// MARK: - Main View

struct TestModusView: View {
    let lernSet: LernSet
    @Environment(\.dismiss) private var dismiss

    @State private var shuffledCards: [LernSetCard] = []
    @State private var currentIndex: Int = 0
    @State private var inputText: String = ""
    @State private var collectedAnswers: [(card: LernSetCard, userAnswer: String)] = []

    enum Phase { case test, evaluating, results }
    @State private var phase: Phase = .test
    @State private var evalProgress: Int = 0
    @State private var evalResults: [TestEvalEntry] = []
    @State private var showMistakes: Bool = false

    @FocusState private var isFocused: Bool
    @State private var showStreakPopup: Bool = false

    private let accent = Color(red: 0.25, green: 0.25, blue: 0.80)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            switch phase {
            case .test:
                if currentIndex < shuffledCards.count {
                    VStack(spacing: 0) {
                        testProgressBar
                        testQuestionContent
                    }
                }
            case .evaluating:
                evaluatingView
            case .results:
                testResultsView
            }

            if showStreakPopup {
                StreakPopupView(streak: StreakManager.shared.currentStreak) {
                    showStreakPopup = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationTitle(phase == .test ? "Testmodus" : (phase == .evaluating ? "Wird ausgewertet …" : "Ergebnis"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { shuffledCards = lernSet.cards.shuffled() }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .results {
                let incremented = StreakManager.shared.markActivity()
                if incremented { showStreakPopup = true }
            }
        }
        .fullScreenCover(isPresented: $showMistakes) {
            TestMistakesView(
                results: evalResults.filter { !$0.correct },
                onDismiss: { showMistakes = false }
            )
        }
    }

    // MARK: - Progress Bar

    private var testProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(accent)
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

    // MARK: - Test Question

    private var testQuestionContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("\(currentIndex + 1) / \(shuffledCards.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                // Question card
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent.opacity(0.7))
                        Text("Frage")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(shuffledCards[currentIndex].question)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 8)

                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Deine Antwort")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("Antwort eingeben …", text: $inputText, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(3...6)
                        .focused($isFocused)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isFocused ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                        )
                }
                .padding(.horizontal, 8)

                // No feedback hint
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 11))
                    Text("Kein Feedback während des Tests")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

                // Weiter / Abschicken button
                Button(action: submitAnswer) {
                    Text(currentIndex + 1 < shuffledCards.count ? "Weiter" : "Test abschicken")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? Color(uiColor: .tertiaryLabel)
                                      : accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 40)
            .padding(.top, 16)
        }
    }

    // MARK: - Evaluating View

    private var evaluatingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(accent)
            VStack(spacing: 8) {
                Text("KI wertet aus …")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("\(evalProgress) / \(shuffledCards.count) Antworten bewertet")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results View

    private var testResultsView: some View {
        let correctCount = evalResults.filter { $0.correct }.count
        let totalCount = evalResults.count
        let pct = totalCount == 0 ? 0.0 : Double(correctCount) / Double(totalCount) * 100
        let note = schulnote(from: pct)
        let wrongCount = totalCount - correctCount

        return TestResultsContent(
            correctCount: correctCount,
            totalCount: totalCount,
            percentage: pct,
            note: note,
            hasWrong: wrongCount > 0,
            wrongCards: evalResults.filter { !$0.correct }.map { $0.card },
            isAISet: lernSet.isKIGenerated || lernSet.isScanResult,
            subject: lernSet.subject,
            onShowMistakes: { showMistakes = true },
            onRestart: restart,
            onBack: { dismiss() }
        )
    }

    // MARK: - Logic

    private func submitAnswer() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = trimmed.isEmpty ? "–" : trimmed
        collectedAnswers.append((card: shuffledCards[currentIndex], userAnswer: answer))
        inputText = ""
        isFocused = false

        if currentIndex + 1 < shuffledCards.count {
            currentIndex += 1
        } else {
            startEvaluation()
        }
    }

    private func startEvaluation() {
        phase = .evaluating
        Task {
            var results: [TestEvalEntry] = []
            for entry in collectedAnswers {
                do {
                    let (correct, correction) = try await AIService.shared.evaluateAnswer(
                        question: entry.card.question,
                        correctAnswer: entry.card.answer,
                        userAnswer: entry.userAnswer
                    )
                    results.append(TestEvalEntry(
                        card: entry.card,
                        userAnswer: entry.userAnswer,
                        correct: correct,
                        correction: correction
                    ))
                } catch {
                    results.append(TestEvalEntry(
                        card: entry.card,
                        userAnswer: entry.userAnswer,
                        correct: false,
                        correction: "Fehler bei der Auswertung. Korrekte Antwort: \(entry.card.answer)"
                    ))
                }
                evalProgress = results.count
            }
            evalResults = results
            withAnimation { phase = .results }
        }
    }

    private func restart() {
        shuffledCards = lernSet.cards.shuffled()
        currentIndex = 0
        inputText = ""
        collectedAnswers = []
        evalProgress = 0
        evalResults = []
        phase = .test
    }
}

// MARK: - Results Content

private struct TestResultsContent: View {
    let correctCount: Int
    let totalCount: Int
    let percentage: Double
    let note: Int
    let hasWrong: Bool
    let wrongCards: [LernSetCard]
    let isAISet: Bool
    let subject: String
    let onShowMistakes: () -> Void
    let onRestart: () -> Void
    let onBack: () -> Void

    @State private var circleTrim: CGFloat = 0
    @State private var noteOpacity: Double = 0
    @State private var showExplainer: Bool = false

    private let accent = Color(red: 0.25, green: 0.25, blue: 0.80)

    private var noteColor: Color {
        switch note {
        case 1, 2: return .green
        case 3:    return .orange
        default:   return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("Testergebnis")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 40)

                // Note display
                VStack(spacing: 4) {
                    Text("Note")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(note)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(noteColor)
                        .opacity(noteOpacity)
                }
                .padding(.vertical, 8)

                // Percentage ring
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 12)
                        .frame(width: 130, height: 130)
                    Circle()
                        .trim(from: 0, to: circleTrim * CGFloat(percentage / 100))
                        .stroke(
                            percentage >= 80 ? Color.green : (percentage >= 50 ? Color.orange : Color.red),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(round(percentage))) %")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

                // Stats row
                HStack(spacing: 0) {
                    statCell(value: "\(correctCount)", label: "Richtig", color: .green)
                    Divider().frame(height: 40)
                    statCell(value: "\(totalCount - correctCount)", label: "Falsch", color: .red)
                    Divider().frame(height: 40)
                    statCell(value: "\(totalCount)", label: "Gesamt", color: .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 18)

                // Buttons
                VStack(spacing: 12) {
                    if hasWrong {
                        actionButton(title: "Fehler ansehen", icon: "list.bullet.rectangle", color: accent, action: onShowMistakes)
                    }
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
                        .buttonStyle(.plain)
                    }
                    actionButton(title: "Nochmal", icon: "arrow.clockwise", color: .primary, action: onRestart)
                    actionButton(title: "Zurück", icon: "chevron.left", color: .primary, action: onBack)
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
                noteOpacity = 1.0
            }
        }
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                    .frame(width: 24, alignment: .center)
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(color == .primary ? Color.primary : color)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color == accent
                          ? accent.opacity(0.12)
                          : Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mistakes Review

private struct TestMistakesView: View {
    let results: [TestEvalEntry]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, entry in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Frage \(idx + 1)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Text(entry.card.question)
                                    .font(.system(size: 15, weight: .semibold))

                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Deine Antwort", systemImage: "person.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.red.opacity(0.8))
                                    Text(entry.userAnswer)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)
                                }

                                if let correction = entry.correction {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("Richtige Antwort", systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.green.opacity(0.8))
                                        Text(correction)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("Richtige Antwort", systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.green.opacity(0.8))
                                        Text(entry.card.answer)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Fehler ansehen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { onDismiss() }
                }
            }
        }
    }
}
