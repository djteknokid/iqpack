import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("IQPacks")
                    .font(.system(size: 48, weight: .bold))
                Text("Knowledge that sticks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await authManager.handleAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            #if DEBUG
            Button("Skip Sign In (Simulator)") {
                Task { await authManager.signInAsGuest() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 16)
            #endif

            Spacer().frame(height: 60)
        }
    }
}
