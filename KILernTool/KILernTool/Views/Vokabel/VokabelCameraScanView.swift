import SwiftUI
import PhotosUI

// MARK: - Camera Scan Flow

@MainActor
struct VokabelCameraScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: LernSetStore

    enum Step { case hint, processing, review }

    @State private var step: Step = .hint
    @State private var capturedImage: UIImage?
    @State private var showCamera = false

    // Parsed results
    @State private var scannedPairs: [VokabelPair] = []
    @State private var detectedLanguage = "Englisch"
    @State private var suggestedName = ""
    @State private var setName = ""
    @State private var selectedFach = "Englisch"
    @State private var errorMessage: String?
    @State private var showError = false

    // Animations
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotActive = 0
    @State private var robertMood: MascotMood = .happy

    private let accent = AppColors.brandVokabelGold
    private let accentDark = Color(red: 0.86, green: 0.50, blue: 0.10)
    private let fächer = ["Englisch","Französisch","Spanisch","Latein","Deutsch","Italienisch"]

    struct VokabelPair: Identifiable {
        let id = UUID()
        var word: String
        var translation: String
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            switch step {
            case .hint:       hintView
            case .processing: processingView
            case .review:     reviewView
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { img in
                capturedImage = img
                showCamera = false
                step = .processing
                analyzeImage(img)
            }
        }
        .alert("Fehler", isPresented: $showError, presenting: errorMessage) { _ in
            Button("Nochmal") {
                withAnimation { step = .hint }
            }
        } message: { m in Text(m) }
    }

    // MARK: – Step 1: Hint

    private var hintView: some View {
        VStack(spacing: 0) {
            // Nav bar
            hintNavBar

            // Scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Robert speech
                    robertSpeechBubble(
                        mood: robertMood,
                        text: "Ich scanne deine Vokabelliste! Halte die Kamera auf eine Tabelle oder Liste mit Vokabeln – ich erkenne die Wörter automatisch. ✨"
                    )

                    // Tips
                    VStack(spacing: 10) {
                        tipCard(
                            icon: "tablecells.fill",
                            color: Color(red: 0.10, green: 0.48, blue: 0.92),
                            title: "Tabelle oder Liste",
                            desc: "Vokabel links, Übersetzung rechts – oder eine Liste untereinander"
                        )
                        tipCard(
                            icon: "light.max",
                            color: Color(red: 0.30, green: 0.70, blue: 0.40),
                            title: "Gute Beleuchtung",
                            desc: "Helles Licht sorgt für bessere Erkennung"
                        )
                        tipCard(
                            icon: "viewfinder",
                            color: Color(red: 0.85, green: 0.25, blue: 0.45),
                            title: "Gerade halten",
                            desc: "Kamera parallel zum Blatt – nicht schräg"
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 20)
                .offset(y: contentOffset)
                .opacity(contentOpacity)
            }

            // Kamera button pinned to bottom
            VStack(spacing: 0) {
                Divider()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        robertMood = .celebrating
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showCamera = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Kamera öffnen")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.15),
                                     Color(red: 0.98, green: 0.65, blue: 0.05)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: accent.opacity(0.5), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) {
                contentOffset = 0
                contentOpacity = 1
            }
        }
    }

    private var hintNavBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Vokabeln scannen")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Color.clear.frame(width: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: – Step 2: Processing

    private var processingView: some View {
        VStack(spacing: 0) {
            // Mini nav
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text("Analysiere Bild")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Robert arbeitet...")
                        .font(.system(size: 11))
                        .foregroundStyle(accentDark)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.bar)
            .overlay(alignment: .bottom) {
                Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
            }

            Spacer()

            VStack(spacing: 32) {
                // Robert with pulsing rings
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(accent.opacity(0.18 - Double(i) * 0.04), lineWidth: 2)
                            .frame(width: 110 + CGFloat(i) * 32, height: 110 + CGFloat(i) * 32)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 1.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.18),
                                value: pulseScale
                            )
                    }
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.88, blue: 0.15),
                                         Color(red: 0.98, green: 0.62, blue: 0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: accent.opacity(0.45), radius: 20, x: 0, y: 6)
                    MascotView(color: .black.opacity(0.75), mood: .thinking, size: 68)
                }
                .onAppear { pulseScale = 1.10 }

                VStack(spacing: 10) {
                    Text("Robert analysiert…")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("Vokabeln werden erkannt und sortiert")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Animated dot progress
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accent.opacity(dotActive == i ? 1 : 0.25))
                            .frame(width: dotActive == i ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: dotActive)
                    }
                }
                .onAppear { animateDots() }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { t in
            dotActive = (dotActive + 1) % 4
            if step != .processing { t.invalidate() }
        }
    }

    // MARK: – Step 3: Review

    private var reviewView: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Robert success message
                        robertSpeechBubble(
                            mood: .celebrating,
                            text: "Super! Ich habe \(scannedPairs.count) Vokabelpaare gefunden 🎉 Prüfe die Wörter, gib dem Set einen Namen und wähle ein Fach."
                        )

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Name des Sets")
                            TextField("z. B. \(suggestedName)", text: $setName)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                        }

                        // Fach picker
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Sprache / Fach")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(fächer, id: \.self) { f in
                                        Button { selectedFach = f } label: {
                                            Text(f)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(selectedFach == f ? .black : .primary)
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedFach == f ? accent : Color(uiColor: .secondarySystemGroupedBackground))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Vocabulary table
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                sectionLabel("Erkannte Vokabeln (\(scannedPairs.count))")
                                Spacer()
                                Button {
                                    scannedPairs.append(VokabelPair(word: "", translation: ""))
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(accent)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 0) {
                                Text("VOKABEL").frame(maxWidth: .infinity, alignment: .leading)
                                Text("ÜBERSETZUNG").frame(maxWidth: .infinity, alignment: .leading)
                                Spacer().frame(width: 36)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(spacing: 0) {
                                ForEach(Array(scannedPairs.enumerated()), id: \.element.id) { idx, _ in
                                    pairRow(idx: idx)
                                    if idx < scannedPairs.count - 1 {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }

                        // Captured image thumbnail
                        if let img = capturedImage {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Gescanntes Bild")
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Vokabeln prüfen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { saveScannedSet() }
                        .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty
                                  || scannedPairs.filter { !$0.word.isEmpty }.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func pairRow(idx: Int) -> some View {
        HStack(spacing: 0) {
            TextField("Vokabel", text: Binding(
                get: { idx < scannedPairs.count ? scannedPairs[idx].word : "" },
                set: { if idx < scannedPairs.count { scannedPairs[idx].word = $0 } }
            ))
            .font(.system(size: 14))
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            TextField("Übersetzung", text: Binding(
                get: { idx < scannedPairs.count ? scannedPairs[idx].translation : "" },
                set: { if idx < scannedPairs.count { scannedPairs[idx].translation = $0 } }
            ))
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            if scannedPairs.count > 1 {
                Button {
                    scannedPairs.remove(at: idx)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: 36)
            } else {
                Spacer().frame(width: 36)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    // MARK: – AI Analysis

    private func analyzeImage(_ image: UIImage) {
        Task {
            let systemPrompt = """
            Du bist ein Vokabel-Erkennungs-Assistent. Analysiere das Bild und erkenne alle Vokabelpaare.
            Regeln:
            - Erkenne vollständige Phrasen bis 5 Wörter; kürze nur wenn ein Ausdruck länger als 6 Wörter ist.
            - Trenne Verben von Artikeln: "laufen" statt "das Laufen", außer es handelt sich um ein Nomen.
            - Erhalte Sonderzeichen (Akzente, Umlaute, ñ, ç, etc.) exakt wie im Bild.
            - Erkenne die Fremdsprache der Vokabeln automatisch.
            - Schlage einen kurzen Set-Namen vor (max 4 Wörter).
            Antworte NUR mit gültigem JSON, kein anderer Text:
            {"name":"...","language":"...","pairs":[{"word":"...","translation":"..."}]}
            """
            do {
                let raw = try await AIService.shared.tutorChat(
                    systemPrompt: systemPrompt,
                    userText: "Erkenne alle Vokabelpaare in diesem Bild.",
                    images: [image]
                )
                parseAIResponse(raw)
            } catch {
                errorMessage = "KI konnte das Bild nicht analysieren: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    @MainActor
    private func parseAIResponse(_ raw: String) {
        let cleaned = raw
            .components(separatedBy: "```").filter { !$0.hasPrefix("json") }.joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else {
            errorMessage = "Konnte keine Vokabeln erkennen. Bitte versuche es erneut."
            showError = true
            return
        }

        let jsonStr = String(cleaned[jsonStart...jsonEnd])
        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pairs = json["pairs"] as? [[String: String]] else {
            errorMessage = "Format-Fehler. Bitte erneut versuchen."
            showError = true
            return
        }

        scannedPairs = pairs.compactMap { dict in
            guard let w = dict["word"], let t = dict["translation"],
                  !w.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return VokabelPair(word: truncateToWords(w, max: 3),
                               translation: truncateToWords(t, max: 3))
        }

        suggestedName = (json["name"] as? String) ?? "Vokabelset"
        detectedLanguage = (json["language"] as? String) ?? "Englisch"
        setName = suggestedName

        if let match = fächer.first(where: { $0.lowercased() == detectedLanguage.lowercased() }) {
            selectedFach = match
        } else {
            selectedFach = detectedLanguage
        }

        if scannedPairs.isEmpty {
            errorMessage = "Keine Vokabeln gefunden. Halte die Kamera auf eine Vokabelliste oder -tabelle."
            showError = true
        } else {
            withAnimation(.spring(response: 0.5)) { step = .review }
        }
    }

    private func truncateToWords(_ text: String, max: Int) -> String {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.prefix(max).joined(separator: " ")
    }

    private func saveScannedSet() {
        let cards = scannedPairs
            .filter { !$0.word.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { LernSetCard(question: $0.word, answer: $0.translation) }
        guard !cards.isEmpty else { return }
        let name = setName.trimmingCharacters(in: .whitespaces).isEmpty ? suggestedName : setName
        let set = LernSet(name: name, subject: selectedFach, cards: cards, isVokabelSet: true)
        store.save(set)
        _ = StreakManager.shared.markActivity()
        dismiss()
    }

    // MARK: – Shared Helpers

    private func robertSpeechBubble(mood: MascotMood, text: String) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.15),
                                     Color(red: 0.98, green: 0.62, blue: 0.04)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: accent.opacity(0.4), radius: 10, x: 0, y: 4)
                MascotView(color: .black.opacity(0.75), mood: mood, size: 42)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text("Robert")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(accentDark)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(accentDark)
                }
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func tipCard(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}
