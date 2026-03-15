import Foundation
import Combine

final class LernSetStore: ObservableObject {
    static let shared = LernSetStore()

    @Published private(set) var lernSets: [LernSet] = []

    private let storageKey = "ki_lernsets_v1"

    init() { load() }

    func save(_ lernSet: LernSet) {
        if let index = lernSets.firstIndex(where: { $0.id == lernSet.id }) {
            lernSets[index] = lernSet
        } else {
            lernSets.insert(lernSet, at: 0)
        }
        persist()
    }

    func delete(_ lernSet: LernSet) {
        lernSets.removeAll { $0.id == lernSet.id }
        persist()
    }

    func lernSets(for subject: String) -> [LernSet] {
        lernSets.filter { $0.subject == subject }
    }

    // MARK: - Persistence

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
