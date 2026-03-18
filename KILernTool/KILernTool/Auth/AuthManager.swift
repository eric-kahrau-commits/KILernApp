import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// MARK: - AuthManager
// Central authentication manager for Firebase Auth.
// Supports: Email/Password, Google Sign-In, Apple Sign-In.

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var resetPasswordSent = false

    private var nonce: String?
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    private init() {
        currentUser = Auth.auth().currentUser
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.currentUser = user
            }
        }
    }

    var isLoggedIn: Bool { currentUser != nil }

    var displayName: String {
        currentUser?.displayName
            ?? currentUser?.email?.components(separatedBy: "@").first
            ?? "Nutzer"
    }

    var email: String? { currentUser?.email }
    var photoURL: URL? { currentUser?.photoURL }
    var userInitial: String { String(displayName.prefix(1)).uppercased() }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = authErrorMessage(error)
        }
        isLoading = false
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name.trimmingCharacters(in: .whitespaces)
            try await change.commitChanges()
        } catch {
            errorMessage = authErrorMessage(error)
        }
        isLoading = false
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        resetPasswordSent = false
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            resetPasswordSent = true
        } catch {
            errorMessage = authErrorMessage(error)
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        guard
            let clientID = FirebaseApp.app()?.options.clientID,
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            isLoading = false
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google-Anmeldung fehlgeschlagen."
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            let code = (error as NSError).code
            if code != GIDSignInError.canceled.rawValue {
                errorMessage = "Google-Anmeldung fehlgeschlagen."
            }
        }
        isLoading = false
    }

    // MARK: - Apple Sign-In

    /// Call before presenting ASAuthorizationController. Returns the hashed nonce
    /// that must be attached to the ASAuthorizationAppleIDRequest.
    func prepareAppleSignIn() -> String {
        let raw = randomNonceString()
        nonce = raw
        return sha256(raw)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            await signInWithApple(credential: credential)
        case .failure(let error):
            // User cancelled — don't show an error
            let code = (error as NSError).code
            if code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple-Anmeldung fehlgeschlagen."
            }
        }
    }

    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false; nonce = nil }

        guard
            let nonce,
            let appleIDToken = credential.identityToken,
            let tokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            errorMessage = "Apple-Anmeldung fehlgeschlagen."
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        do {
            try await Auth.auth().signIn(with: firebaseCredential)
        } catch {
            errorMessage = "Apple-Anmeldung fehlgeschlagen."
        }
    }

    // MARK: - Helpers

    private func authErrorMessage(_ error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .userNotFound, .wrongPassword, .invalidCredential:
            return "E-Mail oder Passwort falsch."
        case .emailAlreadyInUse:
            return "Diese E-Mail ist bereits registriert."
        case .weakPassword:
            return "Passwort zu schwach — mindestens 6 Zeichen."
        case .invalidEmail:
            return "Ungültige E-Mail-Adresse."
        case .networkError:
            return "Kein Internet. Bitte Verbindung prüfen."
        case .tooManyRequests:
            return "Zu viele Versuche. Bitte kurz warten."
        default:
            return "Ein Fehler ist aufgetreten. Bitte erneut versuchen."
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
