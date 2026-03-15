import SwiftUI
import PhotosUI

// MARK: - Result Models (display only, not persisted)

enum BewertungsStatus: String {
    case richtig, falsch, teilweise

    var farbe: Color {
        switch self {
        case .richtig:   return .green
        case .falsch:    return .red
        case .teilweise: return .orange
        }
    }
    var icon: String {
        switch self {
        case .richtig:   return "checkmark.circle.fill"
        case .falsch:    return "xmark.circle.fill"
        case .teilweise: return "minus.circle.fill"
        }
    }
    var label: String {
        switch self {
        case .richtig:   return "Richtig"
        case .falsch:    return "Falsch"
        case .teilweise: return "Teilweise"
        }
    }
}

struct AufgabeBewertung: Identifiable {
    let id = UUID()
    let nummer: Int
    let aufgabeText: String
    let status: BewertungsStatus
    let erreichtePunkte: Int
    let maxPunkte: Int
    let schuelerAntwort: String?
    let erklaerung: String?
    let verbesserung: String?
}

struct KorrekturErgebnis {
    let testName: String
    let fach: String
    let erreichtePunkte: Int
    let gesamtPunkte: Int
    let lehrerFeedback: String
    let bewertungen: [AufgabeBewertung]

    var prozentzahl: Double {
        gesamtPunkte == 0 ? 0 : Double(erreichtePunkte) / Double(gesamtPunkte) * 100
    }
    var note: Int { schulnote(from: prozentzahl) }
    var richtigCount: Int   { bewertungen.filter { $0.status == .richtig }.count }
    var falschCount: Int    { bewertungen.filter { $0.status == .falsch }.count }
    var teilweiseCount: Int { bewertungen.filter { $0.status == .teilweise }.count }
}

// MARK: - Main View

struct TestKorrigierenView: View {
    let preSelectedTest: GeneratedTest?
    @Environment(\.dismiss) private var dismiss

    enum Phase { case testAuswahl, foto, analysiert, ergebnis }
    @State private var phase: Phase
    @State private var selectedTest: GeneratedTest?
    @State private var selectedImages: [UIImage] = []
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var ergebnis: KorrekturErgebnis? = nil
    @State private var errorMessage: String? = nil

    private let testStore = GeneratedTestStore.shared
    private let accentBlue = Color(red: 0.10, green: 0.52, blue: 0.95)

    init(preSelectedTest: GeneratedTest? = nil) {
        self.preSelectedTest = preSelectedTest
        _phase = State(initialValue: preSelectedTest != nil ? .foto : .testAuswahl)
        _selectedTest = State(initialValue: preSelectedTest)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                switch phase {
                case .testAuswahl: testAuswahlView
                case .foto:        fotoView
                case .analysiert:  analyseView
                case .ergebnis:
                    if let e = ergebnis {
                        KorrekturResultView(ergebnis: e, accent: accentBlue) { dismiss() }
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if phase != .analysiert {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            switch phase {
                            case .testAuswahl, .ergebnis:
                                dismiss()
                            case .foto:
                                if preSelectedTest != nil { dismiss() }
                                else { withAnimation { phase = .testAuswahl } }
                            case .analysiert: break
                            }
                        } label: {
                            let isBack = phase == .foto && preSelectedTest == nil
                            Image(systemName: isBack ? "chevron.left" : "xmark.circle.fill")
                                .font(.system(size: isBack ? 16 : 20, weight: isBack ? .semibold : .regular))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onChange(of: photoItems) { _, items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            if selectedImages.count < 4 { selectedImages.append(img) }
                        }
                    }
                    photoItems = []
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView { img in
                    if selectedImages.count < 4 { selectedImages.append(img) }
                }
            }
        }
    }

    private var navTitle: String {
        switch phase {
        case .testAuswahl: return "Test auswählen"
        case .foto:        return "Test korrigieren"
        case .analysiert:  return "Wird korrigiert …"
        case .ergebnis:    return "Korrektur"
        }
    }

    // MARK: - Phase 1: Test auswählen

