import SwiftUI
import Combine

// MARK: - Tutorial Step

enum TutorialStep: Int {
    case hamburgerMenu  = 0
    case neuSidebarItem = 1
    case kiLernsetCard  = 2

    var instruction: String {
        switch self {
        case .hamburgerMenu:   return "Öffne das Menü"
        case .neuSidebarItem:  return "Tippe auf 'Neu'"
        case .kiLernsetCard:   return "Dein erstes KI-Lernset!"
        }
    }

    var detail: String {
        switch self {
        case .hamburgerMenu:   return "Tippe auf das Symbol\noben links."
        case .neuSidebarItem:  return "Hier erstellst du alles\nNeue in der App."
        case .kiLernsetCard:   return "Tippe auf 'KI Lernset' -\ndie KI erledigt den Rest."
        }
    }

    var mood: MascotMood {
        switch self {
        case .hamburgerMenu:   return .talking
        case .neuSidebarItem:  return .happy
        case .kiLernsetCard:   return .celebrating
        }
    }

    var next: TutorialStep? {
        TutorialStep(rawValue: rawValue + 1)
    }
}

// MARK: - Tutorial Manager

final class TutorialManager: ObservableObject {
    static let shared = TutorialManager()

    @Published var isActive  = false
    @Published var step: TutorialStep = .hamburgerMenu
    @Published var frames: [TutorialStep: CGRect] = [:]

    private static let doneKey = "ol_tutorialDone"

    private init() {}

    var currentFrame: CGRect { frames[step] ?? .zero }
    var isDone: Bool { UserDefaults.standard.bool(forKey: Self.doneKey) }

    func start() {
        guard !isDone else { return }
        step = .hamburgerMenu
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                self.isActive = true
            }
        }
    }

    func advance() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            if let next = step.next {
                step = next
            } else {
                finishAnimation()
            }
        }
    }

    func complete() {
        guard isActive else { return }
        UserDefaults.standard.set(true, forKey: Self.doneKey)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isActive = false
        }
    }

    func skip() {
        complete()
    }

    func reportFrame(_ frame: CGRect, for targetStep: TutorialStep) {
        DispatchQueue.main.async { [weak self] in
            self?.frames[targetStep] = frame
        }
    }

    private func finishAnimation() {
        complete()
    }
}
