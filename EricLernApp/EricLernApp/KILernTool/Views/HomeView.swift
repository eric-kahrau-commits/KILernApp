import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore
    @EnvironmentObject var streakManager: StreakManager

    var onNavigateToLearn: (() -> Void)? = nil

    @State private var fullGreeting: String = ""
    @State private var visibleCount: Int = 0
    @State private var typingTimer: Timer?
    @State private var selectedPlan: LernPlan? = nil
    @State private var showZuletztSet: LernSet? = nil
    @State private var showKILernset = false
    @State private var showVokabel = false
    @State private var showScan = false
    @State private var showTestErstellen = false
    @State private var showTutor = false

    private let userName: String = "Eric"
    private let learnGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.18, blue: 0.90), Color(red: 0.10, green: 0.48, blue: 0.92)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var activePlan: LernPlan? {
        lernPlanStore.plans.first { $0.daysUntilTest >= 0 }
    }

    private var nextTestPlan: LernPlan? {
        lernPlanStore.plans
            .filter { $0.daysUntilTest >= 0 && $0.daysUntilTest <= 14 }
            .sorted { $0.daysUntilTest < $1.daysUntilTest }
            .first
    }

    private var totalCardCount: Int {
        lernSetStore.lernSets.reduce(0) { $0 + $1.cards.count }
    }

    private var subjectsWithSets: [Subject] {
        Subject.all.filter { lernSetStore.lernSets(for: $0.name).count > 0 }
    }

    private var recentSet: LernSet? {
        lernSetStore.lernSets.last
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // 1. Greeting + Streak
                greetingHeader

                // 2. Stats tiles
                statsRow

                // 3. Hero CTA
                learnNowButton

                // 4. Schnellzugriff
                SchnellaktionenWidget(
                    onKILernset: { showKILernset = true },
                    onVokabeln:  { showVokabel = true },
                    onScannen:   { showScan = true },
                    onTestErstellen: { showTestErstellen = true }
                )

                // 5. Heute
                HeuteWidget()

                // 6. Aktiver Lernplan
                if let plan = activePlan {
                    LernpfadWidget(plan: plan) { selectedPlan = plan }
                }

                // 7. Nächster Test Countdown (only if test within 14 days)
                if let plan = nextTestPlan {
                    NächsterTestWidget(plan: plan) { selectedPlan = plan }
                }

                // 8. Wochenaktivität
                WochenaktivitätWidget(
                    streak: streakManager.currentStreak,
                    isActiveToday: streakManager.isActiveToday
                )

                // 9. Meine Fächer (only if user has sets)
                if !subjectsWithSets.isEmpty {
                    FächerScrollWidget(
                        subjects: subjectsWithSets,
                        store: lernSetStore,
                        onNavigateToLearn: onNavigateToLearn
                    )
                }

                // 10. Zuletzt hinzugefügt (only if user has sets)
                if let set = recentSet {
                    ZuletztWidget(lernSet: set)
                }

                // 11. Sets Übersicht
                if !lernSetStore.lernSets.isEmpty {
                    SetsÜbersichtWidget(store: lernSetStore)
                }

                // 12. Tagesquote
                TagesquoteWidget()

                // 13. Olly – KI Lernbegleiter
                TutorHomeWidget { showTutor = true }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 48)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear { startGreeting() }
        .onDisappear { typingTimer?.invalidate() }
        .fullScreenCover(item: $selectedPlan) { plan in
            LernPlanDetailView(planId: plan.id)
                .environmentObject(lernPlanStore)
                .environmentObject(lernSetStore)
        }
        .fullScreenCover(isPresented: $showKILernset) {
            KILernsetStartView().environmentObject(lernSetStore)
        }
        .fullScreenCover(isPresented: $showVokabel) {
            VokabelStartView().environmentObject(lernSetStore)
        }
        .fullScreenCover(isPresented: $showScan) {
            ScanStartView().environmentObject(lernSetStore)
        }
        .fullScreenCover(isPresented: $showTestErstellen) {
            TestErstellenStartView().environmentObject(lernSetStore)
        }
        .fullScreenCover(isPresented: $showTutor) {
            AITutorView()
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(timeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(String(fullGreeting.prefix(visibleCount)))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
            // Streak badge
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(streakManager.currentStreak > 0
                                     ? Color(red: 0.96, green: 0.52, blue: 0.08)
                                     : Color(uiColor: .tertiaryLabel))
                Text("\(streakManager.currentStreak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }

    // MARK: - Stats Row (3 tiles)

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(
                value: "\(lernSetStore.lernSets.count)",
                label: "Lernsets",
                icon: "square.stack.fill",
                color: Color(red: 0.38, green: 0.18, blue: 0.90)
            )
            statTile(
                value: "\(totalCardCount)",
                label: "Karten",
                icon: "rectangle.on.rectangle.fill",
                color: Color(red: 0.10, green: 0.48, blue: 0.92)
            )
            statTile(
                value: "\(lernPlanStore.plans.filter { $0.daysUntilTest >= 0 }.count)",
                label: "Pläne",
                icon: "calendar.badge.checkmark",
                color: Color(red: 0.95, green: 0.45, blue: 0.10)
            )
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    // MARK: - Learn Now Button

    private var learnNowButton: some View {
        Button { onNavigateToLearn?() } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jetzt lernen")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(motivationSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.80))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(learnGradient)
                    .shadow(color: Color(red: 0.38, green: 0.18, blue: 0.90).opacity(0.35),
                            radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var timeLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "GUTEN MORGEN"
        case 12..<17: return "GUTEN NACHMITTAG"
        case 17..<22: return "GUTEN ABEND"
        default:      return "HALLO"
        }
    }

    private var motivationSubtitle: String {
        if let plan = activePlan {
            let d = plan.daysUntilTest
            if d <= 2 { return "Test in \(d == 0 ? "heute" : "\(d) Tag\(d == 1 ? "" : "en")") – jetzt pauken!" }
            return "Lernplan aktiv – bleib dran!"
        }
        if streakManager.currentStreak > 0 {
            return "\(streakManager.currentStreak) Tage in Folge – weiter so!"
        }
        return "Starte jetzt deine Lerneinheit"
    }

    // MARK: - Greeting Logic

    private func startGreeting() {
        typingTimer?.invalidate()
        fullGreeting = buildGreeting()
        visibleCount = 0
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { timer in
            if visibleCount < fullGreeting.count {
                visibleCount += 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func buildGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Morgen, \(userName) 👋"
        case 12..<17: return "Hey, \(userName) ✌️"
        case 17..<22: return "Abend, \(userName) 🌙"
        default:      return "Hey, \(userName) 👋"
        }
    }
}

// MARK: - Schnellaktionen Widget

struct SchnellaktionenWidget: View {
    var onKILernset: () -> Void
    var onVokabeln: () -> Void
    var onScannen: () -> Void
    var onTestErstellen: () -> Void

    private let items: [(title: String, icon: String, color: Color)] = [
        ("KI-Lernset",     "brain.head.profile",          Color(red: 0.15, green: 0.60, blue: 0.40)),
        ("Vokabeln",       "character.book.closed.fill",  Color(red: 0.86, green: 0.50, blue: 0.10)),
        ("Scannen",        "doc.viewfinder",              Color(red: 0.12, green: 0.58, blue: 0.46)),
        ("Test erstellen", "pencil.and.list.clipboard",   Color(red: 0.55, green: 0.20, blue: 0.85)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SCHNELLZUGRIFF")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                quickButton(items[0], action: onKILernset)
                quickButton(items[1], action: onVokabeln)
                quickButton(items[2], action: onScannen)
                quickButton(items[3], action: onTestErstellen)
            }
        }
    }

    private func quickButton(_ item: (title: String, icon: String, color: Color), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.color)
                }
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nächster Test Widget

struct NächsterTestWidget: View {
    let plan: LernPlan
    let onTap: () -> Void

    private var urgencyColor: Color {
        let d = plan.daysUntilTest
        if d == 0 { return .red }
        if d <= 3  { return Color(red: 0.95, green: 0.45, blue: 0.10) }
        return Color(red: 0.10, green: 0.48, blue: 0.92)
    }

    private var subjectColor: Color {
        Subject.all.first { $0.name == plan.fach }?.color ?? Color(red: 0.10, green: 0.48, blue: 0.92)
    }

    private var subjectIcon: String {
        Subject.all.first { $0.name == plan.fach }?.icon ?? "book.fill"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Countdown block
                VStack(spacing: 2) {
                    Text(plan.daysUntilTest == 0 ? "!" : "\(plan.daysUntilTest)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(urgencyColor)
                        .contentTransition(.numericText())
                    Text(plan.daysUntilTest == 0 ? "HEUTE" : "TAGE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(urgencyColor.opacity(0.75))
                        .tracking(2)
                }
                .frame(width: 72)

                Rectangle()
                    .fill(Color(uiColor: .separator).opacity(0.5))
                    .frame(width: 0.5, height: 52)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 5) {
                    Text("NÄCHSTER TEST")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    Text(plan.titel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: subjectIcon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(plan.fach)
                            .font(.system(size: 12))
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(plan.testDatum.formatted(.dateTime.day().month()))
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(urgencyColor.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(urgencyColor.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: urgencyColor.opacity(0.10), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wochenaktivität Widget

struct WochenaktivitätWidget: View {
    let streak: Int
    let isActiveToday: Bool

    private let dayLabels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let accent = Color(red: 0.30, green: 0.52, blue: 0.98)

    // 0 = Mon … 6 = Sun
    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 2 + 7) % 7
    }

    private func isActive(index: Int) -> Bool {
        let daysAgo = todayIndex - index
        if daysAgo < 0 { return false }
        if daysAgo == 0 { return isActiveToday }
        return daysAgo <= streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("Wochenaktivität")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                }
                Spacer()
                Text("\(streak) Tage-Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    dayCell(index: idx)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: accent.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private func dayCell(index: Int) -> some View {
        let active = isActive(index: index)
        let isToday = index == todayIndex
        let isFuture = index > todayIndex

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        active ? accent :
                        isFuture ? Color(uiColor: .tertiarySystemGroupedBackground) :
                        Color(uiColor: .tertiarySystemGroupedBackground)
                    )
                    .frame(width: 34, height: 34)
                if active {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else if isToday {
                    Circle()
                        .stroke(accent, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }
            }
            Text(dayLabels[index])
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? accent : .secondary)
        }
    }
}

// MARK: - Sets Übersicht Widget

struct SetsÜbersichtWidget: View {
    let store: LernSetStore

    private var kiCount: Int       { store.lernSets.filter { $0.isKIGenerated && !$0.isScanResult }.count }
    private var karteiCount: Int   { store.lernSets.filter { !$0.isKIGenerated && !$0.isVokabelSet && !$0.isScanResult }.count }
    private var vokabelCount: Int  { store.lernSets.filter { $0.isVokabelSet }.count }
    private var scanCount: Int     { store.lernSets.filter { $0.isScanResult }.count }

    private var rows: [(title: String, count: Int, icon: String, color: Color)] {
        var r: [(String, Int, String, Color)] = []
        if kiCount > 0      { r.append(("KI-Lernsets",  kiCount,     "brain.head.profile",         Color(red: 0.15, green: 0.60, blue: 0.40))) }
        if karteiCount > 0  { r.append(("Karteikarten", karteiCount, "rectangle.on.rectangle.angled", Color(red: 0.38, green: 0.18, blue: 0.90))) }
        if vokabelCount > 0 { r.append(("Vokabeln",     vokabelCount,"character.book.closed.fill",  Color(red: 0.86, green: 0.50, blue: 0.10))) }
        if scanCount > 0    { r.append(("Scans",        scanCount,   "doc.viewfinder",              Color(red: 0.12, green: 0.58, blue: 0.46))) }
        return r
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEINE SETS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    if idx > 0 { Divider().padding(.leading, 60) }
                    setRow(title: row.title, count: row.count, icon: row.icon, color: row.color)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            )
        }
    }

    private func setRow(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

// MARK: - Tagesquote Widget

struct TagesquoteWidget: View {
    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    private let quotes: [(text: String, author: String)] = [
        ("Bildung ist die mächtigste Waffe, die du benutzen kannst, um die Welt zu verändern.", "Nelson Mandela"),
        ("Der Beginn aller Weisheit ist, die Dinge so zu sehen, wie sie sind.", "Sokrates"),
        ("Wer aufhört zu lernen, ist alt – ob mit 20 oder 80.", "Henry Ford"),
        ("Investiere in dein Wissen – es bringt die besten Zinsen.", "Benjamin Franklin"),
        ("Erfolg ist die Summe kleiner Anstrengungen, die Tag für Tag wiederholt werden.", "Robert Collier"),
        ("Jeder Experte war einmal ein Anfänger.", "Helen Hayes"),
        ("Disziplin ist die Brücke zwischen Zielen und Leistungen.", "Jim Rohn"),
        ("Wissen ist Macht.", "Francis Bacon"),
        ("Du musst tun, was du nicht kannst, um zu lernen, wie man es tut.", "Henry Ford"),
        ("Der einzige Weg, großartige Arbeit zu leisten, ist zu lieben, was du tust.", "Steve Jobs"),
        ("Es gibt keine Abkürzungen zu einem Ort, der es wert ist zu gehen.", "Beverly Sills"),
        ("Lernen ist Erfahrung. Alles andere ist nur Information.", "Albert Einstein"),
        ("Der heutige Schweiß ist der morgige Erfolg.", "Unbekannt"),
        ("Glaube an dich und alles ist möglich.", "Unbekannt"),
    ]

    private var todayQuote: (text: String, author: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[day % quotes.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Motivation des Tages")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
            }

            Text("„\(todayQuote.text)\u{201D}")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            HStack {
                Spacer()
                Text("— \(todayQuote.author)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.08), Color(uiColor: .secondarySystemGroupedBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: accent.opacity(0.07), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Fächer Scroll Widget

struct FächerScrollWidget: View {
    let subjects: [Subject]
    let store: LernSetStore
    let onNavigateToLearn: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MEINE FÄCHER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onNavigateToLearn?()
                } label: {
                    Text("Alle anzeigen")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.90))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(subjects) { subject in
                        let count = store.lernSets(for: subject.name).count
                        subjectChip(subject: subject, count: count)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private func subjectChip(subject: Subject, count: Int) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(subject.color.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: subject.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(subject.color)
            }
            VStack(spacing: 2) {
                Text(subject.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(count) Set\(count == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72)
    }
}

// MARK: - Zuletzt Widget

struct ZuletztWidget: View {
    let lernSet: LernSet
    @State private var showLearn = false
    @EnvironmentObject var lernSetStore: LernSetStore

    private var subjectColor: Color {
        Subject.all.first { $0.name == lernSet.subject }?.color
            ?? Color(red: 0.38, green: 0.18, blue: 0.90)
    }

    private var subjectIcon: String {
        Subject.all.first { $0.name == lernSet.subject }?.icon ?? "book.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ZULETZT HINZUGEFÜGT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            Button { showLearn = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(subjectColor.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: subjectIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(subjectColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lernSet.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(lernSet.subject)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text("\(lernSet.cards.count) Karten")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Lernen")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(subjectColor)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(subjectColor.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(subjectColor.opacity(0.10))
                    )
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showLearn) {
            NavigationStack {
                LearnModeSelectionView(lernSet: lernSet)
            }
            .environmentObject(lernSetStore)
        }
    }
}

// MARK: - Lernpfad Widget

struct LernpfadWidget: View {
    let plan: LernPlan
    let onTap: () -> Void

    private let accent = Color(red: 0.10, green: 0.48, blue: 0.92)

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {

                // Header row
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                        Text("Lernplan")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    Spacer()
                    Text(daysLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(daysUrgent ? .red : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(daysUrgent
                                      ? Color.red.opacity(0.10)
                                      : Color(uiColor: .tertiarySystemGroupedBackground))
                        )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }

                // Plan title
                Text(plan.titel)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Today's task (if any)
                if let aufgabe = plan.todayTag?.aufgaben.first {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(aufgabe.completed ? Color.green.opacity(0.14) : accent.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: aufgabe.completed ? "checkmark.circle.fill" : "book.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(aufgabe.completed ? .green : accent)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Heute")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(aufgabe.titel)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(aufgabe.completed ? .secondary : .primary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [accent, Color(red: 0.22, green: 0.70, blue: 1.00)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * plan.overallProgress, height: 4)
                    }
                }
                .frame(height: 4)

                // Progress label
                HStack {
                    Text("\(Int(plan.overallProgress * 100))% abgeschlossen")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(plan.tage.count) Lerntage")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: accent.opacity(0.10), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var daysLabel: String {
        let d = plan.daysUntilTest
        if d == 0 { return "Test heute!" }
        if d == 1 { return "Noch 1 Tag" }
        return "Noch \(d) Tage"
    }

    private var daysUrgent: Bool {
        plan.daysUntilTest <= 2
    }
}

// MARK: - Heute Widget

struct HeuteWidget: View {
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore

    @State private var generatingId: UUID? = nil
    @State private var navigateToSet: LernSet? = nil

    private let accent = Color(red: 0.10, green: 0.48, blue: 0.92)
    private let orange = Color(red: 0.95, green: 0.55, blue: 0.10)

    struct TodayItem: Identifiable {
        let id: UUID
        let plan: LernPlan
        let tag: LernPlanTag
        let aufgabe: LernPlanAufgabe
    }

    private var todayItems: [TodayItem] {
        lernPlanStore.plans
            .filter { $0.daysUntilTest >= 0 }
            .compactMap { plan -> [TodayItem]? in
                guard let tag = plan.todayTag else { return nil }
                return tag.aufgaben.map { TodayItem(id: $0.id, plan: plan, tag: tag, aufgabe: $0) }
            }
            .flatMap { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(orange)
                    Text("Heute")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(orange)
                }
                Spacer()
                Text(Date().formatted(.dateTime.day().month()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if todayItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(todayItems) { item in
                        todayRow(item: item)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: orange.opacity(0.07), radius: 10, x: 0, y: 4)
        )
        .sheet(item: $navigateToSet) { set in
            NavigationStack {
                LernsetViewerView(lernSet: set)
            }
            .environmentObject(lernSetStore)
        }
    }

    private var emptyState: some View {
        HStack(spacing: 14) {
            Text("🎉")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 3) {
                Text("Alles erledigt!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Kein offener Lernplan für heute.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func todayRow(item: TodayItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.aufgabe.completed ? Color.green.opacity(0.12) : accent.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: item.aufgabe.completed ? "checkmark.circle.fill" : "book.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.aufgabe.completed ? .green : accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.aufgabe.titel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(item.aufgabe.completed ? .secondary : .primary)
                    .strikethrough(item.aufgabe.completed, color: .secondary)
                    .lineLimit(1)
                Text(item.plan.titel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            actionButton(item: item)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private func actionButton(item: TodayItem) -> some View {
        if item.aufgabe.completed {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)
        } else if let setId = item.aufgabe.generatedLernSetId,
                  let set = lernSetStore.lernSets.first(where: { $0.id == setId }) {
            Button { navigateToSet = set } label: {
                playCircle(color: .green)
            }
            .buttonStyle(.plain)
        } else {
            Button { generateLernSet(item: item) } label: {
                if generatingId == item.aufgabe.id {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(width: 34, height: 34)
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.55)
                            .tint(accent)
                    }
                } else {
                    playCircle(color: accent)
                }
            }
            .buttonStyle(.plain)
            .disabled(generatingId != nil)
        }
    }

    private func playCircle(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 34, height: 34)
            Image(systemName: "play.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func generateLernSet(item: TodayItem) {
        generatingId = item.aufgabe.id
        Task {
            do {
                let cards = try await AIService.shared.generateLernSet(
                    fach: item.plan.fach,
                    klassenstufe: item.plan.klassenstufe,
                    thema: item.aufgabe.thema,
                    schwierigkeit: item.aufgabe.schwierigkeit,
                    anzahl: item.aufgabe.anzahl
                )
                let newSet = LernSet(
                    name: item.aufgabe.titel,
                    subject: item.plan.fach,
                    cards: cards,
                    isKIGenerated: true
                )
                lernSetStore.save(newSet)

                var updatedAufgabe = item.aufgabe
                updatedAufgabe.generatedLernSetId = newSet.id
                lernPlanStore.updateAufgabe(updatedAufgabe, inPlan: item.plan.id, tagId: item.tag.id)

                generatingId = nil
                navigateToSet = newSet
            } catch {
                generatingId = nil
            }
        }
    }
}
