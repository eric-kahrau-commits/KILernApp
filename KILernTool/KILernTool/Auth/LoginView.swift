import SwiftUI
import AuthenticationServices

// MARK: - LoginView
// Full-screen onboarding / login wall shown when the user is not authenticated.
// Supports: Email+Password, Google Sign-In, Apple Sign-In.

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var mode: LoginMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var appeared = false

    @FocusState private var focusedField: Field?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum LoginMode { case login, register }
    enum Field: Hashable { case email, password, name, confirmPassword, resetEmail }

    private var canSubmit: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        switch mode {
        case .login:
            return emailOK && password.count >= 6
        case .register:
            return emailOK && password.count >= 6 && !name.trimmingCharacters(in: .whitespaces).isEmpty
                && password == confirmPassword
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    AppColors.brandPurple.opacity(0.18),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Header
                    headerSection
                        .padding(.top, 48)
                        .padding(.bottom, 32)

                    // MARK: Tab Switcher
                    tabSwitcher
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // MARK: Form
                    formSection
                        .padding(.horizontal, 20)

                    // MARK: Error
                    if let err = authManager.errorMessage {
                        errorBanner(err)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    // MARK: Submit
                    submitButton
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // MARK: Forgot Password
                    if mode == .login {
                        Button("Passwort vergessen?") {
                            resetEmail = email
                            showForgotPassword = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                    }

                    // MARK: Divider
                    socialDivider
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                    // MARK: Social Buttons
                    socialButtons
                        .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(reduceMotion ? nil : AppAnimation.emphasized) {
                appeared = true
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            // App icon badge — matches the real home-screen icon
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.23, blue: 0.93),
                                Color(red: 0.18, green: 0.06, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: AppColors.brandPurple.opacity(0.45), radius: 18, x: 0, y: 8)

                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 60, height: 60)

                MascotView(color: .white, mood: .happy, size: 62)
            }

            VStack(spacing: 5) {
                Text("Open Learn")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Smarter lernen · Mehr erreichen")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(label: "Anmelden", selected: mode == .login) {
                withAnimation(AppAnimation.standard) { mode = .login }
                authManager.errorMessage = nil
            }
            tabButton(label: "Registrieren", selected: mode == .register) {
                withAnimation(AppAnimation.standard) { mode = .register }
                authManager.errorMessage = nil
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }

    private func tabButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selected ? Color(uiColor: .systemBackground) : Color.clear)
                        .shadow(color: .black.opacity(selected ? 0.08 : 0), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 12) {
            if mode == .register {
                inputField(
                    icon: "person.fill",
                    placeholder: "Dein Name",
                    text: $name,
                    field: .name
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            inputField(
                icon: "envelope.fill",
                placeholder: "E-Mail-Adresse",
                text: $email,
                field: .email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            inputField(
                icon: "lock.fill",
                placeholder: "Passwort",
                text: $password,
                field: .password,
                isSecure: true,
                textContentType: mode == .login ? .password : .newPassword
            )

            if mode == .register {
                inputField(
                    icon: "lock.fill",
                    placeholder: "Passwort bestätigen",
                    text: $confirmPassword,
                    field: .confirmPassword,
                    isSecure: true,
                    textContentType: .newPassword
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                if !confirmPassword.isEmpty && password != confirmPassword {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                        Text("Passwörter stimmen nicht überein.")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    .transition(.opacity)
                }
            }
        }
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.brandPurple)
                .frame(width: 22)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                }
            }
            .textContentType(textContentType)
            .font(.system(size: 16))
            .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            focusedField == field ? AppColors.brandPurple.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(reduceMotion ? nil : AppAnimation.micro, value: focusedField)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.09))
        )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            focusedField = nil
            Task {
                if mode == .login {
                    await authManager.signIn(email: email, password: password)
                } else {
                    await authManager.signUp(email: email, password: password, name: name)
                }
            }
        } label: {
            ZStack {
                if authManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(mode == .login ? "Anmelden" : "Konto erstellen")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        canSubmit
                        ? LinearGradient(colors: [AppColors.brandPurple, Color(red: 0.30, green: 0.52, blue: 0.98)],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.25)],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: canSubmit ? AppColors.brandPurple.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!canSubmit || authManager.isLoading)
        .animation(reduceMotion ? nil : AppAnimation.micro, value: canSubmit)
    }

    // MARK: - Social Divider

    private var socialDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 1)
            Text("oder fortfahren mit")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 1)
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: 12) {
            // Google
            Button {
                Task { await authManager.signInWithGoogle() }
            } label: {
                HStack(spacing: 12) {
                    GoogleLogo(size: 26)
                    Text("Mit Google anmelden")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(authManager.isLoading)

            // Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = authManager.prepareAppleSignIn()
            } onCompletion: { result in
                Task { await authManager.handleAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 52)
            .cornerRadius(14)
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.brandPurple)
                        .padding(.top, 8)

                    VStack(spacing: 6) {
                        Text("Passwort zurücksetzen")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Wir senden dir einen Reset-Link per E-Mail.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(AppColors.brandPurple)
                        TextField("E-Mail-Adresse", text: $resetEmail)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )

                    if authManager.resetPasswordSent {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("E-Mail versendet! Bitte prüfe dein Postfach.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }

                    if let err = authManager.errorMessage {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await authManager.resetPassword(email: resetEmail) }
                    } label: {
                        Group {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Reset-Link senden")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppColors.brandPurple)
                        )
                    }
                    .disabled(resetEmail.isEmpty || authManager.isLoading)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { showForgotPassword = false }
                }
            }
        }
        .presentationDetents([.medium])
        .onDisappear {
            authManager.errorMessage = nil
            authManager.resetPasswordSent = false
        }
    }
}

