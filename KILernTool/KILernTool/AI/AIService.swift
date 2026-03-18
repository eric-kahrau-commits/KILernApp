import Foundation
import UIKit

// MARK: - API Types

struct AIMessage: Codable {
    let role: String    // "system" | "user" | "assistant"
    let content: String
}

private struct AIRequest: Codable {
    let model: String
    let messages: [AIMessage]
    let temperature: Double
}

private struct AIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Vision API Types (multimodal)

private struct VisionTextContent: Codable {
    let type: String
    let text: String
}

private struct VisionImageContent: Codable {
    struct ImageURL: Codable { let url: String }
    let type: String
    let image_url: ImageURL
}

// Heterogeneous vision content item
private enum VisionContentItem: Encodable {
    case text(VisionTextContent)
    case image(VisionImageContent)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let t):  try t.encode(to: encoder)
        case .image(let i): try i.encode(to: encoder)
        }
    }
}

private struct VisionMessage: Encodable {
    let role: String
    let content: [VisionContentItem]
}

private struct VisionRequest: Encodable {
    let model: String
    let messages: [VisionMessage]
    let max_tokens: Int
    let temperature: Double
}

// MARK: - Service

final class AIService {
    static let shared = AIService()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var apiKey: String { Env.OPENAI_API_KEY }

    // MARK: - Text Chat

