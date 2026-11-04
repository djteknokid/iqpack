import SwiftUI
import AudioToolbox

struct RankedGameView: View {
    let items: [RankedItem]
    let onSolve: () -> Void

    @State private var order: [RankedItem]
    @State private var revealed = false

    init(items: [RankedItem], onSolve: @escaping () -> Void) {
        self.items = items
        self.onSolve = onSolve
        _order = State(initialValue: items.shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rank these from top to bottom")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(Array(order.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 28)

                        Text(item.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Button {
                                guard index > 0 else { return }
                                order.swapAt(index, index - 1)
                                FeedbackHelper.tap()
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.caption)
                            }
                            .disabled(index == 0)

                            Button {
                                guard index < order.count - 1 else { return }
                                order.swapAt(index, index + 1)
                                FeedbackHelper.tap()
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .disabled(index == order.count - 1)
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            if !revealed {
                HStack(spacing: 12) {
                    Button("Check") {
                        let correct = order.map(\.id) == items.map(\.id)
                        if correct {
                            FeedbackHelper.correct()
                            onSolve()
                        } else {
                            FeedbackHelper.wrong()
                        }
                        revealed = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reveal") {
                        revealed = true
                        onSolve()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Correct ranking:")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                        HStack(spacing: 8) {
                            Text("#\(i + 1)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 28, alignment: .leading)
                            Text(item.emoji)
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
