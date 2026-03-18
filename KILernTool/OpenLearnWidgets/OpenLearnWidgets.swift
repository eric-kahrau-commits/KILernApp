import WidgetKit
import SwiftUI

// MARK: - Shared Models (mirror of WidgetDataBridge — keep in sync)

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

// MARK: - App Group Data Reader

private let kAppGroup = "group.com.openlearn.app"

private func loadWidgetData() -> (streak: Int, doneToday: Bool, totalSets: Int, tasks: [WidgetTask], sets: [WidgetSetPreview]) {
    let ud = UserDefaults(suiteName: kAppGroup)
    let streak      = ud?.integer(forKey: "widget_streak") ?? 0
    let doneToday   = ud?.bool(forKey: "widget_streak_done") ?? false
    let totalSets   = ud?.integer(forKey: "widget_total_sets") ?? 0
    let tasks: [WidgetTask] = {
        guard let d = ud?.data(forKey: "widget_today_tasks"),
              let v = try? JSONDecoder().decode([WidgetTask].self, from: d) else { return [] }
        return v
    }()
    let sets: [WidgetSetPreview] = {
        guard let d = ud?.data(forKey: "widget_sets"),
              let v = try? JSONDecoder().decode([WidgetSetPreview].self, from: d) else { return [] }
        return v
    }()
    return (streak, doneToday, totalSets, tasks, sets)
}

// MARK: - Streak Mood System

enum StreakMood {
    case celebrating   // streak erledigt heute
    case morning       // 5–11 Uhr, noch nicht erledigt
    case afternoon     // 12–16 Uhr, langsam angespannt
    case evening       // 17–21 Uhr, nervös
    case panic         // 22+ Uhr oder kein Streak, nach 12 Uhr

    static func current(hour: Int, doneToday: Bool, streak: Int) -> StreakMood {
        if doneToday { return .celebrating }
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return streak > 0 ? .afternoon : .evening
        case 17..<22: return .evening
        default:     return .panic
        }
    }

    // Hintergrund-Gradient
    var gradientColors: [Color] {
        switch self {
        case .celebrating:
            return [Color(red: 0.08, green: 0.55, blue: 0.40), Color(red: 0.05, green: 0.35, blue: 0.55)]
        case .morning:
            return [Color(red: 0.45, green: 0.20, blue: 0.95), Color(red: 0.20, green: 0.05, blue: 0.58)]
        case .afternoon:
            return [Color(red: 0.50, green: 0.15, blue: 0.85), Color(red: 0.75, green: 0.35, blue: 0.10)]
        case .evening:
            return [Color(red: 0.80, green: 0.35, blue: 0.05), Color(red: 0.55, green: 0.10, blue: 0.05)]
        case .panic:
            return [Color(red: 0.85, green: 0.15, blue: 0.05), Color(red: 0.50, green: 0.05, blue: 0.02)]
        }
    }

    // (Überschrift, Nachricht)
    func labels(streak: Int) -> (String, String) {
        switch self {
        case .celebrating:
            if streak > 7  { return ("Super gemacht! 🎉", "Streak gesichert! Bis morgen \u{1F917}") }
            return ("Streak gesichert! 🎉", "Theo freut sich auf morgen \u{1F917}")
        case .morning:
            if streak == 0 { return ("Guten Morgen!", "Starte heute deinen ersten Tag \u{1F680}") }
            if streak > 29 { return ("\(streak) Tage Legende!", "Theo ist stolz auf dich \u{2B50}") }
            return ("\(streak) \(streak == 1 ? "Tag" : "Tage") Streak", "Heute wieder dran bleiben \u{1F4AA}")
        case .afternoon:
            return ("Noch Zeit!", "Verlängere deinen Streak heute \u{23F0}")
        case .evening:
            return ("Nur noch wenige Stunden!", "Theo wird schon nervös \u{1F605}")
        case .panic:
            if streak == 0 { return ("Heute noch starten?", "Ein Tag reicht, um anzufangen \u{1F4AB}") }
            return ("LETZTE CHANCE!", "Streak rettet sich nicht von allein \u{1F6A8}")
        }
    }

    // Hintergrundsymbol (große deko)
    var bgEmoji: String {
        switch self {
        case .celebrating: return "🎉"
        case .morning:     return "☀️"
        case .afternoon:   return "⏰"
        case .evening:     return "🌙"
        case .panic:       return "🚨"
        }
    }
}

