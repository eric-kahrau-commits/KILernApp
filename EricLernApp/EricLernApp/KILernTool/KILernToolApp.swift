import SwiftUI

@main
struct KILernToolApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var store = LernSetStore.shared
    @StateObject private var lernPlanStore = LernPlanStore.shared
    @StateObject private var streakManager = StreakManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(store)
                .environmentObject(lernPlanStore)
                .environmentObject(streakManager)
        }
    }
}
