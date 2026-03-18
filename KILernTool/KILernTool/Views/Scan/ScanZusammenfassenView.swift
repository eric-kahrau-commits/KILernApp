import SwiftUI
import PhotosUI

struct ScanZusammenfassenView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lernSetStore: LernSetStore

    let initialName: String
    let initialSubject: String

    enum Phase { case scan, konfigurieren, laden, ergebnis }
    enum Aktion: String, CaseIterable { case zusammenfassen = "Zusammenfassen", lernset = "Lernset erstellen" }
    enum LaengeOption: String, CaseIterable { case kurz = "Kurz", mittel = "Mittel", ausfuehrlich = "Ausführlich" }

    @State private var phase: Phase = .scan
    @State private var selectedImages: [UIImage] = []
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showCamera = false

    // Konfiguration
    @State private var aktion: Aktion = .zusammenfassen
    @State private var laenge: LaengeOption = .mittel
    @State private var fach: String = ""
    @State private var anzahlFragen: Int = 10
    @State private var schwierigkeit: String = "mittel"
    @State private var wuensche: String = ""

    // Ergebnis
    @State private var zusammenfassungText: String = ""
    @State private var generierteKarten: [LernSetCard] = []
    @State private var lernsetName: String = ""
    @State private var saved: Bool = false
    @State private var errorMessage: String? = nil

    private let accent = AppColors.brandTeal
    private let kristinRed = Color(red: 0.85, green: 0.20, blue: 0.22)
    private let schwierigkeiten = ["einfach", "mittel", "schwer"]

    // Laden animation states
    @State private var ladenBeamOffset: CGFloat = -65
    @State private var ladenPulseScale: CGFloat = 0.9
    @State private var ladenPulseOpacity: Double = 0.6

    init(initialName: String, initialSubject: String) {
        self.initialName = initialName
        self.initialSubject = initialSubject
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            switch phase {
            case .scan:          scanView
            case .konfigurieren: konfigurierenView
            case .laden:         ladenView
            case .ergebnis:      ergebnisView
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase != .laden {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        switch phase {
                        case .scan:          dismiss()
                        case .konfigurieren: withAnimation { phase = .scan }
                        case .ergebnis:      dismiss()
                        case .laden:         break
                        }
                    } label: {
                        let isBack = phase == .konfigurieren
                        Image(systemName: isBack ? "chevron.left" : "xmark.circle.fill")
                            .font(.system(size: isBack ? 16 : 20, weight: isBack ? .semibold : .regular))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(phase == .konfigurieren ? "Zurück" : "Schließen")
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            fach = initialSubject.isEmpty ? (Subject.all.first?.name ?? "Mathe") : initialSubject
            lernsetName = initialName
        }
        .onChange(of: photoItems) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        if selectedImages.count < 6 { selectedImages.append(img) }
                    }
                }
                photoItems = []
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { img in
                if selectedImages.count < 6 { selectedImages.append(img) }
            }
        }
    }

    private var navTitle: String {
        switch phase {
        case .scan:          return "Scannen"
        case .konfigurieren: return "Optionen"
        case .laden:         return "KI analysiert …"
        case .ergebnis:      return aktion == .zusammenfassen ? "Zusammenfassung" : "Lernset"
        }
    }

    // MARK: - Phase 1: Scan

    private var scanView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MascotGuideBanner(color: kristinRed, characterName: "Kristin", text: "Fotografiere deine Buchseiten – bis zu 6 Stück! 📸\nIch lese und analysiere jeden Text für dich.")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Seiten scannen")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Fotografiere bis zu 6 Buchseiten oder Texte. Die KI liest den Inhalt automatisch.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    if !selectedImages.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Button {
                                        selectedImages.remove(at: idx)
                                    } label: {
                                        ZStack {
                                            Circle().fill(.black.opacity(0.6)).frame(width: 22, height: 22)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .accessibilityLabel("Bild entfernen")
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                    }

                    if selectedImages.count < 6 {
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

                            PhotosPicker(selection: $photoItems, maxSelectionCount: 6 - selectedImages.count, matching: .images) {
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
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle").font(.system(size: 12))
                        Text(selectedImages.isEmpty
                             ? "Bis zu 6 Seiten möglich."
                             : "\(selectedImages.count) von 6 Seiten hinzugefügt.")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            bottomButton(title: "Weiter", enabled: !selectedImages.isEmpty) {
                withAnimation(.easeInOut(duration: 0.22)) { phase = .konfigurieren }
            }
        }
    }

    // MARK: - Phase 2: Konfigurieren

    private var konfigurierenView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    MascotGuideBanner(color: kristinRed, characterName: "Kristin", text: "Was soll ich mit den Seiten machen? 🤔\nZusammenfassen oder direkt Lernkarten erstellen?")

                    // Aktion wählen
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Was soll die KI tun?")
                        HStack(spacing: 10) {
                            ForEach(Aktion.allCases, id: \.self) { option in
                                Button { aktion = option } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: option == .zusammenfassen ? "text.alignleft" : "rectangle.stack.badge.sparkles")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(option.rawValue)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(aktion == option ? .white : accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(aktion == option ? accent : accent.opacity(0.08))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    if aktion == .zusammenfassen {
                        // Länge
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Länge der Zusammenfassung")
                            HStack(spacing: 10) {
                                ForEach(LaengeOption.allCases, id: \.self) { opt in
                                    Button { laenge = opt } label: {
                                        Text(opt.rawValue)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(laenge == opt ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(laenge == opt ? accent : Color(uiColor: .tertiarySystemGroupedBackground))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        // Lernset-Optionen
                        VStack(alignment: .leading, spacing: 18) {
                            // Fach
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Fach")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Subject.all) { subject in
                                            Button { fach = subject.name } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: subject.icon)
                                                        .font(.system(size: 12, weight: .semibold))
                                                    Text(subject.name)
                                                        .font(.system(size: 13, weight: .semibold))
                                                }
                                                .foregroundStyle(fach == subject.name ? .white : subject.color)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(fach == subject.name ? subject.color : subject.color.opacity(0.10))
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }

                            // Anzahl Fragen
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Anzahl Fragen: \(anzahlFragen)")
                                HStack {
                                    Stepper("", value: $anzahlFragen, in: 5...30, step: 1)
                                        .labelsHidden()
                                    Spacer()
                                }
                            }

                            // Schwierigkeit
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Schwierigkeit")
                                HStack(spacing: 8) {
                                    ForEach(schwierigkeiten, id: \.self) { s in
                                        Button { schwierigkeit = s } label: {
                                            Text(s.capitalized)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(schwierigkeit == s ? .white : .primary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 9)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(schwierigkeit == s ? accent : Color(uiColor: .tertiarySystemGroupedBackground))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Zusatzwünsche
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Zusatzwünsche (optional)")
                                TextField("z. B. Fokus auf Kapitel 3, nur Definitionen …", text: $wuensche, axis: .vertical)
                                    .font(.system(size: 14))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                                    )
                                    .lineLimit(3...5)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            bottomButton(title: "Erstellen", enabled: true) {
                startAnalyse()
            }
        }
    }

    // MARK: - Phase 3: Laden

    private var ladenView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Kristin with scanning beam
            ZStack {
                // Pulsing outer ring
                Circle()
                    .stroke(kristinRed.opacity(0.28), lineWidth: 4)
                    .frame(width: 148, height: 148)
                    .scaleEffect(ladenPulseScale)
                    .opacity(ladenPulseOpacity)

                // Second pulsing ring (delayed)
                Circle()
                    .stroke(kristinRed.opacity(0.15), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(ladenPulseScale * 0.92)
                    .opacity(ladenPulseOpacity * 0.7)

                // Background glow
                Circle()
                    .fill(kristinRed.opacity(0.09))
                    .frame(width: 134, height: 134)

                // Mascot
                MascotView(color: kristinRed, mood: .thinking, size: 100)
                    .frame(width: 100, height: 114)

                // Scanning laser beam
                Circle()
                    .fill(.clear)
                    .frame(width: 134, height: 134)
                    .overlay(
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.clear, kristinRed.opacity(0.55), .clear],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: 22)
                            .offset(y: ladenBeamOffset)
                    )
                    .clipShape(Circle())
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    ladenBeamOffset = 65
                }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    ladenPulseScale = 1.22
                    ladenPulseOpacity = 0
                }
            }

            VStack(spacing: 10) {
                Text("KRISTIN")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(kristinRed)
                    .tracking(1.8)
                Text(aktion == .zusammenfassen ? "Ich fasse deinen Text zusammen …" : "Ich erstelle deine Lernkarten …")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Kristin liest jeden Text für dich! 🔍")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Phase 4: Ergebnis

    @ViewBuilder
    private var ergebnisView: some View {
        if aktion == .zusammenfassen {
            zusammenfassungErgebnis
        } else {
            lernsetErgebnis
        }
    }

    private var zusammenfassungErgebnis: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MascotGuideBanner(color: kristinRed, characterName: "Kristin", text: "Fertig! 🎉 Ich habe \(selectedImages.count) Seite\(selectedImages.count == 1 ? "" : "n") für dich zusammengefasst.\nTeile die Zusammenfassung oder speichere sie für später!")
                HStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("\(laenge.rawValue) · \(selectedImages.count) Seite\(selectedImages.count == 1 ? "" : "n")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Text(zusammenfassungText)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                ShareLink(item: zusammenfassungText) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Teilen")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.25), lineWidth: 1))
                    )
                }

                Button { dismiss() } label: {
                    Text("Fertig")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [accent, Color(red: 0.20, green: 0.80, blue: 0.60)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
    }

    private var lernsetErgebnis: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MascotGuideBanner(color: kristinRed, characterName: "Kristin", text: "Super! 🔥 \(generierteKarten.count) Lernkarten sind fertig!\nGib deinem Lernset einen Namen und speichere es ab.")
                    // Name eingeben
                    if !saved {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Name des Lernsets")
                            TextField("z. B. Kapitel 3 – Photosynthese", text: $lernsetName)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                                )
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Lernset gespeichert unter \"\(fach)\"")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.08))
                        )
                    }

                    // Karten Vorschau
                    Text("\(generierteKarten.count) Lernkarten")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 10) {
                        ForEach(generierteKarten) { card in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(card.question)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(card.answer)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            if !saved {
                bottomButton(title: "Lernset speichern", enabled: !lernsetName.isEmpty) {
                    saveLernset()
                }
            } else {
                VStack(spacing: 0) {
                    Divider()
                    Button { dismiss() } label: {
                        Text("Fertig")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [accent, Color(red: 0.20, green: 0.80, blue: 0.60)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground))
                }
            }
        }
    }

    // MARK: - Logic

    private func startAnalyse() {
        withAnimation(.easeInOut(duration: 0.25)) { phase = .laden }
        Task {
            do {
                if aktion == .zusammenfassen {
                    let laengeStr: String
                    switch laenge {
                    case .kurz:        laengeStr = "kurz"
                    case .mittel:      laengeStr = "mittel"
                    case .ausfuehrlich: laengeStr = "ausführlich"
                    }
                    zusammenfassungText = try await AIService.shared.scanZusammenfassen(images: selectedImages, laenge: laengeStr)
                } else {
                    generierteKarten = try await AIService.shared.scanGenerateLernSet(
                        images: selectedImages, fach: fach, anzahl: anzahlFragen,
                        schwierigkeit: schwierigkeit, wuensche: wuensche)
                    lernsetName = ""
                }
                withAnimation(.easeInOut(duration: 0.3)) { phase = .ergebnis }
            } catch {
                errorMessage = error.localizedDescription
                withAnimation { phase = .konfigurieren }
            }
        }
    }

    private func saveLernset() {
        let set = LernSet(
            name: lernsetName.isEmpty ? "Gescanntes Lernset" : lernsetName,
            subject: fach,
            cards: generierteKarten,
            isKIGenerated: true,
            isScanResult: true
        )
        lernSetStore.save(set)
        _ = StreakManager.shared.markActivity()
        withAnimation { saved = true }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func bottomButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(enabled
                                  ? LinearGradient(colors: [accent, Color(red: 0.20, green: 0.80, blue: 0.60)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : LinearGradient(colors: [Color(uiColor: .tertiaryLabel)],
                                                   startPoint: .leading, endPoint: .trailing))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }
}
