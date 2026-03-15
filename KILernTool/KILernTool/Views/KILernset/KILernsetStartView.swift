import SwiftUI

struct KILernsetStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var selectedSet: LernSet? = nil
    @State private var showIntro = true

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    private let aiGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                 Color(red: 0.30, green: 0.52, blue: 0.98)],
        startPoint: .topLeading, endPoint: .bottomTrailing
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
                TheoIntroOverlay {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        showIntro = false
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(20)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showIntro)
        .fullScreenCover(isPresented: $showCreator) {
            KILernsetCreateView(onSaved: { savedSet in
                showCreator = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedSet = savedSet
                }
            })
            .environmentObject(store)
        }
        .sheet(item: $selectedSet) { set in
            NavigationStack {
                LernsetViewerView(lernSet: set)
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
            Text("KI Lernset")
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
                MascotView(color: .white, mood: .talking, size: 52)
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("KI Lernset erstellen")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Theo erstellt automatisch Fragen für dich")
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
                    .fill(aiGradient)
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

            let kiSets = store.lernSets.filter { $0.isKIGenerated && !$0.isScanResult }
            if kiSets.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "Noch keine KI-Lernsets",
                    subtitle: "Erstelle dein erstes KI-Lernset und es erscheint hier."
                )
                .frame(height: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(kiSets) { set in
                        lernSetRow(set)
                    }
                }
            }
        }
    }

    private func lernSetRow(_ set: LernSet) -> some View {
        Button { selectedSet = set } label: {
            HStack(spacing: 14) {
                MascotIconView(
                    color: accent,
                    size: 42,
                    cornerRadius: 10
                )
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
    }
}

// MARK: - Theo Intro Overlay

private struct TheoIntroOverlay: View {
    let onContinue: () -> Void

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    private let introText = "Hey, ich bin **Theo** – dein persönlicher KI-Lernassistent! 🚀\n\nSag mir einfach Fach, Thema und wie viele Karten du brauchst – und ich erstelle dein perfektes Lernset in Sekunden.\n\nBereit? Dann lass uns loslegen! 🎉"

    @State private var displayed: String = ""
    @State private var textDone = false

    var body: some View {
        ZStack {
            // Blurred backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .blur(radius: 0)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Mascot
                    MascotView(
                        color: accent,
                        mood: .talking,
                        size: 100
                    )
                    .padding(.top, 32)

                    // Name badge
                    HStack(spacing: 6) {
                        Text("THEO")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(accent)
                        Text("· KI-Lernassistent")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(accent.opacity(0.10))
                            .overlay(Capsule().stroke(accent.opacity(0.2), lineWidth: 1))
                    )

                    // Typewriter text
                    Text(try! AttributedString(
                        markdown: displayed,
                        options: AttributedString.MarkdownParsingOptions(
                            interpretedSyntax: .inlineOnlyPreservingWhitespace
                        )
                    ))
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .animation(nil, value: displayed)

                    // Button
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Text("Loslegen!")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: accent.opacity(0.40), radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(textDone ? 1.0 : 0.5)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 28)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: -8)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task { await typeText() }
    }

    private func typeText() async {
        let full = introText
        var idx = full.startIndex
        while idx < full.endIndex {
            let remaining = full.distance(from: idx, to: full.endIndex)
            let step = min(3, remaining)
            let next = full.index(idx, offsetBy: step)
            displayed = String(full[full.startIndex..<next])
            idx = next
            try? await Task.sleep(nanoseconds: 12_000_000)
        }
        withAnimation { textDone = true }
    }
}
