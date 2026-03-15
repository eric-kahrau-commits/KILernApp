import SwiftUI

struct SubjectDetailView: View {
    let subject: Subject
    @EnvironmentObject var store: LernSetStore
    @State private var showCreate = false

    private var subjectSets: [LernSet] { store.lernSets(for: subject.name) }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if subjectSets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Noch keine Lernsets")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("Erstelle ein Lernset für \(subject.name) und es erscheint hier.")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(subjectSets) { set in
                                NavigationLink {
                                    LearnModeSelectionView(lernSet: set)
                                } label: {
                                    lernSetRow(set)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showCreate) {
            KILernsetStartView().environmentObject(store)
        }
    }

    // MARK: - LernSet Row
    private func lernSetRow(_ set: LernSet) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(subject.color.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(subject.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(set.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("\(set.cards.count) Karten")
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
}
