import Foundation
import SwiftUI
import Combine

final class KILernsetViewModel: ObservableObject {

    // MARK: - Form Fields
    var fach: String = ""   // pre-filled from subject picker
    @Published var thema:          String = ""
    @Published var schwierigkeit:  String = "Mittel"
    @Published var besonderheiten: String = ""
    @Published var anzahl:         Double = 10

    // MARK: - Result
    @Published var generatedCards: [LernSetCard] = []
    @Published var showPreview:    Bool = false

    // MARK: - State
    @Published var isLoading:    Bool = false
    @Published var errorMessage: String? = nil
    @Published var verlauf:      [String] = []

    var canGenerate: Bool { !thema.trimmingCharacters(in: .whitespaces).isEmpty }

    private let verlaufKey = "ki_themen_verlauf_v1"

    init() {
        verlauf = UserDefaults.standard.stringArray(forKey: verlaufKey) ?? []
    }

    // MARK: - Generate

    func generateLernSet() async {
        isLoading = true
        errorMessage = nil
        let trimmed = thema.trimmingCharacters(in: .whitespaces)
        addToVerlauf(trimmed)
        do {
            let cards = try await AIService.shared.generateLernSet(
                fach:           fach,
                thema:          trimmed,
                schwierigkeit:  schwierigkeit,
                besonderheiten: besonderheiten,
                anzahl:         Int(anzahl)
            )
            generatedCards = cards
            showPreview    = true
        } catch {
            errorMessage = "Fehler beim Erstellen. Bitte erneut versuchen."
        }
        isLoading = false
    }

    // MARK: - Verlauf

    private func addToVerlauf(_ thema: String) {
        var list = verlauf
        list.removeAll { $0.lowercased() == thema.lowercased() }
        list.insert(thema, at: 0)
        verlauf = Array(list.prefix(6))
        UserDefaults.standard.set(verlauf, forKey: verlaufKey)
    }
}