// MARK: - Timeline Entry & Provider

struct OpenLearnEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let streakDoneToday: Bool
    let totalSets: Int
    let tasks: [WidgetTask]
    let sets: [WidgetSetPreview]
}

struct OpenLearnProvider: TimelineProvider {
    func placeholder(in context: Context) -> OpenLearnEntry {
        OpenLearnEntry(date: Date(), streak: 7, streakDoneToday: false, totalSets: 12,
                       tasks: [WidgetTask(id: "1", titel: "Mathe Kapitel 3", fach: "Mathematik", planId: "p1", completed: false),
                                WidgetTask(id: "2", titel: "Vokabeln üben", fach: "Englisch", planId: "p1", completed: false)],
                       sets: [WidgetSetPreview(id: "1", name: "Vokabeln Englisch", subject: "Englisch"),
                               WidgetSetPreview(id: "2", name: "Mathe Formeln", subject: "Mathematik")])
    }

    func getSnapshot(in context: Context, completion: @escaping (OpenLearnEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context)); return
        }
        let d = loadWidgetData()
        completion(OpenLearnEntry(date: Date(), streak: d.streak, streakDoneToday: d.doneToday,
                                  totalSets: d.totalSets, tasks: d.tasks, sets: d.sets))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OpenLearnEntry>) -> Void) {
        let d = loadWidgetData()
        let now = Date()
        let entry = OpenLearnEntry(date: now, streak: d.streak, streakDoneToday: d.doneToday,
                                   totalSets: d.totalSets, tasks: d.tasks, sets: d.sets)

        // Refresh-Zeitpunkte: Stimmungswechsel und halbstündlich abends
        let hour = Calendar.current.component(.hour, from: now)
        let interval: TimeInterval = (hour >= 17) ? 1800 : (hour >= 12 ? 3600 : 7200)
        let next = now.addingTimeInterval(interval)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Theo Pixel Mascot
// 4 Stimmungen: happy, worried, panicking, celebrating
// Farb-Codes: 0=transparent 1=weiß 2=dunkel-lila 3=highlight 4=schweiß(blau) 5=rouge(pink)

struct TheoPixel: View {
    let size: CGFloat
    var mood: StreakMood = .morning

    // MARK: Grids

    private static let gridHappy: [[UInt8]] = [
        [0,0,0,1,1,1,1,1,1,1,0,0,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,1,1,1,1,1,1,1,1,1,0],
        [0,1,1,2,2,1,1,1,2,2,1,1,0],
        [0,1,1,2,2,1,1,1,2,2,1,1,0],
        [0,1,1,1,1,3,1,1,1,1,1,1,0],
        [0,1,5,1,1,1,1,1,1,1,5,1,0],
        [0,1,2,1,2,2,2,2,2,1,2,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,0,1,1,1,1,1,0,1,1,0],
        [0,1,1,0,0,1,1,1,0,0,1,1,0],
        [0,1,0,0,0,1,1,1,0,0,0,1,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0],
    ]

    private static let gridWorried: [[UInt8]] = [
        [0,0,0,1,1,1,1,1,1,1,0,0,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,2,2,1,1,1,2,2,1,1,0],
        [0,1,1,1,2,2,1,2,2,1,1,1,0],
        [0,1,1,1,2,2,1,2,2,1,1,1,0],
        [0,1,1,1,1,3,4,1,1,1,1,1,0],
        [0,1,1,1,1,1,1,1,1,1,1,1,0],
        [0,1,1,1,2,2,2,2,2,1,1,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,0,1,1,1,1,1,0,1,1,0],
        [0,1,1,0,0,1,1,1,0,0,1,1,0],
        [0,1,0,0,0,1,1,1,0,0,0,1,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0],
    ]

    private static let gridPanic: [[UInt8]] = [
        [0,0,0,1,1,1,1,1,1,1,0,0,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,2,2,1,1,1,1,1,2,2,1,0],
        [0,1,2,2,2,1,1,1,2,2,2,1,0],
        [0,1,2,2,2,1,1,1,2,2,2,1,0],
        [4,4,1,1,1,3,4,1,4,1,1,4,4],
        [0,1,1,2,1,1,1,1,1,2,1,1,0],
        [0,1,1,1,2,2,2,2,2,1,1,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,1,0,1,1,1,0,1,1,1,0],
        [0,1,1,1,0,1,1,1,0,1,1,1,0],
        [0,0,1,1,0,1,1,1,0,1,1,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0],
    ]

    private static let gridCelebrating: [[UInt8]] = [
        [0,1,0,0,1,1,1,1,1,0,0,1,0],
        [0,1,1,0,1,1,1,1,1,0,1,1,0],
        [0,1,1,1,1,1,1,1,1,1,1,1,0],
        [0,1,2,1,1,1,1,1,1,1,2,1,0],
        [0,1,1,2,1,1,1,1,1,2,1,1,0],
        [0,1,5,5,1,3,1,1,1,5,5,1,0],
        [0,1,2,1,1,1,1,1,1,1,2,1,0],
        [0,1,1,2,2,2,2,2,2,2,1,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,0,0],
        [0,0,1,0,0,1,1,1,0,0,1,0,0],
        [0,0,1,0,0,1,1,1,0,0,1,0,0],
        [0,0,0,0,0,1,1,1,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0],
    ]

    private static func grid(for mood: StreakMood) -> [[UInt8]] {
        switch mood {
        case .celebrating:           return gridCelebrating
        case .morning:               return gridHappy
        case .afternoon:             return gridWorried
        case .evening, .panic:       return gridPanic
        }
    }

    private static func bodyColor(for mood: StreakMood) -> Color {
        switch mood {
        case .celebrating: return Color(red: 0.90, green: 1.00, blue: 0.95)
        case .morning:     return .white
        case .afternoon:   return Color(red: 1.00, green: 0.97, blue: 0.90)
        case .evening:     return Color(red: 1.00, green: 0.92, blue: 0.85)
        case .panic:       return Color(red: 1.00, green: 0.88, blue: 0.82)
        }
    }

    var body: some View {
        Canvas { ctx, sz in
            let g   = Self.grid(for: mood)
            let px  = sz.width / CGFloat(g[0].count)
            let body = Self.bodyColor(for: mood)
            for (r, row) in g.enumerated() {
                for (c, val) in row.enumerated() {
                    guard val != 0 else { continue }
                    let rect = CGRect(x: CGFloat(c) * px, y: CGFloat(r) * px,
                                      width: px + 0.5, height: px + 0.5)
                    let color: Color
                    switch val {
                    case 1: color = body
                    case 2: color = Color(red: 0.14, green: 0.07, blue: 0.45)
                    case 3: color = Color.white.opacity(0.75)
                    case 4: color = Color(red: 0.55, green: 0.82, blue: 1.0)
                    case 5: color = Color(red: 1.0,  green: 0.70, blue: 0.72)
                    default: color = .clear
                    }
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - App Icon Badge (für TodayWidget & QuickStatsWidget)

struct TheoIconBadge: View {
    let size: CGFloat
    var mood: StreakMood = .morning
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.49, green: 0.23, blue: 0.93),
                             Color(red: 0.18, green: 0.06, blue: 0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.4),
                        radius: size * 0.18, x: 0, y: size * 0.08)
            TheoPixel(size: size * 0.70, mood: mood)
        }
    }
}

// MARK: - Subject Color Helper

private func subjectColor(_ s: String) -> Color {
    let l = s.lowercased()
    if l.contains("math")       { return Color(red: 0.25, green: 0.47, blue: 0.98) }
    if l.contains("deutsch")    { return Color(red: 0.92, green: 0.28, blue: 0.28) }
    if l.contains("englisch")   { return Color(red: 0.18, green: 0.72, blue: 0.45) }
    if l.contains("bio")        { return Color(red: 0.25, green: 0.65, blue: 0.30) }
    if l.contains("physik")     { return Color(red: 0.55, green: 0.20, blue: 0.90) }
    if l.contains("chemie")     { return Color(red: 0.95, green: 0.45, blue: 0.10) }
    if l.contains("geschichte") { return Color(red: 0.75, green: 0.55, blue: 0.25) }
    return Color(red: 0.38, green: 0.18, blue: 0.90)
}

// MARK: ─────────────────────────────────────────────
// MARK: - StreakWidget  (small) — Emotionales Mood-System
// MARK: ─────────────────────────────────────────────

private struct StreakWidgetView: View {
    let entry: OpenLearnEntry

    private var hour: Int { Calendar.current.component(.hour, from: entry.date) }
    private var mood: StreakMood {
        StreakMood.current(hour: hour, doneToday: entry.streakDoneToday, streak: entry.streak)
    }

    var body: some View {
        ZStack {
            // ── Hintergrund-Glow ──────────────────────
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 35, y: -30)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 80, height: 80)
                .offset(x: -40, y: 40)

            // ── Haupt-Content ─────────────────────────
            VStack(spacing: 0) {
                Spacer(minLength: 2)

                // Maskottchen + Flamme
                mascotAndFlame
                    .padding(.bottom, 4)

                // Streak-Zahl
                Text("\(entry.streak)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

                // Tage-Label
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 12))
                    Text(entry.streak == 1 ? "Tag" : "Tage")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.bottom, 5)

                // Stimmungs-Botschaft
                let labels = mood.labels(streak: entry.streak)
                VStack(spacing: 1) {
                    Text(labels.0)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(labels.1)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: mood.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        }
    }

    // ── Maskottchen-Flammen-Kombo ─────────────────
    @ViewBuilder
    private var mascotAndFlame: some View {
        switch mood {

        case .celebrating:
            // Theo mit erhobenen Armen, Flamme links davon — "Ich hab's geschafft!"
            ZStack(alignment: .center) {
                Text("🔥")
                    .font(.system(size: 20))
                    .offset(x: -18, y: 6)
                TheoPixel(size: 44, mood: .celebrating)
                Text("✨")
                    .font(.system(size: 10))
                    .offset(x: 20, y: -16)
            }

        case .morning:
            // Theo entspannt neben der Flamme
            HStack(spacing: 2) {
                TheoPixel(size: 38, mood: .morning)
                Text("🔥")
                    .font(.system(size: 18))
                    .offset(y: 3)
            }

        case .afternoon:
            // Theo guckt nervös zur Flamme rüber
            HStack(spacing: 1) {
                TheoPixel(size: 38, mood: .afternoon)
                VStack(spacing: 0) {
                    Text("⚡️")
                        .font(.system(size: 10))
                    Text("🔥")
                        .font(.system(size: 16))
                }
            }

        case .evening:
            // Theo will die Flamme beschützen, streckt Arme aus
            ZStack(alignment: .center) {
                Text("🔥")
                    .font(.system(size: 22))
                    .offset(x: 14, y: 4)
                TheoPixel(size: 40, mood: .evening)
                    .offset(x: -6)
            }

        case .panic:
            // Theo komplett panisch — Flamme flackert gefährlich
            ZStack(alignment: .center) {
                // Flackernde Flamme im Hintergrund
                Text("🔥")
                    .font(.system(size: 26))
                    .offset(x: 16, y: 2)
                Text("💨")
                    .font(.system(size: 12))
                    .offset(x: -16, y: -14)
                TheoPixel(size: 40, mood: .panic)
                    .offset(x: -8)
            }
        }
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpenLearnProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Theo zeigt dir wie dringend der Streak ist.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: - TodayWidget  (medium + large)
// MARK: ─────────────────────────────────────────────

private struct TodayWidgetView: View {
    let entry: OpenLearnEntry
    @Environment(\.widgetFamily) var family

    private var openTasks: [WidgetTask] { entry.tasks.filter { !$0.completed } }
    private var maxTasks: Int { family == .systemLarge ? 5 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──────────────────────────────
            HStack(spacing: 10) {
                TheoIconBadge(size: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Open Learn")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(openTasks.isEmpty ? "Alles erledigt! 🎉" : "Heute wartet auf dich")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Streak pill
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 11))
                    Text("\(entry.streak)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.13)))
            }
            .padding(.horizontal, 14).padding(.top, 13).padding(.bottom, 10)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 14)

            // ── Content ──────────────────────────────
            if !openTasks.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(openTasks.prefix(maxTasks).enumerated()), id: \.element.id) { idx, task in
                        Link(destination: URL(string: "openlearn://plan?id=\(task.planId)")!) {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(subjectColor(task.fach))
                                    .frame(width: 3, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.titel)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(task.fach)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.45))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(idx % 2 == 0 ? 0.0 : 0.03))
                        }
                    }
                }
                .padding(.top, 4)

            } else if !entry.sets.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Vorschläge zum Lernen")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 6)

                    ForEach(entry.sets.prefix(3)) { set in
                        Link(destination: URL(string: "openlearn://learn?id=\(set.id)")!) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(subjectColor(set.subject).opacity(0.25))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "rectangle.stack.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(subjectColor(set.subject))
                                }
                                Text(set.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 7)
                        }
                    }
                }

            } else {
                Link(destination: URL(string: "openlearn://new")!) {
                    VStack(spacing: 8) {
                        Text("📚")
                            .font(.system(size: 28))
                        Text("Ersten Lernplan erstellen")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.07, green: 0.05, blue: 0.15)
                LinearGradient(
                    colors: [Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.18), .clear],
                    startPoint: .topLeading, endPoint: .center)
            }
        }
    }
}

