import SwiftUI

struct KILernsetSaveSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: LernSetStore

    let cards: [LernSetCard]
    let suggestedName: String

    @State private var setName = ""
    @State private var selectedSubject = Subject.all.first?.name ?? ""
    @State private var isSaved = false

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 22) {
                        nameSection
                        subjectSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }

                if isSaved { savedBanner }
            }
        }
        .onAppear { setName = suggestedName }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button("Abbrechen") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text("Lernset speichern")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
            Button("Speichern") { save() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(setName.isEmpty ? Color(uiColor: .tertiaryLabel) : accent)
                .disabled(setName.isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Name Section
    private var nameSection: some View {
        sectionCard(title: "Name des Lernsets") {
            TextField("z. B. Photosynthese Klasse 9", text: $setName)
                .font(.system(size: 16))
                .padding(16)
        }
    }

    // MARK: - Subject Section
    private var subjectSection: some View {
        sectionCard(title: "Fach (Ordner)") {
            VStack(spacing: 0) {
                ForEach(Subject.all) { subject in
                    Button { selectedSubject = subject.name } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(subject.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: subject.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(subject.color)
                            }
                            Text(subject.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSubject == subject.name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: selectedSubject)

                    if subject.name != Subject.all.last?.name {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: - Saved Banner
    private var savedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text("Lernset erfolgreich gespeichert!")
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.green.opacity(0.12))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Section card helper
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }

    // MARK: - Save
    private func save() {
        let newSet = LernSet(
            name:    setName.isEmpty ? suggestedName : setName,
            subject: selectedSubject,
            cards:   cards
        )
        store.save(newSet)
        StreakManager.shared.markActivity()
        withAnimation(.spring(response: 0.4)) { isSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
    }
}
