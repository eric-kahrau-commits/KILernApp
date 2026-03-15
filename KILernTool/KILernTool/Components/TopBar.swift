import SwiftUI

struct TopBar: View {
    let title: String
    @Binding var isSidebarOpen: Bool
    var trailingItem: AnyView? = nil

    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                    isSidebarOpen.toggle()
                }
            } label: {
                if isSidebarOpen {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .animation(.spring(response: 0.3), value: isSidebarOpen)
                        .frame(width: 44, height: 44, alignment: .center)
                } else {
                    VStack(spacing: 5) {
                        Capsule()
                            .fill(Color.primary)
                            .frame(width: 18, height: 2.6)
                        Capsule()
                            .fill(Color.primary)
                            .frame(width: 24, height: 2.6)
                        Capsule()
                            .fill(Color.primary)
                            .frame(width: 18, height: 2.6)
                    }
                    .frame(width: 44, height: 44, alignment: .center)
                    .animation(.spring(response: 0.3), value: isSidebarOpen)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .id("title_\(title)")
                .transition(.opacity)

            Spacer()

            // Trailing placeholder or custom item
            if let trailing = trailingItem {
                trailing
            } else {
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.primary.opacity(0.06))
                .frame(height: 0.5)
        }
    }
}
