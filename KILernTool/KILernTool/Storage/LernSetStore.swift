import Foundation
import Combine
import FirebaseAuth

final class LernSetStore: ObservableObject {
    static let shared = LernSetStore()

    @Published private(set) var lernSets: [LernSet] = []
    @Published private(set) var isSyncing = false

    private let storageKey = "ki_lernsets_v1"
    private let firestore = FirestoreService.shared

    init() { load() }

    // MARK: - CRUD

    func save(_ lernSet: LernSet) {
        if let index = lernSets.firstIndex(where: { $0.id == lernSet.id }) {
            lernSets[index] = lernSet
        } else {
            lernSets.insert(lernSet, at: 0)
        }
        persist()
        if Auth.auth().currentUser != nil {
            Task { await firestore.uploadLernSet(lernSet) }
        }
    }

    func delete(_ lernSet: LernSet) {
        lernSets.removeAll { $0.id == lernSet.id }
        persist()
        if Auth.auth().currentUser != nil {
            Task { await firestore.deleteLernSet(id: lernSet.id) }
        }
    }

    func lernSets(for subject: String) -> [LernSet] {
        lernSets.filter { $0.subject == subject }
    }

    // MARK: - SRS: Update card mastery (SM-2 simplified)

    /// Call after answering a card. Updates masteryLevel + nextReviewDate.
    func updateCardMastery(lernSetId: UUID, cardId: UUID, correct: Bool) {
        guard let setIdx = lernSets.firstIndex(where: { $0.id == lernSetId }),
              let cardIdx = lernSets[setIdx].cards.firstIndex(where: { $0.id == cardId })
        else { return }

        var card = lernSets[setIdx].cards[cardIdx]

        if correct {
            card.correctCount += 1
            card.masteryLevel = min(5, card.masteryLevel + 1)
            // SM-2 intervals: 0→1d, 1→3d, 2→7d, 3→14d, 4→30d, 5→90d
            let intervals = [1, 3, 7, 14, 30, 90]
            let days = intervals[min(card.masteryLevel, intervals.count - 1)]
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        } else {
            card.wrongCount += 1
            card.masteryLevel = max(0, card.masteryLevel - 1)
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }

        lernSets[setIdx].cards[cardIdx] = card
        persist()
    }

    // MARK: - SRS: Get sets that have cards due today

    var setsDueToday: [LernSet] {
        lernSets.filter { !$0.cardsDueToday.isEmpty }
    }

    var totalCardsDueToday: Int {
        lernSets.reduce(0) { $0 + $1.cardsDueToday.count }
    }

    // MARK: - Session History

    func saveSessionResult(lernSetId: UUID, score: Double, mode: String) {
        guard let idx = lernSets.firstIndex(where: { $0.id == lernSetId }) else { return }
        let record = SessionRecord(score: score, mode: mode)
        lernSets[idx].sessionHistory.append(record)
        // Keep max 50 records
        if lernSets[idx].sessionHistory.count > 50 {
            lernSets[idx].sessionHistory.removeFirst()
        }
        persist()
    }

    // MARK: - Cloud Sync

    func syncFromCloud() async {
        guard Auth.auth().currentUser != nil else { return }
        await MainActor.run { isSyncing = true }

        let cloudSets = await firestore.fetchAllLernSets()

        await MainActor.run {
            var merged = lernSets
            for cloudSet in cloudSets {
                if let idx = merged.firstIndex(where: { $0.id == cloudSet.id }) {
                    merged[idx] = cloudSet
                } else {
                    merged.append(cloudSet)
                }
            }
            lernSets = merged.sorted { $0.createdAt > $1.createdAt }
            persist()
            isSyncing = false
        }
    }

    func uploadAllToCloud() async {
        guard Auth.auth().currentUser != nil else { return }
        for set in lernSets {
            await firestore.uploadLernSet(set)
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func persist() {
        guard let data = try? JSONEncoder().encode(lernSets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([LernSet].self, from: data)
        else { return }
        lernSets = decoded
    }
}