struct TodayWidget: Widget {
    let kind = "TodayWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpenLearnProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Heute")
        .description("Dein heutiger Lernplan auf einen Blick.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: - QuickStatsWidget  (small + medium)
// MARK: ─────────────────────────────────────────────

private struct QuickStatsWidgetView: View {
    let entry: OpenLearnEntry
    @Environment(\.widgetFamily) var family

    private var completedToday: Int { entry.tasks.filter { $0.completed }.count }
    private var totalToday: Int { entry.tasks.count }
    private var openToday: Int { entry.tasks.filter { !$0.completed }.count }

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        if family == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TheoIconBadge(size: 26)
                Spacer()
                Text("Open\nLearn")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(accent.opacity(0.55))
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(1)
            }
            .padding(.bottom, 6)

            Spacer()

            Text("\(entry.streak)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("🔥 Streak")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 6) {
                miniStat(icon: "rectangle.stack.fill", value: "\(entry.totalSets)", color: accent)
                Spacer()
                miniStat(icon: "checkmark.circle.fill", value: "\(completedToday)/\(totalToday)", color: .green)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.97, green: 0.96, blue: 1.0)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                TheoIconBadge(size: 36)

                Text("\(entry.streak)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("🔥 Streak")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(LinearGradient(
                colors: [Color(red: 0.45, green: 0.20, blue: 0.95),
                         Color(red: 0.20, green: 0.05, blue: 0.58)],
                startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(alignment: .leading, spacing: 10) {
                statRow(icon: "rectangle.stack.fill",
                        label: "Lernsets", value: "\(entry.totalSets)", color: accent)
                statRow(icon: "checkmark.circle.fill",
                        label: "Heute erledigt", value: "\(completedToday)", color: .green)
                statRow(icon: "clock.fill",
                        label: "Noch offen", value: "\(openToday)", color: .orange)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            Color(red: 0.97, green: 0.96, blue: 1.0)
        }
    }

    private func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9)).foregroundStyle(color)
            Text(value).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(color)
        }
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13)).foregroundStyle(color).frame(width: 18)
            Text(label)
                .font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(color)
        }
    }
}

struct QuickStatsWidget: Widget {
    let kind = "QuickStatsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpenLearnProvider()) { entry in
            QuickStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Statistiken")
        .description("Streak, Sets und Tagesfortschritt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
