import SwiftUI
import Photos

// MARK: - Generated Test View

struct GeneratedTestView: View {
    let test: GeneratedTest
    @Environment(\.dismiss) private var dismiss

    @State private var pdfURL: URL? = nil
    @State private var shareImage: UIImage? = nil
    @State private var isRendering: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var photoSaveStatus: PhotoSaveStatus? = nil
    @State private var showKorrigieren: Bool = false

    enum PhotoSaveStatus: Identifiable {
        case success, failure(String)
        var id: String {
            switch self { case .success: return "ok"; case .failure(let m): return m }
        }
    }

    private let accent = Color(red: 0.85, green: 0.25, blue: 0.45)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Test sheet preview
                    TestSheetView(test: test)
                        .padding(.horizontal, 8)
                        .padding(.top, 12)

                    // Export buttons
                    exportButtons
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle(test.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $photoSaveStatus) { status in
            switch status {
            case .success:
                return Alert(title: Text("Gespeichert"),
                             message: Text("Der Test wurde in deinen Fotos gespeichert."),
                             dismissButton: .default(Text("OK")))
            case .failure(let msg):
                return Alert(title: Text("Fehler"),
                             message: Text(msg),
                             dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .fullScreenCover(isPresented: $showKorrigieren) {
            TestKorrigierenView(preSelectedTest: test)
        }
    }

    // MARK: - Export Buttons

    private var exportButtons: some View {
        VStack(spacing: 12) {
            Text("Exportieren")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            // PDF Export
            Button {
                exportAsPDF()
            } label: {
                HStack(spacing: 12) {
                    if isRendering {
                        ProgressView().progressViewStyle(.circular).tint(.white)
                            .frame(width: 24)
                    } else {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 24, alignment: .center)
                    }
                    Text(isRendering ? "Wird erstellt …" : "Als PDF exportieren")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isRendering
                              ? LinearGradient(colors: [Color(uiColor: .tertiaryLabel)], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [accent, Color(red: 0.60, green: 0.18, blue: 0.75)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(isRendering)

            // Save to Photos
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 24, alignment: .center)
                    Text("In Fotos speichern")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)

            // Correct this test
            Button { showKorrigieren = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 24, alignment: .center)
                        .foregroundStyle(Color.blue)
                    Text("Test korrigieren")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Export Logic

    @MainActor
    private func exportAsPDF() {
        isRendering = true
        Task {
            let sheetView = TestSheetView(test: test)
                .frame(width: 595)
                .background(Color.white)

            let renderer = ImageRenderer(content: sheetView)
            renderer.scale = 2.0

            guard let image = renderer.uiImage else {
                isRendering = false
                return
            }

            let url = createPDF(from: image)
            pdfURL = url
            isRendering = false
            if url != nil { showShareSheet = true }
        }
    }

    @MainActor
    private func saveToPhotos() {
        Task {
            isRendering = true

            let sheetView = TestSheetView(test: test)
                .frame(width: 828)
                .background(Color.white)

            let renderer = ImageRenderer(content: sheetView)
            renderer.scale = 2.0

            guard let image = renderer.uiImage else {
                isRendering = false
                return
            }

            // Request authorization
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                isRendering = false
                photoSaveStatus = .failure("Bitte erlaube in den Einstellungen den Zugriff auf deine Fotos (Einstellungen → \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App") → Fotos).")
                return
            }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                isRendering = false
                photoSaveStatus = .success
            } catch {
                isRendering = false
                photoSaveStatus = .failure("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    private func createPDF(from image: UIImage) -> URL? {
        let pageW: CGFloat = image.size.width
        let pageH: CGFloat = image.size.height
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(test.name.replacingOccurrences(of: " ", with: "_")).pdf")

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)
        let data = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(at: .zero)
        }

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Test Sheet View (the actual test layout)

struct TestSheetView: View {
    let test: GeneratedTest

    private var subjectColor: Color {
        Subject.all.first { $0.name == test.fach }?.color
            ?? Color(red: 0.85, green: 0.25, blue: 0.45)
    }

    var body: some View {
        VStack(spacing: 0) {
            testHeader
            Divider().padding(.vertical, 12)
            metaRow
            Divider().padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 24) {
                ForEach(test.sektionen) { sektion in
                    sektionView(sektion)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)

            Divider()
            scoreFooter
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 4)
        )
    }

    // MARK: - Header

    private var testHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: Subject.all.first { $0.name == test.fach }?.icon ?? "doc.text")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(subjectColor)
                        Text(test.fach.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(subjectColor)
                            .tracking(1.5)
                    }
                    Text(test.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .label))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(test.dauer)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(test.gesamtPunkte) Punkte")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(subjectColor)
                }
            }

