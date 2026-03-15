import SwiftUI

struct CreateOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let mascotColor: Color

    static let all: [CreateOption] = [
        CreateOption(
            title: "KI Lernset",
            subtitle: "KI erstellt automatisch deine Lernkarten",
            icon: "sparkles",
            colors: [Color(red: 0.38, green: 0.18, blue: 0.90), Color(red: 0.70, green: 0.28, blue: 1.00)],
            mascotColor: Color(red: 0.38, green: 0.18, blue: 0.90)
        ),
        CreateOption(
            title: "Lern Plan",
            subtitle: "Strukturiere deinen Lernalltag",
            icon: "calendar.badge.plus",
            colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
            mascotColor: Color(red: 0.10, green: 0.48, blue: 0.92)
        ),
        CreateOption(
            title: "Test erstellen",
            subtitle: "Prüfe und festige dein Wissen",
            icon: "checkmark.seal.fill",
            colors: [Color(red: 0.90, green: 0.28, blue: 0.50), Color(red: 1.00, green: 0.52, blue: 0.32)],
            mascotColor: Color(red: 0.90, green: 0.28, blue: 0.50)
        ),
        CreateOption(
            title: "Karteikartenset",
            subtitle: "Klassisches Lernen mit Karteikarten",
            icon: "rectangle.stack.fill",
            colors: [Color(red: 0.10, green: 0.64, blue: 0.54), Color(red: 0.18, green: 0.80, blue: 0.62)],
            mascotColor: Color(red: 0.10, green: 0.64, blue: 0.54)
        ),
        CreateOption(
            title: "Vokabelset",
            subtitle: "Sprachen effizient und schnell lernen",
            icon: "character.bubble.fill",
            colors: [Color(red: 0.86, green: 0.50, blue: 0.10), Color(red: 1.00, green: 0.72, blue: 0.18)],
            mascotColor: Color(red: 0.86, green: 0.50, blue: 0.10)
        ),
        CreateOption(
            title: "Scannen",
            subtitle: "Buchseiten scannen & zusammenfassen oder als Lernset",
            icon: "doc.viewfinder.fill",
            colors: [Color(red: 0.12, green: 0.58, blue: 0.46), Color(red: 0.20, green: 0.80, blue: 0.60)],
            mascotColor: Color(red: 0.12, green: 0.58, blue: 0.46)
        ),
    ]
}
