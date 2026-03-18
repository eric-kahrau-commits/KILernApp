import Foundation
import Combine
import FirebaseAuth

/// Central manager for the daily learning streak.
/// Uses UserDefaults for local persistence and syncs to Firestore when logged in.
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    /// Set to true when streak is incremented; ContentView observes this to show the popup.
    @Published var pendingPopup: Bool = false

    private let defaults = UserDefaults.standard
    private let firestore = FirestoreService.shared

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

        let lastActiveDate = Date()
        defaults.set(currentStreak, forKey: Key.current)
        defaults.set(longestStreak, forKey: Key.longest)
        defaults.set(lastActiveDate, forKey: Key.lastActive)

        pendingPopup = true

        if Auth.auth().currentUser != nil {
            let (c, l) = (currentStreak, longestStreak)
            Task { await firestore.uploadStreak(current: c, longest: l, lastActive: lastActiveDate) }
        }
        return true
    }

    // MARK: - Cloud Sync

    /// Pull streak from Firestore and take the higher values (merge strategy).
    func syncFromCloud() async {
        guard Auth.auth().currentUser != nil else { return }
        guard let remote = await firestore.fetchStreak() else { return }

        await MainActor.run {
            let newCurrent = max(currentStreak, remote.current)
            let newLongest = max(longestStreak, remote.longest)
            currentStreak = newCurrent
            longestStreak = newLongest
            defaults.set(newCurrent, forKey: Key.current)
            defaults.set(newLongest, forKey: Key.longest)
            if let remoteDate = remote.lastActive {
                // Keep whichever last-active date is more recent
                if let localDate = defaults.object(forKey: Key.lastActive) as? Date {
                    if remoteDate > localDate {
                        defaults.set(remoteDate, forKey: Key.lastActive)
                    }
                } else {
                    defaults.set(remoteDate, forKey: Key.lastActive)
                }
            }
        }
    }
}
