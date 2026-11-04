import Foundation
import Supabase

struct SolvedCardRow: Decodable {
    let card_id: String
    let score: Int
    let solved_at: Date
}

struct LeaderboardRow: Decodable {
    let user_id: UUID
    let total_score: Int
    let cards_solved: Int
    let display_name: String?
}

struct SetProgressRow: Decodable {
    let set_id: String
    let total_score: Int
    let cards_solved: Int
    let last_played_at: Date
}

actor ProgressRepository {
    static let shared = ProgressRepository()
    private init() {}

    // MARK: - Read

    func fetchSolvedCardIds(userId: UUID) async throws -> Set<String> {
        let rows: [SolvedCardRow] = try await supabase
            .from("user_solved_cards")
            .select("card_id, score, solved_at")
            .eq("user_id", value: userId)
            .execute()
            .value
        return Set(rows.map(\.card_id))
    }

    func fetchAllSolvedCards(userId: UUID) async throws -> [SolvedCardRow] {
        try await supabase
            .from("user_solved_cards")
            .select("card_id, score, solved_at")
            .eq("user_id", value: userId)
            .order("solved_at", ascending: false)
            .execute()
            .value
    }

    func fetchSetProgress(userId: UUID) async throws -> [SetProgressRow] {
        try await supabase
            .from("user_set_progress")
            .select("set_id, total_score, cards_solved, last_played_at")
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func fetchLeaderboard() async throws -> [LeaderboardRow] {
        // Aggregate total_score per user across all packs
        try await supabase
            .from("user_set_progress")
            .select("user_id, total_score, cards_solved, display_name:user_id(raw_user_meta_data->full_name)")
            .order("total_score", ascending: false)
            .limit(20)
            .execute()
            .value
    }

    // MARK: - Write

    func markSolved(userId: UUID, packId: String, cardId: String, score: Int) async throws {
        // Upsert solved card (idempotent — won't double-score if already solved)
        struct SolvedInsert: Encodable {
            let user_id: UUID
            let set_id: String
            let card_id: String
            let score: Int
        }
        try await supabase
            .from("user_solved_cards")
            .upsert(
                SolvedInsert(user_id: userId, set_id: packId, card_id: cardId, score: score),
                onConflict: "user_id,set_id,card_id"
            )
            .execute()

        // Recalculate and upsert pack-level progress
        try await refreshSetProgress(userId: userId, packId: packId)

        // Append to history
        struct HistoryInsert: Encodable {
            let user_id: UUID
            let question: String
        }
        let question = allPacks.first(where: { $0.id == packId })?.cards.first(where: { $0.id == cardId })?.question ?? cardId
        try await supabase
            .from("user_history")
            .insert(HistoryInsert(user_id: userId, question: question))
            .execute()
    }

    private func refreshSetProgress(userId: UUID, packId: String) async throws {
        struct AggRow: Decodable { let count: Int; let sum: Int? }
        struct ProgressUpsert: Encodable {
            let user_id: UUID; let set_id: String; let total_score: Int; let cards_solved: Int
        }
        let rows: [SolvedCardRow] = try await supabase
            .from("user_solved_cards")
            .select("card_id, score, solved_at")
            .eq("user_id", value: userId)
            .eq("set_id", value: packId)
            .execute()
            .value
        let totalScore = rows.reduce(0) { $0 + $1.score }
        try await supabase
            .from("user_set_progress")
            .upsert(
                ProgressUpsert(user_id: userId, set_id: packId, total_score: totalScore, cards_solved: rows.count),
                onConflict: "user_id,set_id"
            )
            .execute()
    }
}
