import SwiftUI

struct NewView: View {
    @EnvironmentObject var store: LernSetStore
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @State private var showKILernset = false
    @State private var showLernPlan = false
    @State private var showTestErstellen = false
    @State private var showScannen = false
    @State private var showVokabel = false
    @State private var selectedOption: CreateOption? = nil
    @State private var showCardSetStart = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Was möchtest du")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("erstellen?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                         Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 4)

                VStack(spacing: 14) {
                    ForEach(Array(CreateOption.all.enumerated()), id: \.element.id) { index, option in
                        CreateOptionCard(option: option, index: index) {
                            switch option.title {
                            case "KI Lernset":
                                showKILernset = true
                            case "Lern Plan":
                                showLernPlan = true
                            case "Test erstellen":
                                showTestErstellen = true
                            case "Scannen":
                                showScannen = true
                            case "Vokabelset":
                                showVokabel = true
                            case "Karteikartenset":
                                showCardSetStart = true
                            default:
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    selectedOption = option
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .fullScreenCover(isPresented: $showKILernset) {
            KILernsetStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showLernPlan) {
            LernPlanStartView()
                .environmentObject(lernPlanStore)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showTestErstellen) {
            TestErstellenStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showCardSetStart) {
            CardSetStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showScannen) {
            ScanStartView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showVokabel) {
            VokabelStartView()
                .environmentObject(store)
        }
        .sheet(item: $selectedOption) { option in
            CreateDetailView(option: option)
        }
    }
}

// MARK: - Create Option Card

struct CreateOptionCard: View {
    let option: CreateOption
    let index: Int
    let action: () -> Void

    @State private var isPressed = false

    var gradient: LinearGradient {
        LinearGradient(colors: option.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: option.colors.first!.opacity(0.40), radius: 8, x: 0, y: 4)
                    Image(systemName: option.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(option.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))     { isPressed = false } }
        )
    }
}
