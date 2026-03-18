import SwiftUI

struct KILernsetChatView: View {
    let setName: String
    let subjectName: String
    var onSaved: ((LernSet) -> Void)? = nil

    @StateObject private var viewModel = KILernsetViewModel()
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss
    @FocusState private var themaFocused: Bool

    @State private var isGeneratingOverlay = false
    @State private var generationProgress: Double = 0

    private let accent = AppColors.brandPurple

    private var themenVorschläge: [String] {
        switch subjectName {
        case "Mathematik":  return ["Pythagoras", "Quadratische Gl.", "Statistik", "Trigonometrie", "Geometrie"]
        case "Biologie":    return ["Photosynthese", "Zellteilung", "Genetik", "Ökosysteme", "Evolution"]
        case "Chemie":      return ["Atombau", "Periodensystem", "Säuren & Basen", "Reaktionen", "Organische Chemie"]
        case "Physik":      return ["Mechanik", "Elektromagnetismus", "Optik", "Thermodynamik", "Wellen"]
        case "Geschichte":  return ["Weimarer Republik", "2. Weltkrieg", "Franz. Revolution", "Römer", "Kalter Krieg"]
        case "Englisch":    return ["Simple Past", "Present Perfect", "Vokabeln", "Grammatik", "Textanalyse"]
        case "Deutsch":     return ["Grammatik", "Literaturanalyse", "Rechtschreibung", "Aufsatz", "Gedichtinterpretation"]
        case "Geographie":  return ["Klimazonen", "Kontinente", "Bevölkerung", "Wirtschaft", "Naturkatastrophen"]
        case "Informatik":  return ["Algorithmen", "Datenstrukturen", "Python Basics", "Netzwerke", "Datenbanken"]
        default:            return ["Grundlagen", "Zusammenfassung", "Prüfungsvorbereitung", "Fachbegriffe"]
        }
    }

    private let schwierigkeitOptionen: [(label: String, subtitle: String, color: Color)] = [
        ("Leicht",  "Grundwissen",    Color(red: 0.15, green: 0.70, blue: 0.40)),
        ("Mittel",  "Gemischt",       Color(red: 0.86, green: 0.50, blue: 0.10)),
        ("Schwer",  "Anspruchsvoll",  Color(red: 0.85, green: 0.22, blue: 0.22)),
    ]

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        themaSection
                        schwierigkeitSection
                        anzahlSection
                        besonderheitenSection
                        if !viewModel.verlauf.isEmpty {
                            verlaufSection
                        }
                        generateButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }

            if isGeneratingOverlay {
                TheoGeneratingOverlay(progress: $generationProgress)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isGeneratingOverlay)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.fach = subjectName }
        .onChange(of: viewModel.showPreview) { _, shown in
            if shown {
                withAnimation { generationProgress = 100 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { isGeneratingOverlay = false }
                }
            }
        }
        .sheet(isPresented: $viewModel.showPreview) {
            KILernsetPreviewView(
                cards: viewModel.generatedCards,
                setName: setName,
                subjectName: subjectName,
                onSaved: onSaved
            )
            .environmentObject(store)
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
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 1) {
                Text("KI-Lernset erstellen")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(subjectName)
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

    // MARK: - Thema

    private var themaSection: some View {
        sectionCard(title: "Thema *") {
            VStack(alignment: .leading, spacing: 0) {
                TextField("z. B. Photosynthese, Pythagoras …", text: $viewModel.thema)
                    .font(.system(size: 16))
                    .focused($themaFocused)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                Divider().padding(.leading, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(themenVorschläge, id: \.self) { vorschlag in
                            Button {
                                viewModel.thema = vorschlag
                                themaFocused = false
                            } label: {
                                Text(vorschlag)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(viewModel.thema == vorschlag ? .white : accent)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(
                                            viewModel.thema == vorschlag
                                                ? AnyShapeStyle(accent)
                                                : AnyShapeStyle(accent.opacity(0.10))
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.thema)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Schwierigkeit

    private var schwierigkeitSection: some View {
        sectionCard(title: "Schwierigkeit") {
            HStack(spacing: 8) {
                ForEach(schwierigkeitOptionen, id: \.label) { option in
                    let isSelected = viewModel.schwierigkeit == option.label
                    Button { viewModel.schwierigkeit = option.label } label: {
                        VStack(spacing: 4) {
                            Text(option.label)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? .white : .primary)
                            Text(option.subtitle)
                                .font(.system(size: 10))
                                .foregroundStyle(isSelected ? .white.opacity(0.80) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected
                                      ? AnyShapeStyle(option.color)
                                      : AnyShapeStyle(Color(uiColor: .tertiarySystemGroupedBackground)))
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.schwierigkeit)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Anzahl

    private var anzahlSection: some View {
        sectionCard(title: "Anzahl Fragen") {
            VStack(spacing: 6) {
                Text("\(Int(viewModel.anzahl))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.anzahl)

                HStack(spacing: 10) {
                    Text("5")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    Slider(value: $viewModel.anzahl, in: 5...30, step: 1)
                        .tint(accent)
                    Text("30")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }

                Text("Fragen werden generiert")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
    }

    // MARK: - Besonderheiten

    private var besonderheitenSection: some View {
        sectionCard(title: "Besonderheiten (optional)") {
            TextField("z. B. mit Beispielen, Fokus auf Formeln, für Prüfung …",
                      text: $viewModel.besonderheiten, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...4)
                .padding(16)
        }
    }

    // MARK: - Verlauf

    private var verlaufSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ZULETZT VERWENDET")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.verlauf, id: \.self) { thema in
                        Button { viewModel.thema = thema } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(thema)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    @ViewBuilder
    private var generateButton: some View {
        VStack(spacing: 10) {
            Button {
                guard viewModel.canGenerate else { return }
                themaFocused = false
                generationProgress = 0
                withAnimation { isGeneratingOverlay = true }
                startFakeProgress()
                Task { await viewModel.generateLernSet() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Lernset erstellen")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .shadow(color: accent.opacity(viewModel.canGenerate ? 0.40 : 0.10),
                                radius: 12, x: 0, y: 6)
                )
                .opacity(viewModel.canGenerate ? 1.0 : 0.45)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGenerate)

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Helpers

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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }
}

// MARK: - Theo Generating Overlay

private struct TheoGeneratingOverlay: View {
    @Binding var progress: Double
    private let accent = AppColors.brandPurple

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 28) {
                MascotView(color: accent, mood: .celebrating, size: 110)
                    .frame(height: 130)
                VStack(spacing: 8) {
                    Text("Ich erstelle dein Lernset …")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Theo arbeitet auf Hochtouren für dich! 🔥")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.15), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress / 100))
                        .stroke(
                            LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
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
