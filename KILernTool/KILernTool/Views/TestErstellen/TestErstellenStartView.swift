import SwiftUI

struct TestErstellenStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lernSetStore: LernSetStore

    @StateObject private var store = GeneratedTestStore.shared
    @State private var showCreate = false
    @State private var showKorrigieren = false
    @State private var selectedTest: GeneratedTest? = nil
    @State private var showIntro = true

    private let accent = Color(red: 0.85, green: 0.25, blue: 0.45)

    var body: some View {
        ZStack {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Create button
                        createButton

                        // Correct button
                        korrigierenButton

                        // Test list
                        if store.tests.isEmpty {
                            emptyState
                        } else {
                            testList
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Tests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .fullScreenCover(isPresented: $showCreate) {
                CreateTestView()
                    .environmentObject(lernSetStore)
            }
            .fullScreenCover(isPresented: $showKorrigieren) {
                TestKorrigierenView()
            }
            .navigationDestination(item: $selectedTest) { test in
                GeneratedTestView(test: test)
            }
        }

        if showIntro {
            MaxIntroOverlay {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showIntro = false }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(20)
        }
        } // end outer ZStack
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showIntro)
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button { showCreate = true } label: {
            HStack(spacing: 14) {
                MascotIconView(color: accent, size: 44, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Neuen Test erstellen")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("KI erstellt ein vollständiges Arbeitsblatt")
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
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Korrigieren Button

    private var korrigierenButton: some View {
        Button { showKorrigieren = true } label: {
            HStack(spacing: 14) {
                MascotIconView(color: Color.blue, size: 44, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test korrigieren")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Foto aufnehmen – KI bewertet die Antworten")
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
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Test List

    private var testList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meine Tests")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(store.tests) { test in
                    testRow(test)
                }
            }
        }
    }

    private func testRow(_ test: GeneratedTest) -> some View {
        Button { selectedTest = test } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(subjectColor(test.fach).opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: subjectIcon(test.fach))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(subjectColor(test.fach))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(test.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(test.fach)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(test.allAufgaben.count) Aufgaben")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(test.dauer)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(test.gesamtPunkte) P.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(test.erstelltAm.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { store.delete(test) }
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            MascotView(color: accent.opacity(0.5), mood: .idle, size: 54)
                .frame(width: 54, height: 62)
            Text("Noch keine Tests")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("Erstelle deinen ersten KI-Test mit einem Klick auf den Button oben.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func subjectColor(_ fach: String) -> Color {
        Subject.all.first { $0.name == fach }?.color ?? accent
    }

    private func subjectIcon(_ fach: String) -> String {
        Subject.all.first { $0.name == fach }?.icon ?? "doc.text"
    }
}

// MARK: - Max Intro Overlay

private struct MaxIntroOverlay: View {
    let onDismiss: () -> Void

    private let accent = Color(red: 0.85, green: 0.25, blue: 0.45)
    private let fullText = "Hey! Ich bin **Max**, dein KI-Testassistent! 📝\n\nMit mir erstellst du in Sekunden professionelle Tests – mit echten Aufgaben, Punktesystem und verschiedenen Fragetypen.\n\nGib mir einfach Fach und Thema – den Rest erledige ich für dich! 🚀"

    @State private var displayedText: String = ""
    @State private var mascotMood: MascotMood = .talking
    @State private var isDone: Bool = false
    @State private var mascotScale: CGFloat = 0.7
    @State private var cardOffset: CGFloat = 60

    var body: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Mascot
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.12))
                            .frame(width: 130, height: 130)
                        MascotView(color: accent, mood: mascotMood, size: 100)
                            .frame(width: 100, height: 114)
                    }
                    .scaleEffect(mascotScale)

                    // Name badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accent)
                        Text("MAX · KI-Testassistent")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                            .tracking(0.8)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(accent.opacity(0.10)))

                    // Typewriter text
                    Group {
                        if isDone {
                            Text(try! AttributedString(markdown: fullText,
                                 options: AttributedString.MarkdownParsingOptions(
                                     interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        } else {
                            Text(displayedText)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                    // Loslegen button
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Los geht's!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDone
                                      ? LinearGradient(colors: [accent, Color(red: 0.60, green: 0.18, blue: 0.75)],
                                                       startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                                       startPoint: .leading, endPoint: .trailing))
                                .shadow(color: isDone ? accent.opacity(0.38) : .clear, radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isDone)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.18), radius: 32, x: 0, y: -6)
                )
                .offset(y: cardOffset)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                mascotScale = 1.0
                cardOffset = 0
            }
            startTypewriter()
        }
    }

    private func startTypewriter() {
        Task {
            var idx = fullText.startIndex
            while idx < fullText.endIndex {
                let remaining = fullText.distance(from: idx, to: fullText.endIndex)
                let step = min(3, remaining)
                let nextIdx = fullText.index(idx, offsetBy: step)
                displayedText = String(fullText[fullText.startIndex..<nextIdx])
                idx = nextIdx
                try? await Task.sleep(nanoseconds: 12_000_000)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                mascotMood = .happy
                isDone = true
            }
        }
    }
}
