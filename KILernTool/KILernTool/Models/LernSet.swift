import Foundation

// MARK: - Session History

struct SessionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var score: Double   // 0.0 – 1.0
    var mode: String    // "schnell", "auswendig", "test", "karteikarten", "schwach", "faellig"
}

// MARK: - LernSetCard

struct LernSetCard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var question: String
    var answer: String
    /// Optional Bilddaten für die Vorderseite
    var frontImageData: Data? = nil
    /// Optional Bilddaten für die Rückseite
    var backImageData: Data? = nil
    /// Falsche Antworten für Multiple-Choice (nur bei KI-generierten Karten)
    var wrongAnswer1: String? = nil
    var wrongAnswer2: String? = nil
    var wrongAnswer3: String? = nil

    // MARK: - SRS fields (Spaced Repetition System)
    /// Mastery-Level 0–5 (0=neu, 5=gemeistert)
    var masteryLevel: Int = 0
    /// Nächstes Review-Datum (nil = heute fällig)
    var nextReviewDate: Date? = nil
    /// Anzahl korrekter Antworten gesamt
    var correctCount: Int = 0
    /// Anzahl falscher Antworten gesamt
    var wrongCount: Int = 0

    /// Gibt 4 Antwortoptionen zurück (1 richtig + 3 falsche), zufällig gemischt.
    func shuffledAnswers(fallbackFrom cards: [LernSetCard]) -> [String] {
        var wrong: [String] = []
        if let w1 = wrongAnswer1, let w2 = wrongAnswer2, let w3 = wrongAnswer3 {
            wrong = [w1, w2, w3]
        } else {
            wrong = cards.filter { $0.id != id }.map { $0.answer }.shuffled().prefix(3).map { $0 }
        }
        return ([answer] + wrong.prefix(3)).shuffled()
    }

    /// Ob diese Karte heute reviewed werden soll (nextReviewDate <= today, oder nil)
    var isDueToday: Bool {
        guard let next = nextReviewDate else { return true }
        return next <= Calendar.current.startOfDay(for: Date())
    }

    /// Ob diese Karte als "schwach" gilt (> 2 Fehler, Fehlerrate > 40%)
    var isWeak: Bool {
        let total = correctCount + wrongCount
        guard total >= 3 else { return wrongCount >= 2 }
        return Double(wrongCount) / Double(total) > 0.40
    }
}

// MARK: - LernSet

struct LernSet: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var subject: String
    var cards: [LernSetCard]
    var createdAt: Date = Date()
    var isKIGenerated: Bool = false
    var isVokabelSet: Bool = false
    var isScanResult: Bool = false

    /// Session-Verlauf für Fortschrittsanzeige
    var sessionHistory: [SessionRecord] = []

    // MARK: - Computed helpers

    /// Mastery-Prozent 0–100 (Durchschnitt aller Karten)
    var masteryPercent: Int {
        guard !cards.isEmpty else { return 0 }
        let avg = Double(cards.reduce(0) { $0 + $1.masteryLevel }) / Double(cards.count * 5)
        return Int(avg * 100)
    }

    /// Karten, die heute reviewed werden sollen
    var cardsDueToday: [LernSetCard] {
        cards.filter { $0.isDueToday }
    }

    /// Karten, die als "schwach" gelten
    var weakCards: [LernSetCard] {
        cards.filter { $0.isWeak }
    }

    /// Letzte 7 Sessions für Chart
    var recentSessions: [SessionRecord] {
        Array(sessionHistory.sorted { $0.date > $1.date }.prefix(7).reversed())
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
