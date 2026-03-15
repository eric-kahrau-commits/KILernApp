import SwiftUI

// MARK: - Data Types

private struct TaskItem: Identifiable {
    let id = UUID()
    let card: LernSetCard
    enum Kind { case mc, input }
    let kind: Kind
    let stationIndex: Int
}

// MARK: - Main View

struct MemorizeLearnView: View {
    let lernSet: LernSet
    @Environment(\.dismiss) private var dismiss

    // Task structure: array of stations, each station is array of tasks
    @State private var stations: [[TaskItem]] = []

    // Navigation state
    @State private var currentStation = 0
    @State private var currentTaskInStation = 0

    enum Phase { case loading, task, stationSummary, errorStation, finalSummary }
    @State private var phase: Phase = .loading

    // Per-station tracking
    @State private var stationCorrect = 0
    @State private var stationTotal = 0
    @State private var lastStationCorrect = 0
    @State private var lastStationTotal = 0

    // Error station
    @State private var wrongItems: [TaskItem] = []
    @State private var errorTasks: [TaskItem] = []
    @State private var currentErrorTask = 0
    @State private var errorCorrect = 0

    // Grand totals
    @State private var grandCorrect = 0
    @State private var grandTotal = 0
    @State private var showStreakPopup: Bool = false

    private let accent = Color(red: 0.15, green: 0.60, blue: 0.40)

