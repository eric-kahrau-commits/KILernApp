import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar row
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("Lernsets suchen…", text: $query)
                                .font(.system(size: 16))
                                .focused($isFocused)
                            if !query.isEmpty {
                                Button { query = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )

                        Button("Abbrechen") {
                            withAnimation { isPresented = false }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(red: 0.38, green: 0.28, blue: 0.90))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(.bar)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
                    }

                    // Empty state
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Lernsets durchsuchen",
                        subtitle: "Suche nach Lernsets, Themen oder Fächern. Diese Funktion wird bald verfügbar sein."
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { isFocused = true }
    }
}
