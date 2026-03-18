import SwiftUI

struct StatsView: View {
    @EnvironmentObject var lernSetStore: LernSetStore
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var streakManager: StreakManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // 1. Top overview row
                overviewRow

                // 2. Aktivität letzte 7 Tage
                activitySection

                // 3. Lernsets nach Fach
                if !subjectStats.isEmpty {
                    subjectSection
                }

                // 4. KI vs. Manuell
                if totalSets > 0 {
                    kiVsManualSection
                }

                // 5. Streak-Übersicht
                streakSection

                // 6. Lernplan-Fortschritt
                if !lernPlanStore.plans.isEmpty {
                    planSection
                }

                // 7. Aufgaben-Statistik
                if totalAufgaben > 0 {
                    aufgabenSection
                }

                // 8. Aufgaben-Typen Verteilung
                if totalAufgaben > 0 {
                    aufgabenTypSection
                }

                // 9. Nächste Prüfungen
                if !upcomingTests.isEmpty {
                    upcomingTestsSection
                }

                // 10. 4-Wochen Überblick
                weeklyOverviewSection

            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Computed data

    private var totalSets: Int { lernSetStore.lernSets.count }
    private var totalCards: Int { lernSetStore.lernSets.reduce(0) { $0 + $1.cards.count } }
    private var kiCount: Int { lernSetStore.lernSets.filter { $0.isKIGenerated }.count }
    private var manualCount: Int { lernSetStore.lernSets.filter { !$0.isKIGenerated }.count }

    private var totalAufgaben: Int {
        lernPlanStore.plans.flatMap { $0.tage }.flatMap { $0.aufgaben }.count
    }
    private var completedAufgaben: Int {
        lernPlanStore.plans.flatMap { $0.tage }.flatMap { $0.aufgaben }.filter { $0.completed }.count
    }
    private var aufgabenQuote: Double {
        totalAufgaben == 0 ? 0 : Double(completedAufgaben) / Double(totalAufgaben)
    }

    private var subjectStats: [(name: String, cards: Int, sets: Int, color: Color, icon: String)] {
        let grouped = Dictionary(grouping: lernSetStore.lernSets, by: { $0.subject })
        return grouped.map { subject, sets in
            let cards = sets.reduce(0) { $0 + $1.cards.count }
            let sub = Subject.all.first(where: { $0.name == subject })
            return (name: subject, cards: cards, sets: sets.count,
                    color: sub?.color ?? .gray, icon: sub?.icon ?? "folder")
        }.sorted { $0.cards > $1.cards }
    }
    private var maxSubjectCards: Int { max(1, subjectStats.map { $0.cards }.max() ?? 1) }

    private var last7Days: [(label: String, count: Int)] {
        let fmt = DateFormatter()
        fmt.dateFormat = "E"
        return (0..<7).reversed().map { offset in
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let count = lernSetStore.lernSets.filter {
                Calendar.current.isDate($0.createdAt, inSameDayAs: day)
            }.count
            return (label: fmt.string(from: day), count: count)
        }
    }
    private var maxDayCount: Int { max(1, last7Days.map { $0.count }.max() ?? 1) }

    // MARK: - 1. Overview Row

    private var overviewRow: some View {
        HStack(spacing: 10) {
            overviewCard(
                value: "\(totalCards)",
                label: "Karten gesamt",
                icon: "rectangle.stack.fill",
                colors: [AppColors.statsKartenStart, AppColors.statsKartenEnd]
            )
            overviewCard(
                value: "\(totalSets)",
                label: "Lernsets",
                icon: "folder.fill",
                colors: [AppColors.statsSetsStart, AppColors.statsSetsEnd]
            )
            overviewCard(
                value: "\(streakManager.currentStreak)",
                label: "Streak",
                icon: "flame.fill",
                colors: [AppColors.statsStreakStart, AppColors.statsStreakEnd]
            )
        }
    }

