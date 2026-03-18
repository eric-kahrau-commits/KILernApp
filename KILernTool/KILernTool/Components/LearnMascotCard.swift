import SwiftUI

// MARK: - Learn Mascot Card
// Appears at the top of SubjectDetailView (book mascot) and
// LearnModeSelectionView (lamp mascot) with a motivational quote.

struct LearnMascotCard: View {
    enum Style { case browse, selectMode }

    let style: Style
    var color: Color = AppColors.brandPurple

    @State private var visible = false
    @State private var quoteIndex: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let browseQuotes = [
        "Welches Set lernst du heute? 📚",
        "Bereit zum Lernen? Ich auch! 🚀",
        "Ich helfe dir beim Durchstarten! 💡",
        "Wähle ein Lernset – los geht's! ✨",
        "Heute wird gelernt! 🎯"
    ]

    private let modeQuotes = [
        "Welcher Modus passt heute? 💡",
        "Bereit für eine Herausforderung? 🔥",
        "Wähle deinen Lernstil! 🎮",
        "Ich feure dich an – wähl einen Modus! 💪",
        "Du schaffst das – starte jetzt! ⚡"
    ]

    private var quote: String {
        let list = style == .browse ? browseQuotes : modeQuotes
        return list[quoteIndex % list.count]
    }

    var body: some View {
        HStack(spacing: 16) {
            // Mascot
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 72, height: 72)

                if style == .browse {
                    BookReadingMascotView(color: color, size: 52)
                } else {
                    LampMascotView(color: color, size: 52)
                }
            }

            // Quote
            VStack(alignment: .leading, spacing: 4) {
                Text(style == .browse ? "Lernset wählen" : "Modus wählen")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(quote)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: color.opacity(0.10), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(visible ? 1 : 0.92)
        .opacity(visible ? 1 : 0)
        .onAppear {
            quoteIndex = Int.random(in: 0..<5)
            withAnimation(reduceMotion ? nil : AppAnimation.standard.delay(0.1)) {
                visible = true
            }
        }
    }
}
