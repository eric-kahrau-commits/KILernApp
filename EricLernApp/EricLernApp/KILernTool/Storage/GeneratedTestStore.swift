import Foundation
import Combine

final class GeneratedTestStore: ObservableObject {
    static let shared = GeneratedTestStore()

    @Published private(set) var tests: [GeneratedTest] = []
    private let storageKey = "generated_tests_v1"

    private init() { load() }

    func save(_ test: GeneratedTest) {
        if let idx = tests.firstIndex(where: { $0.id == test.id }) {
            tests[idx] = test
        } else {
            tests.insert(test, at: 0)
        }
        persist()
    }

    func delete(_ test: GeneratedTest) {
        tests.removeAll { $0.id == test.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(tests) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([GeneratedTest].self, from: data)
        else { return }
        tests = decoded
    }
}