    private func overviewCard(value: String, label: String, icon: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - 2. Aktivität (7-Tage-Balkendiagramm)

    private var activitySection: some View {
        statsCard(title: "Erstellt diese Woche", icon: "chart.bar.fill",
                  iconColor: Color(red: 0.38, green: 0.18, blue: 0.90)) {
            VStack(spacing: 10) {
                // Bar chart
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(last7Days.enumerated()), id: \.offset) { idx, day in
                        VStack(spacing: 4) {
                            if day.count > 0 {
                                Text("\(day.count)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90))
                            }
                            let barH = max(6, CGFloat(day.count) / CGFloat(maxDayCount) * 70)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    day.count > 0
                                    ? LinearGradient(
                                        colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                                 Color(red: 0.30, green: 0.52, blue: 0.98)],
                                        startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [Color(uiColor: .tertiarySystemGroupedBackground),
                                                 Color(uiColor: .tertiarySystemGroupedBackground)],
                                        startPoint: .top, endPoint: .bottom)
                                )
                                .frame(height: barH)
                            Text(day.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(idx) * 0.05), value: day.count)
                    }
                }
                .frame(height: 100)
                .accessibilityLabel("Balkendiagramm: Erstellte Lernsets diese Woche. Gesamt: \(last7Days.reduce(0) { $0 + $1.count }) Sets.")

                if lernSetStore.lernSets.isEmpty {
                    Text("Noch keine Lernsets erstellt")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - 3. Lernsets nach Fach

    private var subjectSection: some View {
        statsCard(title: "Karten nach Fach", icon: "books.vertical.fill",
                  iconColor: Color(red: 0.10, green: 0.64, blue: 0.54)) {
            VStack(spacing: 10) {
                ForEach(Array(subjectStats.prefix(6).enumerated()), id: \.offset) { _, stat in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(stat.color.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: stat.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(stat.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stat.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(stat.cards) Karten")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.07))
                                        .frame(height: 5)
                                    Capsule()
                                        .fill(stat.color)
                                        .frame(width: geo.size.width * CGFloat(stat.cards) / CGFloat(maxSubjectCards), height: 5)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stat.cards)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 4. KI vs. Manuell

    private var kiVsManualSection: some View {
        statsCard(title: "KI vs. Manuell", icon: "sparkles",
                  iconColor: Color(red: 0.95, green: 0.55, blue: 0.10)) {
            HStack(spacing: 20) {
                // Circular indicator
                ProgressRing(
                    progress: totalSets == 0 ? 0 : Double(kiCount) / Double(totalSets),
                    size: 80,
                    lineWidth: 10,
                    gradient: [AppColors.brandQuick, Color(red: 1.00, green: 0.72, blue: 0.18)],
                    centerLabel: "\(totalSets == 0 ? 0 : kiCount * 100 / totalSets)%",
                    centerSubLabel: "KI"
                )

                VStack(alignment: .leading, spacing: 12) {
                    kiLegendRow(
                        color: Color(red: 0.95, green: 0.55, blue: 0.10),
                        label: "KI-generiert",
                        count: kiCount
                    )
                    kiLegendRow(
                        color: Color(red: 0.38, green: 0.18, blue: 0.90),
                        label: "Manuell erstellt",
                        count: manualCount
                    )
                }
                Spacer()
            }
        }
    }

    private func kiLegendRow(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - 5. Streak-Übersicht

    private var streakSection: some View {
        statsCard(title: "Streak-Übersicht", icon: "flame.fill",
                  iconColor: Color(red: 0.96, green: 0.42, blue: 0.08)) {
            HStack(spacing: 0) {
                streakStat(value: "\(streakManager.currentStreak)",
                           label: "Aktuell",
                           color: Color(red: 0.96, green: 0.42, blue: 0.08))
                Divider().frame(height: 40)
                streakStat(value: "\(streakManager.longestStreak)",
                           label: "Bester",
                           color: Color(red: 0.38, green: 0.18, blue: 0.90))
                Divider().frame(height: 40)
                streakStat(value: streakManager.isActiveToday ? "✓" : "–",
                           label: "Heute",
                           color: streakManager.isActiveToday ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func streakStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 6. Lernplan-Fortschritt

    private var planSection: some View {
        statsCard(title: "Lernplan-Fortschritt", icon: "calendar.badge.checkmark",
                  iconColor: Color(red: 0.10, green: 0.48, blue: 0.92)) {
            VStack(spacing: 10) {
                ForEach(lernPlanStore.plans.prefix(3)) { plan in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(plan.titel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(plan.overallProgress * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(red: 0.10, green: 0.48, blue: 0.92))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.07))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.10, green: 0.48, blue: 0.92),
                                                     Color(red: 0.30, green: 0.52, blue: 0.98)],
                                            startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: geo.size.width * plan.overallProgress, height: 6)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: plan.overallProgress)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    // MARK: - 7. Aufgaben-Statistik

    private var aufgabenSection: some View {
        statsCard(title: "Aufgaben erledigt", icon: "checkmark.circle.fill",
                  iconColor: Color(red: 0.10, green: 0.64, blue: 0.54)) {
            HStack(spacing: 16) {
                // Arc indicator
                ProgressRing(
                    progress: aufgabenQuote,
                    size: 80,
                    lineWidth: 10,
                    gradient: [Color(red: 0.10, green: 0.64, blue: 0.54),
                               Color(red: 0.20, green: 0.82, blue: 0.60)],
                    centerLabel: "\(Int(aufgabenQuote * 100))%"
                )

                VStack(alignment: .leading, spacing: 10) {
                    aufgabenLegendRow(
                        color: Color(red: 0.10, green: 0.64, blue: 0.54),
                        label: "Erledigt",
                        count: completedAufgaben
                    )
                    aufgabenLegendRow(
                        color: Color.primary.opacity(0.15),
                        label: "Offen",
                        count: totalAufgaben - completedAufgaben
                    )
                    aufgabenLegendRow(
                        color: Color(red: 0.38, green: 0.18, blue: 0.90),
                        label: "Gesamt",
                        count: totalAufgaben
                    )
                }
                Spacer()
            }
        }
    }

    private func aufgabenLegendRow(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - 8. Aufgaben-Typen Verteilung

    private var aufgabenTypData: [(label: String, count: Int, color: Color)] {
        let alle = lernPlanStore.plans.flatMap { $0.tage }.flatMap { $0.aufgaben }
        let types: [(String, String, Color)] = [
            ("neuerStoff", "Neuer Stoff",  Color(red: 0.20, green: 0.48, blue: 0.95)),
            ("uebung",     "Übung",        Color(red: 0.15, green: 0.70, blue: 0.40)),
            ("wiederholung","Wiederholung",Color(red: 0.86, green: 0.50, blue: 0.10)),
            ("simulation", "Simulation",  Color(red: 0.85, green: 0.22, blue: 0.22)),
        ]
        return types.map { key, label, color in
            (label: label,
             count: alle.filter { $0.typ.lowercased() == key }.count,
             color: color)
        }.filter { $0.count > 0 }
    }

    private var aufgabenTypSection: some View {
        statsCard(title: "Lernplan-Aktivitäten", icon: "square.grid.2x2.fill",
                  iconColor: Color(red: 0.20, green: 0.48, blue: 0.95)) {
            let maxCount = max(1, aufgabenTypData.map { $0.count }.max() ?? 1)
            VStack(spacing: 10) {
                ForEach(Array(aufgabenTypData.enumerated()), id: \.offset) { idx, stat in
                    HStack(spacing: 10) {
                        Text(stat.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 100, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.07))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(stat.color)
                                    .frame(
                                        width: max(8, geo.size.width * CGFloat(stat.count) / CGFloat(maxCount)),
                                        height: 8
                                    )
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8)
                                               .delay(Double(idx) * 0.06), value: stat.count)
                            }
                        }
                        .frame(height: 8)
                        Text("\(stat.count)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(stat.color)
                            .frame(width: 24, alignment: .trailing)
                    }
                }

                // Balance-Hinweis
                let hasGoodBalance = aufgabenTypData.count >= 3
                HStack(spacing: 6) {
                    Image(systemName: hasGoodBalance ? "checkmark.circle.fill" : "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(hasGoodBalance ? Color.green : Color.orange)
                    Text(hasGoodBalance
                         ? "Gute Mischung aus Lernphasen!"
                         : "Tipp: Plane Wiederholungs- und Übungsphasen ein.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - 9. Nächste Prüfungen

    private var upcomingTests: [LernPlan] {
        lernPlanStore.plans
            .filter { $0.daysUntilTest >= 0 }
            .sorted { $0.daysUntilTest < $1.daysUntilTest }
    }

    private var upcomingTestsSection: some View {
        statsCard(title: "Nächste Prüfungen", icon: "calendar.badge.exclamationmark",
                  iconColor: Color(red: 0.85, green: 0.22, blue: 0.22)) {
            VStack(spacing: 10) {
                ForEach(upcomingTests.prefix(4)) { plan in
                    let days = plan.daysUntilTest
                    let urgencyColor: Color = days <= 2 ? .red : days <= 6 ? .orange : Color(red: 0.10, green: 0.48, blue: 0.92)
                    HStack(spacing: 12) {
                        // Countdown bubble
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(urgencyColor.opacity(0.12))
                                .frame(width: 46, height: 40)
                            VStack(spacing: 0) {
                                Text("\(days)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(urgencyColor)
                                Text("Tage")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(urgencyColor.opacity(0.8))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.titel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                let sub = Subject.all.first(where: { $0.name == plan.fach })
                                Image(systemName: sub?.icon ?? "folder")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(sub?.color ?? .secondary)
                                Text(plan.fach)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: 11))
                                Text(plan.testDatum, style: .date)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        // Progress ring mini
                        ProgressRing(
                            progress: plan.overallProgress,
                            size: 32,
                            lineWidth: 4,
                            color: urgencyColor,
                            centerLabel: "\(Int(plan.overallProgress * 100))%"
                        )
                    }
                }
            }
        }
    }

    // MARK: - 10. 4-Wochen Überblick

    private var last4Weeks: [(label: String, count: Int)] {
        (0..<4).reversed().map { weekOffset in
            let endDay = Calendar.current.date(byAdding: .day, value: -(weekOffset * 7), to: Date())!
            let startDay = Calendar.current.date(byAdding: .day, value: -6, to: endDay)!
            let count = lernSetStore.lernSets.filter {
                $0.createdAt >= Calendar.current.startOfDay(for: startDay) &&
                $0.createdAt <= endDay
            }.count
            let weekFmt = DateFormatter()
            weekFmt.dateFormat = "d.M."
            return (label: weekFmt.string(from: startDay), count: count)
        }
    }
    private var maxWeekCount: Int { max(1, last4Weeks.map { $0.count }.max() ?? 1) }

    private var weeklyOverviewSection: some View {
        statsCard(title: "4-Wochen Überblick", icon: "chart.line.uptrend.xyaxis",
                  iconColor: Color(red: 0.10, green: 0.64, blue: 0.54)) {
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(last4Weeks.enumerated()), id: \.offset) { idx, week in
                        VStack(spacing: 5) {
                            if week.count > 0 {
                                Text("\(week.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.10, green: 0.64, blue: 0.54))
                            }
                            let barH = max(8, CGFloat(week.count) / CGFloat(maxWeekCount) * 80)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    week.count > 0
                                    ? LinearGradient(
                                        colors: [Color(red: 0.10, green: 0.64, blue: 0.54),
                                                 Color(red: 0.20, green: 0.82, blue: 0.60)],
                                        startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [Color(uiColor: .tertiarySystemGroupedBackground),
                                                 Color(uiColor: .tertiarySystemGroupedBackground)],
                                        startPoint: .top, endPoint: .bottom)
                                )
                                .frame(height: barH)
                                .animation(.spring(response: 0.55, dampingFraction: 0.75)
                                           .delay(Double(idx) * 0.07), value: week.count)
                            Text("KW\(idx + 1)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(week.label)
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
                .accessibilityLabel("4-Wochen-Diagramm: Gesamt \(last4Weeks.reduce(0) { $0 + $1.count }) Sets in den letzten 4 Wochen erstellt.")

                // Empty state
                if last4Weeks.allSatisfy({ $0.count == 0 }) {
                    Text("Noch keine Lernsets in den letzten 4 Wochen erstellt")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // Trend-Hinweis
                let trend = (last4Weeks.last?.count ?? 0) - (last4Weeks.first?.count ?? 0)
                HStack(spacing: 5) {
                    Image(systemName: trend > 0 ? "arrow.up.right" : trend < 0 ? "arrow.down.right" : "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(trend > 0 ? Color.green : trend < 0 ? Color.orange : Color.secondary)
                    Text(trend > 0
                         ? "Mehr Sets als vor 4 Wochen – weiter so! 🚀"
                         : trend < 0
                         ? "Etwas weniger aktiv – du schaffst das!"
                         : "Gleichmäßiges Lernen – gut gemacht!")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Card Wrapper

    private func statsCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