    private var testAuswahlView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welchen Test korrigieren?")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Wähle den Test aus, den der Schüler bearbeitet hat.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                if testStore.tests.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.text.below.ecg")
                            .font(.system(size: 40))
                            .foregroundStyle(accentBlue.opacity(0.4))
                        Text("Noch keine Tests vorhanden")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Text("Erstelle zuerst einen Test, bevor du ihn korrigieren kannst.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(spacing: 10) {
                        ForEach(testStore.tests) { test in
                            Button {
                                selectedTest = test
                                withAnimation(.easeInOut(duration: 0.22)) { phase = .foto }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(subjectColor(test.fach).opacity(0.15))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: subjectIcon(test.fach))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(subjectColor(test.fach))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(test.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("\(test.fach) · \(test.allAufgaben.count) Aufgaben · \(test.gesamtPunkte) P.")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Phase 2: Foto aufnehmen

    private var fotoView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Selected test chip
                    if let test = selectedTest {
                        HStack(spacing: 10) {
                            Image(systemName: subjectIcon(test.fach))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(subjectColor(test.fach))
                            Text(test.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text("\(test.gesamtPunkte) P.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(subjectColor(test.fach).opacity(0.1))
                                .overlay(Capsule().stroke(subjectColor(test.fach).opacity(0.2), lineWidth: 1))
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Foto(s) aufnehmen")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Fotografiere alle Seiten des ausgefüllten Tests. Die KI liest die Antworten automatisch aus.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    // Photo grid
                    if !selectedImages.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Button {
                                        selectedImages.remove(at: idx)
                                    } label: {
                                        ZStack {
                                            Circle().fill(.black.opacity(0.6)).frame(width: 26, height: 26)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(6)
                                }
                            }
                        }
                    }

                    // Add photo buttons
                    if selectedImages.count < 4 {
                        HStack(spacing: 12) {
                            Button { showCamera = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text("Kamera")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(accentBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(accentBlue.opacity(0.10))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentBlue.opacity(0.25), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)

                            PhotosPicker(selection: $photoItems, maxSelectionCount: 4 - selectedImages.count, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Bibliothek")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(accentBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(accentBlue.opacity(0.10))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentBlue.opacity(0.25), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text(selectedImages.isEmpty
                             ? "Bis zu 4 Fotos – z. B. für mehrseitige Tests."
                             : "\(selectedImages.count) von 4 Seiten hinzugefügt.")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(error).font(.system(size: 13)).foregroundStyle(.red)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            // Bottom action button
            VStack(spacing: 0) {
                Divider()
                Button(action: startAnalyse) {
                    Text("Jetzt korrigieren")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedImages.isEmpty
                                      ? LinearGradient(colors: [Color(uiColor: .tertiaryLabel)], startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [accentBlue, Color(red: 0.10, green: 0.72, blue: 1.00)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedImages.isEmpty)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemBackground))
            }
        }
    }

    // MARK: - Phase 3: Analysiert (Loading)

    private var analyseView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.08))
                    .frame(width: 90, height: 90)
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(accentBlue)
            }
            VStack(spacing: 8) {
                Text("KI korrigiert …")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Antworten werden ausgelesen und bewertet")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logic

    private func startAnalyse() {
        guard let test = selectedTest, !selectedImages.isEmpty else { return }
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.25)) { phase = .analysiert }

        Task {
            do {
                let raw = try await AIService.shared.korrigiereTest(test: test, images: selectedImages)

                let bewertungen = raw.aufgaben.map { b in
                    AufgabeBewertung(
                        nummer: b.aufgabeNummer,
                        aufgabeText: test.allAufgaben.first(where: { $0.nummer == b.aufgabeNummer })?.text ?? "",
                        status: BewertungsStatus(rawValue: b.status) ?? .falsch,
                        erreichtePunkte: b.erhaltendePunkte,
                        maxPunkte: b.erreichbarePunkte,
                        schuelerAntwort: b.schuelerAntwort.isEmpty ? nil : b.schuelerAntwort,
                        erklaerung: b.korrektur.isEmpty ? nil : b.korrektur,
                        verbesserung: b.richtigeAntwort.isEmpty ? nil : b.richtigeAntwort
                    )
                }

                let erreichtePunkte = raw.aufgaben.reduce(0) { $0 + $1.erhaltendePunkte }
                ergebnis = KorrekturErgebnis(
                    testName: test.name,
                    fach: test.fach,
                    erreichtePunkte: erreichtePunkte,
                    gesamtPunkte: test.gesamtPunkte,
                    lehrerFeedback: raw.lehrerfeedback,
                    bewertungen: bewertungen
                )
                withAnimation(.easeInOut(duration: 0.3)) { phase = .ergebnis }

            } catch {
                errorMessage = error.localizedDescription
                withAnimation { phase = .foto }
            }
        }
    }

    // MARK: - Helpers

    private func subjectColor(_ fach: String) -> Color {
        Subject.all.first { $0.name == fach }?.color ?? accentBlue
    }
    private func subjectIcon(_ fach: String) -> String {
        Subject.all.first { $0.name == fach }?.icon ?? "doc.text"
    }
}

// MARK: - Korrektur Result View

private struct KorrekturResultView: View {
    let ergebnis: KorrekturErgebnis
    let accent: Color
    let onDismiss: () -> Void

    @State private var circleTrim: CGFloat = 0
    @State private var numberOpacity: Double = 0

    private var noteColor: Color {
        switch ergebnis.note {
        case 1, 2: return .green
        case 3:    return .orange
        default:   return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Korrektur abgeschlossen")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .padding(.top, 32)

                // Grade + Ring
                HStack(spacing: 32) {
                    // Note
                    VStack(spacing: 4) {
                        Text("Note")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("\(ergebnis.note)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(noteColor)
                            .opacity(numberOpacity)
                    }

                    // Percentage ring
                    ZStack {
                        Circle()
                            .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 12)
                            .frame(width: 110, height: 110)
                        Circle()
                            .trim(from: 0, to: circleTrim * CGFloat(ergebnis.prozentzahl / 100))
                            .stroke(
                                ergebnis.prozentzahl >= 80 ? Color.green : (ergebnis.prozentzahl >= 50 ? Color.orange : Color.red),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(Int(round(ergebnis.prozentzahl))) %")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("\(ergebnis.erreichtePunkte) / \(ergebnis.gesamtPunkte) P.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .opacity(numberOpacity)
                    }
                }
                .padding(.vertical, 8)

                // Stats row
                HStack(spacing: 0) {
                    statCell(value: "\(ergebnis.richtigCount)",    label: "Richtig",    color: .green)
                    Divider().frame(height: 40)
                    statCell(value: "\(ergebnis.teilweiseCount)",  label: "Teilweise",  color: .orange)
                    Divider().frame(height: 40)
                    statCell(value: "\(ergebnis.falschCount)",     label: "Falsch",     color: .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 18)

                // Lehrer-Feedback
                if !ergebnis.lehrerFeedback.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(accent)
                            Text("Lehrerfeedback")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(accent)
                        }
                        Text(ergebnis.lehrerFeedback)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.2), lineWidth: 1))
                    )
                    .padding(.horizontal, 18)
                }

                // Per-question results
                VStack(alignment: .leading, spacing: 10) {
                    Text("Aufgaben im Detail")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 22)

                    VStack(spacing: 10) {
                        ForEach(ergebnis.bewertungen) { b in
                            aufgabeCard(b)
                        }
                    }
                    .padding(.horizontal, 18)
                }

                // Dismiss button
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Fertig")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [accent, Color(red: 0.10, green: 0.72, blue: 1.00)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) {
                circleTrim = 1.0
                numberOpacity = 1.0
            }
        }
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func aufgabeCard(_ b: AufgabeBewertung) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: b.status.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(b.status.farbe)
                Text("Aufgabe \(b.nummer)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(b.erreichtePunkte) / \(b.maxPunkte) P.")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(b.status.farbe)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(b.status.farbe.opacity(0.1)))
            }

            // Task text
            if !b.aufgabeText.isEmpty {
                Text(b.aufgabeText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Student answer
            if let antwort = b.schuelerAntwort, !antwort.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    Label("Schülerantwort", systemImage: "pencil")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(antwort)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                }
            }

            // Explanation / correction
            if let erklaerung = b.erklaerung, !erklaerung.isEmpty {
                if b.schuelerAntwort == nil { Divider() }
                VStack(alignment: .leading, spacing: 3) {
                    Label("Korrektur", systemImage: b.status == .teilweise ? "exclamationmark.circle" : "xmark.circle")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(b.status.farbe.opacity(0.8))
                    Text(erklaerung)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                }
            }

            // Improvement hint
            if let verbesserung = b.verbesserung, !verbesserung.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Richtige Antwort", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.8))
                    Text(verbesserung)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(b.status.farbe.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
