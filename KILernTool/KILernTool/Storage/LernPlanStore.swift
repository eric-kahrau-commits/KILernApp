import Foundation
import Combine
import FirebaseAuth

final class LernPlanStore: ObservableObject {
    static let shared = LernPlanStore()

    @Published private(set) var plans: [LernPlan] = []

    private let storageKey = "lernplaene_v1"
    private let firestore = FirestoreService.shared

    init() { load() }

    // MARK: - CRUD

    func save(_ plan: LernPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.insert(plan, at: 0)
        }
        persist()
        if Auth.auth().currentUser != nil {
            Task { await firestore.uploadLernPlan(plan) }
        }
    }

    func delete(_ plan: LernPlan) {
        plans.removeAll { $0.id == plan.id }
        persist()
        if Auth.auth().currentUser != nil {
            Task { await firestore.deleteLernPlan(id: plan.id) }
        }
    }

    /// Update a specific Aufgabe inside a plan (e.g. mark completed, store lernSetId)
    func updateAufgabe(_ aufgabe: LernPlanAufgabe, inPlan planId: UUID, tagId: UUID) {
        guard let planIndex = plans.firstIndex(where: { $0.id == planId }),
              let tagIndex = plans[planIndex].tage.firstIndex(where: { $0.id == tagId }),
              let aufgabeIndex = plans[planIndex].tage[tagIndex].aufgaben.firstIndex(where: { $0.id == aufgabe.id })
        else { return }
        plans[planIndex].tage[tagIndex].aufgaben[aufgabeIndex] = aufgabe
        persist()
        if Auth.auth().currentUser != nil {
            let updated = plans[planIndex]
            Task { await firestore.uploadLernPlan(updated) }
        }
    }

    // MARK: - Cloud Sync

    func syncFromCloud() async {
        guard Auth.auth().currentUser != nil else { return }
        let cloudPlans = await firestore.fetchAllLernPlans()
        await MainActor.run {
            var merged = plans
            for cp in cloudPlans {
                if let idx = merged.firstIndex(where: { $0.id == cp.id }) {
                    merged[idx] = cp
                } else {
                    merged.append(cp)
                }
            }
            plans = merged.sorted { $0.erstelltAm > $1.erstelltAm }
            persist()
        }
    }

    func uploadAllToCloud() async {
        guard Auth.auth().currentUser != nil else { return }
        for plan in plans {
            await firestore.uploadLernPlan(plan)
        }
    }

    // MARK: - Persistence (UserDefaults)

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
