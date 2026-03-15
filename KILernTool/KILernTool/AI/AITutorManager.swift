import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Models

struct AITutorMessage: Codable, Identifiable, Equatable {
    var id = UUID()
    let role: String        // "user" | "assistant"
    let content: String
    var imageData: Data?
    let timestamp: Date

    init(role: String, content: String, image: UIImage? = nil) {
        self.role      = role
        self.content   = content
        self.imageData = image?.jpegData(compressionQuality: 0.6)
        self.timestamp = Date()
    }

    var uiImage: UIImage? { imageData.flatMap { UIImage(data: $0) } }
}

struct AITutorSession: Codable, Identifiable {
    var id        = UUID()
    var title:     String
    var createdAt: Date
    var updatedAt: Date
    var messages:  [AITutorMessage]

    var preview: String {
        messages.last { $0.role == "assistant" }?
            .content.trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(60).description ?? "Neues Gespräch"
    }
}

struct AITutorNote: Codable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        case test        = "Test"
        case homework    = "Hausaufgaben"
        case appointment = "Termin"
        case preference  = "Präferenz"
        case problem     = "Problem"
        case note        = "Notiz"

        var icon: String {
            switch self {
            case .test:        return "pencil.and.list.clipboard"
            case .homework:    return "book.fill"
            case .appointment: return "calendar"
            case .preference:  return "person.fill"
            case .problem:     return "exclamationmark.circle.fill"
            case .note:        return "note.text"
            }
        }
        var color: Color {
            switch self {
            case .test:        return Color(red: 0.85, green: 0.25, blue: 0.45)
            case .homework:    return Color(red: 0.10, green: 0.48, blue: 0.92)
            case .appointment: return Color(red: 0.30, green: 0.52, blue: 0.98)
            case .preference:  return Color(red: 0.38, green: 0.18, blue: 0.90)
            case .problem:     return Color(red: 0.95, green: 0.45, blue: 0.10)
            case .note:        return Color(red: 0.15, green: 0.60, blue: 0.40)
            }
        }
    }

    var id        = UUID()
    var kind:      Kind
    var text:      String
    var createdAt: Date = Date()
}

// MARK: - Manager

@MainActor
final class AITutorManager: ObservableObject {
    static let shared = AITutorManager()

    @Published var sessions: [AITutorSession] = []
    @Published var notes:    [AITutorNote]    = []

    private init() { load() }

    // MARK: Sessions

    func newSession() -> AITutorSession {
        let s = AITutorSession(title: "Neues Gespräch",
                               createdAt: Date(), updatedAt: Date(), messages: [])
        sessions.insert(s, at: 0)
        persist()
        return s
    }

