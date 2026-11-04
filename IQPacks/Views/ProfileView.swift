import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userProgress: UserProgress
    @State private var history: [SolvedCardRow] = []
    @State private var packProgress: [SetProgressRow] = []
    @State private var isLoading = true

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Text(authManager.displayName.prefix(1).uppercased())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(authManager.displayName)
                            .font(.headline)
                        Text("Total score: \(userProgress.totalScore) pts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Pack breakdown
            Section("Packs") {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    ForEach(allPacks) { pack in
                        let solved = userProgress.solvedCount(in: pack)
                        let score = packProgress.first(where: { $0.set_id == pack.id })?.total_score ?? 0
                        HStack {
                            Text(pack.name)
                            Spacer()
                            Text("\(solved)/\(pack.cardCount)")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Text("· \(score) pts")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Recent activity
            if !history.isEmpty {
                Section("Recent Activity") {
                    ForEach(history.prefix(20), id: \.card_id) { row in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(row.card_id)
                                .font(.subheadline)
                            Spacer()
                            Text(row.solved_at, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Sign out
            Section {
                Button(role: .destructive) {
                    Task { await authManager.signOut() }
                } label: {
                    Text("Sign Out")
                }
            }

            Section {
                NavigationLink(destination: SoundLabView()) {
                    Label("Sound Lab", systemImage: "waveform")
                        .foregroundStyle(.secondary)
                }
            }

        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
    }

    private func loadData() async {
        guard let userId = authManager.userId else { return }
        async let h = try? ProgressRepository.shared.fetchAllSolvedCards(userId: userId)
        async let p = try? ProgressRepository.shared.fetchSetProgress(userId: userId)
        history = await h ?? []
        packProgress = await p ?? []
        isLoading = false
    }
}
