import SwiftUI
import Charts

struct LernsetViewerView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore

    private var currentSet: LernSet {
        store.lernSets.first { $0.id == lernSet.id } ?? lernSet
    }

    private var subjectColor: Color {
        Subject.all.first { $0.name == lernSet.subject }?.color
            ?? Color(red: 0.38, green: 0.18, blue: 0.90)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title + Mastery
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentSet.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        HStack(spacing: 10) {
                            // Mastery progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(uiColor: .systemFill))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(masteryColor)
                                        .frame(width: geo.size.width * CGFloat(currentSet.masteryPercent) / 100, height: 6)
                                }
                            }
                            .frame(height: 6)

                            Text("\(currentSet.masteryPercent)%")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(masteryColor)
                                .frame(width: 36, alignment: .trailing)
                        }

                        HStack(spacing: 16) {
                            Label("\(currentSet.cards.count) Karten", systemImage: "rectangle.on.rectangle")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            if !currentSet.cardsDueToday.isEmpty {
                                Label("\(currentSet.cardsDueToday.count) fällig", systemImage: "clock.badge.exclamationmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }

                            if !currentSet.weakCards.isEmpty {
                                Label("\(currentSet.weakCards.count) schwach", systemImage: "exclamationmark.triangle")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    // Progress chart (if sessions exist)
                    if currentSet.recentSessions.count >= 2 {
                        progressChartSection
                            .padding(.horizontal, 18)
                    }

                    // Mode buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MODI")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            // Fällige Karten (SRS) — shown if cards are due
                            if !currentSet.cardsDueToday.isEmpty {
                                NavigationLink {
                                    DueCardsView(lernSet: currentSet)
                                        .environmentObject(store)
                                } label: {
                                    modeRow(
                                        icon: "clock.badge.exclamationmark.fill",
                                        color: .orange,
                                        title: "Fällige Karten",
                                        subtitle: "\(currentSet.cardsDueToday.count) Karten heute wiederholen",
                                        badge: "\(currentSet.cardsDueToday.count)"
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            if currentSet.isKIGenerated {
                                NavigationLink {
                                    LearnModeSelectionView(lernSet: currentSet)
                                } label: {
                                    modeRow(
                                        icon: "brain.head.profile",
                                        color: Color(red: 0.15, green: 0.60, blue: 0.40),
                                        title: "Lernen-Modus",
                                        subtitle: "Lerne mit Multiple-Choice und Freitexteingaben"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    BlitzReviewView(lernSet: currentSet)
                                        .environmentObject(store)
                                } label: {
                                    modeRow(
                                        icon: "bolt.fill",
                                        color: Color(red: 0.38, green: 0.18, blue: 0.90),
                                        title: "Blitz-Review",
                                        subtitle: "Karten blitzschnell selbst einschätzen"
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            NavigationLink {
                                FlashcardSessionView(lernSet: currentSet)
                            } label: {
                                modeRow(
                                    icon: "rectangle.on.rectangle.angled",
                                    color: subjectColor,
                                    title: "Karteikarten-Modus",
                                    subtitle: "Vorderseite ansehen, umklappen, richtig oder falsch wählen"
                                )
                            }
                            .buttonStyle(.plain)

                            if currentSet.isKIGenerated {
                                NavigationLink {
                                    TestModusView(lernSet: currentSet)
                                } label: {
                                    modeRow(
                                        icon: "pencil.and.list.clipboard",
                                        color: Color(red: 0.25, green: 0.25, blue: 0.80),
                                        title: "Testmodus",
                                        subtitle: "Alle Fragen eingeben – Schulnote am Ende"
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // Schwachstellen üben — shown if weak cards exist
                            if !currentSet.weakCards.isEmpty {
                                NavigationLink {
                                    WeakCardsView(lernSet: currentSet)
                                        .environmentObject(store)
                                } label: {
                                    modeRow(
                                        icon: "exclamationmark.triangle.fill",
                                        color: Color(red: 0.85, green: 0.25, blue: 0.20),
                                        title: "Schwachstellen üben",
                                        subtitle: "Nur die Karten, die du oft falsch beantwortest",
                                        badge: "\(currentSet.weakCards.count)"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var masteryColor: Color {
        let p = currentSet.masteryPercent
        if p >= 80 { return .green }
        if p >= 50 { return .orange }
        return Color(red: 0.38, green: 0.18, blue: 0.90)
    }

    // MARK: - Progress Chart

    @ViewBuilder
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FORTSCHRITT (LETZTE SESSIONS)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Chart {
                ForEach(Array(currentSet.recentSessions.enumerated()), id: \.element.id) { idx, session in
                    LineMark(
                        x: .value("Session", idx),
                        y: .value("Score", session.score * 100)
                    )
                    .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Session", idx),
                        y: .value("Score", session.score * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.25), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Session", idx),
                        y: .value("Score", session.score * 100)
                    )
                    .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90))
                    .symbolSize(40)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text("\(v)%").font(.system(size: 10)) }
                    }
                }
            }
            .frame(height: 100)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }

    private func modeRow(icon: String, color: Color, title: String, subtitle: String, badge: String? = nil) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(color))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Blitz-Review (P6 — replaces old AnschauModus)

struct BlitzReviewView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var knownCount: Int = 0
    @State private var unknownCount: Int = 0
    @State private var isShowingAnswer = false
    @State private var offset: CGFloat = 0
    @State private var isDone = false

    private var cards: [LernSetCard] { lernSet.cards }
    private var progress: Double { cards.isEmpty ? 0 : Double(currentIndex) / Double(cards.count) }
    private let accent = AppColors.brandPurple

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if isDone {
                doneView
            } else if cards.isEmpty {
                emptyView
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(uiColor: .systemFill)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(currentIndex + 1) / \(cards.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        Spacer()

                        // placeholder for alignment
                        Circle().fill(.clear).frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(uiColor: .systemFill))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accent)
                                .frame(width: geo.size.width * progress, height: 5)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    Spacer()

                    // Card
                    ZStack {
                        cardView(card: cards[currentIndex])
                            .offset(x: offset)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Action buttons
                    if isShowingAnswer {
                        HStack(spacing: 16) {
                            // Nicht gewusst
                            Button {
                                rate(known: false)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Nicht gewusst")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                            }
                            .buttonStyle(.plain)

                            // Gewusst
                            Button {
                                rate(known: true)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Gewusst")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) { isShowingAnswer = true }
                        } label: {
                            Text("Antwort zeigen")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .navigationTitle("Blitz-Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func cardView(card: LernSetCard) -> some View {
        VStack(spacing: 0) {
            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("FRAGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent.opacity(0.6))
                Text(card.question)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity)

            if isShowingAnswer {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("ANTWORT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.green.opacity(0.7))
                    Text(card.answer)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
        .animation(.easeOut(duration: 0.2), value: isShowingAnswer)
    }

    private func rate(known: Bool) {
        if known { knownCount += 1 } else { unknownCount += 1 }
        store.updateCardMastery(lernSetId: lernSet.id, cardId: cards[currentIndex].id, correct: known)

        withAnimation(.easeInOut(duration: 0.25)) {
            offset = known ? -400 : 400
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            offset = 0
            isShowingAnswer = false
            if currentIndex + 1 < cards.count {
                currentIndex += 1
            } else {
                let score = Double(knownCount) / Double(cards.count)
                store.saveSessionResult(lernSetId: lernSet.id, score: score, mode: "blitz")
                withAnimation { isDone = true }
            }
        }
    }

    @ViewBuilder
    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: knownCount > unknownCount ? "star.fill" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(knownCount > unknownCount ? .yellow : .green)

            Text("Blitz-Review abgeschlossen!")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            VStack(spacing: 12) {
                HStack(spacing: 32) {
                    VStack {
                        Text("\(knownCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("Gewusst")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(unknownCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                        Text("Nicht gewusst")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(Int(Double(knownCount) / Double(cards.count) * 100))% Trefferquote")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 32)

            Spacer()

            Button { dismiss() } label: {
                Text("Fertig")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.brandPurple))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Keine Karten vorhanden")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Due Cards View (P1 — SRS fällige Karten)

struct DueCardsView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var isShowingAnswer = false
    @State private var correctCount: Int = 0
    @State private var isDone = false

    private var dueCards: [LernSetCard] { lernSet.cardsDueToday }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if isDone || dueCards.isEmpty {
                doneView
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(uiColor: .systemFill)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("\(currentIndex + 1) / \(dueCards.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Circle().fill(.clear).frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(uiColor: .systemFill)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(Color.orange)
                                .frame(width: geo.size.width * (Double(currentIndex) / Double(max(1, dueCards.count))), height: 5)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Spacer()

                    let card = dueCards[currentIndex]
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Heute fällig · Level \(card.masteryLevel)/5", systemImage: "clock.badge.exclamationmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.orange)
                            Text(card.question)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)

                        if isShowingAnswer {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ANTWORT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.green.opacity(0.7))
                                Text(card.answer)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
                    )
                    .padding(.horizontal, 24)
                    .animation(.easeOut(duration: 0.2), value: isShowingAnswer)

                    Spacer()

                    if isShowingAnswer {
                        HStack(spacing: 16) {
                            Button {
                                store.updateCardMastery(lernSetId: lernSet.id, cardId: card.id, correct: false)
                                advance(correct: false)
                            } label: {
                                Label("Falsch", systemImage: "xmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.red))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.updateCardMastery(lernSetId: lernSet.id, cardId: card.id, correct: true)
                                advance(correct: true)
                            } label: {
                                Label("Richtig", systemImage: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.green))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) { isShowingAnswer = true }
                        } label: {
                            Text("Antwort zeigen")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Fällige Karten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func advance(correct: Bool) {
        if correct { correctCount += 1 }
        withAnimation(.easeOut(duration: 0.2)) { isShowingAnswer = false }
        if currentIndex + 1 < dueCards.count {
            currentIndex += 1
        } else {
            let score = Double(correctCount) / Double(max(1, dueCards.count))
            store.saveSessionResult(lernSetId: lernSet.id, score: score, mode: "faellig")
            withAnimation { isDone = true }
        }
    }

    @ViewBuilder
    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text(dueCards.isEmpty ? "Keine Karten fällig!" : "SRS-Session abgeschlossen!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            if !dueCards.isEmpty {
                Text("\(correctCount) von \(dueCards.count) Karten richtig beantwortet.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Alle Karten sind auf dem aktuellen Stand. Komm morgen wieder!")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Button { dismiss() } label: {
                Text("Fertig")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Weak Cards View (P5)

struct WeakCardsView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var isShowingAnswer = false
    @State private var correctCount: Int = 0
    @State private var isDone = false

    private let accent = Color(red: 0.85, green: 0.25, blue: 0.20)
    private var weakCards: [LernSetCard] { lernSet.weakCards }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if isDone || weakCards.isEmpty {
                doneView
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(uiColor: .systemFill)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("\(currentIndex + 1) / \(weakCards.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Circle().fill(.clear).frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(uiColor: .systemFill)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(accent)
                                .frame(width: geo.size.width * (Double(currentIndex) / Double(max(1, weakCards.count))), height: 5)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Spacer()

                    let card = weakCards[currentIndex]
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(accent)
                                Text("Schwache Karte · \(card.wrongCount)x falsch")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                            Text(card.question)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)

                        if isShowingAnswer {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ANTWORT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.green.opacity(0.7))
                                Text(card.answer)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
                    )
                    .padding(.horizontal, 24)
                    .animation(.easeOut(duration: 0.2), value: isShowingAnswer)

                    Spacer()

                    if isShowingAnswer {
                        HStack(spacing: 16) {
                            Button {
                                store.updateCardMastery(lernSetId: lernSet.id, cardId: card.id, correct: false)
                                advance(correct: false)
                            } label: {
                                Label("Immer noch falsch", systemImage: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.red))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.updateCardMastery(lernSetId: lernSet.id, cardId: card.id, correct: true)
                                advance(correct: true)
                            } label: {
                                Label("Jetzt richtig!", systemImage: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.green))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) { isShowingAnswer = true }
                        } label: {
                            Text("Antwort zeigen")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Schwachstellen üben")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func advance(correct: Bool) {
        if correct { correctCount += 1 }
        withAnimation(.easeOut(duration: 0.2)) { isShowingAnswer = false }
        if currentIndex + 1 < weakCards.count {
            currentIndex += 1
        } else {
            let score = Double(correctCount) / Double(max(1, weakCards.count))
            store.saveSessionResult(lernSetId: lernSet.id, score: score, mode: "schwach")
            withAnimation { isDone = true }
        }
    }

    @ViewBuilder
    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: weakCards.isEmpty ? "checkmark.circle.fill" : "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(weakCards.isEmpty ? .green : accent)
            Text(weakCards.isEmpty ? "Keine schwachen Karten mehr!" : "Schwachstellen-Training abgeschlossen!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            if !weakCards.isEmpty {
                Text("\(correctCount) von \(weakCards.count) Schwach-Karten richtig beantwortet.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button { dismiss() } label: {
                Text("Fertig")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - AnschauModusView kept for compatibility (now redirects to BlitzReviewView)

struct AnschauModusView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore

    var body: some View {
        BlitzReviewView(lernSet: lernSet)
            .environmentObject(store)
    }
}
