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
                            .buttonStyle(.plain)
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
