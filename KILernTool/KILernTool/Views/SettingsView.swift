import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var lernSetStore: LernSetStore
    @EnvironmentObject var lernPlanStore: LernPlanStore

    // Konto
    @AppStorage("userName") private var userName: String = "Eric"
    @State private var editingName = false
    @State private var tempName = ""

    // Benachrichtigungen
    @AppStorage("lernReminderEnabled") private var lernReminderEnabled: Bool = false
    @AppStorage("lernReminderHour") private var lernReminderHour: Int = 18
    @AppStorage("testReminderEnabled") private var testReminderEnabled: Bool = false

    // Lernen
    @AppStorage("defaultLernModus") private var defaultLernModus: String = "Karteikarten"
    @AppStorage("dailyZielKarten") private var dailyZielKarten: Int = 20

    // KI
    @AppStorage("kiSchwierigkeit") private var kiSchwierigkeit: String = "mittel"
    @AppStorage("kiAntwortstil") private var kiAntwortstil: String = "präzise"

    // Datenverwaltung
    @State private var showDeleteConfirm = false
    @State private var deleteTarget: DeleteTarget? = nil

    // Sound / Haptik
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("haptikEnabled") private var haptikEnabled: Bool = true

    private let accent = Color(red: 0.38, green: 0.18, blue: 0.90)

    enum DeleteTarget: Identifiable {
        case lernsets, lernplaene, alles
        var id: Self { self }
        var title: String {
            switch self {
            case .lernsets:  return "Alle Lernsets löschen?"
            case .lernplaene: return "Alle Lernpläne löschen?"
            case .alles:     return "Alle Daten löschen?"
            }
        }
        var message: String {
            switch self {
            case .lernsets:  return "Alle gespeicherten Lernsets und Karteikarten werden unwiderruflich gelöscht."
            case .lernplaene: return "Alle gespeicherten Lernpläne werden unwiderruflich gelöscht."
            case .alles:     return "Alle Lernsets, Lernpläne und Einstellungen werden unwiderruflich gelöscht."
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                // Profile card
                profileCard

                // Erscheinungsbild
                settingsSection(title: "Erscheinungsbild") {
                    appearanceRow
                    divider
                    soundRow
                    divider
                    haptikRow
                }

                // Benachrichtigungen
                settingsSection(title: "Benachrichtigungen") {
                    lernReminderRow
                    if lernReminderEnabled {
                        divider
                        reminderTimeRow
                    }
                    divider
                    testReminderRow
                }

                // Lernen
                settingsSection(title: "Lernen") {
                    defaultModeRow
                    divider
                    dailyZielRow
                }

                // KI-Einstellungen
                settingsSection(title: "KI-Einstellungen") {
                    schwierigkeitRow
                    divider
                    antwortstilRow
                }

                // Datenverwaltung
                settingsSection(title: "Datenverwaltung") {
                    dataInfoRow(icon: "rectangle.stack.fill",
                                iconColor: accent,
                                label: "Lernsets",
                                value: "\(lernSetStore.lernSets.count)")
                    divider
                    dataInfoRow(icon: "calendar.badge.checkmark",
                                iconColor: Color(red: 0.10, green: 0.48, blue: 0.92),
                                label: "Lernpläne",
                                value: "\(lernPlanStore.plans.count)")
                    divider
                    deleteRow(icon: "trash.fill", iconColor: .red,
                              label: "Alle Lernsets löschen") {
                        deleteTarget = .lernsets
                    }
                    divider
                    deleteRow(icon: "trash.fill", iconColor: .orange,
                              label: "Alle Lernpläne löschen") {
                        deleteTarget = .lernplaene
                    }
                }

                // Support
                settingsSection(title: "Support") {
                    shareRow
                    divider
                    linkRow(icon: "star.fill", iconColor: .orange, label: "App bewerten",
                            detail: "App Store",
                            urlString: "itms-apps://itunes.apple.com/app/id0000000000?action=write-review")
                    divider
                    linkRow(icon: "envelope.fill", iconColor: .green,
                            label: "Feedback senden", detail: "",
                            urlString: "mailto:feedback@kilern.app?subject=KI%20Lern%20Feedback")
                    divider
                    infoRow(icon: "info.circle.fill",
                            iconColor: accent,
                            label: "Version", value: "1.0.0")
                }

                Text("KI Lern · Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .confirmationDialog(
            deleteTarget?.title ?? "",
            isPresented: .init(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                performDelete()
            }
            Button("Abbrechen", role: .cancel) { deleteTarget = nil }
        } message: {
            Text(deleteTarget?.message ?? "")
        }
        .sheet(isPresented: $editingName) {
            nameEditSheet
        }
        .onChange(of: lernReminderHour) {
            if lernReminderEnabled { scheduleLearnNotification() }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        Button { tempName = userName; editingName = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.38, green: 0.18, blue: 0.90),
                                         Color(red: 0.30, green: 0.52, blue: 0.98)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 4)
                    Text(String(userName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(userName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Persönliches Konto")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accent.opacity(0.5))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name Edit Sheet

    private var nameEditSheet: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        TextField("Dein Name", text: $tempName)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                    }
                    Spacer()
                }
                .padding(18)
                .padding(.top, 12)
            }
            .navigationTitle("Name bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { editingName = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let name = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty { userName = name }
                        editingName = false
                    }
                    .fontWeight(.semibold)
                    .disabled(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Appearance

    private var appearanceRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                iconBadge(symbol: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill",
                          color: themeManager.isDarkMode ? .indigo : .orange)
                Text("Erscheinungsbild")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
            }
            HStack(spacing: 0) {
                themeOption(label: "Hell", icon: "sun.max.fill", isSelected: !themeManager.isDarkMode) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        themeManager.isDarkMode = false
                    }
                }
                themeOption(label: "Dunkel", icon: "moon.fill", isSelected: themeManager.isDarkMode) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        themeManager.isDarkMode = true
                    }
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.07)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func themeOption(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .medium))
                Text(label).font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? Color(uiColor: .systemBackground) : Color.clear)
                    .shadow(color: .black.opacity(isSelected ? 0.08 : 0), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var soundRow: some View {
        toggleSettingsRow(
            icon: "speaker.wave.2.fill", iconColor: .blue,
            title: "Sound-Effekte", binding: $soundEnabled
        )
    }

    private var haptikRow: some View {
        toggleSettingsRow(
            icon: "waveform", iconColor: .purple,
            title: "Haptisches Feedback", binding: $haptikEnabled
        )
    }

    // MARK: - Benachrichtigungen

    private var lernReminderRow: some View {
        toggleSettingsRow(
            icon: "bell.fill", iconColor: .red,
            title: "Lern-Erinnerung",
            binding: Binding(
                get: { lernReminderEnabled },
                set: { newVal in
                    if newVal {
                        requestNotificationPermission { granted in
                            lernReminderEnabled = granted
                            if granted { scheduleLearnNotification() }
                        }
                    } else {
                        lernReminderEnabled = false
                        cancelNotification(id: "lern_reminder")
                    }
                }
            )
        )
    }

    private var reminderTimeRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "clock.fill", color: .red)
            Text("Erinnerungszeit")
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $lernReminderHour) {
                ForEach([7, 8, 9, 12, 14, 16, 17, 18, 19, 20, 21], id: \.self) { h in
                    Text("\(h):00 Uhr").tag(h)
                }
            }
            .pickerStyle(.menu)
            .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var testReminderRow: some View {
        toggleSettingsRow(
            icon: "calendar.badge.exclamationmark", iconColor: .orange,
            title: "Test-Erinnerung",
            binding: Binding(
                get: { testReminderEnabled },
                set: { newVal in
                    if newVal {
                        requestNotificationPermission { granted in
                            testReminderEnabled = granted
                            if granted { scheduleTestNotification() }
                        }
                    } else {
                        testReminderEnabled = false
                        cancelNotification(id: "test_reminder")
                    }
                }
            )
        )
    }

    // MARK: - Lernen

    private var defaultModeRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "rectangle.on.rectangle.angled.fill", color: Color(red: 0.10, green: 0.64, blue: 0.54))
            Text("Standard-Lernmodus")
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $defaultLernModus) {
                Text("Karteikarten").tag("Karteikarten")
                Text("Schnell lernen").tag("Schnell lernen")
                Text("Testmodus").tag("Testmodus")
            }
            .pickerStyle(.menu)
            .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var dailyZielRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "target", color: Color(red: 0.95, green: 0.45, blue: 0.10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Tagesziel Karten")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Text("\(dailyZielKarten) Karten täglich")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Stepper("", value: $dailyZielKarten, in: 5...100, step: 5)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - KI-Einstellungen

    private var schwierigkeitRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "slider.horizontal.3", color: Color(red: 0.38, green: 0.18, blue: 0.90))
            Text("KI-Schwierigkeit")
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $kiSchwierigkeit) {
                Text("Leicht").tag("leicht")
                Text("Mittel").tag("mittel")
                Text("Schwer").tag("schwer")
            }
            .pickerStyle(.menu)
            .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var antwortstilRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "sparkles", color: Color(red: 0.95, green: 0.55, blue: 0.10))
            Text("KI-Antwortstil")
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $kiAntwortstil) {
                Text("Präzise").tag("präzise")
                Text("Ausführlich").tag("ausführlich")
                Text("Einfach").tag("einfach")
            }
            .pickerStyle(.menu)
            .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - Datenverwaltung

    private func dataInfoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(symbol: icon, color: iconColor)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func deleteRow(icon: String, iconColor: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(symbol: icon, color: iconColor)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Support

    private var shareRow: some View {
        ShareLink(item: "Ich lerne täglich mit KI Lern! 🔥 Die smarte Lernapp für deinen Schulalltag.") {
            HStack(spacing: 12) {
                iconBadge(symbol: "square.and.arrow.up", color: .green)
                Text("App teilen")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private func linkRow(icon: String, iconColor: Color, label: String, detail: String, urlString: String? = nil) -> some View {
        Button {
            if let str = urlString, let url = URL(string: str) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                iconBadge(symbol: icon, color: iconColor)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(symbol: icon, color: iconColor)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - Reusable components

    private func toggleSettingsRow(icon: String, iconColor: Color, title: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBadge(symbol: icon, color: iconColor)
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func iconBadge(symbol: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var divider: some View {
        Divider().padding(.leading, 50)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Actions

    private func performDelete() {
        switch deleteTarget {
        case .lernsets:
            lernSetStore.lernSets.forEach { lernSetStore.delete($0) }
        case .lernplaene:
            lernPlanStore.plans.forEach { lernPlanStore.delete($0) }
        case .alles:
            lernSetStore.lernSets.forEach { lernSetStore.delete($0) }
            lernPlanStore.plans.forEach { lernPlanStore.delete($0) }
        case nil:
            break
        }
        deleteTarget = nil
    }

    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func scheduleLearnNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["lern_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Zeit zum Lernen! 📚"
        content.body = "Dein tägliches Lernziel wartet auf dich. Bleib am Ball!"
        content.sound = .default

        var components = DateComponents()
        components.hour = lernReminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "lern_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleTestNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["test_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Anstehende Tests prüfen 🎯"
        content.body = "Schau nach deinen Lernplänen und prüfe bald anstehende Tests."
        content.sound = .default

        // Daily reminder at 8:00 AM
        var components = DateComponents()
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "test_reminder", content: content, trigger: trigger)
        center.add(request)
    }
}
