import Foundation
import Combine
import UserNotifications

// MARK: - NotificationManager

/// Central singleton that owns all push-notification logic.
/// Call `scheduleAll(streak:plans:sets:)` whenever the app becomes active
/// so the next-day notifications stay fresh and dynamic.
@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()
    private init() {}

    // Published so views can react to status changes
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - UserDefaults Keys

    private let kFirstAskedDate  = "notif_first_asked_date"
    private let kWeeklyAskedDate = "notif_weekly_ask_date"

    // MARK: - Notification Identifiers

    static let streakMorningID = "theo_streak_morning"
    static let streakEveningID = "theo_streak_evening"
    static let lernplanDailyID = "theo_lernplan_daily"

    // MARK: - Permission Status

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Requests system permission. Returns true if granted.
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            UserDefaults.standard.set(Date(), forKey: kFirstAskedDate)
            UserDefaults.standard.set(Date(), forKey: kWeeklyAskedDate)
            return granted
        } catch {
            return false
        }
    }

    // MARK: - In-App Prompt Logic

    /// True when the system permission dialog has never been requested yet.
    var shouldShowFirstLaunchPrompt: Bool {
        UserDefaults.standard.object(forKey: kFirstAskedDate) == nil
    }

    /// True when notifications are not authorised AND it's been ≥7 days since last in-app ask.
    var shouldShowWeeklyPrompt: Bool {
        guard authorizationStatus != .authorized else { return false }
        guard let last = UserDefaults.standard.object(forKey: kWeeklyAskedDate) as? Date else {
            return true
        }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 7
    }

    /// Call when the in-app prompt is dismissed (allow OR deny).
    func markPromptShown() {
        UserDefaults.standard.set(Date(), forKey: kFirstAskedDate)
        UserDefaults.standard.set(Date(), forKey: kWeeklyAskedDate)
    }

    // MARK: - Master Scheduler

    /// Reschedules all notifications. Call on app-active and after permission is granted.
    func scheduleAll(streak: Int, plans: [LernPlan], sets: [LernSet]) async {
        await refreshStatus()
        guard authorizationStatus == .authorized else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.streakMorningID,
            Self.streakEveningID,
            Self.lernplanDailyID
        ])

        scheduleStreakMorning(streak: streak, center: center)
        scheduleStreakEvening(streak: streak, center: center)
        scheduleLernplan(plans: plans, sets: sets, center: center)
    }

    // MARK: - Streak: Morning  (08:00)

    private func scheduleStreakMorning(streak: Int, center: UNUserNotificationCenter) {
        let c = UNMutableNotificationContent()

        if streak > 1 {
            c.title = "🤖 \(streak) Tage Streak – halte ihn am Leben! 🔥"
            c.body  = "Theo wartet schon auf dich. Ein paar Karten reichen – los geht's! 💪"
        } else if streak == 1 {
            c.title = "🤖 Guten Morgen! Tag 1 – ein toller Start!"
            c.body  = "Theo fiebert mit dir. Lern heute wieder und bau deinen Streak aus 🚀"
        } else {
            c.title = "🤖 Guten Morgen! Heute neu anfangen?"
            c.body  = "Kein aktiver Streak – das ändern wir heute! Theo hilft dir 📚"
        }
        c.sound = .default

        var comps = DateComponents()
        comps.hour   = 8
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.streakMorningID,
                                         content: c, trigger: trigger))
    }

    // MARK: - Streak: Evening  (20:00)

    private func scheduleStreakEvening(streak: Int, center: UNUserNotificationCenter) {
        let c = UNMutableNotificationContent()
        let remaining = hoursUntilMidnight()

        if streak > 1 {
            c.title = "⚡️ Streak-Alarm! Noch \(remaining) Std. übrig"
            c.body  = "Theo schläft gleich ein 😴 – \(streak) Tage Streak retten? Jetzt kurz lernen!"
        } else if streak == 1 {
            c.title = "⚡️ Dein erster Tag – nicht aufgeben!"
            c.body  = "Theo drückt die Daumen 🤞 Kurz lernen und Tag 1 sichern!"
        } else {
            c.title = "🤖 Hey! Heute noch nichts gelernt?"
            c.body  = "Nur 5 Minuten reichen. Theo zeigt dir den Weg 🗺️"
        }
        c.sound = .default

        var comps = DateComponents()
        comps.hour   = 20
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.streakEveningID,
                                         content: c, trigger: trigger))
    }

    // MARK: - Lernplan / Lernset Daily  (user-configured hour, default 19:00)

    private func scheduleLernplan(plans: [LernPlan], sets: [LernSet],
                                   center: UNUserNotificationCenter) {
        let c = UNMutableNotificationContent()
        c.sound = .default

        // Find any open task for today
        let today = Calendar.current.startOfDay(for: Date())
        var openTask: LernPlanAufgabe? = nil
        var planName: String? = nil

        outer: for plan in plans {
            for tag in plan.tage {
                if Calendar.current.isDate(tag.datum, inSameDayAs: today) {
                    if let task = tag.aufgaben.first(where: { !$0.completed }) {
                        openTask = task
                        planName = plan.fach
                        break outer
                    }
                }
            }
        }

        if let task = openTask {
            c.title = "📚 Theo hat deinen Plan für heute!"
            let subject = planName.map { " (\($0))" } ?? ""
            c.body  = "\u{201E}\(task.titel)\u{201C}\(subject) wartet auf dich. Lass uns loslegen \u{1F4AA}"
        } else if !sets.isEmpty, let pick = sets.randomElement() {
            c.title = "🤖 Theo hat eine Idee für dich!"
            c.body  = "Wie w\u{00E4}r's mit \u{201E}\(pick.name)\u{201C}? Nur ein paar Karten \u{2013} du schaffst das \u{1F60A}"
        } else {
            c.title = "🤖 Theo ruft nach dir!"
            c.body  = "Erstell heute dein erstes Lernset und starte deine Lernreise 🚀"
        }

        let savedHour = UserDefaults.standard.integer(forKey: "lernReminderHour")
        var comps = DateComponents()
        comps.hour   = savedHour > 0 ? savedHour : 19
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.lernplanDailyID,
                                         content: c, trigger: trigger))
    }

    // MARK: - Helpers

    private func hoursUntilMidnight() -> Int {
        let cal = Calendar.current
        let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
        return cal.dateComponents([.hour], from: Date(), to: end).hour ?? 4
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
