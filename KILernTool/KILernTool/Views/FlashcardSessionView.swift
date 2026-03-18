import SwiftUI

/// Karteikarten-Modus: Vorderseite anzeigen → umklappen → Richtig/Falsch wählen. Am Ende Auswertung.
struct FlashcardSessionView: View {
    let lernSet: LernSet
    /// Wenn gesetzt, nur diese Karten verwenden (z. B. „Falsche wiederholen”).
    var cardsToUse: [LernSetCard]?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LernSetStore
    @State private var sessionCards: [LernSetCard] = []
    @State private var currentIndex: Int = 0
    @State private var showBack: Bool = false
    @State private var correctIndices: Set<UUID> = []
    @State private var isFinished: Bool = false
    @State private var resultPercentage: Double = 0
    @State private var wrongCards: [LernSetCard] = []
    @State private var showMistakesReview: Bool = false
    @State private var cardOffsetX: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var questionCard: LernSetCard? = nil
    @State private var showStreakPopup: Bool = false
    @State private var sessionStreak: Int = 0
    @State private var showCorrectFlash: Bool = false
    @State private var showStreakBanner: Bool = false

    private var cards: [LernSetCard] {
        sessionCards.isEmpty ? (cardsToUse ?? lernSet.cards) : sessionCards
    }

