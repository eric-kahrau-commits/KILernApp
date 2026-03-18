import SwiftUI

// MARK: - Start View (saved scans overview)

struct ScanStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var showSetup = false
    @State private var selectedSet: LernSet? = nil
    @State private var showIntro = !UserDefaults.standard.bool(forKey: "introSeen_scan")

    private let accent = AppColors.brandTeal
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
            ModeIntroView(
                characterName: "Kristin",
                characterRole: "KI-Scan-Assistentin",
                gradientTop: Color(red: 0.85, green: 0.20, blue: 0.22),
                gradientBottom: Color(red: 0.65, green: 0.10, blue: 0.10),
                mascotColor: .white,
                introText: "Hey, ich bin **Kristin** – deine KI-Scan-Assistentin! 📱\n\nIch lese deine Buchseiten und Texte, erkenne den Inhalt automatisch und erstelle daraus eine **Zusammenfassung** oder ein komplettes **Lernset**.\n\nEinfach fotografieren – ich erledige den Rest! ✨",
                defaultsKey: "introSeen_scan"
            ) {
                withAnimation(.easeOut(duration: 0.35)) { showIntro = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showSetup = true }
            }
            .transition(.opacity)
            .zIndex(20)
        }
        } // outer ZStack
        .animation(.easeOut(duration: 0.35), value: showIntro)
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
            .accessibilityLabel("Schließen")
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

    private let accent = AppColors.brandTeal

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

