import Foundation
import SwiftUI
import Combine

// MARK: - Checklist Item

struct ChecklistField: Identifiable {
    let id: String
    let label: String
    var isDone: Bool = false
}

// MARK: - ViewModel

final class KILernsetViewModel: ObservableObject {

    // MARK: Chat
    @Published var messages:     [ChatMessage] = []
    @Published var inputText:    String = ""
    @Published var isLoading:    Bool = false
    @Published var errorMessage: String? = nil

    // MARK: Collected fields (updated from AI extraction)
    @Published var fach:          String = ""
    @Published var klassenstufe:  String = ""
    @Published var thema:         String = ""
    @Published var schwierigkeit: String = ""
    @Published var anzahl:        Int    = 0

    // MARK: Result
    @Published var generatedCards: [LernSetCard] = []
    @Published var showPreview:    Bool = false

    // MARK: Checklist
    @Published var checklist: [ChecklistField]

    var allFieldsComplete: Bool { checklist.allSatisfy(\.isDone) }

    // MARK: - Private

    /// Full conversation history sent to the API each turn.
    private var conversationHistory: [AIMessage] = []

    private let systemPrompt = """
    Du bist ein freundlicher KI-Assistent, der dem Nutzer hilft, ein Lernset zu erstellen.
    Dein Ziel ist es, im natürlichen Gespräch folgende Informationen zu sammeln:
    - fach: Schulfach (z. B. Mathe, Biologie, Englisch)
    - klassenstufe: Klassenstufe (z. B. Klasse 8, 10. Klasse)
    - thema: Konkretes Thema (z. B. Photosynthese, Quadratische Gleichungen)
    - schwierigkeit: Schwierigkeitsgrad oder Sonderwünsche (z. B. leicht, mittel, schwer, mit Beispielen)
    - anzahl: Anzahl der Fragen als ganze Zahl (z. B. 10)

    Antworte immer auf Deutsch, natürlich und freundlich.
    Reagiere auch auf Smalltalk (z. B. "Hallo" → freundlich begrüßen).
    Frage fehlende Informationen nach – aber maximal 1–2 pro Nachricht, nicht alle auf einmal.
    Wenn der Nutzer mehrere Infos auf einmal nennt, erkenne und bestätige alle.

    Hänge am Ende JEDER deiner Antworten – nach einer Leerzeile – exakt diesen Block an:
    <<<FIELDS>>>
    {"fach":"","klassenstufe":"","thema":"","schwierigkeit":"","anzahl":0}
    <<<END>>>

    Regeln für das JSON:
    - Trage nur Felder ein, die aus dem gesamten bisherigen Gespräch sicher bekannt sind.
    - Übernehme bereits bekannte Werte aus früheren Turns kumulativ.
    - Unbekannte String-Felder bleiben "", unbekannte Zahl-Felder bleiben 0.
    - Gib das JSON IMMER aus, auch wenn alle Felder leer sind.
    """

    // MARK: - Init

    init() {
        checklist = [
            ChecklistField(id: "fach",          label: "Fach"),
            ChecklistField(id: "klassenstufe",  label: "Klassenstufe"),
            ChecklistField(id: "thema",         label: "Thema"),
            ChecklistField(id: "schwierigkeit", label: "Schwierigkeit"),
            ChecklistField(id: "anzahl",        label: "Anzahl Fragen"),
        ]
    }

    // MARK: - Start conversation (call once on appear)

    func startConversation() {
        guard messages.isEmpty else { return }
        let greeting = "Hallo! 👋 Ich helfe dir, ein Lernset zu erstellen. Für welches **Fach** und **Thema** soll es sein?"
        messages.append(ChatMessage(sender: .ai, text: greeting))
        conversationHistory.append(AIMessage(role: "assistant", content: greeting))
    }

    // MARK: - Send user message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        inputText = ""
        messages.append(ChatMessage(sender: .user, text: text))
        conversationHistory.append(AIMessage(role: "user", content: text))
        Task { await fetchReply() }
    }

    // MARK: - Generate learning set

    func generateLernSet() async {
        isLoading = true
        errorMessage = nil
        do {
            let cards = try await AIService.shared.generateLernSet(
                fach:          fach,
                klassenstufe:  klassenstufe,
                thema:         thema,
                schwierigkeit: schwierigkeit,
                anzahl:        anzahl > 0 ? anzahl : 10
            )
            generatedCards = cards
            showPreview    = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Private: fetch AI reply

    private func fetchReply() async {
        isLoading = true
        errorMessage = nil

        var allMessages = [AIMessage(role: "system", content: systemPrompt)]
        allMessages += conversationHistory

        do {
            let raw = try await AIService.shared.chat(messages: allMessages)
            let (reply, extracted) = parseResponse(raw)
            conversationHistory.append(AIMessage(role: "assistant", content: raw))
            messages.append(ChatMessage(sender: .ai, text: reply))
            applyExtracted(extracted)
        } catch {
            let fallback = "Entschuldigung, da ist etwas schiefgelaufen. Bitte versuche es nochmal."
            messages.append(ChatMessage(sender: .ai, text: fallback))
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Splits raw AI output into the display reply and the structured JSON fields.
    private func parseResponse(_ raw: String) -> (String, [String: Any]) {
        let parts = raw.components(separatedBy: "<<<FIELDS>>>")
        let reply = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)

        var fields: [String: Any] = [:]
        if parts.count > 1 {
            let jsonStr = (parts[1].components(separatedBy: "<<<END>>>").first ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = jsonStr.data(using: .utf8),
               let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                fields = decoded
            }
        }
        return (reply, fields)
    }

    /// Writes extracted field values and updates checklist accordingly.
    private func applyExtracted(_ fields: [String: Any]) {
        if let v = fields["fach"]          as? String, !v.isEmpty { fach          = v }
        if let v = fields["klassenstufe"]  as? String, !v.isEmpty { klassenstufe  = v }
        if let v = fields["thema"]         as? String, !v.isEmpty { thema         = v }
        if let v = fields["schwierigkeit"] as? String, !v.isEmpty { schwierigkeit = v }

        if let raw = fields["anzahl"] {
            let n: Int
            if      let i = raw as? Int    { n = i }
            else if let d = raw as? Double { n = Int(d) }
            else if let s = raw as? String { n = Int(s) ?? 0 }
            else { n = 0 }
            if n > 0 { anzahl = n }
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            mark("fach",          !fach.isEmpty)
            mark("klassenstufe",  !klassenstufe.isEmpty)
            mark("thema",         !thema.isEmpty)
            mark("schwierigkeit", !schwierigkeit.isEmpty)
            mark("anzahl",        anzahl > 0)
        }
    }

    private func mark(_ id: String, _ done: Bool) {
        if let i = checklist.firstIndex(where: { $0.id == id }) {
            checklist[i].isDone = done
        }
    }
}