    private var subjectColor: Color {
        Subject.all.first { $0.name == lernSet.subject }?.color
            ?? Color(red: 0.38, green: 0.18, blue: 0.90)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if cards.isEmpty {
                emptyState
            } else if isFinished {
                FlashcardResultsView(
                    percentage: resultPercentage,
                    correctCount: correctIndices.count,
                    totalCount: cards.count,
                    wrongCards: wrongCards,
                    onRestart: restart,
                    onBack: { popToRootOrDismiss() },
                    onRepeatWrong: repeatWrong,
                    onReviewMistakes: { showMistakesReview = true }
                )
            } else {
                sessionContent
            }

            // Correct answer flash
            if showCorrectFlash {
                CorrectAnswerFlash(isVisible: $showCorrectFlash)
                    .zIndex(8)
            }

            // 5-in-a-row streak banner
            if showStreakBanner {
                VStack {
                    StreakBanner(streak: sessionStreak, color: subjectColor, isVisible: $showStreakBanner)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showMistakesReview) {
            MistakesReviewView(cards: wrongCards, onDismiss: { showMistakesReview = false })
        }
        .sheet(item: $questionCard) { card in
            CardQuestionView(card: card)
        }
        .onAppear {
            if sessionCards.isEmpty {
                sessionCards = cardsToUse ?? lernSet.cards
            }
        }
        .onChange(of: isFinished) { _, finished in
            if finished {
                let incremented = StreakManager.shared.markActivity()
                if incremented { showStreakPopup = true }
                store.saveSessionResult(
                    lernSetId: lernSet.id,
                    score: resultPercentage / 100.0,
                    mode: "karteikarten"
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("Keine Karten")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text("Dieses Lernset enthält keine Karten.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionContent: some View {
        VStack(spacing: 0) {
            progressBar

            VStack(spacing: 24) {
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                cardView
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            showBack.toggle()
                        }
                    }

                if showBack {
                    answerButtons
                }

                if lernSet.isKIGenerated {
                    Button { questionCard = cards[currentIndex] } label: {
                        Label("Frage stellen", systemImage: "bubble.left.and.bubble.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(subjectColor)
                    .frame(width: max(0, geo.size.width * CGFloat(currentIndex) / CGFloat(max(1, cards.count))), height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var cardView: some View {
        let card = cards[currentIndex]
        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            // Vorder- und Rückseite werden separat gedreht, damit der Text nie auf dem Kopf steht.
            ZStack {
                // Vorderseite
                VStack(spacing: 12) {
                    Text(card.question)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    if let data = card.frontImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(showBack ? 0 : 1)
                .rotation3DEffect(
                    .degrees(showBack ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

                // Rückseite
                VStack(spacing: 12) {
                    Text(card.answer)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    if let data = card.backImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(showBack ? 1 : 0)
                .rotation3DEffect(
                    .degrees(showBack ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
        }
        .padding(.horizontal, 8)
        .offset(x: cardOffsetX)
        .opacity(cardOpacity)
    }

    private var answerButtons: some View {
        HStack(spacing: 16) {
            Button {
                answer(correct: false)
            } label: {
                Label("Falsch", systemImage: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
            }
            .buttonStyle(.plain)

            Button {
                answer(correct: true)
            } label: {
                Label("Richtig", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func answer(correct: Bool) {
        let card = cards[currentIndex]

        // SRS: Mastery-Level für diese Karte aktualisieren
        store.updateCardMastery(lernSetId: lernSet.id, cardId: card.id, correct: correct)

        // Karte seitlich wegfliegen lassen: richtig → rechts, falsch → links
        let direction: CGFloat = correct ? 1 : -1
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            cardOffsetX = direction * 600
            cardOpacity = 0
        }

        // Bewertungsdaten sofort aktualisieren
        if correct {
            correctIndices.insert(card.id)
            sessionStreak += 1
            showCorrectFlash = true
            if sessionStreak % 5 == 0 {
                showStreakBanner = true
            }
        } else {
            wrongCards.append(card)
            sessionStreak = 0
        }

        // Nach kurzer Zeit nächste Karte einblenden oder Auswertung zeigen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let isLast = currentIndex + 1 >= cards.count

            if isLast {
                resultPercentage = Double(correctIndices.count) / Double(cards.count) * 100
                withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                    isFinished = true
                }
            } else {
                currentIndex += 1
                showBack = false

                // Neue Karte von der Mitte wieder einblenden
                cardOffsetX = -direction * 80
                cardOpacity = 0
                withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                    cardOffsetX = 0
                    cardOpacity = 1
                }
            }
        }
    }

    private func restart() {
        currentIndex = 0
        showBack = false
        correctIndices = []
        wrongCards = []
        isFinished = false
        sessionStreak = 0
        withAnimation(.easeOut(duration: 0.25)) { }
    }

    private func repeatWrong() {
        guard !wrongCards.isEmpty else { return }
        let toRepeat = wrongCards
        sessionCards = toRepeat
        currentIndex = 0
        showBack = false
        correctIndices = []
        wrongCards = []
        isFinished = false
    }

    private func popToRootOrDismiss() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                dismiss()
            }
        }
    }
}

// MARK: - Results View (Apple-Style mit Animation)

private struct FlashcardResultsView: View {
    let percentage: Double
    let correctCount: Int
    let totalCount: Int
    let wrongCards: [LernSetCard]
    let onRestart: () -> Void
    let onBack: () -> Void
    let onRepeatWrong: () -> Void
    let onReviewMistakes: () -> Void

    @State private var appeared = false
    @State private var circleTrim: CGFloat = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MascotResultHeader(percentage: percentage)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                Text("\(correctCount) von \(totalCount) richtig")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    resultButton(title: "Nochmal starten", icon: "arrow.clockwise") { onRestart() }
                    resultButton(title: "Zur Startseite", icon: "house.fill") { onBack() }
                    if !wrongCards.isEmpty {
                        resultButton(title: "Falsche wiederholen", icon: "arrow.uturn.backward") { onRepeatWrong() }
                        resultButton(title: "Fehler einblicken", icon: "list.bullet.rectangle") { onReviewMistakes() }
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.top, 40)
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
                circleTrim = 1.0
                labelOpacity = 1.0
            }
        }
    }

    private var percentageRing: some View {
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
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .opacity(labelOpacity)
        }
        .padding(.vertical, 20)
    }

    private func resultButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 24, alignment: .center)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fehler einblicken

private struct MistakesReviewView: View {
    let cards: [LernSetCard]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Frage \(index + 1)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Text(card.question)
                                    .font(.system(size: 15, weight: .medium))
                                Text("Antwort")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Text(card.answer)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
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
            .navigationTitle("Fehler einblicken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { onDismiss() }
                }
            }
        }
    }
}

// (Ehemalige CorrectCelebrationView entfernt, da „Richtig“-Animation nicht mehr gewünscht ist.)

