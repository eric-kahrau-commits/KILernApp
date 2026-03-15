import Foundation
import Combine

final class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    struct FeedbackEntry: Codable {
        var fach: String
        var testDatum: Date
        var schwierigkeit: String   // Wie lief der Test / Probleme
        var verbesserungen: String  // Verbesserungsvorschläge
        var createdAt: Date = Date()
    }

    @Published private(set) var entries: [FeedbackEntry] = []
    private var seenPlanIds: Set<String> = []

    private enum Key {
        static let entries  = "ki_feedback_entries_v1"
        static let seenIds  = "ki_feedback_seen_plans_v1"
    }

    private init() { load() }

    // MARK: - Public API

    func add(fach: String, testDatum: Date, schwierigkeit: String, verbesserungen: String) {
        let entry = FeedbackEntry(
            fach: fach,
            testDatum: testDatum,
            schwierigkeit: schwierigkeit,
            verbesserungen: verbesserungen
        )
        entries.insert(entry, at: 0)
        persist()
    }

    func markSeen(planId: UUID) {
        seenPlanIds.insert(planId.uuidString)
        persistSeenIds()
    }

    func hasSeen(planId: UUID) -> Bool {
        seenPlanIds.contains(planId.uuidString)
    }

    /// Context string injected into KI system prompts.
    /// Empty if no feedback exists.
    var feedbackContext: String {
        let recent = entries.prefix(5)
        guard !recent.isEmpty else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM.yyyy"
        let lines = recent.map { e in
            "- Fach \(e.fach) (Test am \(fmt.string(from: e.testDatum))): " +
            "Verlauf/Probleme: \(e.schwierigkeit.isEmpty ? "keine Angabe" : e.schwierigkeit). " +
            "Verbesserungsvorschläge: \(e.verbesserungen.isEmpty ? "keine" : e.verbesserungen)."
        }
        return """
        Beachte folgendes Nutzerfeedback aus vergangenen Tests bei der Generierung:
        \(lines.joined(separator: "\n"))
        Versuche, die genannten Probleme zu vermeiden und die Vorschläge umzusetzen.
        """
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Key.entries)
    }

    private func persistSeenIds() {
        UserDefaults.standard.set(Array(seenPlanIds), forKey: Key.seenIds)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Key.entries),
           let decoded = try? JSONDecoder().decode([FeedbackEntry].self, from: data) {
            entries = decoded
        }
        if let ids = UserDefaults.standard.stringArray(forKey: Key.seenIds) {
            seenPlanIds = Set(ids)
        }
    }
}
