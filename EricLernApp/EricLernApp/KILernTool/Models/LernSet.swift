import Foundation

struct LernSetCard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var question: String
    var answer: String
    /// Optional Bilddaten für die Vorderseite (z. B. ein Foto oder eine Illustration)
    var frontImageData: Data? = nil
    /// Optional Bilddaten für die Rückseite (z. B. ein Foto oder eine Illustration, z. B. Lösung)
    var backImageData: Data? = nil
    /// Falsche Antworten für Multiple-Choice (nur bei KI-generierten Karten)
    var wrongAnswer1: String? = nil
    var wrongAnswer2: String? = nil
    var wrongAnswer3: String? = nil

    /// Gibt 4 Antwortoptionen zurück (1 richtig + 3 falsche), zufällig gemischt.
    /// Falls keine wrongAnswers vorhanden sind, werden andere Karten als Fallback genutzt.
    func shuffledAnswers(fallbackFrom cards: [LernSetCard]) -> [String] {
        var wrong: [String] = []
        if let w1 = wrongAnswer1, let w2 = wrongAnswer2, let w3 = wrongAnswer3 {
            wrong = [w1, w2, w3]
        } else {
            wrong = cards.filter { $0.id != id }.map { $0.answer }.shuffled().prefix(3).map { $0 }
        }
        return ([answer] + wrong.prefix(3)).shuffled()
    }
}

struct LernSet: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var subject: String
    var cards: [LernSetCard]
    var createdAt: Date = Date()
    var isKIGenerated: Bool = false
    var isVokabelSet: Bool = false
    var isScanResult: Bool = false

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
