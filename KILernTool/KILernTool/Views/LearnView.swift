import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: LernSetStore
    @State private var showSearch = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    searchBarButton

                    // Theo motivation banner
                    TheoLearnBanner(totalSets: store.lernSets.count)

                    // Fällige Karten Banner (SRS)
                    if store.totalCardsDueToday > 0 {
                        DueCardsBanner(count: store.totalCardsDueToday, sets: store.setsDueToday)
                            .environmentObject(store)
                    }

                    Text("Deine Fächer")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 2)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Subject.all) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject)
                                    .environmentObject(store)
                            } label: {
                                SubjectFolderCard(
                                    subject: subject,
                                    setCount: store.lernSets(for: subject.name).count
                                )
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(isPresented: $showSearch)
            }
        }
    }

    private var searchBarButton: some View {
        Button { showSearch = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Lernsets suchen…")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Due Cards Banner (SRS)

struct DueCardsBanner: View {
    let count: Int
    let sets: [LernSet]
    @EnvironmentObject var store: LernSetStore
    @State private var navigateTo: LernSet? = nil

    var body: some View {
        Button {
            // Navigate to the first set with due cards
            navigateTo = sets.first
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Karte\(count == 1 ? "" : "n") zum Wiederholen fällig")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Stärke dein Gedächtnis mit Spaced Repetition")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.20), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .sheet(item: $navigateTo) { set in
            NavigationStack {
                DueCardsView(lernSet: set)
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Subject Folder Card

struct SubjectFolderCard: View {
    let subject: Subject
    let setCount: Int

    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Colored top area
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [subject.color, subject.color.opacity(0.72)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(height: 80)
                        .overlay(
                            ZStack {
                                Circle().fill(Color.white.opacity(0.10)).frame(width: 70, height: 70).offset(x: 30, y: -20)
                                Circle().fill(Color.white.opacity(0.06)).frame(width: 44, height: 44).offset(x: 55, y:  20)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        )
                    Image(systemName: subject.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(14)
                }

                // Label
                VStack(alignment: .leading, spacing: 3) {
                    Text(subject.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(setCount == 0
                         ? "Keine Lernsets"
                         : "\(setCount) Lernset\(setCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: subject.color.opacity(0.22), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Theo Learn Banner

private struct TheoLearnBanner: View {
    let totalSets: Int
    private let accent = AppColors.brandPurple

    private let tips = [
        "Kleine Lerneinheiten sind effektiver als lange Sessions! 💡",
        "Regelmäßigkeit schlägt Intensität – jeden Tag ein bisschen! 🔥",
        "Teste dein Wissen aktiv, nicht nur passiv lesen. 🎯",
        "Nach 20 Minuten Lernen kurz pausieren – hilft dem Gehirn! 🧠",
        "Erkläre Gelerntes mit eigenen Worten – das festigt es! ✍️",
    ]

    private var tip: String {
        tips[Calendar.current.component(.day, from: Date()) % tips.count]
    }

    @State private var displayedTip = ""
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Pulsing Theo
            Group {
                PulseGlowMascotView(color: accent, size: 52)
            }
            .frame(width: 66, height: 66, alignment: .center)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("Tipp des Tages")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                    if totalSets > 0 {
                        Text("· \(totalSets) Sets")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(displayedTip)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineLimit(3)
                    .frame(minHeight: 16, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.10), Color(red: 0.30, green: 0.52, blue: 0.98).opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .task {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.78)) { appeared = true }
            try? await Task.sleep(nanoseconds: 350_000_000)
            await typeTip()
        }
    }

    private func typeTip() async {
        let words = tip.components(separatedBy: " ")
        for (i, word) in words.enumerated() {
            guard !Task.isCancelled else { return }
            displayedTip += (i == 0 ? "" : " ") + word
            try? await Task.sleep(nanoseconds: 65_000_000)
        }
    }
}