// MARK: - Google Logo

/// Draws the official 4-color Google "G" logo using SwiftUI arc trims.
/// Circle.trim(0) starts at 12 o'clock; rotationEffect(+90°) shifts it to 3 o'clock.
/// Gap is at 3 o'clock (trim 0.972–0.028). Arm runs from center to circle path.
private struct GoogleLogo: View {
    let size: CGFloat

    private let blue   = Color(red: 0.259, green: 0.522, blue: 0.957)
    private let red    = Color(red: 0.859, green: 0.267, blue: 0.216)
    private let yellow = Color(red: 0.957, green: 0.706, blue: 0.000)
    private let green  = Color(red: 0.059, green: 0.616, blue: 0.345)

    var body: some View {
        ZStack {
            // d inset so stroke (lw/2 on each side) stays inside the frame
            let d  = size * 0.80
            let lw = size * 0.185
            let style = StrokeStyle(lineWidth: lw, lineCap: .butt)

            // Clockwise from bottom of gap (3 o'clock):
            //   Green  0.028–0.045  ≈ 6°    lower-right sliver
            //   Blue   0.045–0.513  ≈ 169°  right → 6 o'clock → left
            //   Red    0.513–0.924  ≈ 148°  left → 12 o'clock → upper-right
            //   Yellow 0.924–0.972  ≈ 17°   upper-right sliver
            //   Gap    0.972–0.028  ≈ 20°   opening at 3 o'clock
            Group {
                Circle().trim(from: 0.028, to: 0.045).stroke(green,  style: style)
                Circle().trim(from: 0.045, to: 0.513).stroke(blue,   style: style)
                Circle().trim(from: 0.513, to: 0.924).stroke(red,    style: style)
                Circle().trim(from: 0.924, to: 0.972).stroke(yellow, style: style)
            }
            .frame(width: d, height: d)
            .rotationEffect(.degrees(90))   // shifts trim-start from 12 o'clock → 3 o'clock

            // Blue arm: left edge at ZStack center, right edge reaches circle path.
            // width = d/2, offset +d/4 → left = center, right = center + d/2.
            Rectangle()
                .fill(blue)
                .frame(width: d / 2, height: lw)
                .offset(x: d / 4)
        }
        .frame(width: size, height: size)
    }
}
