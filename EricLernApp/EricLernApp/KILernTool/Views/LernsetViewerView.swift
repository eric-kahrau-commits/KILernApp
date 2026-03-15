import SwiftUI

struct LernsetViewerView: View {
    let lernSet: LernSet

    private var subjectColor: Color {
        Subject.all.first { $0.name == lernSet.subject }?.color
            ?? Color(red: 0.38, green: 0.18, blue: 0.90)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(lernSet.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("MODI")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            if lernSet.isKIGenerated {
                                NavigationLink {
                                    LearnModeSelectionView(lernSet: lernSet)
                                } label: {
                                    modeRow(
                                        icon: "brain.head.profile",
                                        color: Color(red: 0.15, green: 0.60, blue: 0.40),
                                        title: "Lernen-Modus",
                                        subtitle: "Lerne mit Multiple-Choice und Freitexteingaben"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    AnschauModusView(lernSet: lernSet)
                                } label: {
                                    modeRow(
                                        icon: "tablecells",
                                        color: Color(red: 0.38, green: 0.18, blue: 0.90),
                                        title: "Anschau-Modus",
                                        subtitle: "Alle Fragen und Antworten auf einen Blick"
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            NavigationLink {
                                FlashcardSessionView(lernSet: lernSet)
                            } label: {
                                modeRow(
                                    icon: "rectangle.on.rectangle.angled",
                                    color: subjectColor,
                                    title: "Karteikarten-Modus",
                                    subtitle: "Vorderseite ansehen, umklappen, richtig oder falsch wählen"
                                )
                            }
                            .buttonStyle(.plain)

                            if lernSet.isKIGenerated {
                                NavigationLink {
                                    TestModusView(lernSet: lernSet)
                                } label: {
                                    modeRow(
                                        icon: "pencil.and.list.clipboard",
                                        color: Color(red: 0.25, green: 0.25, blue: 0.80),
                                        title: "Testmodus",
                                        subtitle: "Alle Fragen eingeben – Schulnote am Ende"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func modeRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Anschau-Modus

struct AnschauModusView: View {
    let lernSet: LernSet

    @State private var questionCard: LernSetCard? = nil
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("FRAGE").frame(maxWidth: .infinity, alignment: .leading)
                        Text("ANTWORT").frame(maxWidth: .infinity, alignment: .leading)
                        Color.clear.frame(width: 36)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))

                    ForEach(Array(lernSet.cards.enumerated()), id: \.element.id) { idx, card in
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("F\(idx + 1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(accent)
                                        .padding(.horizontal, 7).padding(.vertical, 2)
                                        .background(Capsule().fill(accent.opacity(0.10)))
                                    Text(card.question)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text(card.answer)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Menu {
                                    Button {
                                        questionCard = card
                                    } label: {
                                        Label("Frage stellen", systemImage: "bubble.left.and.bubble.right")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .contentShape(Rectangle())
                                }
                                .menuStyle(.button)
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(idx % 2 == 0
                                ? Color(uiColor: .secondarySystemGroupedBackground)
                                : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))

                            if idx < lernSet.cards.count - 1 { Divider() }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Anschau-Modus")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $questionCard) { card in
            CardQuestionView(card: card)
        }
    }
}
