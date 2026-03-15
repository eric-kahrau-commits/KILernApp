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

    private let gradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92), Color(red: 0.22, green: 0.70, blue: 1.00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let accent = Color(red: 0.10, green: 0.48, blue: 0.92)

    private var canAdvance: Bool {
        if currentStep == 1 { return true }  // photos optional
        return !klassenstufe.trimmingCharacters(in: .whitespaces).isEmpty &&
               !thema.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                stepIndicator
                ScrollView {
                    VStack(spacing: 24) {
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
                if currentStep > 1 { currentStep -= 1 } else { dismiss() }
            } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                    Image(systemName: currentStep > 1 ? "chevron.left" : "xmark")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
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

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...2, id: \.self) { step in
                Capsule()
                    .fill(currentStep >= step ? accent : Color(uiColor: .tertiarySystemGroupedBackground))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
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
                    if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                            Text("KI erstellt Lernplan …")
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
                        .fill(canAdvance && !isGenerating ? gradient : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || isGenerating)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Logic

    private func handleMainAction() {
        if currentStep == 1 {
            withAnimation { currentStep = 2 }
        } else {
            generatePlan()
        }
    }

    private func generatePlan() {
        generationError = nil
        isGenerating = true
        Task {
            do {
                let rawPlan = try await AIService.shared.generateLernPlan(
                    fach: fach,
                    klassenstufe: klassenstufe,
                    thema: thema,
                    besonderheiten: besonderheiten,
                    testDatum: testDatum,
                    images: selectedImages
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
                            anzahl: 10
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
                isGenerating = false
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onSaved?(plan)
                }
            } catch {
                isGenerating = false
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
