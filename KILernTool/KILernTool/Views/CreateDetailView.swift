import SwiftUI

struct CreateDetailView: View {
    let option: CreateOption
    @Environment(\.dismiss) var dismiss

    var gradient: LinearGradient {
        LinearGradient(
            colors: option.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    ZStack(alignment: .bottomLeading) {
                        gradient
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 150)
                            .overlay(
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 180, height: 180)
                                        .offset(x: 140, y: -60)
                                }
                                .clipped()
                            )

                        HStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(option.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 20)

                        Button { dismiss() } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.20))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }

                    // Empty state
                    EmptyStateView(
                        icon: option.icon,
                        title: "Bald verfügbar",
                        subtitle: "\(option.title) ist in Entwicklung. Diese Funktion wird demnächst freigeschaltet."
                    )
                }
            }
            .navigationBarHidden(true)
        }
    }
}
