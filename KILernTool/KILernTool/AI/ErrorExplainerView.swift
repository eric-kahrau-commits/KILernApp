import SwiftUI

struct ErrorExplainerView: View {
    let wrongCards: [LernSetCard]
    let subject: String
    let onDismiss: () -> Void

    @State private var isLoading = true
    @State private var explanation: String = ""
    @State private var errorMessage: String? = nil

    private let accent = Color.purple

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else {
                    explanationContent
                }
            }
            .navigationTitle("Fehler erklären")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { onDismiss() }
                }
            }
        }
        .task { await loadExplanation() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(accent)
            VStack(spacing: 6) {
                Text("KI erklärt deine Fehler …")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text("Das dauert einen Moment.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Explanation

    private var explanationContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KI-Erklärung")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(wrongCards.count) \(wrongCards.count == 1 ? "Fehler" : "Fehler") erklärt")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accent.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.2), lineWidth: 1))
                )

                // Explanation text
                Text(explanation)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }
            .padding(18)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Load

    private func loadExplanation() async {
        do {
            let cards = wrongCards.map { (question: $0.question, correctAnswer: $0.answer) }
            explanation = try await AIService.shared.explainErrors(wrongCards: cards, subject: subject)
            isLoading = false
        } catch {
            errorMessage = "Die Erklärung konnte nicht geladen werden. Bitte versuche es erneut."
            isLoading = false
        }
    }
}
