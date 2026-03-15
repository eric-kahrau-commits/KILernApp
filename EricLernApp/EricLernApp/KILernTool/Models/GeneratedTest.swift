import Foundation

// MARK: - Task Types

enum TestAufgabeTyp: String, Codable {
    case freitext        // Freitextantwort mit Zeilen
    case multipleChoice  // Multiple Choice A/B/C/D
    case lueckentext     // Lückentext mit ___
    case diagramm        // Leeres Beschriftungsfeld (z. B. Bio)
    case rechenweg       // Karierter Bereich für Rechenwege (Mathe)
}

// MARK: - Task

struct TestAufgabe: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var nummer: Int
    var text: String
    var typ: TestAufgabeTyp
    var punkte: Int
    var zeilen: Int = 4
    var optionen: [String]? = nil       // Für multipleChoice: ["A) ...", "B) ...", ...]
    var hinweis: String? = nil
    var diagrammLabel: String? = nil    // Beschriftung unter dem Diagrammfeld
}

// MARK: - Section

struct TestSektion: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var titel: String
    var punkte: Int
    var aufgaben: [TestAufgabe]
}

// MARK: - Generated Test

struct GeneratedTest: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var fach: String
    var beschreibung: String
    var besondereWuensche: String
    var lernSetIds: [UUID]
    var erstelltAm: Date = Date()

    // KI-generierter Inhalt
    var sektionen: [TestSektion]
    var dauer: String
    var gesamtPunkte: Int

    var allAufgaben: [TestAufgabe] {
        sektionen.flatMap { $0.aufgaben }
    }
}
