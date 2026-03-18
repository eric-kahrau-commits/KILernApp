import SwiftUI

struct VokabelDetailView: View {
    let lernSet: LernSet
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    private let accent = AppColors.brandVokabel
    private let minMC = 4

    // MARK: - KI Feedback state
    @State private var kiFeedbackActive = false
    @State private var kiFeedbackCardIndex: Int = 0
    @State private var kiUserInput: String = ""
    @State private var kiFeedbackResult: String? = nil
    @State private var kiIsChecking = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Info Card
                    infoCard

                    // Vocabulary List
                    vocabSection

                    // KI Feedback Section
                    kiFeedbackSection

                    // Learning Modes
                    modesSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(lernSet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Schließen")
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.86, green: 0.50, blue: 0.10), Color(red: 1.00, green: 0.72, blue: 0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(lernSet.subject)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                Text("\(lernSet.cards.count) Vokabeln")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
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

    // MARK: - Vocab Table
    private var vocabSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vokabeln")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("VOKABEL")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("ÜBERSETZUNG")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))

                ForEach(Array(lernSet.cards.enumerated()), id: \.element.id) { idx, card in
                    HStack(spacing: 0) {
                        Text(card.question)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(card.answer)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(idx % 2 == 0
                        ? Color(uiColor: .secondarySystemGroupedBackground)
                        : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))

                    if idx < lernSet.cards.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Learning Modes
    private var modesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lernmodus wählen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            let hasEnough = lernSet.cards.count >= minMC

            VStack(spacing: 10) {
                // Anschauen
                NavigationLink {
                    VokabelAnschauView(lernSet: lernSet)
                } label: {
                    modeCard(
                        icon: "eye.fill",
                        color: Color(red: 0.30, green: 0.52, blue: 0.98),
                        title: "Anschauen",
                        subtitle: "Alle Vokabeln durchblättern",
                        locked: false
                    )
                }
                .buttonStyle(.plain)

                // Karteikarten
                NavigationLink {
                    FlashcardSessionView(lernSet: lernSet)
                } label: {
                    modeCard(
                        icon: "rectangle.on.rectangle.angled.fill",
                        color: Color(red: 0.10, green: 0.64, blue: 0.54),
                        title: "Karteikarten",
                        subtitle: "Karte umdrehen – Richtig oder Falsch",
                        locked: false
                    )
                }
                .buttonStyle(.plain)

                // Lernmodus (QuickLearn – needs ≥ 4)
                if hasEnough {
                    NavigationLink {
                        QuickLearnView(lernSet: lernSet)
                    } label: {
                        modeCard(
                            icon: "bolt.fill",
                            color: Color(red: 0.95, green: 0.55, blue: 0.10),
                            title: "Lernmodus",
                            subtitle: "Multiple-Choice – alle Vokabeln abfragen",
                            locked: false
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    modeCard(
                        icon: "bolt.fill",
                        color: Color(uiColor: .tertiaryLabel),
                        title: "Lernmodus",
                        subtitle: "Mindestens \(minMC) Vokabeln erforderlich (\(lernSet.cards.count)/\(minMC))",
                        locked: true
                    )
                }

                // Auswendig lernen (needs ≥ 4)
                if hasEnough {
                    NavigationLink {
                        MemorizeLearnView(lernSet: lernSet)
                    } label: {
                        modeCard(
                            icon: "brain.head.profile",
                            color: Color(red: 0.15, green: 0.60, blue: 0.40),
                            title: "Auswendig lernen",
                            subtitle: "Stationsweise: Multiple-Choice & Eingabe",
                            locked: false
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    modeCard(
                        icon: "brain.head.profile",
                        color: Color(uiColor: .tertiaryLabel),
                        title: "Auswendig lernen",
                        subtitle: "Mindestens \(minMC) Vokabeln erforderlich (\(lernSet.cards.count)/\(minMC))",
                        locked: true
                    )
                }

                // Testmodus (needs ≥ 4)
                if hasEnough {
                    NavigationLink {
                        TestModusView(lernSet: lernSet)
                    } label: {
                        modeCard(
                            icon: "checkmark.seal.fill",
                            color: Color(red: 0.85, green: 0.25, blue: 0.45),
                            title: "Testmodus",
                            subtitle: "Timed Test mit allen Vokabeln",
                            locked: false
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    modeCard(
                        icon: "checkmark.seal.fill",
                        color: Color(uiColor: .tertiaryLabel),
                        title: "Testmodus",
                        subtitle: "Mindestens \(minMC) Vokabeln erforderlich (\(lernSet.cards.count)/\(minMC))",
                        locked: true
                    )
                }
            }
        }
    }

    // MARK: - KI Feedback Section
    private var kiFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("KI-Feedback")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        kiFeedbackActive.toggle()
                        if kiFeedbackActive {
                            kiFeedbackCardIndex = 0
                            kiUserInput = ""
                            kiFeedbackResult = nil
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: kiFeedbackActive ? "xmark.circle.fill" : "brain.head.profile")
                            .font(.system(size: 13, weight: .semibold))
                        Text(kiFeedbackActive ? "Beenden" : "KI-Modus starten")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(kiFeedbackActive ? Color.red : accent)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(
                        Capsule().fill(kiFeedbackActive ? Color.red.opacity(0.10) : accent.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
            }

            if kiFeedbackActive && !lernSet.cards.isEmpty {
                let card = lernSet.cards[kiFeedbackCardIndex]
                VStack(alignment: .leading, spacing: 12) {
                    // Card counter
                    HStack {
                        Text("Vokabel \(kiFeedbackCardIndex + 1) von \(lernSet.cards.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Question
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VOKABEL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accent.opacity(0.7))
                        Text(card.question)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }

                    // Input field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEINE ÜBERSETZUNG")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        TextField("Übersetzung eingeben …", text: $kiUserInput)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            )
                            .autocorrectionDisabled()
                    }

                    // KI prüfen button
                    Button {
                        checkWithKI(card: card)
                    } label: {
                        HStack(spacing: 8) {
                            if kiIsChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text(kiIsChecking ? "KI prüft …" : "KI prüfen")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(kiUserInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? Color(uiColor: .tertiaryLabel)
                                      : accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(kiUserInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || kiIsChecking)

                    // Feedback result
                    if let result = kiFeedbackResult {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: kiFeedbackIsCorrect(result) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(kiFeedbackIsCorrect(result) ? Color.green : Color.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Richtige Antwort: \(card.answer)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(kiFeedbackIsCorrect(result)
                                      ? Color.green.opacity(0.08)
                                      : Color.orange.opacity(0.08))
                        )

                        // Navigation buttons
                        HStack(spacing: 12) {
                            if kiFeedbackCardIndex > 0 {
                                Button {
                                    kiFeedbackCardIndex -= 1
                                    kiUserInput = ""
                                    kiFeedbackResult = nil
                                } label: {
                                    Label("Zurück", systemImage: "chevron.left")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(accent)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                            if kiFeedbackCardIndex + 1 < lernSet.cards.count {
                                Button {
                                    kiFeedbackCardIndex += 1
                                    kiUserInput = ""
                                    kiFeedbackResult = nil
                                } label: {
                                    Label("Weiter", systemImage: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(accent))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("Alle Vokabeln abgeschlossen!")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func checkWithKI(card: LernSetCard) {
        let input = kiUserInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        kiIsChecking = true
        kiFeedbackResult = nil

        let prompt = """
        Du bist ein Sprachlehrer. Der Schüler hat die folgende Vokabel übersetzt.
        Vokabel: "\(card.question)"
        Korrekte Übersetzung: "\(card.answer)"
        Antwort des Schülers: "\(input)"

        Bewerte die Antwort in einer kurzen Zeile (maximal 2 Sätze) auf Deutsch.
        Kategorisiere als eines von: korrekt / Tippfehler / grammatisch falsch / semantisch falsch / falsch.
        Gib kurzes konstruktives Feedback.
        """

        Task {
            let result = await AIService.shared.complete(prompt: prompt)
            await MainActor.run {
                kiFeedbackResult = result ?? "KI konnte die Antwort nicht prüfen."
                kiIsChecking = false
            }
        }
    }

    private func kiFeedbackIsCorrect(_ result: String) -> Bool {
        let lower = result.lowercased()
        return lower.contains("korrekt") || lower.contains("richtig") || lower.contains("tippfehler")
    }

    private func modeCard(icon: String, color: Color, title: String, subtitle: String, locked: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(locked ? 0.08 : 0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(locked ? .secondary : .primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(locked ? 0.02 : 0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(locked ? 0.7 : 1.0)
    }
}

// MARK: - Anschau View

struct VokabelAnschauView: View {
    let lernSet: LernSet
    @State private var flipped: Set<UUID> = []

    private let accent = AppColors.brandVokabel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(lernSet.cards) { card in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
                            if flipped.contains(card.id) { flipped.remove(card.id) }
                            else { flipped.insert(card.id) }
                        }
                    } label: {
                        let isFlipped = flipped.contains(card.id)
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isFlipped ? card.answer : card.question)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .animation(nil, value: isFlipped)
                                Text(isFlipped ? "Übersetzung" : "Vokabel")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                            Spacer()
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isFlipped
                                      ? accent.opacity(0.07)
                                      : Color(uiColor: .secondarySystemGroupedBackground))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(isFlipped ? accent.opacity(0.25) : Color.clear, lineWidth: 1))
                        )
                    }
                    .accessibilityLabel("Karte umdrehen")
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Anschauen")
        .navigationBarTitleDisplayMode(.inline)
    }
}
