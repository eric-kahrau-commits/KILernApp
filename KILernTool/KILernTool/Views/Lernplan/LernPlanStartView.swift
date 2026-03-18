import SwiftUI

struct LernPlanStartView: View {
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var lernSetStore: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var showCreator = false
    @State private var selectedPlan: LernPlan? = nil
    @State private var showIntro = !UserDefaults.standard.bool(forKey: "introSeen_lernplan")

    private let gradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
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

        if showIntro {
            ModeIntroView(
                characterName: "Sascha",
                characterRole: "KI-Lernplan-Assistent",
                gradientTop: Color(red: 0.10, green: 0.48, blue: 0.92),
                gradientBottom: Color(red: 0.08, green: 0.35, blue: 0.80),
                mascotColor: .white,
                introText: "Hey, ich bin **Sascha** – dein KI-Lernplan-Assistent! 🌈\n\nIch erstelle dir einen persönlichen Tagesplan bis zu deinem Test – strukturiert, motivierend und genau auf dich zugeschnitten.\n\nFotografiere dein Schulbuch oder nenn mir dein Thema – ich plane den Rest! ✨",
                defaultsKey: "introSeen_lernplan"
            ) {
                withAnimation(.easeOut(duration: 0.35)) { showIntro = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCreator = true }
            }
            .transition(.opacity)
            .zIndex(20)
        }
        } // outer ZStack
        .animation(.easeOut(duration: 0.35), value: showIntro)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
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
                MascotView(color: .white, mood: .happy, size: 48)
                    .frame(width: 48, height: 54)
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
                        .fill(LinearGradient(
                            colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                     Color(red: 0.10, green: 0.48, blue: 0.92),
                                     Color(red: 0.10, green: 0.64, blue: 0.54)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 42, height: 42)
                    MascotView(color: .white, mood: .idle, size: 28)
                        .frame(width: 28, height: 32)
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

