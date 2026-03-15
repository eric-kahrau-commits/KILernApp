import SwiftUI

struct VokabelCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: LernSetStore

    @State private var setName: String = ""
    @State private var fach: String = "Englisch"
    @State private var rows: [VokabelRow] = [VokabelRow(), VokabelRow(), VokabelRow()]
    @FocusState private var focusedField: FieldID?

    private let accent = Color(red: 0.86, green: 0.50, blue: 0.10)
    private let sprachen = ["Englisch", "Französisch", "Spanisch", "Latein"]

    struct VokabelRow: Identifiable {
        let id = UUID()
        var vokabel: String = ""
        var uebersetzung: String = ""
    }
    enum FieldID: Hashable {
        case vokabel(UUID), uebersetzung(UUID)
    }

    private var canSave: Bool {
        !setName.isEmpty && rows.filter { !$0.vokabel.isEmpty && !$0.uebersetzung.isEmpty }.count >= 1
    }

    private var filledCount: Int {
        rows.filter { !$0.vokabel.isEmpty && !$0.uebersetzung.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Name des Sets")
                            TextField("z. B. Englisch Kapitel 5", text: $setName)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                        }

                        // Sprache
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Sprache / Fach")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(sprachen, id: \.self) { s in
                                        Button { fach = s } label: {
                                            Text(s)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(fach == s ? .white : accent)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(fach == s ? accent : accent.opacity(0.10))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    // Custom fach
                                    ForEach(Subject.all.filter { !sprachen.contains($0.name) }) { subject in
                                        Button { fach = subject.name } label: {
                                            Text(subject.name)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(fach == subject.name ? .white : subject.color)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(fach == subject.name ? subject.color : subject.color.opacity(0.10))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }

                        // Table
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                sectionLabel("Vokabeln")
                                Spacer()
                                Text("\(filledCount) eingetragen")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            // Header
                            HStack(spacing: 0) {
                                Text("VOKABEL")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("ÜBERSETZUNG")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer().frame(width: 36)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Rows
                            VStack(spacing: 0) {
                                ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                                    tableRow(row: row, idx: idx)
                                    if idx < rows.count - 1 {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )

                            // Add row button
                            Button {
                                let newRow = VokabelRow()
                                rows.append(newRow)
                                focusedField = .vokabel(newRow.id)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(accent)
                                    Text("Zeile hinzufügen")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(accent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(accent.opacity(0.07))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.20), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)

                            if filledCount < 4 {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                    Text("Mindestens 4 Vokabeln für Multiple-Choice-Modi.")
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Neues Vokabelset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { saveSet() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func tableRow(row: VokabelRow, idx: Int) -> some View {
        HStack(spacing: 0) {
            TextField("Vokabel", text: binding(for: row.id, keyPath: \.vokabel))
                .font(.system(size: 14))
                .focused($focusedField, equals: .vokabel(row.id))
                .submitLabel(.next)
                .onSubmit { focusedField = .uebersetzung(row.id) }
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            TextField("Übersetzung", text: binding(for: row.id, keyPath: \.uebersetzung))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .focused($focusedField, equals: .uebersetzung(row.id))
                .submitLabel(idx == rows.count - 1 ? .done : .next)
                .onSubmit {
                    if idx == rows.count - 1 {
                        let newRow = VokabelRow()
                        rows.append(newRow)
                        focusedField = .vokabel(newRow.id)
                    } else {
                        focusedField = .vokabel(rows[idx + 1].id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            if rows.count > 1 {
                Button {
                    rows.removeAll { $0.id == row.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: 36)
            } else {
                Spacer().frame(width: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func binding(for id: UUID, keyPath: WritableKeyPath<VokabelRow, String>) -> Binding<String> {
        Binding(
            get: { rows.first(where: { $0.id == id })?[keyPath: keyPath] ?? "" },
            set: { newVal in
                if let idx = rows.firstIndex(where: { $0.id == id }) {
                    rows[idx][keyPath: keyPath] = newVal
                }
            }
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func saveSet() {
        let cards = rows
            .filter { !$0.vokabel.isEmpty && !$0.uebersetzung.isEmpty }
            .map { LernSetCard(question: $0.vokabel, answer: $0.uebersetzung) }
        guard !cards.isEmpty else { return }
        let set = LernSet(name: setName, subject: fach, cards: cards, isVokabelSet: true)
        store.save(set)
        _ = StreakManager.shared.markActivity()
        dismiss()
    }
}
