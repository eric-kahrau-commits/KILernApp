import SwiftUI

// MARK: - Start View (saved scans overview)

struct ScanStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var showSetup = false
    @State private var selectedSet: LernSet? = nil
    @State private var showIntro = true

    private let accent = Color(red: 0.12, green: 0.58, blue: 0.46)
    private let kristinRed = Color(red: 0.85, green: 0.20, blue: 0.22)
    private let gradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.58, blue: 0.46), Color(red: 0.20, green: 0.80, blue: 0.60)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var scanSets: [LernSet] {
        store.lernSets.filter { $0.isScanResult }
    }

    var body: some View {
        ZStack {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        heroButton
                        savedSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showSetup) {
            ScanSetupView()
                .environmentObject(store)
        }
        .sheet(item: $selectedSet) { set in
            NavigationStack {
                LearnModeSelectionView(lernSet: set)
            }
        }

        if showIntro {
            KristinIntroOverlay {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showIntro = false }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(20)
        }
        } // outer ZStack
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showIntro)
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
            Text("Scannen")
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

    // MARK: - Hero Button

    private var heroButton: some View {
        Button { showSetup = true } label: {
            HStack(spacing: 16) {
                MascotView(color: .white, mood: .happy, size: 48)
                    .frame(width: 48, height: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neuen Scan starten")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Buchseiten oder Texte scannen & verarbeiten")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.80))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: accent.opacity(0.40), radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Saved Scans

    @ViewBuilder
    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Scans")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if scanSets.isEmpty {
                EmptyStateView(
                    icon: "doc.viewfinder",
                    title: "Noch keine Scans",
                    subtitle: "Starte deinen ersten Scan und es erscheint hier."
                )
                .frame(height: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(scanSets) { set in
                        scanRow(set)
                    }
                }
            }
        }
    }

    private func scanRow(_ set: LernSet) -> some View {
        Button { selectedSet = set } label: {
            HStack(spacing: 14) {
                MascotIconView(color: kristinRed, size: 42, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(set.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("\(set.subject) · \(set.cards.count) Karten")
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
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { store.delete(set) } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

// MARK: - Setup View (name + subject before scanning)

struct ScanSetupView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var scanName: String = ""
    @State private var selectedSubject: String = Subject.all.first?.name ?? ""
    @State private var showScanner = false

    private let accent = Color(red: 0.12, green: 0.58, blue: 0.46)

    private var canProceed: Bool {
        !scanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            kristinSetupBanner
                            nameSection
                            subjectSection
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    startButton
                }
            }
            .navigationTitle("Scan vorbereiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .navigationDestination(isPresented: $showScanner) {
                ScanZusammenfassenView(
                    initialName: scanName.trimmingCharacters(in: .whitespacesAndNewlines),
                    initialSubject: selectedSubject
                )
                .environmentObject(store)
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                // Default name: "Scan vom <Datum>"
                if scanName.isEmpty {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "dd.MM.yyyy"
                    scanName = "Scan vom \(fmt.string(from: Date()))"
                }
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            TextField("z. B. Biologie Kapitel 4", text: $scanName)
                .font(.system(size: 16))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }

    // MARK: - Subject Section

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FACH")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Subject.all) { subject in
                    Button { selectedSubject = subject.name } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(subject.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: subject.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(subject.color)
                            }
                            Text(subject.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSubject == subject.name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if subject.name != Subject.all.last?.name {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                if canProceed { showScanner = true }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Scan starten")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canProceed
                              ? LinearGradient(colors: [accent, Color(red: 0.20, green: 0.80, blue: 0.60)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                               startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Kristin Setup Banner

    private var kristinSetupBanner: some View {
        let kristinRed = Color(red: 0.85, green: 0.20, blue: 0.22)
        return HStack(spacing: 14) {
            MascotIconView(color: kristinRed, size: 48, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text("KRISTIN")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(kristinRed)
                    .tracking(1.5)
                Text("Gib dem Scan einen Namen und wähle das Fach – dann kann ich loslegen! 📄")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(kristinRed.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(kristinRed.opacity(0.22), lineWidth: 1))
        )
    }
}

// MARK: - Kristin Intro Overlay

private struct KristinIntroOverlay: View {
    let onDismiss: () -> Void

    private let kristinRed = Color(red: 0.85, green: 0.20, blue: 0.22)
    private let fullText = "Hey! Ich bin **Kristin**, deine KI-Scan-Assistentin! 📱\n\nIch lese deine Buchseiten und Texte, erkenne den Inhalt automatisch und erstelle daraus eine **Zusammenfassung** oder ein komplettes **Lernset**.\n\nEinfach fotografieren – ich erledige den Rest! ✨"

    @State private var displayedText: String = ""
    @State private var mascotMood: MascotMood = .thinking
    @State private var isDone: Bool = false
    @State private var mascotScale: CGFloat = 0.65
    @State private var cardOffset: CGFloat = 80
    @State private var beamOffset: CGFloat = -65
    @State private var pulseScale: CGFloat = 0.85
    @State private var pulseOpacity: Double = 0.7

    var body: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    // Mascot with scanning beam animation
                    ZStack {
                        // Pulsing outer ring
                        Circle()
                            .stroke(kristinRed.opacity(0.35), lineWidth: 3)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)

                        // Background glow
                        Circle()
                            .fill(kristinRed.opacity(0.10))
                            .frame(width: 132, height: 132)

                        // Mascot
                        MascotView(color: kristinRed, mood: mascotMood, size: 96)
                            .frame(width: 96, height: 110)

                        // Scanning laser beam (clipped to circle)
                        Circle()
                            .fill(.clear)
                            .frame(width: 132, height: 132)
                            .overlay(
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [.clear, kristinRed.opacity(0.55), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                    .frame(height: 20)
                                    .offset(y: beamOffset)
                            )
                            .clipShape(Circle())
                    }
                    .scaleEffect(mascotScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            beamOffset = 65
                        }
                        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                            pulseScale = 1.18
                            pulseOpacity = 0
                        }
                    }

                    // Name badge
                    HStack(spacing: 6) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(kristinRed)
                        Text("KRISTIN · KI-Scan-Assistentin")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(kristinRed)
                            .tracking(0.6)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(kristinRed.opacity(0.10)))

                    // Typewriter text
                    Group {
                        if isDone {
                            Text(try! AttributedString(markdown: fullText,
                                 options: AttributedString.MarkdownParsingOptions(
                                     interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        } else {
                            Text(displayedText)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                    // Los geht's button
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Scan starten!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDone
                                      ? LinearGradient(
                                            colors: [kristinRed, Color(red: 0.60, green: 0.10, blue: 0.10)],
                                            startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                                       startPoint: .leading, endPoint: .trailing))
                                .shadow(color: isDone ? kristinRed.opacity(0.40) : .clear, radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isDone)
                }
                .padding(26)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.20), radius: 32, x: 0, y: -6)
                )
                .offset(y: cardOffset)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.70)) {
                mascotScale = 1.0
                cardOffset = 0
            }
            startTypewriter()
        }
    }

    private func startTypewriter() {
        Task {
            var idx = fullText.startIndex
            while idx < fullText.endIndex {
                let remaining = fullText.distance(from: idx, to: fullText.endIndex)
                let step = min(3, remaining)
                let nextIdx = fullText.index(idx, offsetBy: step)
                displayedText = String(fullText[fullText.startIndex..<nextIdx])
                idx = nextIdx
                try? await Task.sleep(nanoseconds: 11_000_000)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                mascotMood = .happy
                isDone = true
            }
        }
    }
}
