import SwiftUI

struct PackDetailView: View {
    let pack: Pack
    @EnvironmentObject var userProgress: UserProgress

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(pack.cards) { card in
                    NavigationLink(destination: CardGameView(card: card, pack: pack)) {
                        CardRowView(card: card, solved: userProgress.isSolved(card.id))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CardRowView: View {
    let card: Card
    let solved: Bool

    var mechanicLabel: String {
        switch card.mechanic {
        case .sequence:           return "Sequence"
        case .grouping:           return "Sort"
        case .matching:           return "Match"
        case .ranked:             return "Rank"
        case .multipleChoice:     return "Quiz"
        case .imageChoice:        return "Pick"
        case .pronunciation:      return "Pronounce"
        case .visualRecognition:  return "Identify"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(solved ? Color.green.opacity(0.15) : Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: solved ? "checkmark" : "questionmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(solved ? .green : .blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(card.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(mechanicLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
