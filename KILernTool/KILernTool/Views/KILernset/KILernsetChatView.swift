import SwiftUI

struct KILernsetChatView: View {
    let setName: String
    let subjectName: String
    var onSaved: ((LernSet) -> Void)? = nil

    @StateObject private var viewModel = KILernsetViewModel()
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var inputMode: InputMode = .text
    @State private var isListening = false
    @FocusState private var isFocused: Bool

    // Generation overlay
    @State private var isGeneratingOverlay = false
    @State private var generationProgress: Double = 0

    enum InputMode { case text, voice }

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                checklistStrip
                Divider()
                chatScrollView
                inputBar
            }

            if isGeneratingOverlay {
                TheoGeneratingOverlay(progress: $generationProgress)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isGeneratingOverlay)
        .onAppear { viewModel.startConversation() }
        .onChange(of: viewModel.showPreview) { _, shown in
            if shown {
                withAnimation { generationProgress = 100 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { isGeneratingOverlay = false }
                }
            }
        }
        .sheet(isPresented: $viewModel.showPreview) {
            KILernsetPreviewView(
                cards: viewModel.generatedCards,
                setName: setName,
                subjectName: subjectName,
                onSaved: onSaved
            )
            .environmentObject(store)
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

            VStack(spacing: 1) {
                Text("KI Lernset erstellen")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Freier KI-Chat")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    private func startFakeProgress() {
        Task {
            let steps = 40
            for i in 0..<steps {
                let pct = Double(i + 1) / Double(steps) * 88.0
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard isGeneratingOverlay else { break }
                withAnimation(.easeOut(duration: 0.3)) { generationProgress = pct }
            }
        }
    }

    // MARK: - Checklist Strip

    private var checklistStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.checklist) { item in
                    ChecklistChip(item: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Chat Scroll View

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        ChatBubble(message: msg).id(msg.id)
                    }

                    if viewModel.isLoading { loadingIndicator }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.allFieldsComplete && !viewModel.isLoading {
                        generateButton
                    }

                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: viewModel.isLoading) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // MARK: - Loading indicator

    private var loadingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(accent.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: viewModel.isLoading
                        )
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            Spacer()
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generationProgress = 0
            withAnimation { isGeneratingOverlay = true }
            startFakeProgress()
            Task { await viewModel.generateLernSet() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                Text("Lernset erstellen").font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .shadow(color: accent.opacity(0.40), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                // Toggle text / voice
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        inputMode = inputMode == .text ? .voice : .text
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .frame(width: 38, height: 38)
                        Image(systemName: inputMode == .text ? "mic" : "keyboard")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if inputMode == .text {
                    textField
                } else {
                    voiceButton
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
        }
    }

    private var textField: some View {
        HStack(spacing: 8) {
            TextField("Antwort eingeben…", text: $viewModel.inputText, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...4)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { viewModel.sendMessage() }

            if !viewModel.inputText.isEmpty {
                Button { viewModel.sendMessage() } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var voiceButton: some View {
        // Placeholder integration point for SFSpeechRecognizer.
        // To activate: inject a VoiceInputManager and bind its transcript to viewModel.inputText.
        Button {
            withAnimation(.spring(response: 0.3)) { isListening.toggle() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isListening
                              ? Color.red.opacity(0.14)
                              : accent.opacity(0.10))
                        .frame(width: 42, height: 42)
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isListening ? .red : accent)
                        .symbolEffect(.pulse, isActive: isListening)
                }
                Text(isListening ? "Tippe zum Stoppen…" : "Tippe zum Sprechen")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Checklist Chip

struct ChecklistChip: View {
    let item: ChecklistField
    private let doneColor = Color(red: 0.18, green: 0.70, blue: 0.40)

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(item.isDone ? doneColor : Color.secondary.opacity(0.20))
                    .frame(width: 18, height: 18)
                if item.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: item.isDone)

            Text(item.label)
                .font(.system(size: 13, weight: item.isDone ? .semibold : .regular))
                .foregroundStyle(item.isDone ? .primary : .secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(
            Capsule()
                .fill(item.isDone
                      ? doneColor.opacity(0.10)
                      : Color(uiColor: .tertiarySystemGroupedBackground))
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: item.isDone)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    private var isUser: Bool { message.sender == .user }

    // Typewriter state – only used for AI messages
    @State private var displayedText: String = ""
    @State private var animationDone: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                MascotView(
                    color: accent,
                    mood: animationDone ? .idle : .talking,
                    size: 30
                )
                .frame(width: 30, height: 34)
            }

            Group {
                if isUser || animationDone {
                    Text(styledText(message.text))
                } else {
                    Text(displayedText)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isUser
                          ? AnyShapeStyle(LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)))
            )
            .shadow(color: isUser ? accent.opacity(0.25) : .black.opacity(0.05),
                    radius: 6, x: 0, y: 3)

            if !isUser { Spacer(minLength: 60) }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            if isUser {
                animationDone = true
            } else {
                startTypewriter()
            }
        }
    }

    /// Fast typewriter: 4 characters per step, ~14ms between steps.
    private func startTypewriter() {
        let full = message.text
        guard !full.isEmpty else { animationDone = true; return }
        Task {
            var idx = full.startIndex
            while idx < full.endIndex {
                let remaining = full.distance(from: idx, to: full.endIndex)
                let step = min(4, remaining)
                let nextIdx = full.index(idx, offsetBy: step)
                displayedText = String(full[full.startIndex..<nextIdx])
                idx = nextIdx
                // Slight random jitter gives a more human feel
                let baseNs: UInt64 = 14_000_000
                let jitterNs = UInt64.random(in: 0...6_000_000)
                try? await Task.sleep(nanoseconds: baseNs + jitterNs)
            }
            animationDone = true
        }
    }

    private func styledText(_ raw: String) -> AttributedString {
        (try? AttributedString(markdown: raw,
             options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace)))
        ?? AttributedString(raw)
    }
}

// MARK: - Theo Generating Overlay

private struct TheoGeneratingOverlay: View {
    @Binding var progress: Double

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 28) {
                MascotView(color: accent, mood: .celebrating, size: 110)
                    .frame(height: 130)

                VStack(spacing: 8) {
                    Text("Ich erstelle dein Lernset …")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Theo arbeitet auf Hochtouren für dich! 🔥")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.15), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress / 100))
                        .stroke(
                            LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.3), value: progress)
                    Text("\(Int(progress)) %")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 8)
            )
            .padding(.horizontal, 40)
        }
    }
}
