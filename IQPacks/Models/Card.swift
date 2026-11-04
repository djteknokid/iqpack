import Foundation

// MARK: - Mechanic types

enum MechanicType: String, Codable {
    case sequence
    case grouping
    case matching
    case ranked
    case multipleChoice = "multiple-choice"
    case pronunciation
    case visualRecognition = "visual-recognition"
}

// MARK: - Shared sub-types

struct SequenceItem: Identifiable, Codable {
    let id: String
    let text: String
}

struct Zone: Identifiable, Codable {
    let id: String
    let label: String
    let color: String
}

struct GroupingItem: Identifiable, Codable {
    let id: String
    let label: String
    let emoji: String?
    let correctGroup: String
}

struct MatchingPair: Identifiable, Codable {
    let id: String
    let left: String
    let right: String
    let imageUrl: String?
}

struct RankedItem: Identifiable, Codable {
    let id: String
    let title: String
    let emoji: String
    let description: String
}

struct ChoiceOption: Identifiable, Codable {
    let id: String
    let text: String
}

struct ImageChoiceOption: Identifiable, Codable {
    let id: String
    let label: String
    let imageName: String?   // Asset catalog name (nil when imageUrl is used)
    let imageUrl: URL?       // Cloud URL (takes priority over imageName)
}

struct RecognitionOption: Identifiable, Codable {
    let id: String
    let label: String
}

// MARK: - Card mechanic payload

enum CardMechanic: Codable {
    case sequence(items: [SequenceItem])
    case grouping(zones: [Zone], items: [GroupingItem])
    case matching(pairs: [MatchingPair])
    case ranked(items: [RankedItem])
    case multipleChoice(options: [ChoiceOption], correctIds: [String], mediaUrl: String?)
    case imageChoice(options: [ImageChoiceOption], correctIds: [String])
    case pronunciation(audioUrl: String, phonetic: String?, definition: String?)
    case visualRecognition(imageIds: [String], options: [RecognitionOption], correctId: String, explanation: String?)
}

// MARK: - Card

struct Card: Identifiable, Codable {
    let id: String
    let question: String
    let topic: String
    let thumbId: String?
    let mechanic: CardMechanic

    var displayThumbId: String { thumbId ?? id }
}
