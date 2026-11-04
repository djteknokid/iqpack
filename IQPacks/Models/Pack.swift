import Foundation

struct Pack: Identifiable, Codable {
    let id: String
    let number: String
    let name: String
    let description: String
    let topics: [String]
    let thumbUrl: URL?
    let headerImageUrl: URL?
    let cards: [Card]

    var cardCount: Int { cards.count }
}