    /// Sends a conversation and returns the assistant reply string.
    func chat(messages: [AIMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AIRequest(model: "gpt-4o-mini", messages: messages, temperature: 0.7)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.badResponse
        }
        let decoded = try JSONDecoder().decode(AIResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    /// Public tutor chat – supports optional images.
    func tutorChat(systemPrompt: String, userText: String, images: [UIImage] = []) async throws -> String {
        if images.isEmpty {
            let msgs = [AIMessage(role: "system", content: systemPrompt),
                        AIMessage(role: "user",   content: userText.isEmpty ? "(Bild)" : userText)]
            return try await chat(messages: msgs)
        }
        return try await chatWithImages(systemPrompt: systemPrompt, userText: userText, images: images)
    }

    // MARK: - Vision Chat

    /// Sends a vision request (text + images) and returns the assistant reply.
    private func chatWithImages(systemPrompt: String, userText: String, images: [UIImage]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        // Build content items: text first, then images
        var contentItems: [VisionContentItem] = [
            .text(VisionTextContent(type: "text", text: userText))
        ]
        for image in images {
            // Compress to max 1024px wide, JPEG 0.6 quality
            let compressed = resized(image, maxWidth: 1024)
            guard let jpeg = compressed.jpegData(compressionQuality: 0.6) else { continue }
            let b64 = jpeg.base64EncodedString()
            contentItems.append(.image(VisionImageContent(
                type: "image_url",
                image_url: .init(url: "data:image/jpeg;base64,\(b64)")
            )))
        }

        let visionRequest = VisionRequest(
            model: "gpt-4o-mini",
            messages: [
                VisionMessage(role: "system", content: [.text(VisionTextContent(type: "text", text: systemPrompt))]),
                VisionMessage(role: "user", content: contentItems)
            ],
            max_tokens: 4096,
            temperature: 0.7
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(visionRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.badResponse
        }
        let decoded = try JSONDecoder().decode(AIResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    // MARK: - Lernset Generation

    /// Generates a list of LernSetCards from the collected parameters.
    func generateLernSet(
        fach: String,
        thema: String,
        schwierigkeit: String,
        besonderheiten: String = "",
        anzahl: Int
    ) async throws -> [LernSetCard] {

        let feedbackCtx = FeedbackManager.shared.feedbackContext
        let systemPrompt = """
        Du bist ein erfahrener Lehrer. Erstelle genau \(anzahl) Lernkarten.
        Fach: \(fach), Thema: \(thema), Schwierigkeit: \(schwierigkeit).
        \(besonderheiten.isEmpty ? "" : "Besondere Wünsche: \(besonderheiten)\n")
        \(feedbackCtx.isEmpty ? "" : "\n" + feedbackCtx + "\n")

        Qualitätsregeln:
        - Erstelle Fragen auf verschiedenen Niveaustufen: ~40% Faktenwissen, ~40% Verständnis/Anwendung, ~20% Analyse.
        - Die wrongAnswers sollen häufige Schüler-Fehlannahmen oder verwandte Konzepte abbilden, NICHT zufällig falsche Antworten.
        - Decke alle relevanten Teilbereiche des Themas proportional ab.
        - Variiere die Frageformulierungen – nicht alle mit "Was ist…?" beginnen.
        - Antworte IMMER mit exakt \(anzahl) Karten, auch wenn das Thema klein wirkt.

        Antworte NUR mit einem gültigen JSON-Array (kein Markdown, keine Erklärung):
        [{"question":"...","answer":"...","wrongAnswer1":"...","wrongAnswer2":"...","wrongAnswer3":"..."}, ...]
        """

        let raw = try await chat(messages: [AIMessage(role: "system", content: systemPrompt)])

        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }

        struct RawCard: Codable {
            let question: String
            let answer: String
            let wrongAnswer1: String?
            let wrongAnswer2: String?
            let wrongAnswer3: String?
        }
        let rawCards = try JSONDecoder().decode([RawCard].self, from: data)
        return rawCards.map {
            LernSetCard(
                question: $0.question,
                answer: $0.answer,
                wrongAnswer1: $0.wrongAnswer1,
                wrongAnswer2: $0.wrongAnswer2,
                wrongAnswer3: $0.wrongAnswer3
            )
        }
    }

    // MARK: - Simple Completion

    /// Sends a single user prompt and returns the response. Returns nil on error (non-throwing).
    func complete(prompt: String) async -> String? {
        return try? await chat(messages: [AIMessage(role: "user", content: prompt)])
    }

    // MARK: - Answer Evaluation

    /// Evaluates a student answer using AI.
    func evaluateAnswer(
        question: String,
        correctAnswer: String,
        userAnswer: String
    ) async throws -> (correct: Bool, correction: String?) {
        let systemPrompt = """
        Du bist ein Lehrer. Bewerte die Antwort des Schülers auf die Frage.
        Sei fair: leichte Tipp- oder Grammatikfehler gelten als richtig, solange der Inhalt stimmt.
        Antworte NUR mit einem gültigen JSON-Objekt (kein Markdown):
        {"correct": true, "correction": null}
        oder
        {"correct": false, "correction": "Kurze Erklärung was falsch war und was die richtige Antwort ist."}
        """
        let userMsg = "Frage: \(question)\nKorrekte Antwort: \(correctAnswer)\nSchülerantwort: \(userAnswer)"

        let raw = try await chat(messages: [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: userMsg)
        ])

        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }

        struct EvalResult: Codable {
            let correct: Bool
            let correction: String?
        }
        let result = try JSONDecoder().decode(EvalResult.self, from: data)
        return (result.correct, result.correction)
    }

    // MARK: - Lernplan Generation

    struct RawLernPlanAufgabe: Codable {
        let titel: String
        let beschreibung: String
        let thema: String
        let schwierigkeit: String
        let typ: String?
        let dauerMinuten: Int?
    }

    struct RawLernPlanTag: Codable {
        let aufgaben: [RawLernPlanAufgabe]
    }

    struct RawLernPlan: Codable {
        let titel: String
        let tage: [RawLernPlanTag]
    }

    /// Generates a structured learning plan.
    /// Pass `extractedContent` from `analyzeBookPages()` when images were uploaded.
    func generateLernPlan(
        fach: String,
        klassenstufe: String,
        thema: String,
        besonderheiten: String,
        testDatum: Date,
        images: [UIImage] = [],
        extractedContent: String = ""
    ) async throws -> RawLernPlan {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        let dayCount = max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: testDatum)).day ?? 1)

        let feedbackCtx = FeedbackManager.shared.feedbackContext

        // Build the book-content section if we have extracted material
        let bookSection: String
        if !extractedContent.isEmpty {
            bookSection = """

            ── INHALT AUS BUCHSEITEN (aus Foto-Analyse) ──
            \(extractedContent)
            ── ENDE BUCHINHALT ──

            WICHTIG: Erstelle Lernaufgaben, die DIREKT auf den oben extrahierten Buchinhalt eingehen.
            Nutze die konkreten Themen, Konzepte und Aufgabentypen aus dem Buch.
            Das "thema"-Feld jeder Aufgabe muss exakt auf die Buchinhalte verweisen.
            """
        } else {
            bookSection = ""
        }

