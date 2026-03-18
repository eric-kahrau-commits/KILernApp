import Foundation
import WidgetKit

// MARK: - Shared model types
// Identical structs are redeclared in the widget extension — keep in sync.

struct WidgetTask: Codable, Identifiable {
    let id: String
    let titel: String
    let fach: String
    let planId: String
    let completed: Bool
}

struct WidgetSetPreview: Codable, Identifiable {
    let id: String
    let name: String
    let subject: String
}

// MARK: - WidgetDataBridge

/// Writes live app data into the shared App Group so all widget timelines stay fresh.
/// Call `update(...)` whenever streak, plans or sets change.
///
/// Setup required (one-time in Xcode):
/// 1. Main app target → Signing & Capabilities → + → App Groups → "group.com.openlearn.app"
/// 2. Widget Extension target → same App Group
struct WidgetDataBridge {

    static let appGroupID = "group.com.openlearn.app"

    private static var ud: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Write

    static func update(streak: Int, streakDoneToday: Bool = false, plans: [LernPlan], sets: [LernSet]) {
        let defaults = ud

        // 1. Streak
        defaults?.set(streak, forKey: "widget_streak")
        defaults?.set(streakDoneToday, forKey: "widget_streak_done")

        // 2. Total set count (quick stats)
        defaults?.set(sets.count, forKey: "widget_total_sets")

        // 3. Today's open tasks (max 5)
        let today = Calendar.current.startOfDay(for: Date())
        var tasks: [WidgetTask] = []

        outer: for plan in plans {
            for tag in plan.tage {
                guard Calendar.current.isDate(tag.datum, inSameDayAs: today) else { continue }
                for aufgabe in tag.aufgaben {
                    tasks.append(WidgetTask(
                        id:        aufgabe.id.uuidString,
                        titel:     aufgabe.titel,
                        fach:      plan.fach,
                        planId:    plan.id.uuidString,
                        completed: aufgabe.completed
                    ))
                    if tasks.count >= 5 { break outer }
                }
            }
        }
        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults?.set(encoded, forKey: "widget_today_tasks")
        }

        // 4. Suggested sets (max 3, prefer recently created)
        let previews: [WidgetSetPreview] = sets
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { WidgetSetPreview(id: $0.id.uuidString, name: $0.name, subject: $0.subject) }
        if let encoded = try? JSONEncoder().encode(previews) {
            defaults?.set(encoded, forKey: "widget_sets")
        }

        defaults?.set(Date().timeIntervalSince1970, forKey: "widget_updated")

        // 5. Tell WidgetKit to reload all timelines
        WidgetCenter.shared.reloadAllTimelines()
    }
}
