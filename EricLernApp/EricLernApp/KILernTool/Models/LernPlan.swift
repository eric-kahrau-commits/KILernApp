import Foundation

// MARK: - Aufgabe (Task per Day)

struct LernPlanAufgabe: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var titel: String
    var beschreibung: String
    /// Specific topic used when generating the lernset via AIService
    var thema: String
    var schwierigkeit: String = "mittel"
    var anzahl: Int = 10
    var completed: Bool = false
    /// UUID of the LernSet generated when user taps Play
    var generatedLernSetId: UUID? = nil
}

// MARK: - Tag (One learning day)

struct LernPlanTag: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var tagNummer: Int          // 1-based
    var datum: Date
    var aufgaben: [LernPlanAufgabe]

    var isToday: Bool {
        Calendar.current.isDateInToday(datum)
    }

    var isPast: Bool {
        datum < Calendar.current.startOfDay(for: Date())
    }

    var allCompleted: Bool {
        !aufgaben.isEmpty && aufgaben.allSatisfy { $0.completed }
    }
}

// MARK: - LernPlan (Top-level)

struct LernPlan: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var titel: String
    var fach: String
    var klassenstufe: String
    var testDatum: Date
    var thema: String
    var besonderheiten: String
    var tage: [LernPlanTag]
    var erstelltAm: Date = Date()

    /// Days remaining until the test (0 on test day, negative after)
    var daysUntilTest: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: testDatum)).day ?? 0
    }

    /// The tag corresponding to today (nil if today is not in the plan)
    var todayTag: LernPlanTag? {
        tage.first { $0.isToday }
    }

    /// Index of today in tage array (-1 if not found)
    var todayIndex: Int {
        tage.firstIndex { $0.isToday } ?? -1
    }

    var overallProgress: Double {
        let total = tage.flatMap { $0.aufgaben }.count
        let done = tage.flatMap { $0.aufgaben }.filter { $0.completed }.count
        return total == 0 ? 0 : Double(done) / Double(total)
    }
}
