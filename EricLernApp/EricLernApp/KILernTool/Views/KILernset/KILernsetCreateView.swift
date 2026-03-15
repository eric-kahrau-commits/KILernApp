import SwiftUI

struct KILernsetCreateView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    var onSaved: ((LernSet) -> Void)? = nil

    @State private var setName: String = ""
    @State private var selectedSubjectName: String = Subject.all.first?.name ?? ""
    @State private var showChat = false

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            nameSection
                            subjectSection
                            createButton
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }

                }
            }
            .onAppear {
                if setName.isEmpty {
                    setName = "Neues KI-Lernset"
                }
            }
            .navigationDestination(isPresented: $showChat) {
                KILernsetChatView(
                    setName: setName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Neues KI-Lernset"
                        : setName.trimmingCharacters(in: .whitespacesAndNewlines),
                    subjectName: selectedSubjectName,
                    onSaved: onSaved
                )
                .environmentObject(store)
            }
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button("Abbrechen") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text("KI-Lernset")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
            Button("Weiter") {
                if canProceed {
                    showChat = true
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(canProceed ? accent : Color(uiColor: .tertiaryLabel))
            .disabled(!canProceed)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    private var canProceed: Bool {
        !setName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    Button { selectedSubjectName = subject.name } label: {
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
                            if selectedSubjectName == subject.name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if subject.name != Subject.all.last?.name {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: - Erstellen Button
    private var createButton: some View {
        HStack {
            Spacer()
            Button {
                if canProceed {
                    showChat = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("KI-Lernset starten")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
            .opacity(canProceed ? 1.0 : 0.5)
            Spacer()
        }
    }

    // MARK: - Section helper
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
}