    // MARK: Body

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            switch phase {
            case .loading:
                ProgressView()

            case .task:
                if currentStation < stations.count {
                    let tasks = stations[currentStation]
                    if currentTaskInStation < tasks.count {
                        let task = tasks[currentTaskInStation]
                        taskView(for: task)
                            .id(task.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }

            case .stationSummary:
                MemorizeStationSummaryView(
                    stationNumber: currentStation + 1,
                    totalStations: stations.count,
                    correct: lastStationCorrect,
                    total: lastStationTotal,
                    accent: accent,
                    onContinue: advanceFromStationSummary
                )
                .transition(.opacity)

            case .errorStation:
                if currentErrorTask < errorTasks.count {
                    let task = errorTasks[currentErrorTask]
                    taskView(for: task, isErrorStation: true)
                        .id(task.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

            case .finalSummary:
                MemorizeFinalView(
                    correct: grandCorrect,
                    total: grandTotal,
                    accent: accent,
                    onRestart: restart,
                    onBack: { dismiss() }
                )
                .transition(.opacity)
            }

            if showStreakPopup {
                StreakPopupView(streak: StreakManager.shared.currentStreak) {
                    showStreakPopup = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { buildTasks() }
        .animation(.easeInOut(duration: 0.25), value: phase == .stationSummary)
        .onChange(of: phase) { _, newPhase in
            if newPhase == .finalSummary {
                let incremented = StreakManager.shared.markActivity()
                if incremented { showStreakPopup = true }
            }
        }
    }

    private var navTitle: String {
        switch phase {
        case .loading: return "Auswendig lernen"
        case .task: return stations.isEmpty ? "" : "Station \(currentStation + 1) / \(stations.count)"
        case .stationSummary: return "Station abgeschlossen"
        case .errorStation: return "Fehlerstation"
        case .finalSummary: return "Auswertung"
        }
    }

    // MARK: Task View Factory

    @ViewBuilder
    private func taskView(for task: TaskItem, isErrorStation: Bool = false) -> some View {
        switch task.kind {
        case .mc:
            MCTaskView(
                card: task.card,
                allCards: lernSet.cards,
                accent: accent,
                onAnswer: { correct in handleAnswer(correct: correct, task: task, isErrorStation: isErrorStation) }
            )
        case .input:
            InputTaskView(
                card: task.card,
                accent: accent,
                onAnswer: { correct in handleAnswer(correct: correct, task: task, isErrorStation: isErrorStation) }
            )
        }
    }

    // MARK: Task Logic

    private func handleAnswer(correct: Bool, task: TaskItem, isErrorStation: Bool) {
        if isErrorStation {
            if correct { errorCorrect += 1; grandCorrect += 1 }
            grandTotal += 1
            withAnimation {
                currentErrorTask += 1
                if currentErrorTask >= errorTasks.count {
                    phase = .finalSummary
                }
            }
        } else {
            if correct {
                stationCorrect += 1
                grandCorrect += 1
            } else {
                wrongItems.append(task)
            }
            stationTotal += 1
            grandTotal += 1

            let tasks = stations[currentStation]
            if currentTaskInStation + 1 < tasks.count {
                withAnimation {
                    currentTaskInStation += 1
                }
            } else {
                // Station complete
                lastStationCorrect = stationCorrect
                lastStationTotal = stationTotal
                stationCorrect = 0
                stationTotal = 0
                withAnimation { phase = .stationSummary }
            }
        }
    }

    private func advanceFromStationSummary() {
        if currentStation + 1 < stations.count {
            currentStation += 1
            currentTaskInStation = 0
            withAnimation { phase = .task }
        } else {
            // All stations done
            if wrongItems.isEmpty {
                withAnimation { phase = .finalSummary }
            } else {
                errorTasks = wrongItems
                currentErrorTask = 0
                errorCorrect = 0
                withAnimation { phase = .errorStation }
            }
        }
    }

    // MARK: Build Tasks

    private func buildTasks() {
        let cards = lernSet.cards
        guard !cards.isEmpty else { phase = .finalSummary; return }

        let size = 3
        let numStations = (cards.count + size - 1) / size
        var result: [[TaskItem]] = []

        for i in 0..<numStations {
            var stationTasks: [TaskItem] = []

            // MC for current group
            let start = i * size
            let end = min(start + size, cards.count)
            for j in start..<end {
                stationTasks.append(TaskItem(card: cards[j], kind: .mc, stationIndex: i))
            }

            // Input for previous group (from station 1 onward)
            if i > 0 {
                let prevStart = (i - 1) * size
                let prevEnd = min(prevStart + size, cards.count)
                for j in prevStart..<prevEnd {
                    stationTasks.append(TaskItem(card: cards[j], kind: .input, stationIndex: i))
                }
            }

            result.append(stationTasks)
        }

        stations = result
        phase = .task
    }

    private func restart() {
        currentStation = 0
        currentTaskInStation = 0
        stationCorrect = 0
        stationTotal = 0
        lastStationCorrect = 0
        lastStationTotal = 0
        wrongItems = []
        errorTasks = []
        currentErrorTask = 0
        errorCorrect = 0
        grandCorrect = 0
        grandTotal = 0
        buildTasks()
    }
}

// MARK: - MC Task View

private struct MCTaskView: View {
    let card: LernSetCard
    let allCards: [LernSetCard]
    let accent: Color
    let onAnswer: (Bool) -> Void

    @State private var choices: [String] = []
    @State private var selectedAnswer: String? = nil

    private var hasAnswered: Bool { selectedAnswer != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                taskLabel(text: "Multiple-Choice", icon: "checkmark.square", color: accent)

                questionCard

                VStack(spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        choiceButton(choice: choice)
                    }
                }
                .padding(.horizontal, 8)

                if hasAnswered {
                    Button {
                        onAnswer(selectedAnswer == card.answer)
                    } label: {
                        Text("Weiter")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 40)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedAnswer)
        }
        .onAppear {
            choices = card.shuffledAnswers(fallbackFrom: allCards)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 10) {
            Text(card.question)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(20)
            if let data = card.frontImageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 130)
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
    }

    private func choiceButton(choice: String) -> some View {
        let isSelected = selectedAnswer == choice
        let isCorrect = choice == card.answer

        let bg: Color
        let border: Color
        if hasAnswered {
            bg = isCorrect ? .green.opacity(0.13) : (isSelected ? .red.opacity(0.10) : Color(uiColor: .secondarySystemGroupedBackground))
            border = isCorrect ? .green.opacity(0.6) : (isSelected ? .red.opacity(0.5) : .clear)
        } else {
            bg = Color(uiColor: .secondarySystemGroupedBackground)
            border = .clear
        }

        return Button {
            guard !hasAnswered else { return }
            withAnimation(.spring(response: 0.3)) { selectedAnswer = choice }
        } label: {
            HStack(spacing: 12) {
                if hasAnswered && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        .font(.system(size: 18, weight: .semibold))
                } else if hasAnswered && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    Circle().stroke(Color(uiColor: .tertiaryLabel), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
                Text(choice)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(bg)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Task View

private struct InputTaskView: View {
    let card: LernSetCard
    let accent: Color
    let onAnswer: (Bool) -> Void

    @State private var inputText: String = ""
    @State private var isEvaluating: Bool = false
    @State private var evalResult: (correct: Bool, correction: String?)? = nil
    @FocusState private var isFocused: Bool

    private var hasResult: Bool { evalResult != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                taskLabel(text: "Eigene Antwort", icon: "pencil.line", color: Color(red: 0.38, green: 0.18, blue: 0.90))

                questionCard

                if hasResult {
                    resultCard
                } else {
                    inputArea
                }

                if hasResult {
                    Button {
                        onAnswer(evalResult?.correct ?? false)
                    } label: {
                        Text("Weiter")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(evalResult?.correct == true ? Color.green : Color.red)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 40)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasResult)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 10) {
            Text(card.question)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 8)
    }

    private var inputArea: some View {
        VStack(spacing: 12) {
            TextField("Deine Antwort …", text: $inputText, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(3...6)
                .focused($isFocused)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isFocused ? accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 8)

            Button {
                submitInput()
            } label: {
                Group {
                    if isEvaluating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Antwort prüfen")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEvaluating
                              ? Color(uiColor: .tertiaryLabel)
                              : Color(red: 0.38, green: 0.18, blue: 0.90))
                )
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEvaluating)
            .padding(.horizontal, 8)
        }
    }

    private var resultCard: some View {
        let correct = evalResult?.correct ?? false
        let correction = evalResult?.correction

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(correct ? .green : .red)
                Text(correct ? "Richtig!" : "Leider falsch")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(correct ? .green : .red)
            }

            if let correction {
                Divider()
                Text(correction)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            } else if correct {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 13))
                    Text(card.answer)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(correct ? Color.green.opacity(0.08) : Color.red.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(correct ? Color.green.opacity(0.25) : Color.red.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
    }

    private func submitInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isEvaluating else { return }
        isFocused = false

        // Fast local check first (ignores articles + case)
        if locallyCorrect(trimmed, card.answer) {
            withAnimation { evalResult = (correct: true, correction: nil) }
            return
        }

        isEvaluating = true
        Task {
            do {
                let result = try await AIService.shared.evaluateAnswer(
                    question: card.question,
                    correctAnswer: card.answer,
                    userAnswer: trimmed
                )
                withAnimation { evalResult = result }
            } catch {
                // Fallback: use local comparison result
                withAnimation { evalResult = (correct: false, correction: "Richtige Antwort: \(card.answer)") }
            }
            isEvaluating = false
        }
    }

    /// Local answer check: case-insensitive, ignores common articles.
    private func locallyCorrect(_ input: String, _ answer: String) -> Bool {
        normalizeAnswer(input) == normalizeAnswer(answer)
    }

    private func normalizeAnswer(_ text: String) -> String {
        let articles = ["der ", "die ", "das ", "ein ", "eine ", "einen ", "einem ", "einer ", "eines ",
                        "dem ", "den ", "des ", "the ", "a ", "an "]
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for article in articles {
            if s.hasPrefix(article) { s = String(s.dropFirst(article.count)); break }
        }
        return s
    }
}

// MARK: - Station Summary View

struct MemorizeStationSummaryView: View {
    let stationNumber: Int
    let totalStations: Int
    let correct: Int
    let total: Int
    let accent: Color
    let onContinue: () -> Void

    @State private var circleTrim: CGFloat = 0

    private var percentage: Double {
        total == 0 ? 100 : Double(correct) / Double(total) * 100
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Station \(stationNumber) abgeschlossen")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                if totalStations > stationNumber {
                    Text("Noch \(totalStations - stationNumber) Station\(totalStations - stationNumber == 1 ? "" : "en") übrig")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }

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
                VStack(spacing: 2) {
                    Text("\(correct)/\(total)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("richtig")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 16)

            Button(action: onContinue) {
                Text(totalStations > stationNumber ? "Zur nächsten Station" : "Auswertung")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16).fill(accent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { circleTrim = 1.0 }
        }
    }
}

// MARK: - Final Summary View

struct MemorizeFinalView: View {
    let correct: Int
    let total: Int
    let accent: Color
    let onRestart: () -> Void
    let onBack: () -> Void

    @State private var circleTrim: CGFloat = 0
    @State private var labelOpacity: Double = 0

    private var percentage: Double {
        total == 0 ? 0 : Double(correct) / Double(total) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Lerneinheit abgeschlossen!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

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

                Text("\(correct) von \(total) richtig")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    resultButton(title: "Nochmal lernen", icon: "arrow.clockwise", action: onRestart)
                    resultButton(title: "Zurück", icon: "chevron.left", action: onBack)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                circleTrim = 1.0
                labelOpacity = 1.0
            }
        }
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

// MARK: - Shared Helpers

private func taskLabel(text: String, icon: String, color: Color) -> some View {
    HStack(spacing: 6) {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Capsule().fill(color.opacity(0.12)))
}