        let systemPrompt = """
        Du bist ein erfahrener Lehrer und Lerncoach.
        Erstelle einen strukturierten Lernplan mit genau \(dayCount) Lerntagen.
        Fach: \(fach), Klassenstufe: \(klassenstufe).
        Prüfungsthema: \(thema).
        Testtermin-Details und Besonderheiten: \(besonderheiten).
        \(feedbackCtx.isEmpty ? "" : feedbackCtx + "\n")\(bookSection)

        Regeln:
        - Verteile die Themen sinnvoll über alle \(dayCount) Tage; Grundlagen vor Anwendungen.
        - Max. 2 Aufgaben pro Tag.
        - Das Feld "thema" muss sehr präzise sein (wird für KI-Lernkartengeneration genutzt).
        - schwierigkeit: "einfach", "mittel" oder "schwer".
        - Vergib für jede Aufgabe einen "typ":
          "neuerStoff" (neue Inhalte lernen), "uebung" (Aufgaben lösen/schreiben),
          "wiederholung" (bereits Gelerntes festigen), "simulation" (testähnliche Bedingungen).
        - Vergib "dauerMinuten" (15–45 je nach Aufgabenmenge).
        - Die letzten 2 Tage vor dem Test: ausschließlich "wiederholung" und "simulation".

        Antworte NUR mit gültigem JSON (kein Markdown):
        {"titel":"Planname","tage":[{"aufgaben":[{"titel":"...","beschreibung":"...","thema":"präzises Thema für Lernkartengenerierung, Fach \(fach), Klasse \(klassenstufe)","schwierigkeit":"mittel","typ":"neuerStoff","dauerMinuten":30}]}]}
        Exakt \(dayCount) Objekte im tage-Array.
        """

        let userText = extractedContent.isEmpty
            ? "Erstelle den Lernplan. Thema: \(thema). Besonderheiten: \(besonderheiten)"
            : "Erstelle den Lernplan basierend auf dem extrahierten Buchinhalt. Thema: \(thema). Besonderheiten: \(besonderheiten)"

