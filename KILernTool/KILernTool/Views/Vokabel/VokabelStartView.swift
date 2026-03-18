import SwiftUI

struct VokabelStartView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) private var dismiss

    @State private var showCreate = false
    @State private var showCameraScan = false
    @State private var showMethodPicker = false
    @State private var selectedSet: LernSet? = nil
    @State private var showIntro = !UserDefaults.standard.bool(forKey: "introSeen_vokabel")

    private let accent = AppColors.brandVokabel
    private let robertColor = Color(red: 0.98, green: 0.78, blue: 0.08)
    private let gradient = LinearGradient(
        colors: [Color(red: 0.86, green: 0.50, blue: 0.10), Color(red: 1.00, green: 0.72, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var vokabelSets: [LernSet] {
        store.lernSets.filter { $0.isVokabelSet }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 20) {
                        createHeroButton
                        setsSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }

            if showIntro {
                ModeIntroView(
                    characterName: "Robert",
                    characterRole: "Vokabel-Trainer",
                    gradientTop: Color(red: 0.86, green: 0.50, blue: 0.05),
                    gradientBottom: Color(red: 0.78, green: 0.38, blue: 0.02),
                    mascotColor: .white,
                    introText: "Hey, ich bin **Robert** – dein Vokabel-Trainer! 📚\n\nIch helfe dir neue Wörter zu lernen. Du kannst Vokabeln manuell eingeben oder einfach ein Foto machen – ich erkenne die Wörter automatisch!\n\nPerfekt für alle Sprachen. Lass uns starten!",
                    defaultsKey: "introSeen_vokabel"
                ) {
                    withAnimation(.easeOut(duration: 0.35)) { showIntro = false }
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.35), value: showIntro)
        .confirmationDialog("Wie möchtest du das Set erstellen?", isPresented: $showMethodPicker, titleVisibility: .visible) {
            Button("Manuell erstellen") { showCreate = true }
            Button("Mit Kamera scannen") { showCameraScan = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCreate) {
            VokabelCreateView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showCameraScan) {
            VokabelCameraScanView()
                .environmentObject(store)
        }
        .sheet(item: $selectedSet) { set in
            NavigationStack {
                VokabelDetailView(lernSet: set)
                    .environmentObject(store)
            }
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
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
            }
            .accessibilityLabel("Schließen")
            .buttonStyle(.plain)
            Spacer()
            Text("Vokabelset")
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
        Button { showMethodPicker = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    MascotView(color: .white, mood: .talking, size: 40)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neues Vokabelset")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Manuell eingeben oder mit Kamera scannen")
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
                    .shadow(color: accent.opacity(0.42), radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sets Section
    @ViewBuilder
    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meine Vokabelsets")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if vokabelSets.isEmpty {
                VStack(spacing: 16) {
                    MascotView(color: robertColor, mood: .thinking, size: 56)
                    Text("Noch keine Vokabelsets")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("Erstelle dein erstes Set mit dem Button oben.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
            } else {
                VStack(spacing: 10) {
                    ForEach(vokabelSets) { set in
                        setRow(set)
                    }
                }
            }
        }
    }

    private func setRow(_ set: LernSet) -> some View {
        Button { selectedSet = set } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(set.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("\(set.subject) · \(set.cards.count) Vokabeln")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(set)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}
