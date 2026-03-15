import SwiftUI

struct LearnModeSelectionView: View {
    let lernSet: LernSet

    private let minMC = 4

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
                        Text("MODUS WÄHLEN")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {

                            // Anschauen (always available)
                            NavigationLink {
                                VokabelAnschauView(lernSet: lernSet)
                            } label: {
                                modeCard(
                                    icon: "eye.fill",
                                    color: Color(red: 0.30, green: 0.52, blue: 0.98),
                                    title: "Anschauen",
                                    subtitle: "Alle Karten durchblättern – Vorderseite & Rückseite",
                                    detail: "\(lernSet.cards.count) Karten",
                                    locked: false
                                )
                            }
                            .buttonStyle(.plain)

                            // Karteikarten (always available)
                            NavigationLink {
                                FlashcardSessionView(lernSet: lernSet)
                            } label: {
                                modeCard(
                                    icon: "rectangle.on.rectangle.angled.fill",
                                    color: Color(red: 0.10, green: 0.64, blue: 0.54),
                                    title: "Karteikarten",
                                    subtitle: "Karte umdrehen – Richtig oder Falsch wählen",
                                    detail: "\(lernSet.cards.count) Karten",
                                    locked: false
                                )
                            }
                            .buttonStyle(.plain)

                            // Schnell lernen (≥ 4 cards)
                            if lernSet.cards.count >= minMC {
                                NavigationLink {
                                    QuickLearnView(lernSet: lernSet)
                                } label: {
                                    modeCard(
                                        icon: "bolt.fill",
                                        color: Color(red: 0.95, green: 0.55, blue: 0.10),
                                        title: "Schnell lernen",
                                        subtitle: "Alle Karten als Multiple-Choice – flott durch den Stoff",
                                        detail: "\(lernSet.cards.count) Karten",
                                        locked: false
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                modeCard(
                                    icon: "bolt.fill",
                                    color: Color(uiColor: .tertiaryLabel),
                                    title: "Schnell lernen",
                                    subtitle: "Mindestens \(minMC) Karten erforderlich (\(lernSet.cards.count)/\(minMC))",
                                    detail: "",
                                    locked: true
                                )
                            }

                            // Auswendig lernen (≥ 4 cards)
                            if lernSet.cards.count >= minMC {
                                NavigationLink {
                                    MemorizeLearnView(lernSet: lernSet)
                                } label: {
                                    modeCard(
                                        icon: "brain.head.profile",
                                        color: Color(red: 0.15, green: 0.60, blue: 0.40),
                                        title: "Auswendig lernen",
                                        subtitle: "Stationsweise: Multiple-Choice & eigene Antworten eingeben",
                                        detail: "\(stationCount) Stationen",
                                        locked: false
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                modeCard(
                                    icon: "brain.head.profile",
                                    color: Color(uiColor: .tertiaryLabel),
                                    title: "Auswendig lernen",
                                    subtitle: "Mindestens \(minMC) Karten erforderlich (\(lernSet.cards.count)/\(minMC))",
                                    detail: "",
                                    locked: true
                                )
                            }

                            // Testmodus (≥ 4 cards)
                            if lernSet.cards.count >= minMC {
                                NavigationLink {
                                    TestModusView(lernSet: lernSet)
                                } label: {
                                    modeCard(
                                        icon: "checkmark.seal.fill",
                                        color: Color(red: 0.85, green: 0.25, blue: 0.45),
                                        title: "Testmodus",
                                        subtitle: "Timed Test – alle Karten abfragen",
                                        detail: "\(lernSet.cards.count) Karten",
                                        locked: false
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                modeCard(
                                    icon: "checkmark.seal.fill",
                                    color: Color(uiColor: .tertiaryLabel),
                                    title: "Testmodus",
                                    subtitle: "Mindestens \(minMC) Karten erforderlich (\(lernSet.cards.count)/\(minMC))",
                                    detail: "",
                                    locked: true
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Lernmodus")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stationCount: Int {
        max(1, (lernSet.cards.count + 2) / 3)
    }

    private func modeCard(icon: String, color: Color, title: String, subtitle: String, detail: String, locked: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(locked ? 0.07 : 0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(locked ? .secondary : .primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color)
                        .padding(.top, 2)
                }
            }
            Spacer()
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(locked ? 0.02 : 0.04), radius: 8, x: 0, y: 2)
        )
        .opacity(locked ? 0.7 : 1.0)
    }
}