        // Always use text chat for plan generation (images were already analyzed separately)
        let raw = try await chat(messages: [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: userText)
        ])

        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }
        return try JSONDecoder().decode(RawLernPlan.self, from: data)
    }

    // MARK: - Test Generation

    struct RawTestResult: Codable {
        let dauer: String
        let gesamtPunkte: Int
        let sektionen: [RawTestSektion]

        struct RawTestSektion: Codable {
            let titel: String
            let punkte: Int
            let aufgaben: [RawTestAufgabe]
        }

        struct RawTestAufgabe: Codable {
            let nummer: Int
            let text: String
            let typ: String
            let punkte: Int
            let zeilen: Int?
            let optionen: [String]?
            let hinweis: String?
            let diagrammLabel: String?
        }
    }

    /// Generates a complete test worksheet from selected lernsets.
    func generateTest(
        name: String,
        fach: String,
        beschreibung: String,
        anzahlFragen: Int,
        besondereWuensche: String,
        lernSets: [LernSet]
    ) async throws -> RawTestResult {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        let cards = lernSets.flatMap { $0.cards }
        let cardList = cards.prefix(40).map { "F: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n---\n")

        let systemPrompt = """
        Du bist ein erfahrener Lehrer in Deutschland. Erstelle einen vollständigen Schultest.
        Antworte NUR mit gültigem JSON (kein Markdown, keine Erklärungen außerhalb des JSON).
        Kalibriere Schwierigkeit und Sprache strikt auf die angegebene Klassenstufe.

        JSON-Format (exakt):
        {
          "dauer": "45 Minuten",
          "gesamtPunkte": 30,
          "sektionen": [
            {
              "titel": "Teil A: Grundlagen",
              "punkte": 10,
              "aufgaben": [
                {
                  "nummer": 1,
                  "text": "Aufgabentext...",
                  "typ": "freitext",
                  "punkte": 3,
                  "zeilen": 4,
                  "optionen": null,
                  "hinweis": null,
                  "diagrammLabel": null
                }
              ]
            }
          ]
        }

        Gültige Typen für "typ":
        - "freitext": Freitextantwort, zeilen: Anzahl Zeilen (3–8)
        - "multipleChoice": Multiple Choice, optionen: ["A) ...", "B) ...", "C) ...", "D) ..."]
        - "lueckentext": Lückentextaufgabe (text enthält ___ als Lücken), zeilen: 0
        - "diagramm": Leeres Beschriftungsfeld (nur für Bio/Chemie), diagrammLabel: Kurzbeschreibung
        - "rechenweg": Karierter Rechenbereich (nur für Mathe/Physik/Chemie), zeilen: Anzahl benötigter Reihen

        Regeln:
        - Erstelle exakt \(anzahlFragen) Aufgaben verteilt über sinnvolle Sektionen.
        - Steigende Schwierigkeit innerhalb der Sektionen.
        - Gesamtpunkte müssen der Summe aller Aufgabenpunkte entsprechen.
        - Realistischer Punkterahmen: bei \(anzahlFragen) Aufgaben sind 10–50 Gesamtpunkte üblich.
        - Jede Sektion enthält eine sinnvolle Mischung verschiedener Aufgabentypen.
        - Bei "rechenweg"-Aufgaben in Mathe/Physik/Chemie: Gib im Aufgabentext sinnvolle Zwischenschritte als Hinweis vor.
        - Für Mathe/Physik: bevorzugt "rechenweg" und "freitext".
        - Für Bio/Chemie: bevorzugt "diagramm" und "freitext".
        - Für Sprachen: bevorzugt "freitext" und "lueckentext".
        - Für alle Fächer: mindestens 1–2 "multipleChoice" Aufgaben als Einstieg.
        """

        let userPrompt = """
        Erstelle den Test:
        Name: \(name)
        Fach: \(fach)
        Beschreibung: \(beschreibung.isEmpty ? "Keine" : beschreibung)
        Anzahl Aufgaben: \(anzahlFragen)
        Besondere Wünsche: \(besondereWuensche.isEmpty ? "Keine" : besondereWuensche)

        Lernmaterial (Basis für die Fragen):
        \(cardList.isEmpty ? "Keine Lernsets – erstelle thematisch passende Aufgaben für \(fach)." : cardList)
        """

        let raw = try await chat(messages: [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: userPrompt)
        ])

        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }
        return try JSONDecoder().decode(RawTestResult.self, from: data)
    }

    // MARK: - Test Correction

    struct RawKorrekturResult: Codable {
        let gesamtProzent: Int
        let lehrerfeedback: String
        let aufgaben: [RawAufgabeBewertung]

        struct RawAufgabeBewertung: Codable {
            let aufgabeNummer: Int
            let status: String          // "richtig" | "teilweise" | "falsch"
            let schuelerAntwort: String
            let korrektur: String
            let richtigeAntwort: String
            let erreichbarePunkte: Int
            let erhaltendePunkte: Int
        }
    }

    /// Analyses photos of a completed handwritten test and returns per-question evaluations.
    func korrigiereTest(test: GeneratedTest, images: [UIImage]) async throws -> RawKorrekturResult {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        let aufgabenListe = test.sektionen.flatMap { $0.aufgaben }
            .map { "Aufgabe \($0.nummer) (\($0.punkte) Punkte): \($0.text)" }
            .joined(separator: "\n")

        let systemPrompt = """
        Du bist ein erfahrener Lehrer und korrigierst einen handgeschriebenen Schülertest.
        Dir werden Fotos des ausgefüllten Tests und die originalen Aufgaben gegeben.

        Analysiere die Schülerantworten genau und antworte NUR mit gültigem JSON (kein Markdown):

        {
          "gesamtProzent": 75,
          "lehrerfeedback": "Insgesamt gute Leistung. Aufgabe 3 zeigt Verständnislücken bei ...",
          "aufgaben": [
            {
              "aufgabeNummer": 1,
              "status": "richtig",
              "schuelerAntwort": "Was der Schüler geschrieben hat",
              "korrektur": "Kurze Bewertung und ggf. Hinweis zur Verbesserung",
              "richtigeAntwort": "Die korrekte Antwort",
              "erreichbarePunkte": 3,
              "erhaltendePunkte": 3
            }
          ]
        }

        Regeln für "status":
        - "richtig": Antwort ist vollständig korrekt
        - "teilweise": Antwort ist teilweise richtig oder hat kleinere Fehler
        - "falsch": Antwort ist falsch, leer oder unlesbar

        Sei fair aber korrekt. Leichte Rechtschreibfehler zählen nicht als inhaltlicher Fehler.
        Gib für jede Aufgabe eine klare "korrektur" mit Verbesserungshinweis.
        "gesamtProzent" ist die Gesamtpunktzahl in Prozent (0–100).
        """

        let userText = """
        Bitte korrigiere diesen Test:
        Fach: \(test.fach)
        Testname: \(test.name)

        Aufgaben (mit Punkten):
        \(aufgabenListe)

        Analysiere die beigefügten Fotos und bewerte jede Aufgabe.
        """

        let raw = try await chatWithImages(systemPrompt: systemPrompt, userText: userText, images: images)

        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }
        return try JSONDecoder().decode(RawKorrekturResult.self, from: data)
    }

    // MARK: - Extra Cards Generation

    func generateZusatzKarten(fach: String, beschreibung: String, anzahl: Int, anforderungen: String) async throws -> [LernSetCard] {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let system = """
        Du bist ein erfahrener Lehrer. Erstelle genau \(anzahl) neue Lernkarten.
        Fach: \(fach).
        Thema/Beschreibung: \(beschreibung).
        \(anforderungen.isEmpty ? "" : "Besondere Anforderungen: \(anforderungen).")

        Antworte NUR mit einem gültigen JSON-Array (kein Markdown):
        [{"question":"...","answer":"...","wrongAnswer1":"...","wrongAnswer2":"...","wrongAnswer3":"..."}, ...]
        """
        let raw = try await chat(messages: [AIMessage(role: "system", content: system)])
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }
        struct RawCard: Codable { let question, answer, wrongAnswer1, wrongAnswer2, wrongAnswer3: String? }
        return try JSONDecoder().decode([RawCard].self, from: data).map {
            LernSetCard(question: $0.question ?? "", answer: $0.answer ?? "",
                        wrongAnswer1: $0.wrongAnswer1, wrongAnswer2: $0.wrongAnswer2, wrongAnswer3: $0.wrongAnswer3)
        }
    }

    // MARK: - Scan: Zusammenfassen

    func scanZusammenfassen(images: [UIImage], laenge: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let laengeAnweisung: String
        switch laenge {
        case "kurz":       laengeAnweisung = "Schreibe eine sehr kurze Zusammenfassung (3–5 Sätze, die wichtigsten Punkte)."
        case "ausführlich": laengeAnweisung = "Schreibe eine ausführliche Zusammenfassung mit allen Details, Beispielen und Erklärungen."
        default:           laengeAnweisung = "Schreibe eine mittellange Zusammenfassung (ca. 10–15 Sätze) mit den wichtigsten Inhalten."
        }
        let system = """
        Du bist ein Lernassistent. Analysiere die Bilder von Buchseiten oder Texten und fasse den Inhalt zusammen.
        \(laengeAnweisung)

        Strukturierungsregeln:
        - Beginne mit einer 1-Satz-Kernaussage, die das Wichtigste auf den Punkt bringt.
        - Hebe alle Fachbegriffe und Formeln mit **Fettschrift** hervor.
        - Verwende Spiegelstriche (- ) für Aufzählungen und Merksätze.
        - Antworte auf Deutsch. Keine JSON-Ausgabe – nur formatierten Markdown-Text.
        """
        return try await chatWithImages(systemPrompt: system,
                                        userText: "Fasse den Inhalt dieser Seiten zusammen.",
                                        images: images)
    }

    // MARK: - Scan: Lernset erstellen

    func scanGenerateLernSet(images: [UIImage], fach: String, anzahl: Int, schwierigkeit: String, wuensche: String) async throws -> [LernSetCard] {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let system = """
        Du bist ein erfahrener Lehrer. Analysiere die Bilder und erstelle genau \(anzahl) Lernkarten auf Basis des sichtbaren Inhalts.
        Fach: \(fach), Schwierigkeit: \(schwierigkeit).
        \(wuensche.isEmpty ? "" : "Besondere Wünsche: \(wuensche).")

        Qualitätsregeln:
        - Priorisiere Definitionen, Formeln und Kernkonzepte gegenüber peripheren Details.
        - Jede Frage soll einen klar im Bild erkennbaren Fakt oder Begriff abfragen.
        - wrongAnswers: Verwende verwandte Begriffe oder Konzepte, die ebenfalls im Bild vorkommen – NICHT beliebig falsche Antworten.
        - Antworte IMMER mit exakt \(anzahl) Karten.

        Antworte NUR mit einem gültigen JSON-Array (kein Markdown):
        [{"question":"...","answer":"...","wrongAnswer1":"...","wrongAnswer2":"...","wrongAnswer3":"..."}, ...]
        """
        let raw = try await chatWithImages(systemPrompt: system,
                                           userText: "Erstelle \(anzahl) Lernkarten aus dem Inhalt dieser Seiten.",
                                           images: images)
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { throw AIError.parseError }
        struct RawCard: Codable {
            let question, answer, wrongAnswer1, wrongAnswer2, wrongAnswer3: String?
        }
        return try JSONDecoder().decode([RawCard].self, from: data).map {
            LernSetCard(question: $0.question ?? "", answer: $0.answer ?? "",
                        wrongAnswer1: $0.wrongAnswer1, wrongAnswer2: $0.wrongAnswer2, wrongAnswer3: $0.wrongAnswer3)
        }
    }

    // MARK: - Error Explanation

    /// Explains why answers were wrong, card by card, in a motivating teacher style.
    func explainErrors(wrongCards: [(question: String, correctAnswer: String)], subject: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        let cardList = wrongCards.enumerated().map { i, c in
            "\(i + 1). Frage: \(c.question)\n   Richtige Antwort: \(c.correctAnswer)"
        }.joined(separator: "\n\n")

        let systemPrompt = """
        Du bist ein geduldiger und motivierender Lehrer. Ein Schüler hat bei einer Lerneinheit Fehler gemacht.
        Erkläre bei jeder falsch beantworteten Frage Schritt für Schritt, warum die richtige Antwort stimmt und wie man sich das am besten merkt.
        Sei ermutigend und verwende eine klare, verständliche Sprache. Antworte auf Deutsch.
        Nummeriere deine Erklärungen passend zu den Fragen.
        """
        let userMsg = """
        Der Schüler hat bei folgenden Fragen Fehler gemacht\(subject.isEmpty ? "" : " (Fach: \(subject))"):

        \(cardList)

        Bitte erkläre jede Frage einzeln mit einer kurzen, verständlichen Erklärung.
        """

        return try await chat(messages: [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user",   content: userMsg)
        ])
    }

    // MARK: - Book Page Analysis

    struct BookPageAnalysis {
        /// Short topic chips extracted from the images (e.g. "Quadratische Gleichungen")
        let topics: [String]
        /// Full extracted content — used as additional AI context in plan generation
        let fullText: String
    }

    /// Step 1 of the image-based lernplan flow: OCR + content extraction from book pages.
    /// Call this after the user uploads photos, BEFORE calling generateLernPlan.
    func analyzeBookPages(images: [UIImage]) async throws -> BookPageAnalysis {
        let systemPrompt = """
        Du bist ein Experte für Bildungsanalyse. Analysiere die Fotos von Schulbuchseiten oder Unterrichtsmaterialien.
        Extrahiere alle lernrelevanten Inhalte präzise.

        Antworte IMMER in diesem exakten Format (auf Deutsch):
        THEMEN: [Kommagetrennte Liste der Hauptthemen, max. 6]
        KONZEPTE: [Wichtige Definitionen, Formeln, Regeln, Fachbegriffe]
        AUFGABENTYPEN: [Erkennbare Übungs- oder Aufgabentypen aus dem Buch]
        ZUSAMMENFASSUNG: [Kurze Zusammenfassung des Lerninhalts, 2-4 Sätze]

        Sei präzise und fokussiere auf lernplan-relevante Inhalte.
        """
        let raw = try await chatWithImages(
            systemPrompt: systemPrompt,
            userText: "Analysiere diese Schulbuchseiten und extrahiere den gesamten Lerninhalt.",
            images: images
        )

        // Parse THEMEN: line
        var topics: [String] = []
        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("THEMEN:") {
                let rest = trimmed.dropFirst("THEMEN:".count).trimmingCharacters(in: .whitespaces)
                topics = rest.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && $0 != "-" }
                break
            }
        }
        return BookPageAnalysis(topics: topics, fullText: raw)
    }

    // MARK: - Image Helper

    private func resized(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxWidth else { return image }
        let ratio = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case missingAPIKey, badResponse, parseError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API-Schlüssel fehlt. Bitte Config.plist einrichten."
        case .badResponse:   return "Ungültige Antwort vom Server."
        case .parseError:    return "Antwort konnte nicht verarbeitet werden."
        }
    }
}
