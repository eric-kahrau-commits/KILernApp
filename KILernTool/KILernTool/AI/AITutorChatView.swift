import SwiftUI
import PhotosUI

// MARK: - Chat View

struct AITutorChatView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tutorManager = AITutorManager.shared

    @State var session: AITutorSession
    var onSave: (AITutorSession) -> Void

    @State private var inputText   = ""
    @State private var isTyping    = false
    @State private var isTalking   = false
    @State private var pendingImage: UIImage?

    @State private var showPhotoPicker  = false
    @State private var showCamera       = false
    @State private var showAttachMenu   = false
    @State private var photoPickerItem: PhotosPickerItem?

    @State private var remindTitle:   String?
    @State private var remindBody:    String?
    @State private var showRemindSheet = false
    @State private var remindDate      = Date().addingTimeInterval(3600)

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#0F0C29"), Color(hex: "#1A1040")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                Divider().background(Color.white.opacity(0.08))
                messagesArea
                inputBar
            }
        }
        .sheet(isPresented: $showRemindSheet) { reminderSheet }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $photoPickerItem,
            matching: .images
        )
        .onChange(of: photoPickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pendingImage = img
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { img in
                pendingImage = img
            }
        }
        .alert("Fehler", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: saveAndDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            ZStack {
                Circle()
                    .fill(Color(hex: "#7C3AED").opacity(0.4))
                    .frame(width: 38, height: 38)
                OwlCharacterView(isTalking: isTalking, size: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Olly")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Circle()
                        .fill(isTyping ? Color(hex: "#FBBF24") : Color(hex: "#4ADE80"))
                        .frame(width: 6, height: 6)
                    Text(isTyping ? "tippt…" : "Online")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            Menu {
                Button {
                    UIPasteboard.general.string = session.messages
                        .map { "\($0.role == "user" ? "Du" : "Olly"): \($0.content)" }
                        .joined(separator: "\n")
                } label: {
                    Label("Kopieren", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    session.messages.removeAll()
                } label: {
                    Label("Verlauf löschen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if session.messages.isEmpty {
                        welcomePlaceholder
                    } else {
                        ForEach(session.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            .onChange(of: session.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isTyping) { _, typing in
                if typing { scrollToBottom(proxy: proxy, anchor: "typing") }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        withAnimation(.easeOut(duration: 0.3)) {
            if let id = anchor {
                proxy.scrollTo(id, anchor: .bottom)
            } else if let last = session.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var welcomePlaceholder: some View {
        VStack(spacing: 20) {
            OwlCharacterView(size: 90)
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text("Hallo! Ich bin Olly 🦉")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Wie kann ich dir heute beim Lernen helfen?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Suggestion chips
            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { s in
                    Button(action: { inputText = s }) {
                        Text(s)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 16)
    }

    private let suggestions = [
        "Ich habe morgen einen Test in Mathe.",
        "Erkläre mir den Unterschied zwischen Gleichungen und Ungleichungen.",
        "Was kann die App KI Lern alles?",
        "Hilf mir einen Lernplan zu erstellen."
    ]

    // MARK: Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Pending image preview
            if let img = pendingImage {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("Foto angehängt")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button { pendingImage = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07))
            }

            HStack(spacing: 10) {
                // Attach button
                Button {
                    showAttachMenu = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .confirmationDialog("Foto hinzufügen", isPresented: $showAttachMenu) {
                    Button("Kamera") { showCamera = true }
                    Button("Fotos") { showPhotoPicker = true }
                    Button("Abbrechen", role: .cancel) {}
                }

                // Text field
                TextField("Frag Olly etwas…", text: $inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(Color(hex: "#A78BFA"))
                    .lineLimit(1...5)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: inputText.trimmingCharacters(in: .whitespaces).isEmpty && pendingImage == nil
                          ? "mic.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "#7C3AED").opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .disabled(isTyping)
                .opacity(isTyping ? 0.5 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            Color(hex: "#0F0C29").opacity(0.95)
                .background(.ultraThinMaterial.opacity(0.3))
        )
    }

    // MARK: Send Message

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || pendingImage != nil else { return }

        // Build user message
        let userMsg = AITutorMessage(role: "user", content: text, image: pendingImage)
        session.messages.append(userMsg)
        session.updatedAt = Date()

        // Auto-title from first user message
        if session.title == "Neues Gespräch" && !text.isEmpty {
            session.title = String(text.prefix(35))
        }

        let capturedImage = pendingImage
        inputText    = ""
        pendingImage = nil
        isTyping     = true
        isTalking    = false

        Task {
            do {
                let systemPrompt = tutorManager.buildSystemPrompt()
                let fullContext  = buildContextMessages()
                let reply = try await AIService.shared.tutorChatWithHistory(
                    systemPrompt: systemPrompt,
                    history: fullContext,
                    userText: text,
                    images: capturedImage.map { [$0] } ?? []
                )

                await MainActor.run {
                    isTyping  = false
                    isTalking = true

                    let parsed = tutorManager.parse(response: reply)
                    let botMsg = AITutorMessage(role: "assistant", content: parsed.clean)
                    session.messages.append(botMsg)
                    session.updatedAt = Date()

                    // Handle note
                    if let kind = parsed.noteKind, let text = parsed.noteText {
                        tutorManager.addNote(kind: kind, text: text)
                    }

                    // Handle reminder
                    if let rt = parsed.remindTitle, let rb = parsed.remindBody {
                        remindTitle   = rt
                        remindBody    = rb
                        showRemindSheet = true
                    }

                    onSave(session)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isTalking = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTyping     = false
                    errorMessage = error.localizedDescription
                    showError    = true
                }
            }
        }
    }

    private func buildContextMessages() -> [(role: String, content: String)] {
        session.messages.dropLast().suffix(12).map { ($0.role, $0.content) }
    }

    // MARK: Reminder Sheet

    private var reminderSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0F0C29").ignoresSafeArea()
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("🦉")
                            .font(.system(size: 44))
                        Text(remindTitle ?? "Erinnerung")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(remindBody ?? "")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    DatePicker("Zeitpunkt", selection: $remindDate, in: Date()...)
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                        .tint(Color(hex: "#A78BFA"))
                        .padding(.horizontal)

                    HStack(spacing: 14) {
                        Button("Überspringen") { showRemindSheet = false }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button("Erinnern") {
                            if let t = remindTitle, let b = remindBody {
                                tutorManager.scheduleReminder(title: t, body: b, at: remindDate)
                            }
                            showRemindSheet = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Erinnerung setzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") { showRemindSheet = false }
                        .foregroundStyle(Color(hex: "#A78BFA"))
                }
            }
        }
    }

    // MARK: Dismiss

    private func saveAndDismiss() {
        onSave(session)
        dismiss()
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: AITutorMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            if !isUser {
                // Olly avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "#7C3AED").opacity(0.35))
                        .frame(width: 30, height: 30)
                    Text("🦉").font(.system(size: 14))
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Image
                if let img = message.uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 200, maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Text bubble
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundStyle(isUser ? .white : .white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            isUser
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                              )
                            : AnyShapeStyle(Color.white.opacity(0.10))
                        )
                        .clipShape(
                            RoundedCornerBubble(
                                radius: 18,
                                corners: isUser
                                    ? [.topLeft, .topRight, .bottomLeft]
                                    : [.topLeft, .topRight, .bottomRight]
                            )
                        )
                }

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#7C3AED").opacity(0.35))
                    .frame(width: 30, height: 30)
                Text("🦉").font(.system(size: 14))
            }

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(phase == i ? 0.9 : 0.3))
                        .frame(width: 7, height: 7)
                        .offset(y: phase == i ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4).delay(Double(i) * 0.15).repeatForever(),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedCornerBubble(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation { phase = 0 }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

// MARK: - Rounded Corner Bubble Shape

struct RoundedCornerBubble: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - AIService tutorChatWithHistory extension

extension AIService {
    /// Sends a multi-turn conversation with optional images on the latest message.
    func tutorChatWithHistory(
        systemPrompt: String,
        history: [(role: String, content: String)],
        userText: String,
        images: [UIImage] = []
    ) async throws -> String {
        if images.isEmpty {
            var msgs: [AIMessage] = [AIMessage(role: "system", content: systemPrompt)]
            msgs += history.map { AIMessage(role: $0.role, content: $0.content) }
            msgs.append(AIMessage(role: "user", content: userText.isEmpty ? "(Bild)" : userText))
            return try await chat(messages: msgs)
        }
        // Has images – use vision endpoint (only last user turn supported with images)
        return try await tutorChat(systemPrompt: systemPrompt, userText: userText, images: images)
    }
}

// MARK: - Color Hex (local)

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
