import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var rows: [LeaderboardRow] = []
    @State private var isLoading = true
    @State private var error: String? = nil

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error {
                Text(error)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else if rows.isEmpty {
                Text("No scores yet. Be the first!")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 14) {
                        // Rank
                        ZStack {
                            Circle()
                                .fill(rankColor(index).opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(rankColor(index))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.display_name ?? "Player")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                + (row.user_id == authManager.userId ? Text(" (You)").foregroundStyle(.blue).font(.caption) : Text(""))
                            Text("\(row.cards_solved) cards solved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(row.total_score)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        + Text(" pts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadLeaderboard() }
        .refreshable { await loadLeaderboard() }
    }

    private func loadLeaderboard() async {
        isLoading = true
        error = nil
        do {
            rows = try await ProgressRepository.shared.fetchLeaderboard()
        } catch {
            self.error = "Couldn't load scores. Pull to refresh."
        }
        isLoading = false
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(white: 0.6)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }
}
