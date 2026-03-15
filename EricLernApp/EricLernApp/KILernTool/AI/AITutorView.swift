import SwiftUI

// MARK: - Animated Owl Character

struct OwlCharacterView: View {
    var isTalking: Bool = false
    var size: CGFloat   = 120

    @State private var floatOffset:  CGFloat = 0
    @State private var blinkScale:   CGFloat = 1
    @State private var wingOffset:   CGFloat = 0
    @State private var beakOpen:     CGFloat = 0
    @State private var isBlinking = false

    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.12))
                .frame(width: size * 0.65, height: size * 0.09)
                .offset(y: size * 0.54)
                .blur(radius: 4)

            Group {
                owlBody
                leftWing
                rightWing
                owlHead
                leftEar
                rightEar
                leftEye
                rightEye
                beak
                tummyPattern
            }
        }
        .frame(width: size, height: size * 1.1)
        .offset(y: floatOffset)
        .onAppear {
            startAnimations()
        }
        .onChange(of: isTalking) { _, talking in
            if talking { startTalkAnimation() }
        }
    }

    // MARK: Body Parts

    private var owlBody: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#8B5E3C"), Color(hex: "#5C3D1E")],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: size * 0.56, height: size * 0.68)
            .offset(y: size * 0.20)
    }

    private var leftWing: some View {
        Ellipse()
            .fill(Color(hex: "#6B4423"))
            .frame(width: size * 0.24, height: size * 0.42)
            .rotationEffect(.degrees(-18))
            .offset(x: -size * 0.29, y: size * 0.30 + wingOffset)
    }

    private var rightWing: some View {
        Ellipse()
            .fill(Color(hex: "#6B4423"))
            .frame(width: size * 0.24, height: size * 0.42)
            .rotationEffect(.degrees(18))
            .offset(x: size * 0.29, y: size * 0.30 + wingOffset)
    }

    private var owlHead: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#A87048"), Color(hex: "#7A4E2D")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: size * 0.56, height: size * 0.56)
            .offset(y: -size * 0.10)
    }

    private var leftEar: some View {
        EarTuft()
            .fill(Color(hex: "#7A4E2D"))
            .frame(width: size * 0.12, height: size * 0.18)
            .offset(x: -size * 0.14, y: -size * 0.35)
    }

    private var rightEar: some View {
        EarTuft()
            .fill(Color(hex: "#7A4E2D"))
            .frame(width: size * 0.12, height: size * 0.18)
            .offset(x: size * 0.14, y: -size * 0.35)
    }

    private var leftEye: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.16, height: size * 0.16)
            Circle()
                .fill(Color(hex: "#1A1A2E"))
                .frame(width: size * 0.10, height: size * 0.10)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.025, y: -size * 0.025)
        }
        .scaleEffect(x: 1, y: isBlinking ? 0.05 : 1)
        .offset(x: -size * 0.11, y: -size * 0.12)
    }

    private var rightEye: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.16, height: size * 0.16)
            Circle()
                .fill(Color(hex: "#1A1A2E"))
                .frame(width: size * 0.10, height: size * 0.10)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.025, y: -size * 0.025)
        }
        .scaleEffect(x: 1, y: isBlinking ? 0.05 : 1)
        .offset(x: size * 0.11, y: -size * 0.12)
    }

    private var beak: some View {
        BeakShape(openAmount: beakOpen)
            .fill(Color(hex: "#E8A020"))
            .frame(width: size * 0.13, height: size * 0.10)
            .offset(y: -size * 0.02)
    }

    private var tummyPattern: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#C8956A").opacity(0.6))
                .frame(width: size * 0.30, height: size * 0.38)
                .offset(y: size * 0.22)
            // Feather lines
            ForEach(0..<3) { i in
                Ellipse()
                    .stroke(Color(hex: "#9B6842").opacity(0.35), lineWidth: 1)
                    .frame(width: size * 0.18, height: size * 0.10)
                    .offset(y: size * 0.12 + CGFloat(i) * size * 0.09)
            }
        }
    }

    // MARK: Animations

    private func startAnimations() {
        // Float up/down
        withAnimation(
            .easeInOut(duration: 2.2)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -8
        }

        // Wing subtle sway
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            wingOffset = 3
        }

        // Periodic blink
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let delay = Double.random(in: 2.5...5.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.08)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.08)) { isBlinking = false }
                scheduleNextBlink()
            }
        }
    }

    private func startTalkAnimation() {
        guard isTalking else {
            withAnimation(.easeOut(duration: 0.1)) { beakOpen = 0 }
            return
        }
        withAnimation(
            .easeInOut(duration: 0.18)
            .repeatForever(autoreverses: true)
        ) {
            beakOpen = 1
        }
    }
}

// MARK: - Custom Shapes

struct EarTuft: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct BeakShape: Shape {
    var openAmount: CGFloat   // 0 = closed, 1 = open

    var animatableData: CGFloat { get { openAmount } set { openAmount = newValue } }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.midY + openAmount * rect.height * 0.25
        // Upper beak
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3))
        p.addLine(to: CGPoint(x: rect.midX, y: midY))
        p.closeSubpath()
        // Lower beak (only visible when open)
        if openAmount > 0.01 {
            p.move(to: CGPoint(x: rect.midX, y: midY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY + rect.height * 0.45))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.midY + rect.height * 0.45))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: - AI Tutor Hub View

