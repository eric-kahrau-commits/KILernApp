import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirestoreService
// All Firestore read/write operations. Image data (frontImageData, backImageData)
// is intentionally NOT synced — images remain local-only to stay within
// Firestore's 1 MB document size limit.

final class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private var userID: String? { Auth.auth().currentUser?.uid }

    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }

    // MARK: - Collection helpers

    private func userDoc() -> DocumentReference? {
        guard let uid = userID else { return nil }
        return db.collection("users").document(uid)
    }

    private func col(_ path: String) -> CollectionReference? {
        userDoc()?.collection(path)
    }

    // MARK: - User Profile

    func createUserProfile(displayName: String, email: String) async {
        guard let ref = userDoc() else { return }
        let data: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        try? await ref.setData(data, merge: true)
    }

    func updateUserDisplayName(_ name: String) async {
        guard let ref = userDoc() else { return }
        try? await ref.updateData([
            "displayName": name,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    // MARK: - LernSets

    func uploadLernSet(_ set: LernSet) async {
        guard let col = col("lernsets") else { return }
        let dto = LernSetDTO(from: set)
        guard let data = try? Firestore.Encoder().encode(dto) else { return }
        try? await col.document(set.id.uuidString).setData(data)
    }

    func deleteLernSet(id: UUID) async {
        guard let col = col("lernsets") else { return }
        try? await col.document(id.uuidString).delete()
    }

    func fetchAllLernSets() async -> [LernSet] {
        guard let col = col("lernsets") else { return [] }
        guard let snapshot = try? await col.getDocuments() else { return [] }
        return snapshot.documents.compactMap { doc -> LernSet? in
            guard let dto = try? Firestore.Decoder().decode(LernSetDTO.self, from: doc.data()) else { return nil }
            return dto.toLernSet()
        }
    }

    // MARK: - LernPlans

    func uploadLernPlan(_ plan: LernPlan) async {
        guard let col = col("lernplans") else { return }
        let dto = LernPlanDTO(from: plan)
        guard let data = try? Firestore.Encoder().encode(dto) else { return }
        try? await col.document(plan.id.uuidString).setData(data)
    }

    func deleteLernPlan(id: UUID) async {
        guard let col = col("lernplans") else { return }
        try? await col.document(id.uuidString).delete()
    }

    func fetchAllLernPlans() async -> [LernPlan] {
        guard let col = col("lernplans") else { return [] }
        guard let snapshot = try? await col.getDocuments() else { return [] }
        return snapshot.documents.compactMap { doc -> LernPlan? in
            guard let dto = try? Firestore.Decoder().decode(LernPlanDTO.self, from: doc.data()) else { return nil }
            return dto.toLernPlan()
        }
    }

    // MARK: - Streak

    func uploadStreak(current: Int, longest: Int, lastActive: Date?) async {
        guard let ref = userDoc() else { return }
        var data: [String: Any] = [
            "streak.currentStreak": current,
            "streak.longestStreak": longest
        ]
        if let date = lastActive {
            data["streak.lastActive"] = Timestamp(date: date)
        }
        try? await ref.setData(data, merge: true)
    }

    func fetchStreak() async -> (current: Int, longest: Int, lastActive: Date?)? {
        guard let ref = userDoc() else { return nil }
        guard let doc = try? await ref.getDocument(),
              let streakData = doc.data()?["streak"] as? [String: Any] else { return nil }
        let current = streakData["currentStreak"] as? Int ?? 0
        let longest = streakData["longestStreak"] as? Int ?? 0
        let lastActive = (streakData["lastActive"] as? Timestamp)?.dateValue()
        return (current, longest, lastActive)
    }
}

// MARK: - DTOs (Data Transfer Objects for Firestore, no image data)

struct LernSetCardDTO: Codable {
    let id: String
    let question: String
    let answer: String
    let wrongAnswer1: String?
    let wrongAnswer2: String?
    let wrongAnswer3: String?

    init(from card: LernSetCard) {
        id = card.id.uuidString
        question = card.question
        answer = card.answer
        wrongAnswer1 = card.wrongAnswer1
        wrongAnswer2 = card.wrongAnswer2
        wrongAnswer3 = card.wrongAnswer3
    }

    func toLernSetCard() -> LernSetCard {
        LernSetCard(
            id: UUID(uuidString: id) ?? UUID(),
            question: question,
            answer: answer,
            wrongAnswer1: wrongAnswer1,
            wrongAnswer2: wrongAnswer2,
            wrongAnswer3: wrongAnswer3
        )
    }
}

struct LernSetDTO: Codable {
    let id: String
    let name: String
    let subject: String
    let cards: [LernSetCardDTO]
    let createdAt: Date
    let isKIGenerated: Bool
    let isVokabelSet: Bool
    let isScanResult: Bool
    let updatedAt: Date

    init(from set: LernSet) {
        id = set.id.uuidString
        name = set.name
        subject = set.subject
        cards = set.cards.map { LernSetCardDTO(from: $0) }
        createdAt = set.createdAt
        isKIGenerated = set.isKIGenerated
        isVokabelSet = set.isVokabelSet
        isScanResult = set.isScanResult
        updatedAt = Date()
    }

    func toLernSet() -> LernSet {
        LernSet(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            subject: subject,
            cards: cards.map { $0.toLernSetCard() },
            createdAt: createdAt,
            isKIGenerated: isKIGenerated,
            isVokabelSet: isVokabelSet,
            isScanResult: isScanResult
        )
    }
}

// MARK: - LernPlan DTOs

struct LernPlanAufgabeDTO: Codable {
    let id: String
    let titel: String
    let beschreibung: String
    let thema: String
    let schwierigkeit: String
    let anzahl: Int
    let completed: Bool
    let generatedLernSetId: String?
    let typ: String
    let dauerMinuten: Int

    init(from a: LernPlanAufgabe) {
        id = a.id.uuidString; titel = a.titel; beschreibung = a.beschreibung
        thema = a.thema; schwierigkeit = a.schwierigkeit; anzahl = a.anzahl
        completed = a.completed; generatedLernSetId = a.generatedLernSetId?.uuidString
        typ = a.typ; dauerMinuten = a.dauerMinuten
    }

    func toAufgabe() -> LernPlanAufgabe {
        LernPlanAufgabe(
            id: UUID(uuidString: id) ?? UUID(),
            titel: titel, beschreibung: beschreibung, thema: thema,
            schwierigkeit: schwierigkeit, anzahl: anzahl, completed: completed,
            generatedLernSetId: generatedLernSetId.flatMap { UUID(uuidString: $0) },
            typ: typ, dauerMinuten: dauerMinuten
        )
    }
}

struct LernPlanTagDTO: Codable {
    let id: String
    let tagNummer: Int
    let datum: Date
    let aufgaben: [LernPlanAufgabeDTO]

    init(from tag: LernPlanTag) {
        id = tag.id.uuidString; tagNummer = tag.tagNummer; datum = tag.datum
        aufgaben = tag.aufgaben.map { LernPlanAufgabeDTO(from: $0) }
    }

    func toTag() -> LernPlanTag {
        LernPlanTag(
            id: UUID(uuidString: id) ?? UUID(),
            tagNummer: tagNummer, datum: datum,
            aufgaben: aufgaben.map { $0.toAufgabe() }
        )
    }
}

struct LernPlanDTO: Codable {
    let id: String
    let titel: String
    let fach: String
    let klassenstufe: String
    let testDatum: Date
    let thema: String
    let besonderheiten: String
    let tage: [LernPlanTagDTO]
    let erstelltAm: Date
    let updatedAt: Date

    init(from plan: LernPlan) {
        id = plan.id.uuidString; titel = plan.titel; fach = plan.fach
        klassenstufe = plan.klassenstufe; testDatum = plan.testDatum; thema = plan.thema
        besonderheiten = plan.besonderheiten; tage = plan.tage.map { LernPlanTagDTO(from: $0) }
        erstelltAm = plan.erstelltAm; updatedAt = Date()
    }

    func toLernPlan() -> LernPlan {
        LernPlan(
            id: UUID(uuidString: id) ?? UUID(),
            titel: titel, fach: fach, klassenstufe: klassenstufe,
            testDatum: testDatum, thema: thema, besonderheiten: besonderheiten,
            tage: tage.map { $0.toTag() }, erstelltAm: erstelltAm
        )
    }
}
