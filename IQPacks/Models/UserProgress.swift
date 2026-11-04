import Foundation
import Combine

@MainActor
class UserProgress: ObservableObject {
    @Published private(set) var solvedCardIds: Set<String> = []
    @Published private(set) var totalScore: Int = 0
    @Published private(set) var isSyncing = false

    private let localKey = "iqpacks.solved"
    private let openedPacksKey = "iqpacks.openedPacks"
    private var userId: UUID?
    private var openedPackIds: Set<String> = []

    init() {
        if let saved = UserDefaults.standard.array(forKey: localKey) as? [String] {
            solvedCardIds = Set(saved)
        }
        if let opened = UserDefaults.standard.array(forKey: openedPacksKey) as? [String] {
            openedPackIds = Set(opened)
        }
    }

    func hasOpenedPack(_ packId: String) -> Bool {
        openedPackIds.contains(packId)
    }

    func markPackOpened(_ packId: String) {
        guard !openedPackIds.contains(packId) else { return }
        openedPackIds.insert(packId)
        UserDefaults.standard.set(Array(openedPackIds), forKey: openedPacksKey)
    }

    // Called by IQPacksApp once auth resolves
    func attach(userId: UUID) async {
        self.userId = userId
        await syncFromRemote()
    }

    func detach() {
        userId = nil
        solvedCardIds = []
        totalScore = 0
        openedPackIds = []
        UserDefaults.standard.removeObject(forKey: localKey)
        UserDefaults.standard.removeObject(forKey: openedPacksKey)
    }

    // MARK: - Public API

    func isSolved(_ cardId: String) -> Bool {
        solvedCardIds.contains(cardId)
    }

    func solvedCount(in pack: Pack) -> Int {
        pack.cards.filter { solvedCardIds.contains($0.id) }.count
    }

    func markSolved(_ cardId: String, in pack: Pack, firstTry: Bool = true) {
        guard !solvedCardIds.contains(cardId) else { return }
        solvedCardIds.insert(cardId)
        let score = firstTry ? 10 : 5
        totalScore += score
        persistLocally()

        guard let userId else { return }
        Task {
            try? await ProgressRepository.shared.markSolved(
                userId: userId,
                packId: pack.id,
                cardId: cardId,
                score: score
            )
        }
    }

    // MARK: - Private

    private func syncFromRemote() async {
        guard let userId else { return }
        isSyncing = true
        do {
            let ids = try await ProgressRepository.shared.fetchSolvedCardIds(userId: userId)
            solvedCardIds = ids
            persistLocally()

            let progress = try await ProgressRepository.shared.fetchSetProgress(userId: userId)
            totalScore = progress.reduce(0) { $0 + $1.total_score }
        } catch {
            print("Sync error: \(error)")
        }
        isSyncing = false
    }

    private func persistLocally() {
        UserDefaults.standard.set(Array(solvedCardIds), forKey: localKey)
    }
}
