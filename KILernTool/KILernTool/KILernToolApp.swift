import SwiftUI
import FirebaseCore

@main
struct KILernToolApp: App {
    @StateObject private var themeManager    = ThemeManager()
    @StateObject private var store           = LernSetStore.shared
    @StateObject private var lernPlanStore   = LernPlanStore.shared
    @StateObject private var streakManager   = StreakManager.shared
    @StateObject private var authManager     = AuthManager.shared
    @StateObject private var notifManager    = NotificationManager.shared

    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(store)
                .environmentObject(lernPlanStore)
                .environmentObject(streakManager)
                .environmentObject(authManager)
                // Keep widgets in sync whenever data changes while app is open
                .onChange(of: streakManager.currentStreak) { _, streak in
                    WidgetDataBridge.update(streak: streak, streakDoneToday: streakManager.isActiveToday, plans: lernPlanStore.plans, sets: store.lernSets)
                }
                .onChange(of: lernPlanStore.plans) { _, plans in
                    WidgetDataBridge.update(streak: streakManager.currentStreak, streakDoneToday: streakManager.isActiveToday, plans: plans, sets: store.lernSets)
                }
                .onChange(of: store.lernSets) { _, sets in
                    WidgetDataBridge.update(streak: streakManager.currentStreak, streakDoneToday: streakManager.isActiveToday, plans: lernPlanStore.plans, sets: sets)
                }
        }
        // Every time the app becomes active, refresh the next-day notification
        // so the lernplan body is always up-to-date.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Refresh widgets with latest data
                WidgetDataBridge.update(
                    streak:          streakManager.currentStreak,
                    streakDoneToday: streakManager.isActiveToday,
                    plans:           lernPlanStore.plans,
                    sets:            store.lernSets
                )
                Task {
                    await notifManager.scheduleAll(
                        streak: streakManager.currentStreak,
                        plans:  lernPlanStore.plans,
                        sets:   store.lernSets
                    )
                }
            }
        }
    }
}