    func save(session: AITutorSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: i)
        }
        sessions.insert(session, at: 0)
        persist()
    }

    func delete(session: AITutorSession) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    // MARK: Notes

    func addNote(kind: AITutorNote.Kind, text: String) {
        notes.insert(AITutorNote(kind: kind, text: text), at: 0)
        persist()
    }

    func delete(note: AITutorNote) {
        notes.removeAll { $0.id == note.id }
        persist()
    }

    // MARK: Reminders

    func scheduleReminder(title: String, body: String, at date: Date) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                let c = UNMutableNotificationContent()
                c.title = title; c.body = body; c.sound = .default
                let comps = Calendar.current
                    .dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let req = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: c, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
            }
    }

    // MARK: System Prompt

    func buildSystemPrompt() -> String {
        let noteLines = notes.isEmpty
            ? "Noch keine Infos gespeichert."
            : notes.prefix(10).map { "• [\($0.kind.rawValue)] \($0.text)" }.joined(separator: "\n")

        return """
        Du bist "Olly", eine freundliche, weise Eule und persönlicher Lernbegleiter der "KI Lern" App. \
        Du ersetzt den Lehrer und begleitest Schüler beim Lernen. Antworte immer auf Deutsch.

        CHARAKTER: Herzlich, geduldig, motivierend. Nutze gelegentlich 🦉 und ✨. \
        Erkläre Dinge klar mit Beispielen. Gehe besonders auf den Nutzer ein.

        AUTOMATISCHE NOTIZEN – Wenn du folgendes erkennst, füge am ENDE deiner Antwort eine Zeile hinzu:
        [OLLY_NOTE: Typ|Text]   – Typen: Test, Hausaufgaben, Termin, Präferenz, Problem, Notiz
        Beispiel: [OLLY_NOTE: Test|Mathe-Test am 20. März 3. Stunde]

        ERINNERUNGEN – Wenn ein konkretes Datum erwähnt wird, frage ob du erinnern sollst und füge hinzu:
        [OLLY_REMIND: Titel|Nachricht]
        Beispiel: [OLLY_REMIND: Mathe-Test morgen!|Viel Erfolg beim Test! Du schaffst das 🦉]

        DIE APP "KI LERN":
        - Home: Übersicht, Widgets (Stats, Schnellzugriff, Lernpfad, Wochenaktivität, Olly-Widget)
        - Lernen: Fächer → Lernsets → Modi (Karteikarten, Schnell lernen, Auswendig lernen, Testmodus, Anschauen)
        - Neu: KI-Lernset (KI generiert Q&A), Vokabeln, Karteikarten, Test erstellen, Foto scannen → Zusammenfassung/Lernset
        - Lernplan: KI-generiert, Tagesaufgaben, Fortschrittsverfolgung, Test-Countdown
        - Stats: Streak, Lernfortschritt, Karten-Anzahl
        - Einstellungen: Benachrichtigungen, Dark Mode, App bewerten, Feedback

        GESPEICHERTE INFOS ÜBER DEN NUTZER (Eric):
        \(noteLines)
        """
    }

    // MARK: Tag Parsing

    struct ParsedResponse {
        let clean:    String
        let noteKind: AITutorNote.Kind?
        let noteText: String?
        let remindTitle: String?
        let remindBody:  String?
    }

    func parse(response: String) -> ParsedResponse {
        var text = response
        var nKind: AITutorNote.Kind?
        var nText: String?
        var rTitle: String?
        var rBody:  String?

        // [OLLY_NOTE: Typ|Text]
        if let r = text.range(of: #"\[OLLY_NOTE: ([^\|]+)\|([^\]]+)\]"#, options: .regularExpression) {
            let raw = String(text[r])
            let inner = raw.dropFirst(12).dropLast()
            let parts = inner.components(separatedBy: "|")
            if parts.count >= 2 {
                let kindStr = parts[0].trimmingCharacters(in: .whitespaces)
                nText = parts[1].trimmingCharacters(in: .whitespaces)
                nKind = AITutorNote.Kind.allCases.first { $0.rawValue == kindStr } ?? .note
            }
            text = text.replacingCharacters(in: r, with: "")
        }

        // [OLLY_REMIND: Titel|Nachricht]
        if let r = text.range(of: #"\[OLLY_REMIND: ([^\|]+)\|([^\]]+)\]"#, options: .regularExpression) {
            let raw = String(text[r])
            let inner = raw.dropFirst(14).dropLast()
            let parts = inner.components(separatedBy: "|")
            if parts.count >= 2 {
                rTitle = parts[0].trimmingCharacters(in: .whitespaces)
                rBody  = parts[1].trimmingCharacters(in: .whitespaces)
            }
            text = text.replacingCharacters(in: r, with: "")
        }

        return ParsedResponse(
            clean:       text.trimmingCharacters(in: .whitespacesAndNewlines),
            noteKind:    nKind,
            noteText:    nText,
            remindTitle: rTitle,
            remindBody:  rBody
        )
    }

    // MARK: Persistence

    private func persist() {
        if let d = try? JSONEncoder().encode(sessions) { UserDefaults.standard.set(d, forKey: "olly_sessions_v2") }
        if let d = try? JSONEncoder().encode(notes)    { UserDefaults.standard.set(d, forKey: "olly_notes_v2")    }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: "olly_sessions_v2"),
           let v = try? JSONDecoder().decode([AITutorSession].self, from: d) { sessions = v }
        if let d = UserDefaults.standard.data(forKey: "olly_notes_v2"),
           let v = try? JSONDecoder().decode([AITutorNote].self, from: d)    { notes = v }
    }
}
