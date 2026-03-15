import SwiftUI

struct KILernsetPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: LernSetStore

    @State var cards: [LernSetCard]
    let setName: String
    let subjectName: String

    var onSaved: ((LernSet) -> Void)? = nil

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    @State private var questionCard: LernSetCard? = nil
    @State private var showAddSheet: AddCardMode? = nil

    enum AddCardMode: Identifiable {
        case manuell, ki
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 14) {
                        summaryCard
                        cardsTable
                        addButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                bottomButtons
            }
        }
        .sheet(item: $questionCard) { card in
            CardQuestionView(card: card)
        }
        .sheet(item: $showAddSheet) { mode in
            if mode == .manuell {
                AddManualCardSheet { newCard in
                    cards.append(newCard)
                }
            } else {
                AddKICardsSheet(fach: subjectName, accent: accent) { newCards in
                    cards.append(contentsOf: newCards)
                }
            }
        }
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
            Text("Vorschau")
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

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("KI-generiertes Lernset")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("\(cards.count) Fragen · Bereit zum Speichern")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Cards Table
    private var cardsTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("FRAGE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("ANTWORT")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))

            ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("F\(idx + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(accent.opacity(0.10)))
                            Text(card.question)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(card.answer)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Menu {
                            Button {
                                questionCard = card
                            } label: {
                                Label("Frage stellen", systemImage: "bubble.left.and.bubble.right")
                            }
                            Divider()
                            Button(role: .destructive) {
                                withAnimation {
                                    cards.removeAll { $0.id == card.id }
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(idx % 2 == 0
                        ? Color(uiColor: .secondarySystemGroupedBackground)
                        : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))

                    if idx < cards.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Add Button
    private var addButton: some View {
        Menu {
            Button {
                showAddSheet = .manuell
            } label: {
                Label("Manuell hinzufügen", systemImage: "pencil")
            }
            Button {
                showAddSheet = .ki
            } label: {
                Label("Mit KI generieren", systemImage: "sparkles")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Frage hinzufügen")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(accent.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
            )
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    let newSet = LernSet(
                        name: setName,
                        subject: subjectName,
                        cards: cards,
                        isKIGenerated: true
                    )
                    store.save(newSet)
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onSaved?(newSet)
                    }
                } label: {
                    Label("Speichern", systemImage: "square.and.arrow.down.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .shadow(color: accent.opacity(0.35), radius: 10, x: 0, y: 5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

// MARK: - Add Manual Card Sheet

private struct AddManualCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (LernSetCard) -> Void

    @State private var question = ""
    @State private var answer = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Frage") {
                    TextField("Frage eingeben …", text: $question, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Antwort") {
                    TextField("Antwort eingeben …", text: $answer, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Manuell hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        guard !question.isEmpty, !answer.isEmpty else { return }
                        onAdd(LernSetCard(question: question, answer: answer))
                        dismiss()
                    }
                    .disabled(question.isEmpty || answer.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add KI Cards Sheet

private struct AddKICardsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let fach: String
    let accent: Color
    var onAdd: ([LernSetCard]) -> Void

    @State private var beschreibung = ""
    @State private var anzahl = 5
    @State private var anforderungen = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Thema / Beschreibung") {
                    TextField("z. B. Photosynthese, Grundrechenarten …", text: $beschreibung, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Anzahl neuer Fragen: \(anzahl)") {
                    Stepper("", value: $anzahl, in: 1...20, step: 1).labelsHidden()
                }
                Section("Anforderungen (optional)") {
                    TextField("z. B. nur Definitionen, mit Beispielen …", text: $anforderungen, axis: .vertical)
                        .lineLimit(2...3)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.system(size: 13))
                    }
                }
            }
            .navigationTitle("Mit KI generieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView().tint(accent)
                    } else {
                        Button("Generieren") { generate() }
                            .disabled(beschreibung.isEmpty)
                    }
                }
            }
        }
    }

    private func generate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let newCards = try await AIService.shared.generateZusatzKarten(
                    fach: fach,
                    beschreibung: beschreibung,
                    anzahl: anzahl,
                    anforderungen: anforderungen
                )
                onAdd(newCards)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Card Question View

struct CardQuestionView: View {
    @Environment(\.dismiss) var dismiss
    let card: LernSetCard

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isFocused: Bool

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                cardHeader
                Divider()
                chatArea
                inputBar
            }
        }
    }

    // MARK: Nav

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
            VStack(spacing: 1) {
                Text("Frage stellen")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("KI erklärt dir diese Karte")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: Card Reference Header

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Karte")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(card.question)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.green)
                Text(card.answer)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty && !isLoading {
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(accent.opacity(0.45))
                            Text("Stelle eine Rückfrage zu dieser Karte")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                    ForEach(messages) { msg in
                        ChatBubble(message: msg).id(msg.id)
                    }
                    if isLoading {
                        HStack {
                            HStack(spacing: 5) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(accent.opacity(0.6))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isLoading ? 1.0 : 0.5)
                                        .animation(
                                            .easeInOut(duration: 0.5)
                                                .repeatForever()
                                                .delay(Double(i) * 0.15),
                                            value: isLoading
                                        )
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 18)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground)))
                            Spacer()
                        }
                    }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: messages.count) {
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: isLoading) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // MARK: Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("Rückfrage stellen…", text: $inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit { sendQuestion() }
                if !inputText.isEmpty {
                    Button { sendQuestion() } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground)))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
        }
    }

    // MARK: Send

    private func sendQuestion() {
        let q = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !isLoading else { return }
        inputText = ""
        messages.append(ChatMessage(sender: .user, text: q))
        isLoading = true
        Task {
            let system = AIMessage(
                role: "system",
                content: "Du bist ein hilfreicher Lernassistent. Erkläre Konzepte klar und präzise auf Deutsch. Beziehe dich auf die Lernkarte und beantworte die Rückfrage des Schülers kurz und verständlich."
            )
            let context = AIMessage(
                role: "user",
                content: "Lernkarte:\nFrage: \(card.question)\nAntwort: \(card.answer)\n\nMeine Rückfrage: \(q)"
            )
            do {
                let reply = try await AIService.shared.chat(messages: [system, context])
                messages.append(ChatMessage(sender: .ai, text: reply))
            } catch {
                messages.append(ChatMessage(sender: .ai, text: "Entschuldigung, da ist etwas schiefgelaufen. Bitte versuche es erneut."))
            }
            isLoading = false
        }
    }
}
