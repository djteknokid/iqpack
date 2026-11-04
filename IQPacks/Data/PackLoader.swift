import Foundation

// MARK: - JSON-decodable pack

struct PackJSON: Decodable {
    let id: String
    let number: String
    let name: String
    let description: String
    let topics: [String]
    let thumbUrl: String?
    let headerImageUrl: String?
    let cards: [CardJSON]

    func toPack() -> Pack {
        Pack(
            id: id,
            number: number,
            name: name,
            description: description,
            topics: topics,
            thumbUrl: thumbUrl.flatMap { URL(string: $0) },
            headerImageUrl: headerImageUrl.flatMap { URL(string: $0) },
            cards: cards.compactMap { $0.toCard() }
        )
    }
}

// MARK: - JSON-decodable card

struct CardJSON: Decodable {
    let id: String
    let question: String
    let topic: String
    let thumbId: String?
    let mechanic: CardMechanicJSON

    func toCard() -> Card? {
        guard let m = mechanic.toMechanic() else { return nil }
        return Card(id: id, question: question, topic: topic, thumbId: thumbId, mechanic: m)
    }
}

// MARK: - JSON mechanic (discriminated union via "type" field)

struct CardMechanicJSON: Decodable {
    let type: String

    // sequence
    let items: [SequenceItemJSON]?

    // grouping
    let zones: [ZoneJSON]?
    let groupingItems: [GroupingItemJSON]?

    // matching
    let pairs: [MatchingPairJSON]?

    // multipleChoice
    let options: [ChoiceOptionJSON]?
    let correctIds: [String]?
    let mediaUrl: String?

    // imageChoice
    let imageOptions: [ImageChoiceOptionJSON]?

    // visualRecognition
    let imageIds: [String]?
    let recognitionOptions: [RecognitionOptionJSON]?
    let correctId: String?
    let explanation: String?

    // pronunciation
    let audioUrl: String?
    let phonetic: String?
    let definition: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)
        type = try c.decode(String.self, forKey: DynamicKey("type"))
        mediaUrl    = try c.decodeIfPresent(String.self, forKey: DynamicKey("mediaUrl"))
        correctIds  = try c.decodeIfPresent([String].self, forKey: DynamicKey("correctIds"))
        correctId   = try c.decodeIfPresent(String.self, forKey: DynamicKey("correctId"))
        explanation = try c.decodeIfPresent(String.self, forKey: DynamicKey("explanation"))
        audioUrl    = try c.decodeIfPresent(String.self, forKey: DynamicKey("audioUrl"))
        phonetic    = try c.decodeIfPresent(String.self, forKey: DynamicKey("phonetic"))
        definition  = try c.decodeIfPresent(String.self, forKey: DynamicKey("definition"))
        imageIds    = try c.decodeIfPresent([String].self, forKey: DynamicKey("imageIds"))
        zones       = try c.decodeIfPresent([ZoneJSON].self, forKey: DynamicKey("zones"))
        pairs       = try c.decodeIfPresent([MatchingPairJSON].self, forKey: DynamicKey("pairs"))

        switch type {
        case "sequence":
            items              = try c.decodeIfPresent([SequenceItemJSON].self, forKey: DynamicKey("items"))
            groupingItems      = nil
            options            = nil
            imageOptions       = nil
            recognitionOptions = nil
        case "grouping":
            items              = nil
            groupingItems      = try c.decodeIfPresent([GroupingItemJSON].self, forKey: DynamicKey("items"))
            options            = nil
            imageOptions       = nil
            recognitionOptions = nil
        case "multipleChoice":
            items              = nil
            groupingItems      = nil
            options            = try c.decodeIfPresent([ChoiceOptionJSON].self, forKey: DynamicKey("options"))
            imageOptions       = nil
            recognitionOptions = nil
        case "imageChoice":
            items              = nil
            groupingItems      = nil
            options            = nil
            imageOptions       = try c.decodeIfPresent([ImageChoiceOptionJSON].self, forKey: DynamicKey("options"))
            recognitionOptions = nil
        case "visualRecognition":
            items              = nil
            groupingItems      = nil
            options            = nil
            imageOptions       = nil
            recognitionOptions = try c.decodeIfPresent([RecognitionOptionJSON].self, forKey: DynamicKey("options"))
        default:
            items              = nil
            groupingItems      = nil
            options            = nil
            imageOptions       = nil
            recognitionOptions = nil
        }
    }

    func toMechanic() -> CardMechanic? {
        switch type {
        case "sequence":
            guard let raw = items else { return nil }
            return .sequence(items: raw.map { SequenceItem(id: $0.id, text: $0.text) })

        case "grouping":
            guard let zs = zones, let gi = groupingItems else { return nil }
            return .grouping(
                zones: zs.map { Zone(id: $0.id, label: $0.label, color: $0.color) },
                items: gi.map { GroupingItem(id: $0.id, label: $0.label, emoji: $0.emoji, correctGroup: $0.correctGroup) }
            )

        case "matching":
            guard let ps = pairs else { return nil }
            return .matching(pairs: ps.map { MatchingPair(id: $0.id, left: $0.left, right: $0.right, imageUrl: $0.imageUrl) })

        case "multipleChoice":
            guard let opts = options, let ids = correctIds else { return nil }
            return .multipleChoice(
                options: opts.map { ChoiceOption(id: $0.id, text: $0.text) },
                correctIds: ids,
                mediaUrl: mediaUrl
            )

        case "imageChoice":
            guard let opts = imageOptions, let ids = correctIds else { return nil }
            return .imageChoice(
                options: opts.map { ImageChoiceOption(id: $0.id, label: $0.label, imageName: $0.imageName, imageUrl: $0.imageUrl.flatMap { URL(string: $0) }) },
                correctIds: ids
            )

        case "visualRecognition":
            guard let ids = imageIds, let opts = recognitionOptions, let cid = correctId else { return nil }
            return .visualRecognition(
                imageIds: ids,
                options: opts.map { RecognitionOption(id: $0.id, label: $0.label) },
                correctId: cid,
                explanation: explanation
            )

        case "pronunciation":
            guard let audio = audioUrl else { return nil }
            return .pronunciation(audioUrl: audio, phonetic: phonetic, definition: definition)

        default:
            return nil
        }
    }
}

// MARK: - Sub-type JSON models

struct SequenceItemJSON: Decodable    { let id: String; let text: String }
struct ZoneJSON: Decodable            { let id: String; let label: String; let color: String }
struct GroupingItemJSON: Decodable    { let id: String; let label: String; let emoji: String?; let correctGroup: String }
struct MatchingPairJSON: Decodable    { let id: String; let left: String; let right: String; let imageUrl: String? }
struct ChoiceOptionJSON: Decodable    { let id: String; let text: String }
struct RecognitionOptionJSON: Decodable { let id: String; let label: String }
struct ImageChoiceOptionJSON: Decodable {
    let id: String
    let label: String
    let imageName: String?
    let imageUrl: String?
}

// MARK: - Dynamic coding key helper

private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

// MARK: - Loader

enum PackLoader {
    // Add new pack filenames here as you create them
    private static let packFiles = [
        "thomas-edison-v1",
        "thomas-edison-v2",
    ]

    static func loadAll() -> [Pack] {
        packFiles.compactMap { name -> Pack? in
            guard
                let url = Bundle.main.url(forResource: name, withExtension: "json"),
                let data = try? Data(contentsOf: url)
            else { return nil }
            return try? JSONDecoder().decode(PackJSON.self, from: data).toPack()
        }
    }
}
