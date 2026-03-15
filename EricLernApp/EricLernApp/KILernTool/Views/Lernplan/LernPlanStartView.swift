import SwiftUI

struct LernPlanStartView: View {
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var selectedPlan: LernPlan? = nil

    private let gradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        createHeroButton
                        plansSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showCreator) {
            CreateLernPlanView { newPlan in
                showCreator = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedPlan = newPlan
                }
            }
            .environmentObject(lernPlanStore)
            .environmentObject(lernSetStore)
        }
        .fullScreenCover(item: $selectedPlan) { plan in
            LernPlanDetailView(planId: plan.id)
                .environmentObject(lernPlanStore)
                .environmentObject(lernSetStore)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("KI-Lernplan")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Hero Button

    private var createHeroButton: some View {
        Button { showCreator = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.18)).frame(width: 52, height: 52)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("KI-Lernplan erstellen")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Fotos scannen → KI erstellt deinen Tagesplan")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.80))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: Color(red: 0.10, green: 0.48, blue: 0.92).opacity(0.42),
                            radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plans Section

    @ViewBuilder
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Lernpläne")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if lernPlanStore.plans.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "Noch kein Lernplan",
                    subtitle: "Erstelle deinen ersten KI-Lernplan und starte strukturiert."
                )
                .frame(height: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(lernPlanStore.plans) { plan in
                        planRow(plan)
                    }
                }
            }
        }
    }

    private func planRow(_ plan: LernPlan) -> some View {
        Button { selectedPlan = plan } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.10, green: 0.48, blue: 0.92).opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.10, green: 0.48, blue: 0.92))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.titel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(plan.fach)
                        Text("·")
                        Text(daysLabel(plan))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                // Progress ring mini
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: plan.overallProgress)
                        .stroke(Color(red: 0.10, green: 0.48, blue: 0.92), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func daysLabel(_ plan: LernPlan) -> String {
        let d = plan.daysUntilTest
        if d < 0 { return "Test vorbei" }
        if d == 0 { return "Test heute!" }
        return "Noch \(d) Tag\(d == 1 ? "" : "e")"
    }
}
