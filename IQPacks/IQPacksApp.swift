import SwiftUI

@main
struct IQPacksApp: App {
    @StateObject private var userProgress = UserProgress()
    @StateObject private var authManager = AuthManager()

    init() {
        FeedbackHelper.configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if authManager.isSignedIn {
                    PackListView()
                        .environmentObject(userProgress)
                        .environmentObject(authManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.light)
            .onChange(of: authManager.userId) { _, newId in
                Task {
                    if let id = newId {
                        await userProgress.attach(userId: id)
                    } else {
                        userProgress.detach()
                    }
                }
            }
        }
    }
}
