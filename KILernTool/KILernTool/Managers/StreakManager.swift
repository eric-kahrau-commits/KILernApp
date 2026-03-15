import Foundation
import Combine

/// Central manager for the daily learning streak.
/// Uses UserDefaults for persistence. Thread-safe via MainActor isolation.
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    /// Set to true when streak is incremented; ContentView observes this to show the popup.
    @Published var pendingPopup: Bool = false

    private let defaults = UserDefaults.standard
    private enum Key {
        static let current    = "streak_current_v1"
        static let longest    = "streak_longest_v1"
        static let lastActive = "streak_lastActiveDate_v1"
    }

    /// True if the user has already had a qualifying activity today.
    var isActiveToday: Bool {
        guard let last = defaults.object(forKey: Key.lastActive) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private init() {
        currentStreak = defaults.integer(forKey: Key.current)
        longestStreak  = defaults.integer(forKey: Key.longest)
    }

    /// Call when a lernset is created or a learning session finishes.
    /// Returns `true` if the streak was incremented (first activity today).
    @discardableResult
    func markActivity() -> Bool {
        guard !isActiveToday else { return false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = defaults.object(forKey: Key.lastActive) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            currentStreak = diff == 1 ? currentStreak + 1 : 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        defaults.set(currentStreak, forKey: Key.current)
        defaults.set(longestStreak, forKey: Key.longest)
        defaults.set(Date(), forKey: Key.lastActive)

        pendingPopup = true
        return true
    }
}
