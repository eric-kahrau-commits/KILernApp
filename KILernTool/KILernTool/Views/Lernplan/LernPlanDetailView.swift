import SwiftUI

struct LernPlanDetailView: View {
    let planId: UUID
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab: Tab = .heute
    @State private var generatingAufgabeId: UUID? = nil
    @State private var navigateToSet: LernSet? = nil
    @State private var lastNavigatedSetId: UUID? = nil

    enum Tab: String, CaseIterable {
        case heute = "Heute"
        case morgen = "Morgen"
        case ganzerPlan = "Ganzer Plan"
    }

    private var plan: LernPlan? {
        lernPlanStore.plans.first { $0.id == planId }
    }

    private let accent = AppColors.brandBlue

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if let plan {
                VStack(spacing: 0) {
                    planNavBar(plan: plan)
                    tabBar
                    ScrollView {
                        VStack(spacing: 16) {
                            saschaPlanBanner(plan: plan)
                                .padding(.top, 2)
                            switch selectedTab {
                            case .heute:
                                dayContent(plan: plan, tag: plan.todayTag, label: "Heute")
                            case .morgen:
                                let tomorrow = plan.tage.first {
                                    Calendar.current.isDateInTomorrow($0.datum)
                                }
                                dayContent(plan: plan, tag: tomorrow, label: "Morgen")
                            case .ganzerPlan:
                                fullPlanContent(plan: plan)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .sheet(item: $navigateToSet, onDismiss: {
            // P2: Auto-mark aufgabe as completed when user returns from learning session
            if let setId = lastNavigatedSetId, let plan = plan {
                for tag in plan.tage {
                    for aufgabe in tag.aufgaben {
                        if aufgabe.generatedLernSetId == setId && !aufgabe.completed {
                            var updated = aufgabe
                            updated.completed = true
                            lernPlanStore.updateAufgabe(updated, inPlan: plan.id, tagId: tag.id)
                        }
                    }
                }
            }
        }) { set in
            NavigationStack {
                LernsetViewerView(lernSet: set)
            }
            .environmentObject(lernSetStore)
        }
    }

    // MARK: - Sascha Plan Banner

    private func saschaPlanBanner(plan: LernPlan) -> some View {
        let d = plan.daysUntilTest
        let msg: String
        if d < 0 {
            msg = "Der Test ist vorbei – super gemacht! Du hast es durchgezogen! 🏆"
        } else if d == 0 {
            msg = "Heute ist dein Test! Du hast gut gelernt – ich glaube an dich! 🎯"
        } else {
            msg = "Noch **\(d) Tag\(d == 1 ? "" : "e")** bis zum Test. Schritt für Schritt zum Ziel – du schaffst das! 💪"
        }
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                 Color(red: 0.10, green: 0.48, blue: 0.92),
                                 Color(red: 0.10, green: 0.64, blue: 0.54)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                MascotView(color: .white, mood: .happy, size: 34)
                    .frame(width: 34, height: 38)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("SASCHA")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .tracking(1.5)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(accent.opacity(0.12)))
                }
                Text((try? AttributedString(markdown: msg,
                     options: AttributedString.MarkdownParsingOptions(
                         interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(msg))
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                         Color(red: 0.10, green: 0.48, blue: 0.92),
                                         Color(red: 0.10, green: 0.64, blue: 0.54)],
                                startPoint: .topLeading, endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    // MARK: - Nav Bar

    private func planNavBar(plan: LernPlan) -> some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Schließen")
            Spacer()
            VStack(spacing: 1) {
                Text(plan.titel)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(daysRemainingText(plan))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? accent : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(accent)
                                    .frame(height: 2.5)
                                    .padding(.horizontal, 16)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Day Content

    @ViewBuilder
    private func dayContent(plan: LernPlan, tag: LernPlanTag?, label: String) -> some View {
        if let tag {
            if tag.aufgaben.isEmpty {
                emptyDay(label: label)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(label) · Tag \(tag.tagNummer)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if tag.allCompleted {
                            Label("Erledigt", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    ForEach(tag.aufgaben) { aufgabe in
                        aufgabeCard(plan: plan, tag: tag, aufgabe: aufgabe)
                    }
                }
            }
        } else {
            emptyDay(label: label)
        }
    }

    private func emptyDay(label: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("Kein Lernplan für \(label)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Aufgabe Card

    private func aufgabeCard(plan: LernPlan, tag: LernPlanTag, aufgabe: LernPlanAufgabe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if aufgabe.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 16))
                        } else {
                            Circle()
                                .stroke(Color(uiColor: .tertiaryLabel), lineWidth: 1.5)
                                .frame(width: 16, height: 16)
                        }
                        Text(aufgabe.titel)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .strikethrough(aufgabe.completed, color: .secondary)
                    }
                    Text(aufgabe.beschreibung)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                // Already has a generated lernset
                if let setId = aufgabe.generatedLernSetId,
                   let set = lernSetStore.lernSets.first(where: { $0.id == setId }) {
                    Button {
                        lastNavigatedSetId = set.id
                        navigateToSet = set
                    } label: {
                        Label("Weiterlernen", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                    }
                    .buttonStyle(.plain)
                } else {
                    // Play button: generate lernset
                    Button {
                        generateLernSet(plan: plan, tag: tag, aufgabe: aufgabe)
                    } label: {
                        HStack(spacing: 6) {
                            if generatingAufgabeId == aufgabe.id {
                                ProgressView().progressViewStyle(.circular).tint(.white)
                                    .scaleEffect(0.75)
                                Text("Wird erstellt …")
                            } else {
                                Image(systemName: "play.fill")
                                Text("Lernset erstellen")
                            }
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(generatingAufgabeId == aufgabe.id ? Color(uiColor: .tertiaryLabel) : accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(generatingAufgabeId != nil)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    // Typ badge
                    let (typLabel, typColor) = aufgabeTypInfo(aufgabe.typ)
                    Text(typLabel)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(typColor)
                        .tracking(0.8)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(typColor.opacity(0.13)))

                    // Difficulty badge
                    Text(aufgabe.schwierigkeit.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(difficultyColor(aufgabe.schwierigkeit))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(difficultyColor(aufgabe.schwierigkeit).opacity(0.12)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    aufgabe.completed
                    ? RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.25), lineWidth: 1)
                    : nil
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Full Plan

    private func fullPlanContent(plan: LernPlan) -> some View {
        VStack(spacing: 0) {
            // Lernpfad progress widget
            lernpfadWidget(plan: plan)
                .padding(.bottom, 20)

            // All days
            LazyVStack(spacing: 12) {
                ForEach(plan.tage) { tag in
                    tagRow(plan: plan, tag: tag)
                }
                // Test day marker
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TEST")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red)
                        Text(plan.testDatum.formatted(date: .long, time: .omitted))
                            .font(.system(size: 14, weight: .medium))
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.red.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
                )
            }
        }
    }

    private func tagRow(plan: LernPlan, tag: LernPlanTag) -> some View {
        let isToday = tag.isToday
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tag \(tag.tagNummer)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isToday ? accent : .secondary)
                if isToday {
                    Text("HEUTE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(accent))
                }
                Spacer()
                Text(tag.datum.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if tag.allCompleted {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        .font(.system(size: 14))
                }
            }
            ForEach(tag.aufgaben) { aufgabe in
                aufgabeCard(plan: plan, tag: tag, aufgabe: aufgabe)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isToday
                      ? accent.opacity(0.05)
                      : Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    isToday ? RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1) : nil
                )
        )
    }

    // MARK: - Lernpfad Widget

    private func lernpfadWidget(plan: LernPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lernpfad")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(plan.overallProgress * 100)) % abgeschlossen")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(plan.tage.enumerated()), id: \.element.id) { idx, tag in
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(tag.allCompleted ? Color.green
                                              : tag.isToday ? accent
                                              : tag.isPast ? Color(uiColor: .tertiarySystemGroupedBackground)
                                              : Color(uiColor: .secondarySystemGroupedBackground))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle().stroke(tag.isToday ? accent : Color.clear, lineWidth: 2)
                                        )
                                    if tag.allCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                                    } else {
                                        Text("\(tag.tagNummer)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(tag.isToday ? .white : .primary)
                                    }
                                }
                                if tag.isToday {
                                    Text("Heute")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(accent)
                                }
                            }
                            if idx < plan.tage.count - 1 {
                                Rectangle()
                                    .fill(plan.tage[idx].allCompleted ? Color.green : Color(uiColor: .tertiarySystemGroupedBackground))
                                    .frame(width: 24, height: 2)
                            }
                        }
                    }
                    // Test day node
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(width: 24, height: 2)
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                            Text("Test")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - Generate LernSet

    private func generateLernSet(plan: LernPlan, tag: LernPlanTag, aufgabe: LernPlanAufgabe) {
        generatingAufgabeId = aufgabe.id
        Task {
            do {
                let cards = try await AIService.shared.generateLernSet(
                    fach: plan.fach,
                    thema: aufgabe.thema,
                    schwierigkeit: aufgabe.schwierigkeit,
                    anzahl: aufgabe.anzahl
                )
                let newSet = LernSet(
                    name: aufgabe.titel,
                    subject: plan.fach,
                    cards: cards,
                    isKIGenerated: true
                )
                lernSetStore.save(newSet)

                var updatedAufgabe = aufgabe
                updatedAufgabe.generatedLernSetId = newSet.id
                lernPlanStore.updateAufgabe(updatedAufgabe, inPlan: plan.id, tagId: tag.id)

                generatingAufgabeId = nil
                lastNavigatedSetId = newSet.id
                navigateToSet = newSet
            } catch {
                generatingAufgabeId = nil
            }
        }
    }

    // MARK: - Helpers

    private func daysRemainingText(_ plan: LernPlan) -> String {
        let d = plan.daysUntilTest
        if d < 0 { return "Test vorbei" }
        if d == 0 { return "Test ist heute!" }
        return "Noch \(d) Tag\(d == 1 ? "" : "e") bis zum Test"
    }

    private func difficultyColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "einfach": return .green
        case "schwer":  return .red
        default:        return .orange
        }
    }

    private func aufgabeTypInfo(_ typ: String) -> (label: String, color: Color) {
        switch typ.lowercased() {
        case "neuerstoff":    return ("NEU", Color(red: 0.20, green: 0.48, blue: 0.95))
        case "uebung":        return ("ÜBUNG", Color(red: 0.15, green: 0.70, blue: 0.40))
        case "wiederholung":  return ("WDHLG", Color(red: 0.86, green: 0.50, blue: 0.10))
        case "simulation":    return ("TEST", Color(red: 0.85, green: 0.22, blue: 0.22))
        default:              return ("NEU", Color(red: 0.20, green: 0.48, blue: 0.95))
        }
    }
}
