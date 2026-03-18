import SwiftUI

struct CardSetStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var setToEdit: LernSet? = nil
    @State private var selectedSet: LernSet? = nil
    @State private var showIntro = !UserDefaults.standard.bool(forKey: "introSeen_cardset")

    private let accent = AppColors.brandTealBright
    private let gradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.68, blue: 0.58),
                 Color(red: 0.10, green: 0.82, blue: 0.72)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        createHeroButton
                        myFilesSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }

            if showIntro {
                ModeIntroView(
                    characterName: "Jonathan",
                    characterRole: "Karteikartentrainer",
                    gradientTop: Color(red: 0.05, green: 0.68, blue: 0.58),
                    gradientBottom: Color(red: 0.03, green: 0.48, blue: 0.42),
                    mascotColor: .white,
                    introText: "Hey, ich bin **Jonathan** – dein Karteikartentrainer! 🃏\n\nMit mir erstellst du deine eigenen Lernkarten – Vorderseite, Rückseite, sogar mit Bildern. Danach lernst du mit Karteikarten-, Multiple-Choice- oder Schreibmodus.\n\nPerfekt für alle Fächer. Los geht's!",
                    defaultsKey: "introSeen_cardset"
                ) {
                    withAnimation(.easeOut(duration: 0.35)) { showIntro = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCreator = true }
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.35), value: showIntro)
        .fullScreenCover(isPresented: $showCreator) {
            CardSetCreateView()
                .environmentObject(store)
        }
        .sheet(item: $setToEdit) { set in
            NavigationStack {
                CardSetEditorView(
                    setName: set.name,
                    subjectName: set.subject,
                    existingSet: set,
                    onFinished: { }
                )
                .environmentObject(store)
            }
        }
        .sheet(item: $selectedSet) { set in
            NavigationStack {
                LearnModeSelectionView(lernSet: set)
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
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Karteikartenset")
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

    // MARK: - Create Hero Button
    private var createHeroButton: some View {
        Button { showCreator = true } label: {
            HStack(spacing: 16) {
                MascotView(color: .white, mood: .talking, size: 52)
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neues Karteikartenset")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Jonathan hilft dir beim Erstellen deiner Karten")
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
                    .shadow(color: accent.opacity(0.45), radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Files
    @ViewBuilder
    private var myFilesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Dateien")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            let cardSets = store.lernSets.filter { !$0.isKIGenerated && !$0.isVokabelSet }
            if cardSets.isEmpty {
                VStack(spacing: 16) {
                    MascotView(color: accent, mood: .thinking, size: 56)
                    Text("Noch keine Lernsets")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("Erstelle dein erstes Karteikartenset und es erscheint hier.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
            } else {
                VStack(spacing: 10) {
                    ForEach(cardSets) { set in
                        lernSetRow(set)
                    }
                }
            }
        }
    }

    private func lernSetRow(_ set: LernSet) -> some View {
        Button { selectedSet = set } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                }
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
                    .font(.system(size: 13, weight: .semibold))
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
        .contextMenu {
            Button { setToEdit = set } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            Button(role: .destructive) { store.delete(set) } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { store.delete(set) } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { setToEdit = set } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            .tint(accent)
        }
    }
}
