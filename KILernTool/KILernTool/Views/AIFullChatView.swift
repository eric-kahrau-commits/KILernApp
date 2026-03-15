import SwiftUI

struct AIFullChatView: View {
    /// Messages seeded from the mini chat widget (system + user + optional assistant reply)
    let seedMessages: [AIMessage]

    @Environment(\.dismiss) var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var apiMessages: [AIMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    private let systemPrompt = "Du bist ein hilfreicher Lernassistent für Schüler. Antworte präzise, freundlich und auf Deutsch."

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if messages.isEmpty && !isLoading {
                                emptyState
                            }
                            ForEach(messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                            if isLoading {
                                loadingBubble
                                    .id("loading")
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 110)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { _, loading in
                        if loading {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                inputBar
            }
        }
        .onAppear { loadSeed() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("KI-Assistent")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                Text("Lernassistent")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.sender == .user {
                Spacer(minLength: 50)
                Text(msg.text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accent)
                    )
            } else {
                ZStack {
                    Circle().fill(accent.opacity(0.10)).frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                }
                Text(msg.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                Spacer(minLength: 50)
            }
        }
    }

    // MARK: - Loading Bubble

    private var loadingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(accent.opacity(0.10)).frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(accent.opacity(0.5))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            Spacer(minLength: 50)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(spacing: 6) {
                Text("Wie kann ich dir helfen?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Stell eine Frage zu deinem Lernstoff\nund ich helfe dir weiter.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
            HStack(spacing: 12) {
                TextField("Nachricht …", text: $inputText, axis: .vertical)
                    .font(.system(size: 16))
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            sendMessage()
                        }
                    }

                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(uiColor: .tertiarySystemFill)
                                  : accent)
                            .frame(width: 36, height: 36)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color(uiColor: .tertiaryLabel)
                                    : Color.white
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
    }

    // MARK: - Logic

    private func loadSeed() {
        // Build display messages from seed (skip the system message)
        let displayable = seedMessages.filter { $0.role != "system" }
        messages = displayable.map { msg in
            ChatMessage(sender: msg.role == "user" ? .user : .ai, text: msg.content)
        }
        // Reconstruct apiMessages: start with system prompt + all seed messages
        let sys = AIMessage(role: "system", content: systemPrompt)
        apiMessages = [sys] + seedMessages.filter { $0.role != "system" }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        isFocused = false

        let userDisplay = ChatMessage(sender: .user, text: text)
        messages.append(userDisplay)

        let userAPIMsg = AIMessage(role: "user", content: text)
        apiMessages.append(userAPIMsg)

        isLoading = true

        Task {
            do {
                let response = try await AIService.shared.chat(messages: apiMessages)
                let aiDisplay = ChatMessage(sender: .ai, text: response)
                messages.append(aiDisplay)
                apiMessages.append(AIMessage(role: "assistant", content: response))
                isLoading = false
            } catch {
                let errMsg = ChatMessage(sender: .ai, text: "Fehler: \(error.localizedDescription)")
                messages.append(errMsg)
                isLoading = false
            }
        }
    }
}
