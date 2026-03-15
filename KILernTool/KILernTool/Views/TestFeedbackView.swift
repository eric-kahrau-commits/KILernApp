import SwiftUI

struct TestFeedbackView: View {
    let plan: LernPlan
    let onDismiss: () -> Void

    @State private var step: Int = 1
    @State private var schwierigkeit: String = ""
    @State private var verbesserungen: String = ""

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                if step == 1 {
                    stepOneCard
                } else {
                    stepTwoCard
                }
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: step)
    }

    // MARK: - Step 1: Wie lief der Test?

    private var stepOneCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            header(icon: "checkmark.seal.fill", title: "Wie lief dein Test?",
                   subtitle: "\(plan.fach) · \(formattedDate(plan.testDatum))")

            VStack(alignment: .leading, spacing: 8) {
                Text("Verlauf & Probleme")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                TextEditor(text: $schwierigkeit)
                    .frame(minHeight: 90, maxHeight: 120)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if schwierigkeit.isEmpty {
                            Text("z. B. Aufgabe 3 war schwierig, Zeit knapp …")
                                .font(.system(size: 15))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 19)
                                .allowsHitTesting(false)
                        }
                    }
            }

            HStack(spacing: 12) {
                Button("Überspringen") { dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )

                Button("Weiter") {
                    withAnimation { step = 2 }
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        )
    }

    // MARK: - Step 2: Verbesserungsvorschläge

    private var stepTwoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            header(icon: "lightbulb.fill", title: "Verbesserungsvorschläge",
                   subtitle: "Die KI lernt daraus für künftige Pläne")

            VStack(alignment: .leading, spacing: 8) {
                Text("Was soll die KI beim nächsten Mal besser machen?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                TextEditor(text: $verbesserungen)
                    .frame(minHeight: 90, maxHeight: 120)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if verbesserungen.isEmpty {
                            Text("z. B. Mehr Übungsaufgaben, weniger Theorie …")
                                .font(.system(size: 15))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 19)
                                .allowsHitTesting(false)
                        }
                    }
            }

            HStack(spacing: 12) {
                Button("Zurück") { withAnimation { step = 1 } }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )

                Button("Speichern") { save() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        )
    }

    // MARK: - Helpers

    private func header(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM.yyyy"
        return fmt.string(from: date)
    }

    private func dismiss() {
        FeedbackManager.shared.markSeen(planId: plan.id)
        onDismiss()
    }

    private func save() {
        FeedbackManager.shared.add(
            fach: plan.fach,
            testDatum: plan.testDatum,
            schwierigkeit: schwierigkeit,
            verbesserungen: verbesserungen
        )
        FeedbackManager.shared.markSeen(planId: plan.id)
        onDismiss()
    }
}
