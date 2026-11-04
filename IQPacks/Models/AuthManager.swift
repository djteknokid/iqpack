import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published private(set) var session: Session? = nil
    @Published private(set) var isLoading = true

    var isSignedIn: Bool { session != nil }
    var userId: UUID? { session?.user.id }
    var displayName: String {
        session?.user.userMetadata["full_name"]?.stringValue
            ?? session?.user.email
            ?? "You"
    }

    init() {
        Task {
            // Restore existing session if token is still valid
            do {
                session = try await supabase.auth.session
            } catch {
                session = nil
            }
            isLoading = false

            // Listen for future auth changes
            for await (event, newSession) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn, .tokenRefreshed, .userUpdated:
                    session = newSession
                case .signedOut:
                    session = nil
                default:
                    break
                }
            }
        }
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard case .success(let auth) = result,
              let credential = auth.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8)
        else { return }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")

        do {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString,
                    nonce: nil
                )
            )
            // Update display name on first sign-in if Apple provided it
            if !fullName.isEmpty {
                try await supabase.auth.update(user: UserAttributes(data: ["full_name": .string(fullName)]))
            }
        } catch {
            print("Supabase Apple sign-in error: \(error)")
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
    }

    #if DEBUG
    func signInAsGuest() async {
        let email = "simulator@iqpacks.com"
        let password = "simulator-dev-password-123"
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            // Account doesn't exist yet — create it
            do {
                _ = try await supabase.auth.signUp(email: email, password: password)
            } catch {
                print("Guest sign-in failed: \(error)")
            }
        }
    }
    #endif
}
