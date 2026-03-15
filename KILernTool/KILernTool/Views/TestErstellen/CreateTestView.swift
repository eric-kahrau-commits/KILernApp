import SwiftUI

struct CreateTestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lernSetStore: LernSetStore

    // Step state
    @State private var currentStep: Int = 1

    // Step 1
    @State private var testName: String = ""
    @State private var fach: String = Subject.all.first?.name ?? "Mathe"

    // Step 2
    @State private var selectedLernSetIds: Set<UUID> = []

    // Step 3 (optional)
    @State private var beschreibung: String = ""
    @State private var anzahlFragen: Int = 10
    @State private var besondereWuensche: String = ""

    // Generation
    @State private var isGenerating: Bool = false
    @State private var generationError: String? = nil
    @State private var generatedTest: GeneratedTest? = nil
    @State private var showGeneratedTest: Bool = false
    @State private var isGeneratingOverlay: Bool = false
    @State private var generationProgress: Double = 0

    private let totalSteps = 3
    private let accent = Color(red: 0.85, green: 0.25, blue: 0.45)
    private let gradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.25, blue: 0.45), Color(red: 0.60, green: 0.18, blue: 0.75)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var canAdvance: Bool {
        switch currentStep {
        case 1: return !testName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true   // Lernsets (Schritt 2) und Details (Schritt 3) sind optional
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    progressBar
                    ScrollView {
                        VStack(spacing: 24) {
                            maxBanner
                            switch currentStep {
                            case 1: step1
                            case 2: step2
                            default: step3
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    bottomBar
                }

                if isGeneratingOverlay {
                    MaxGeneratingOverlay(progress: $generationProgress)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .zIndex(10)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isGeneratingOverlay)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showGeneratedTest) {
                if let test = generatedTest {
                    GeneratedTestView(test: test)
                }
            }
        }
    }

    // MARK: - Max Banner

    private var maxBanner: some View {
        let messages = [
            "Wie soll dein Test heißen? 🧐\nGib ihm einen Namen – dann kann ich loslegen!",
            "Ich kann deine Lernsets als Vorlage nutzen – oder auch ganz ohne starten. Du entscheidest! 📚",
            "Fast fertig! Je mehr Details du mir gibst, desto besser wird dein Test. 🎯"
        ]
        let msg = messages[min(currentStep - 1, messages.count - 1)]
        return HStack(spacing: 14) {
            MascotView(color: accent, mood: .talking, size: 46)
                .frame(width: 46, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("MAX")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .tracking(1.5)
                Text(msg)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.20), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                if currentStep > 1 {
                    withAnimation(.easeInOut(duration: 0.25)) { currentStep -= 1 }
                } else {
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: currentStep > 1 ? "chevron.left" : "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Test erstellen")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(currentStep >= step ? accent : Color(uiColor: .tertiarySystemGroupedBackground))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    // MARK: - Step 1: Name + Fach

    private var step1: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name & Fach")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Gib deinem Test einen Namen und wähle das Fach aus.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Test name
            VStack(alignment: .leading, spacing: 8) {
                Text("Testname")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("z. B. Mathe-Test Kapitel 3, Bio-Klausur ...", text: $testName)
                    .font(.system(size: 15))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }

            // Fach picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Fach")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Subject.all) { subject in
                            Button { fach = subject.name } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: subject.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(subject.name)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundStyle(fach == subject.name ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(fach == subject.name
                                              ? subject.color
                                              : Color(uiColor: .secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    // MARK: - Step 2: Lernsets

    private var step2: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lernsets auswählen")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Wähle eines oder mehrere Lernsets als Grundlage für deinen Test.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            if lernSetStore.lernSets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Keine Lernsets vorhanden")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Du kannst den Test auch ohne Lernsets erstellen – tippe dann auf 'Weiter'.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            } else {
                VStack(spacing: 8) {
                    // Select all / deselect all
                    HStack {
                        Text("\(selectedLernSetIds.count) ausgewählt")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            if selectedLernSetIds.count == lernSetStore.lernSets.count {
                                selectedLernSetIds.removeAll()
                            } else {
                                selectedLernSetIds = Set(lernSetStore.lernSets.map { $0.id })
                            }
                        } label: {
                            Text(selectedLernSetIds.count == lernSetStore.lernSets.count ? "Alle abwählen" : "Alle auswählen")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)

                    ForEach(lernSetStore.lernSets) { lernSet in
                        lernSetRow(lernSet)
                    }
                }
            }
        }
    }

    private func lernSetRow(_ lernSet: LernSet) -> some View {
        let isSelected = selectedLernSetIds.contains(lernSet.id)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    selectedLernSetIds.remove(lernSet.id)
                } else {
                    selectedLernSetIds.insert(lernSet.id)
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accent : Color(uiColor: .tertiarySystemGroupedBackground))
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(lernSet.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("\(lernSet.subject) · \(lernSet.cards.count) Karten")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if lernSet.isKIGenerated {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.7))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? accent.opacity(0.08)
                          : Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Optional Details

    private var step3: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Details (optional)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Diese Angaben helfen der KI, den Test besser auf deine Bedürfnisse anzupassen.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Beschreibung
            VStack(alignment: .leading, spacing: 8) {
                Text("Beschreibung / Thema")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("z. B. Kapitel 3 bis 5, Schwerpunkt Zellteilung …", text: $beschreibung, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }

            // Anzahl Fragen
            VStack(alignment: .leading, spacing: 8) {
                Text("Anzahl Aufgaben")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack {
                    Button {
                        if anzahlFragen > 3 { anzahlFragen -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(anzahlFragen > 3 ? accent : Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)

                    Text("\(anzahlFragen)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(minWidth: 48)

                    Button {
                        if anzahlFragen < 25 { anzahlFragen += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(anzahlFragen < 25 ? accent : Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Empfohlen: 10–15")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            }

            // Besondere Wünsche
            VStack(alignment: .leading, spacing: 8) {
                Text("Besondere Wünsche")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("z. B. Schwerpunkt auf Diagramme, mehr Multiple Choice, schwere Aufgaben …", text: $besondereWuensche, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }

            if let error = generationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    Text(error).font(.system(size: 13)).foregroundStyle(.red)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: handleMainAction) {
                Group {
                    if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                            Text("KI erstellt Test …")
                        }
                    } else {
                        Text(currentStep < totalSteps ? "Weiter" : "Test erstellen")
                    }
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canAdvance && !isGenerating
                              ? gradient
                              : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                               startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || isGenerating)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Logic

    private func handleMainAction() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
        } else {
            generateTest()
        }
    }

    private func startFakeProgress() {
        Task {
            let steps = 40
            for i in 0..<steps {
                let pct = Double(i + 1) / Double(steps) * 88.0
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard isGeneratingOverlay else { break }
                withAnimation(.easeOut(duration: 0.3)) { generationProgress = pct }
            }
        }
    }

    private func generateTest() {
        generationError = nil
        isGenerating = true
        generationProgress = 0
        withAnimation { isGeneratingOverlay = true }
        startFakeProgress()

        let selectedSets = lernSetStore.lernSets.filter { selectedLernSetIds.contains($0.id) }

        Task {
            do {
                let raw = try await AIService.shared.generateTest(
                    name: testName,
                    fach: fach,
                    beschreibung: beschreibung,
                    anzahlFragen: anzahlFragen,
                    besondereWuensche: besondereWuensche,
                    lernSets: selectedSets
                )

                // Map raw to model
                let sektionen = raw.sektionen.map { rawSek in
                    let aufgaben = rawSek.aufgaben.map { rawAuf in
                        TestAufgabe(
                            nummer: rawAuf.nummer,
                            text: rawAuf.text,
                            typ: TestAufgabeTyp(rawValue: rawAuf.typ) ?? .freitext,
                            punkte: rawAuf.punkte,
                            zeilen: rawAuf.zeilen ?? 4,
                            optionen: rawAuf.optionen,
                            hinweis: rawAuf.hinweis,
                            diagrammLabel: rawAuf.diagrammLabel
                        )
                    }
                    return TestSektion(titel: rawSek.titel, punkte: rawSek.punkte, aufgaben: aufgaben)
                }

                let test = GeneratedTest(
                    name: testName,
                    fach: fach,
                    beschreibung: beschreibung,
                    besondereWuensche: besondereWuensche,
                    lernSetIds: Array(selectedLernSetIds),
                    sektionen: sektionen,
                    dauer: raw.dauer,
                    gesamtPunkte: raw.gesamtPunkte
                )

                GeneratedTestStore.shared.save(test)
                StreakManager.shared.markActivity()

                generatedTest = test
                isGenerating = false
                withAnimation(.easeOut(duration: 0.3)) { generationProgress = 100 }
                try? await Task.sleep(nanoseconds: 700_000_000)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isGeneratingOverlay = false }
                try? await Task.sleep(nanoseconds: 350_000_000)
                showGeneratedTest = true

            } catch {
                isGenerating = false
                withAnimation { isGeneratingOverlay = false }
                generationError = error.localizedDescription
            }
        }
    }
}

// MARK: - Max Generating Overlay

private struct MaxGeneratingOverlay: View {
    @Binding var progress: Double

    private let accent = Color(red: 0.85, green: 0.25, blue: 0.45)

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 28) {
                MascotView(color: accent, mood: .celebrating, size: 110)
                    .frame(height: 130)

                VStack(spacing: 8) {
                    Text("Ich erstelle deinen Test …")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Max arbeitet auf Hochtouren für dich! ✏️")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.15), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress / 100))
                        .stroke(
                            LinearGradient(
                                colors: [accent, Color(red: 0.60, green: 0.18, blue: 0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.3), value: progress)
                    Text("\(Int(progress)) %")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 8)
            )
            .padding(.horizontal, 40)
        }
    }
}
