import SwiftUI

struct CardSetStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var setToEdit: LernSet? = nil
    @State private var selectedSet: LernSet? = nil

    private let gradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                 Color(red: 0.30, green: 0.52, blue: 0.98)],
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
        }
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

    // MARK: Nav Bar
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

    // MARK: Create Hero Button
    private var createHeroButton: some View {
        Button { showCreator = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neues Karteikarten-Set")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Erstelle manuell deine eigenen Karten")
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
                    .shadow(color: Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.42),
                            radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: My Files
    @ViewBuilder
    private var myFilesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Dateien")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            let cardSets = store.lernSets.filter { !$0.isKIGenerated && !$0.isVokabelSet }
            if cardSets.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "Noch keine Lernsets",
                    subtitle: "Erstelle dein erstes Karteikarten-Set und es erscheint hier."
                )
                .frame(height: 220)
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
                        .fill(Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90))
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
            Button {
                setToEdit = set
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            Button(role: .destructive) {
                store.delete(set)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(set)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                setToEdit = set
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

