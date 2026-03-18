import SwiftUI

struct TestErstellenStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lernSetStore: LernSetStore

    @StateObject private var store = GeneratedTestStore.shared
    @State private var showCreate = false
    @State private var showKorrigieren = false
    @State private var selectedTest: GeneratedTest? = nil
    @State private var showIntro = !UserDefaults.standard.bool(forKey: "introSeen_test")

    private let accent = AppColors.brandPink

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
                    .accessibilityLabel("Schließen")
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
            ModeIntroView(
                characterName: "Max",
                characterRole: "KI-Testassistent",
                gradientTop: Color(red: 0.85, green: 0.25, blue: 0.45),
                gradientBottom: Color(red: 0.65, green: 0.15, blue: 0.55),
                mascotColor: .white,
                introText: "Hey, ich bin **Max** – dein KI-Testassistent! 📝\n\nMit mir erstellst du in Sekunden professionelle Tests – mit echten Aufgaben, Punktesystem und verschiedenen Fragetypen.\n\nGib mir einfach Fach und Thema – den Rest erledige ich für dich! 🚀",
                defaultsKey: "introSeen_test"
            ) {
                withAnimation(.easeOut(duration: 0.35)) { showIntro = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCreate = true }
            }
            .transition(.opacity)
            .zIndex(20)
        }
        } // end outer ZStack
        .animation(.easeOut(duration: 0.35), value: showIntro)
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