struct AITutorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tutorManager = AITutorManager.shared

    @State private var selectedSession: AITutorSession?
    @State private var showChat = false
    @State private var showNotes = false
    @State private var deletingSession: AITutorSession?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                background

                ScrollView {
                    VStack(spacing: 0) {
                        owlHeroSection
                        sessionListSection
                        notesPreviewSection
                        Spacer(minLength: 100)
                    }
                }

                newChatButton
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showChat) {
                if let session = selectedSession {
                    AITutorChatView(session: session) { updated in
                        tutorManager.save(session: updated)
                    }
                }
            }
            .sheet(isPresented: $showNotes) {
                OllyNotesSheet()
            }
            .confirmationDialog(
                "Gespräch löschen?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let s = deletingSession { tutorManager.delete(session: s) }
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    // MARK: Background

    private var background: some View {
        LinearGradient(
            colors: [Color(hex: "#0F0C29"), Color(hex: "#1A1040"), Color(hex: "#2D1B69")],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: Owl Hero

    private var owlHeroSection: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                Spacer()
                Button(action: { showNotes = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(tutorManager.notes.count) Notizen")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            // Owl + name
            VStack(spacing: 16) {
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#8B5CF6").opacity(0.35), .clear],
                                center: .center, startRadius: 20, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    OwlCharacterView(size: 110)
                }

                VStack(spacing: 6) {
                    Text("Olly")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#4ADE80"))
                            .frame(width: 8, height: 8)
                        Text("Dein persönlicher Lernbegleiter")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: Session List

    private var sessionListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(tutorManager.sessions.isEmpty ? "Noch keine Gespräche" : "Gespräche")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if !tutorManager.sessions.isEmpty {
                    Text("\(tutorManager.sessions.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            if tutorManager.sessions.isEmpty {
                emptySessionsPlaceholder
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(tutorManager.sessions) { session in
                        SessionRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showChat = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletingSession = session
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptySessionsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.25))
            Text("Starte dein erstes Gespräch\nmit Olly!")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    // MARK: Notes Preview

    @ViewBuilder
    private var notesPreviewSection: some View {
        if !tutorManager.notes.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Gespeicherte Infos")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Alle anzeigen") { showNotes = true }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#A78BFA"))
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(tutorManager.notes.prefix(6)) { note in
                            NoteChip(note: note)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 28)
        }
    }

    // MARK: New Chat Button

    private var newChatButton: some View {
        Button {
            let newSession = tutorManager.newSession()
            selectedSession = newSession
            showChat = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.bubble.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Neues Gespräch")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color(hex: "#7C3AED").opacity(0.5), radius: 16, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 36)
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: AITutorSession

    var body: some View {
        HStack(spacing: 14) {
            // Owl mini avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#7C3AED").opacity(0.8), Color(hex: "#4F46E5").opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Text("🦉")
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(session.preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.updatedAt.formatted(.relative(presentation: .named, unitsStyle: .narrow)))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Note Chip

private struct NoteChip: View {
    let note: AITutorNote

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: note.kind.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(note.kind.color)
            Text(note.text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(note.kind.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(note.kind.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Olly Notes Sheet

struct OllyNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tutorManager = AITutorManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0F0C29").ignoresSafeArea()

                if tutorManager.notes.isEmpty {
                    VStack(spacing: 16) {
                        Text("🦉")
                            .font(.system(size: 52))
                        Text("Noch keine Notizen")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Olly speichert automatisch Infos\naus euren Gesprächen.")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else {
                    List {
                        ForEach(AITutorNote.Kind.allCases, id: \.self) { kind in
                            let filtered = tutorManager.notes.filter { $0.kind == kind }
                            if !filtered.isEmpty {
                                Section {
                                    ForEach(filtered) { note in
                                        NoteRow(note: note)
                                            .listRowBackground(Color.white.opacity(0.06))
                                    }
                                    .onDelete { idx in
                                        let notes = filtered
                                        idx.forEach { tutorManager.delete(note: notes[$0]) }
                                    }
                                } header: {
                                    Label(kind.rawValue, systemImage: kind.icon)
                                        .foregroundStyle(kind.color)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Olly's Notizen")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(Color(hex: "#A78BFA"))
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct NoteRow: View {
    let note: AITutorNote

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: note.kind.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(note.kind.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                Text(note.createdAt.formatted(.dateTime.day().month().year()))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tutor Home Widget (for HomeView)

struct TutorHomeWidget: View {
    var onTap: () -> Void

    @StateObject private var tutorManager = AITutorManager.shared
    @State private var isTalking = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#7C3AED").opacity(0.3), Color(hex: "#4F46E5").opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    OwlCharacterView(isTalking: isTalking, size: 48)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Olly")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Circle()
                            .fill(Color(hex: "#4ADE80"))
                            .frame(width: 7, height: 7)
                    }

                    if let lastSession = tutorManager.sessions.first {
                        Text(lastSession.preview)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Dein KI-Lernbegleiter · Tippen zum Starten")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color(hex: "#7C3AED").opacity(0.15), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { isTalking = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { isTalking = false }
                }
            }
        }
    }
}

// MARK: - Color Hex Extension (local if not already defined)

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
