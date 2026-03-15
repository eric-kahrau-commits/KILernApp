import Foundation
import Combine

final class LernPlanStore: ObservableObject {
    static let shared = LernPlanStore()

    @Published private(set) var plans: [LernPlan] = []

    private let storageKey = "lernplaene_v1"

    init() { load() }

    // MARK: - CRUD

    func save(_ plan: LernPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.insert(plan, at: 0)
        }
        persist()
    }

    func delete(_ plan: LernPlan) {
        plans.removeAll { $0.id == plan.id }
        persist()
    }

    /// Update a specific Aufgabe inside a plan (e.g. mark completed, store lernSetId)
    func updateAufgabe(_ aufgabe: LernPlanAufgabe, inPlan planId: UUID, tagId: UUID) {
        guard let planIndex = plans.firstIndex(where: { $0.id == planId }),
              let tagIndex = plans[planIndex].tage.firstIndex(where: { $0.id == tagId }),
              let aufgabeIndex = plans[planIndex].tage[tagIndex].aufgaben.firstIndex(where: { $0.id == aufgabe.id })
        else { return }
        plans[planIndex].tage[tagIndex].aufgaben[aufgabeIndex] = aufgabe
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([LernPlan].self, from: data)
        else { return }
        plans = decoded
    }
}
