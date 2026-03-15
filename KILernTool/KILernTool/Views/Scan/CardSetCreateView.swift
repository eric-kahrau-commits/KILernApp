import SwiftUI
import PhotosUI

struct CardSetCreateView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    @State private var setName: String = ""
    @State private var selectedSubjectName: String = Subject.all.first?.name ?? ""

    @State private var showEditor = false

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            nameSection
                            subjectSection
                            createButton
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .onAppear {
                if setName.isEmpty {
                    setName = "Neues Karteikartenset"
                }
            }
            .navigationDestination(isPresented: $showEditor) {
                CardSetEditorView(
                    setName: setName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Neues Karteikartenset"
                        : setName.trimmingCharacters(in: .whitespacesAndNewlines),
                    subjectName: selectedSubjectName,
                    existingSet: nil,
                    onFinished: { dismiss() }
                )
                .environmentObject(store)
            }
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button("Abbrechen") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text("Karteikartenset")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
            Button("Erstellen") {
                if canProceed {
                    showEditor = true
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(canProceed ? accent : Color(uiColor: .tertiaryLabel))
            .disabled(!canProceed)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    private var canProceed: Bool {
        !setName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Name Section
    private var nameSection: some View {
        sectionCard(title: "Name des Sets") {
            TextField("z. B. Mathe Formeln", text: $setName)
                .font(.system(size: 16))
                .padding(16)
        }
    }

    // MARK: - Subject Section
    private var subjectSection: some View {
        sectionCard(title: "Fach (Ordner)") {
            VStack(spacing: 0) {
                ForEach(Subject.all) { subject in
                    Button { selectedSubjectName = subject.name } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(subject.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: subject.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(subject.color)
                            }
                            Text(subject.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSubjectName == subject.name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if subject.name != Subject.all.last?.name {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: - Erstellen Button
    private var createButton: some View {
        HStack {
            Spacer()
            Button {
                if canProceed {
                    showEditor = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.fill.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Karten erstellen")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [accent, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
            .opacity(canProceed ? 1.0 : 0.5)
            Spacer()
        }
    }

    // MARK: - Section helper
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }

}

// MARK: - Editor Screen

struct CardSetEditorView: View {
    @EnvironmentObject var store: LernSetStore
    @Environment(\.dismiss) var dismiss

    let setName: String
    let subjectName: String
    let onFinished: () -> Void
    let existingSet: LernSet?

    struct EditableCard: Identifiable {
        let id = UUID()
        var front: String
        var back: String
        var frontImageData: Data? = nil
        var backImageData: Data? = nil
        var frontPhotoItem: PhotosPickerItem? = nil
        var backPhotoItem: PhotosPickerItem? = nil
    }

    @State private var cards: [EditableCard]

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)
    @State private var showSaveAnimation = false

    init(
        setName: String,
        subjectName: String,
        existingSet: LernSet? = nil,
        onFinished: @escaping () -> Void
    ) {
        self.setName = setName
        self.subjectName = subjectName
        self.existingSet = existingSet
        self.onFinished = onFinished

        if let existingSet {
            let editable = existingSet.cards.map {
                EditableCard(
                    front: $0.question,
                    back: $0.answer,
                    frontImageData: $0.frontImageData,
                    backImageData: $0.backImageData
                )
            }
            _cards = State(initialValue: editable.isEmpty ? [EditableCard(front: "", back: "")] : editable)
        } else {
            _cards = State(initialValue: [EditableCard(front: "", back: "")])
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        cardSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }

            if showSaveAnimation {
                SaveSuccessOverlay()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(setName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)

            Spacer()

            Button {
                save()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.4)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.primary.opacity(0.06)).frame(height: 0.5)
        }
    }

    private var canSave: Bool {
        cards.contains { card in
            !card.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !card.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Card Section
    private var cardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KARTEN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach($cards) { $card in
                    cardRow(card: $card)
                }

                Button { addCard() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Karte hinzufügen")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func cardRow(card: Binding<EditableCard>) -> some View {
        let idx = index(of: card.wrappedValue)
        VStack(spacing: 0) {

            // Header: card number + delete only
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 26, height: 26)
                    Text("\(idx + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }
                Text("Karte")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if cards.count > 1 {
                    Button { remove(card.wrappedValue) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            // Front side
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("VORDERSEITE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    Spacer()
                    // Inline photo button
                    PhotosPicker(selection: card.frontPhotoItem, matching: .images) {
                        HStack(spacing: 3) {
                            Image(systemName: card.frontImageData.wrappedValue != nil ? "photo.fill" : "photo")
                                .font(.system(size: 11, weight: .semibold))
                            if card.frontImageData.wrappedValue == nil {
                                Text("Bild")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .foregroundStyle(card.frontImageData.wrappedValue != nil ? accent : Color(uiColor: .tertiaryLabel))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(card.frontImageData.wrappedValue != nil ? accent.opacity(0.10) : Color(uiColor: .tertiarySystemGroupedBackground)))
                    }
                    .buttonStyle(.plain)
                    if card.frontImageData.wrappedValue != nil {
                        Button { card.frontImageData.wrappedValue = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 2)
                    }
                }
                .padding(.top, 10).padding(.horizontal, 14)

                TextField("Begriff, Frage …", text: card.front, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, card.frontImageData.wrappedValue != nil ? 6 : 10)

                if let data = card.frontImageData.wrappedValue, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 90).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 14).padding(.bottom, 10)
                }
            }

            Divider()

            // Back side
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("RÜCKSEITE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    Spacer()
                    // Inline photo button
                    PhotosPicker(selection: card.backPhotoItem, matching: .images) {
                        HStack(spacing: 3) {
                            Image(systemName: card.backImageData.wrappedValue != nil ? "photo.fill" : "photo")
                                .font(.system(size: 11, weight: .semibold))
                            if card.backImageData.wrappedValue == nil {
                                Text("Bild")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .foregroundStyle(card.backImageData.wrappedValue != nil ? accent : Color(uiColor: .tertiaryLabel))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(card.backImageData.wrappedValue != nil ? accent.opacity(0.10) : Color(uiColor: .tertiarySystemGroupedBackground)))
                    }
                    .buttonStyle(.plain)
                    if card.backImageData.wrappedValue != nil {
                        Button { card.backImageData.wrappedValue = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 2)
                    }
                }
                .padding(.top, 10).padding(.horizontal, 14)

                TextField("Antwort, Erklärung …", text: card.back, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, card.backImageData.wrappedValue != nil ? 6 : 10)

                if let data = card.backImageData.wrappedValue, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 90).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 14).padding(.bottom, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
        .onChange(of: card.frontPhotoItem.wrappedValue) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { card.frontImageData.wrappedValue = data }
                }
            }
        }
        .onChange(of: card.backPhotoItem.wrappedValue) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { card.backImageData.wrappedValue = data }
                }
            }
        }
    }

    private func cardSideEditor(
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

                TextEditor(text: text)
                    .font(.system(size: 15))
                    .padding(12)
                    .frame(minHeight: 80, maxHeight: 140)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .overlay(
                        Group {
                            if text.wrappedValue.isEmpty {
                                Text(placeholder)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .padding(16)
                            }
                        },
                        alignment: .topLeading
                    )
            }
        }
    }

    // MARK: - Image Picker
    private func imagePickerRow(
        imageData: Binding<Data?>,
        photoItem: Binding<PhotosPickerItem?>,
        emptyLabel: String,
        filledLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let data = imageData.wrappedValue,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    )
            }

            PhotosPicker(
                selection: photoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                    Text(imageData.wrappedValue == nil ? emptyLabel : filledLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                )
            }
            .onChange(of: photoItem.wrappedValue) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            imageData.wrappedValue = data
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Section helper (gleicher Stil wie im Erstell-Screen)
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
    }

    // MARK: - Save
    private func save() {
        guard canSave else { return }

        let nonEmptyCards = cards.compactMap { card -> LernSetCard? in
            let front = card.front.trimmingCharacters(in: .whitespacesAndNewlines)
            let back  = card.back.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !front.isEmpty, !back.isEmpty else { return nil }
            return LernSetCard(
                question: front,
                answer: back,
                frontImageData: card.frontImageData,
                backImageData: card.backImageData
            )
        }
        guard !nonEmptyCards.isEmpty else { return }

        let set = LernSet(
            id: existingSet?.id ?? UUID(),
            name: setName,
            subject: subjectName,
            cards: nonEmptyCards,
            createdAt: existingSet?.createdAt ?? Date()
        )
        store.save(set)
        StreakManager.shared.markActivity()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showSaveAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showSaveAnimation = false
            }
            dismiss()
            onFinished()
        }
    }

    // MARK: - Helpers
    private func addCard() {
        cards.append(EditableCard(front: "", back: ""))
    }

    private func remove(_ card: EditableCard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards.remove(at: index)
        }
    }

    private func index(of card: EditableCard) -> Int {
        cards.firstIndex(where: { $0.id == card.id }) ?? 0
    }

    // MARK: - Save Animation Overlay
    private struct SaveSuccessOverlay: View {
        @State private var scale: CGFloat = 0.6
        @State private var opacity: Double = 0.0

        var body: some View {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()

                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(width: 170, height: 170)
                        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.green.opacity(0.25), lineWidth: 10)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                            Image(systemName: "checkmark")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text("Gespeichert")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding()
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            }
        }
    }
}