            if !test.beschreibung.isEmpty {
                Text(test.beschreibung)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Meta Row (Name / Klasse / Datum)

    private var metaRow: some View {
        HStack(spacing: 0) {
            metaField(label: "Name")
            Spacer()
            metaField(label: "Klasse")
            Spacer()
            metaField(label: "Datum")
        }
    }

    private func metaField(label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(width: 100, height: 0.5)
        }
    }

    // MARK: - Section

    private func sektionView(_ sektion: TestSektion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack(spacing: 8) {
                Rectangle()
                    .fill(subjectColor)
                    .frame(width: 3, height: 18)
                    .clipShape(Capsule())
                Text(sektion.titel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(uiColor: .label))
                Spacer()
                Text("\(sektion.punkte) P.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(subjectColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(subjectColor.opacity(0.1))
                    )
            }

            // Tasks
            VStack(alignment: .leading, spacing: 18) {
                ForEach(sektion.aufgaben) { aufgabe in
                    aufgabeView(aufgabe)
                }
            }
            .padding(.leading, 11)
        }
    }

    // MARK: - Task

    private func aufgabeView(_ aufgabe: TestAufgabe) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Task header
            HStack(alignment: .top, spacing: 8) {
                Text("\(aufgabe.nummer).")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(minWidth: 20, alignment: .leading)

                Text(aufgabe.text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(uiColor: .label))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text("(\(aufgabe.punkte)P)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            // Hint
            if let hint = aufgabe.hinweis {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.orange.opacity(0.7))
                    Text(hint)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Color.orange.opacity(0.8))
                }
                .padding(.leading, 28)
            }

            // Answer area
            answerArea(for: aufgabe)
                .padding(.leading, 28)
        }
    }

    // MARK: - Answer Areas

    @ViewBuilder
    private func answerArea(for aufgabe: TestAufgabe) -> some View {
        switch aufgabe.typ {
        case .freitext:
            freTextArea(lines: aufgabe.zeilen)

        case .multipleChoice:
            if let optionen = aufgabe.optionen {
                multipleChoiceArea(optionen: optionen)
            }

        case .lueckentext:
            freTextArea(lines: max(2, aufgabe.zeilen))

        case .diagramm:
            diagrammArea(label: aufgabe.diagrammLabel)

        case .rechenweg:
            rechenwegArea(lines: aufgabe.zeilen)
        }
    }

    // Lined area for text answers
    private func freTextArea(lines: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<max(2, lines), id: \.self) { _ in
                Rectangle()
                    .fill(Color(uiColor: .separator).opacity(0.4))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
            }
        }
    }

    // Multiple choice options
    private func multipleChoiceArea(optionen: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(optionen, id: \.self) { option in
                HStack(spacing: 10) {
                    Circle()
                        .stroke(Color(uiColor: .separator), lineWidth: 1.2)
                        .frame(width: 16, height: 16)
                    Text(option)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(uiColor: .label))
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .systemGroupedBackground))
        )
    }

    // Empty diagram box for biology
    private func diagrammArea(label: String?) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        Text("Hier beschriften")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                )
            if let label = label {
                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // Grid (kariertes Papier) for math
    private func rechenwegArea(lines: Int) -> some View {
        let cellSize: CGFloat = 8
        let rows = max(4, lines)
        let height = CGFloat(rows) * cellSize * 3

        return Canvas { context, size in
            let cols = Int(size.width / cellSize)
            let rowCount = Int(size.height / cellSize)

            context.stroke(
                Path { path in
                    // Vertical lines
                    for col in 0...cols {
                        let x = CGFloat(col) * cellSize
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    // Horizontal lines
                    for row in 0...rowCount {
                        let y = CGFloat(row) * cellSize
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                },
                with: .color(Color(uiColor: .systemBlue).opacity(0.15)),
                lineWidth: 0.5
            )
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var scoreFooter: some View {
        HStack {
            Text("Gesamtpunkte:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            Text("___ / \(test.gesamtPunkte)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
            Spacer()
            Text("Note: ___")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
        .padding(.top, 12)
    }
}
