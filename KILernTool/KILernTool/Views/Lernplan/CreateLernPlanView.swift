import SwiftUI
import PhotosUI

struct CreateLernPlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lernPlanStore: LernPlanStore

    var onSaved: ((LernPlan) -> Void)? = nil

    // Step 1: Photos
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false

    // Image Analysis (between Step 1 and Step 2)
    @State private var isAnalyzingImages: Bool = false
    @State private var extractedContent: String = ""
    @State private var extractedTopics: [String] = []
    @State private var analysisExpanded: Bool = false

    // Step 2: Details
    @State private var fach: String = Subject.all.first?.name ?? "Mathe"
    @State private var klassenstufe: String = ""
    @State private var thema: String = ""
    @State private var testDatum: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var besonderheiten: String = ""

    // Navigation
    @State private var currentStep: Int = 1   // 1 = photos, 2 = details

    // Generation
    @State private var isGenerating: Bool = false
    @State private var generationError: String? = nil
    @State private var isGeneratingOverlay: Bool = false
    @State private var generationProgress: Double = 0
    @State private var showCelebration: Bool = false
    @State private var savedPlan: LernPlan? = nil
    @State private var showDismissAlert: Bool = false

    private var hasUnsavedChanges: Bool {
        !thema.isEmpty || !klassenstufe.isEmpty || !besonderheiten.isEmpty || !selectedImages.isEmpty
    }

    private let gradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let accent = AppColors.brandBlue

    private var canAdvance: Bool {
        if currentStep == 1 { return true }  // photos optional
        return !klassenstufe.trimmingCharacters(in: .whitespaces).isEmpty &&
               !thema.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var saschaGuideText: String {
        if currentStep == 1 {
            if selectedImages.isEmpty {
                return "Hast du Buchseiten, die ich analysieren soll? 📸\nFotos helfen mir, deinen Plan noch genauer zu gestalten – aber kein Muss!"
            } else {
                return "Super! \(selectedImages.count) \(selectedImages.count == 1 ? "Seite" : "Seiten") hochgeladen. Ich analysiere den Inhalt und erstelle einen maßgeschneiderten Plan! 🔍"
            }
        } else {
            if isAnalyzingImages {
                return "Ich lese gerade deine Buchseiten … Das dauert nur einen Moment! 📖"
            }
            if !extractedContent.isEmpty {
                return "Ich habe deinen Buchinhalt analysiert! Ergänze noch die Details – dann erstelle ich deinen Plan. 🎯"
            }
            let detailsFilled = !klassenstufe.trimmingCharacters(in: .whitespaces).isEmpty &&
                                !thema.trimmingCharacters(in: .whitespaces).isEmpty
            return detailsFilled
                ? "Perfekt! Ich bin bereit – klick auf **Lernplan erstellen**! 🚀"
                : "Fast da! Sag mir Fach, Klasse und Thema – ich baue dir einen perfekten Lernplan! 🗓️"
        }
    }

    private var formProgress: Double {
        if currentStep == 1 { return 0.5 }
        let filled = !klassenstufe.trimmingCharacters(in: .whitespaces).isEmpty &&
                     !thema.trimmingCharacters(in: .whitespaces).isEmpty
        return filled ? 1.0 : 0.5
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                CreationProgressBar(progress: formProgress, color: accent)
                ScrollView {
                    VStack(spacing: 24) {
                        MascotGuideBanner(color: accent, characterName: "Sascha", text: saschaGuideText)
                        if currentStep == 1 {
                            photoStep
                        } else {
                            detailStep
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                bottomBar
            }

            if isGeneratingOverlay {
                SaschaGeneratingOverlay(progress: $generationProgress)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
            }

            if showCelebration {
                SaveCelebrationOverlay(color: accent, characterName: "Sascha") {
                    showCelebration = false
                    dismiss()
                    if let plan = savedPlan {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onSaved?(plan) }
                    }
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isGeneratingOverlay)
        .alert("Eingaben verwerfen?", isPresented: $showDismissAlert) {
            Button("Verwerfen", role: .destructive) { dismiss() }
            Button("Weiter bearbeiten", role: .cancel) {}
        } message: {
            Text("Deine Eingaben gehen verloren, wenn du jetzt abbrichst.")
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                selectedImages.append(image)
            }
        }
        .onChange(of: photoPickerItems) {
            Task {
                for item in photoPickerItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
                photoPickerItems = []
            }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                if currentStep > 1 {
                    currentStep -= 1
                } else if hasUnsavedChanges {
                    showDismissAlert = true
                } else {
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: currentStep > 1 ? "chevron.left" : "xmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(currentStep > 1 ? "Zurück" : "Schließen")
            Spacer()
            Text("Lernplan erstellen")
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

    // MARK: - Step 1: Photos

    private var photoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Buchseiten scannen")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Fotografiere die relevanten Seiten deines Schulbuchs oder Hefts. Die KI analysiert den Inhalt automatisch.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Photo grid
            if !selectedImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Button {
                                selectedImages.remove(at: idx)
                            } label: {
                                ZStack {
                                    Circle().fill(.black.opacity(0.55)).frame(width: 22, height: 22)
                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                        }
                    }
                }
            }

            // Add photo buttons
            HStack(spacing: 12) {
                Button { showCamera = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Kamera")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 20, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Bibliothek")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }

            if selectedImages.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                    Text("Fotos sind optional – ohne Bilder erstellt die KI den Plan nur auf Basis deiner Themenangabe.")
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .tertiarySystemGroupedBackground)))
            }
        }
    }

    // MARK: - Step 2: Details

    private var detailStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Details zum Test")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Diese Informationen helfen der KI, deinen Lernplan optimal zu gestalten.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Show analysis result if images were uploaded
            if !extractedContent.isEmpty {
                BookAnalysisCard(
                    topics: extractedTopics,
                    fullText: extractedContent,
                    imageCount: selectedImages.count,
                    isExpanded: $analysisExpanded
                )
            }

            // Fach picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Fach")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Subject.all) { subject in
                            Button { fach = subject.name } label: {
                                Text(subject.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(fach == subject.name ? .white : .primary)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(fach == subject.name
                                            ? subject.color
                                            : Color(uiColor: .secondarySystemGroupedBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            // Klassenstufe
            inputField(label: "Klassenstufe", placeholder: "z. B. 9. Klasse", text: $klassenstufe)

            // Thema
            VStack(alignment: .leading, spacing: 8) {
                Text("Thema des Tests")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("z. B. Quadratische Gleichungen, lineare Funktionen …", text: $thema, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }

            // Test date
            VStack(alignment: .leading, spacing: 8) {
                Text("Testtermin")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $testDatum, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Besonderheiten
            VStack(alignment: .leading, spacing: 8) {
                Text("Besonderheiten (optional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("z. B. Lehrer legt großen Wert auf Rechenwege …", text: $besonderheiten, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }

            if let error = generationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    Text(error).font(.system(size: 13)).foregroundStyle(.red)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: handleMainAction) {
                Group {
                    if isAnalyzingImages {
                        HStack(spacing: 10) {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                            Text("Buchseiten werden analysiert …")
                        }
                    } else if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                            Text("KI erstellt Lernplan …")
                        }
                    } else if currentStep == 1 && !selectedImages.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Bilder analysieren & Weiter")
                        }
                    } else {
                        Text(currentStep == 1 ? "Weiter" : "Lernplan erstellen")
                    }
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canAdvance && !isGenerating && !isAnalyzingImages
                              ? gradient
                              : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || isGenerating || isAnalyzingImages)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Logic

    private func handleMainAction() {
        if currentStep == 1 {
            if selectedImages.isEmpty {
                withAnimation { currentStep = 2 }
            } else {
                analyzeImagesAndAdvance()
            }
        } else {
            generatePlan()
        }
    }

    private func analyzeImagesAndAdvance() {
        isAnalyzingImages = true
        Task {
            do {
                let analysis = try await AIService.shared.analyzeBookPages(images: selectedImages)
                extractedContent = analysis.fullText
                extractedTopics  = analysis.topics
                // Pre-fill thema from extracted topics if user hasn't typed anything
                if thema.trimmingCharacters(in: .whitespaces).isEmpty && !analysis.topics.isEmpty {
                    thema = analysis.topics.prefix(3).joined(separator: ", ")
                }
            } catch {
                // Analysis failed — still advance, generation will work without extracted content
                extractedContent = ""
                extractedTopics  = []
            }
            isAnalyzingImages = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { currentStep = 2 }
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

    private func generatePlan() {
        generationError = nil
        isGenerating = true
        generationProgress = 0
        withAnimation { isGeneratingOverlay = true }
        startFakeProgress()
        Task {
            do {
                let rawPlan = try await AIService.shared.generateLernPlan(
                    fach: fach,
                    klassenstufe: klassenstufe,
                    thema: thema,
                    besonderheiten: besonderheiten,
                    testDatum: testDatum,
                    extractedContent: extractedContent
                )

                // Build LernPlanTage with dates starting from tomorrow
                let calendar = Calendar.current
                let startDate = calendar.startOfDay(for: Date())
                var tage: [LernPlanTag] = []
                for (i, rawTag) in rawPlan.tage.enumerated() {
                    let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
                    let aufgaben = rawTag.aufgaben.map { raw in
                        LernPlanAufgabe(
                            titel: raw.titel,
                            beschreibung: raw.beschreibung,
                            thema: raw.thema,
                            schwierigkeit: raw.schwierigkeit,
                            anzahl: 10,
                            typ: raw.typ ?? "neuerStoff",
                            dauerMinuten: raw.dauerMinuten ?? 30
                        )
                    }
                    tage.append(LernPlanTag(tagNummer: i + 1, datum: date, aufgaben: aufgaben))
                }

                let plan = LernPlan(
                    titel: rawPlan.titel,
                    fach: fach,
                    klassenstufe: klassenstufe,
                    testDatum: testDatum,
                    thema: thema,
                    besonderheiten: besonderheiten,
                    tage: tage
                )

                lernPlanStore.save(plan)
                StreakManager.shared.markActivity()
                savedPlan = plan
                isGenerating = false
                withAnimation(.easeOut(duration: 0.3)) { generationProgress = 100 }
                try? await Task.sleep(nanoseconds: 700_000_000)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isGeneratingOverlay = false }
                try? await Task.sleep(nanoseconds: 350_000_000)
                withAnimation { showCelebration = true }
            } catch {
                isGenerating = false
                withAnimation { isGeneratingOverlay = false }
                generationError = "Fehler beim Erstellen: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }
}

// MARK: - Book Analysis Card

private struct BookAnalysisCard: View {
    let topics: [String]
    let fullText: String
    let imageCount: Int
    @Binding var isExpanded: Bool

    private let accent = Color(red: 0.10, green: 0.48, blue: 0.92)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("KI hat \(imageCount) \(imageCount == 1 ? "Buchseite" : "Buchseiten") analysiert")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Lernplan wird auf deinen Buchinhalt zugeschnitten")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(accent.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }

            // Topic chips
            if !topics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(accent.opacity(0.10)))
                        }
                    }
                }
            }

            // Full analysis text (expandable)
            if isExpanded {
                Divider()
                    .overlay(accent.opacity(0.15))

                Text(fullText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sascha Generating Overlay

private struct SaschaGeneratingOverlay: View {
    @Binding var progress: Double

    private let rainbowColors: [Color] = [
        Color(red: 0.38, green: 0.18, blue: 0.90),
        Color(red: 0.10, green: 0.48, blue: 0.92),
        Color(red: 0.10, green: 0.64, blue: 0.54),
        Color(red: 0.86, green: 0.50, blue: 0.10),
        Color(red: 0.90, green: 0.28, blue: 0.50),
        Color(red: 0.55, green: 0.20, blue: 0.85),
    ]

    @State private var colorIndex: Int = 0
    @State private var ringRotation: Double = 0

    private var currentColor: Color { rainbowColors[colorIndex] }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 28) {
                // Rotating rainbow ring + mascot
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(colors: rainbowColors + [rainbowColors[0]], center: .center),
                            lineWidth: 6
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .fill(currentColor.opacity(0.10))
                        .frame(width: 132, height: 132)

                    MascotView(color: currentColor, mood: .celebrating, size: 100)
                        .frame(width: 100, height: 114)
                }

                VStack(spacing: 8) {
                    Text("Ich erstelle deinen Lernplan …")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Sascha plant deinen Weg zum Erfolg! 🌈")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // Rainbow progress ring
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemGroupedBackground), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress / 100))
                        .stroke(
                            AngularGradient(
                                colors: rainbowColors + [rainbowColors[0]],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.3), value: progress)
                    Text("\(Int(progress)) %")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(currentColor)
                        .animation(.easeInOut(duration: 0.6), value: colorIndex)
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
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
        .task {
            var idx = 0
            while true {
                try? await Task.sleep(nanoseconds: 650_000_000)
                idx = (idx + 1) % rainbowColors.count
                withAnimation(.easeInOut(duration: 0.6)) { colorIndex = idx }
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
