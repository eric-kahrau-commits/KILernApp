import SwiftUI

struct VokabelStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var showCreate = false
    @State private var selectedSet: LernSet? = nil

    private let accent = Color(red: 0.86, green: 0.50, blue: 0.10)
    private let gradient = LinearGradient(
        colors: [Color(red: 0.86, green: 0.50, blue: 0.10), Color(red: 1.00, green: 0.72, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var vokabelSets: [LernSet] {
        store.lernSets.filter { $0.isVokabelSet }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView {
                        VStack(spacing: 24) {
                            createHeroButton
                            setsSection
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCreate) {
                VokabelCreateView()
                    .environmentObject(store)
            }
            .sheet(item: $selectedSet) { set in
                NavigationStack {
                    VokabelDetailView(lernSet: set)
                        .environmentObject(store)
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
            Text("Vokabelset")
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
    private var createHeroButton: some View {
        Button { showCreate = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neues Vokabelset")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Vokabeln eingeben und sofort lernen")
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
                    .shadow(color: accent.opacity(0.42), radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sets Section
    @ViewBuilder
    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Vokabelsets")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if vokabelSets.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "character.bubble")
                        .font(.system(size: 40))
                        .foregroundStyle(accent.opacity(0.4))
                    Text("Noch keine Vokabelsets")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("Erstelle dein erstes Set mit dem Button oben.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                VStack(spacing: 10) {
                    ForEach(vokabelSets) { set in
                        setRow(set)
                    }
                }
            }
        }
    }

    private func setRow(_ set: LernSet) -> some View {
        Button { selectedSet = set } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(set.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("\(set.subject) · \(set.cards.count) Vokabeln")
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(set)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}
