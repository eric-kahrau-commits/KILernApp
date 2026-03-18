import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var lernSetStore: LernSetStore
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var streakManager: StreakManager

    // Konto (local fallback when not using Firebase displayName)
    @AppStorage("userName") private var userName: String = "Eric"
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showSignOutConfirm = false

    // Benachrichtigungen
    @AppStorage("lernReminderEnabled")    private var lernReminderEnabled:    Bool = false
    @AppStorage("lernReminderHour")       private var lernReminderHour:       Int  = 19
    @AppStorage("streakMorningEnabled")   private var streakMorningEnabled:   Bool = false
    @AppStorage("streakEveningEnabled")   private var streakEveningEnabled:   Bool = false
    @AppStorage("testReminderEnabled")    private var testReminderEnabled:    Bool = false

    @StateObject private var notifManager = NotificationManager.shared
    @State private var showNotifSheet = false

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

    private let accent = AppColors.brandPurple

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

    /// Display name: Firebase display name if logged in, else local AppStorage name.
    private var effectiveName: String {
        authManager.isLoggedIn ? authManager.displayName : userName
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                // Profile card
                profileCard

                // Konto (sign-out, shown when logged in)
                kontoSection

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
                    // Permission status banner
                    if notifManager.authorizationStatus == .denied {
                        notifDeniedBanner
                        divider
                    } else if notifManager.authorizationStatus == .notDetermined {
                        notifEnableBanner
                        divider
                    }

                    streakMorningRow
                    divider
                    streakEveningRow
                    divider
                    lernReminderRow
                    if lernReminderEnabled {
                        divider
                        reminderTimeRow
                    }
                }
                .task { await notifManager.refreshStatus() }

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
            if lernReminderEnabled { rescheduleIfAuthorized() }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.brandPurple, Color(red: 0.30, green: 0.52, blue: 0.98)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 4)

                if let url = authManager.photoURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(Circle())
                    } placeholder: {
                        Text(authManager.userInitial)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text(String(effectiveName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(effectiveName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                if authManager.isLoggedIn {
                    Text(authManager.email ?? "Angemeldet")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Persönliches Konto")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            if !authManager.isLoggedIn {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accent.opacity(0.5))
            } else {
                // Cloud sync indicator
                Image(systemName: "checkmark.icloud.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accent.opacity(0.6))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .onTapGesture {
            if !authManager.isLoggedIn {
                tempName = userName
                editingName = true
            }
        }
    }

    // MARK: - Konto Section (only shown when logged in)

    @ViewBuilder
    private var kontoSection: some View {
        if authManager.isLoggedIn {
            settingsSection(title: "Konto") {
                HStack(spacing: 12) {
                    iconBadge(symbol: "person.crop.circle.fill", color: accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Angemeldet als")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(authManager.email ?? authManager.displayName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                divider

                Button {
                    showSignOutConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        iconBadge(symbol: "rectangle.portrait.and.arrow.right.fill", color: .red)
                        Text("Abmelden")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .confirmationDialog("Wirklich abmelden?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                    Button("Abmelden", role: .destructive) { authManager.signOut() }
                    Button("Abbrechen", role: .cancel) {}
                } message: {
                    Text("Deine Daten bleiben in der Cloud gespeichert und werden nach der Anmeldung wieder geladen.")
                }
            }
        }
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
                    withAnimation(AppAnimation.standard) {
                        themeManager.isDarkMode = false
                    }
                }
                themeOption(label: "Dunkel", icon: "moon.fill", isSelected: themeManager.isDarkMode) {
                    withAnimation(AppAnimation.standard) {
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

    private var notifEnableBanner: some View {
        Button {
            showNotifSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(Circle().fill(accent))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Benachrichtigungen aktivieren")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Damit Theo dich erinnern kann")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showNotifSheet) {
            NotificationPermissionSheet {
                showNotifSheet = false
                Task {
                    let granted = await notifManager.requestPermission()
                    if granted {
                        streakMorningEnabled = true
                        streakEveningEnabled = true
                        lernReminderEnabled  = true
                        await notifManager.scheduleAll(
                            streak: streakManager.currentStreak,
                            plans:  lernPlanStore.plans,
                            sets:   lernSetStore.lernSets
                        )
                    }
                }
            } onDismiss: {
                notifManager.markPromptShown()
                showNotifSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var notifDeniedBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(Circle().fill(Color.orange))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Benachrichtigungen blockiert")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("In den iOS-Einstellungen aktivieren")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var streakMorningRow: some View {
        toggleSettingsRow(
            icon: "sun.max.fill", iconColor: .orange,
            title: "Streak-Erinnerung (08:00)",
            binding: Binding(
                get: { streakMorningEnabled },
                set: { newVal in
                    streakMorningEnabled = newVal
                    rescheduleIfAuthorized()
                }
            )
        )
    }

    private var streakEveningRow: some View {
        toggleSettingsRow(
            icon: "moon.stars.fill", iconColor: .indigo,
            title: "Streak-Erinnerung (20:00)",
            binding: Binding(
                get: { streakEveningEnabled },
                set: { newVal in
                    streakEveningEnabled = newVal
                    rescheduleIfAuthorized()
                }
            )
        )
    }

    private var lernReminderRow: some View {
        toggleSettingsRow(
            icon: "book.fill", iconColor: accent,
            title: "Tagesplan-Erinnerung",
            binding: Binding(
                get: { lernReminderEnabled },
                set: { newVal in
                    lernReminderEnabled = newVal
                    rescheduleIfAuthorized()
                }
            )
        )
    }

    private var reminderTimeRow: some View {
        HStack(spacing: 12) {
            iconBadge(symbol: "clock.fill", color: accent)
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
            .onChange(of: lernReminderHour) { rescheduleIfAuthorized() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func rescheduleIfAuthorized() {
        Task {
            await notifManager.scheduleAll(
                streak: streakManager.currentStreak,
                plans:  lernPlanStore.plans,
                sets:   lernSetStore.lernSets
            )
        }
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

}
