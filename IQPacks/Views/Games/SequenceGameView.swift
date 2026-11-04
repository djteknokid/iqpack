import SwiftUI
import AudioToolbox

struct SequenceGameView: View {
    let items: [SequenceItem]
    let onSolve: () -> Void
    var onDragChanged: ((Bool) -> Void)? = nil

    @State private var order: [SequenceItem]
    @State private var evalResults: [String: Bool] = [:]  // id → isCorrect
    @State private var checked = false
    @State private var allCorrect = false

    @State private var draggingId: String? = nil
    @State private var dragOffsetY: CGFloat = 0
    @State private var dragStartIndex: Int = 0
    @State private var dragCurrentIndex: Int = 0

    private let rowHeight: CGFloat = 56
    private let rowSpacing: CGFloat = 8
    private var stride: CGFloat { rowHeight + rowSpacing }

    init(items: [SequenceItem], onSolve: @escaping () -> Void, onDragChanged: ((Bool) -> Void)? = nil) {
        self.items = items
        self.onSolve = onSolve
        self.onDragChanged = onDragChanged
        _order = State(initialValue: items.shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Drag to arrange in the correct order")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            rowList

            if checked && !allCorrect {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    Text("Not quite — keep rearranging")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if !allCorrect {
                Button("Check Order") {
                    checkOrder()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Row list

    private var rowList: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(height: CGFloat(order.count) * stride - rowSpacing)

            ForEach(Array(order.enumerated()), id: \.element.id) { index, item in
                let isDragging = draggingId == item.id

                rowCard(index: index, item: item, isDragging: isDragging)
                    .frame(height: rowHeight)
                    .offset(y: isDragging
                        ? CGFloat(dragStartIndex) * stride + dragOffsetY
                        : CGFloat(index) * stride)
                    .zIndex(isDragging ? 10 : 0)
                    .animation(isDragging ? .none : .interactiveSpring(response: 0.25, dampingFraction: 0.8), value: order.map(\.id))
                    .simultaneousGesture(
                        allCorrect ? nil :
                        DragGesture(minimumDistance: 6, coordinateSpace: .named("seqList"))
                            .onChanged { value in
                                if draggingId == nil {
                                    draggingId = item.id
                                    dragStartIndex = index
                                    dragCurrentIndex = index
                                    if checked { evalResults = [:]; checked = false }
                                    onDragChanged?(true)
                                    FeedbackHelper.tap()
                                }

                                dragOffsetY = value.translation.height

                                // Determine target index from absolute drag position
                                let absoluteY = CGFloat(dragStartIndex) * stride + dragOffsetY + rowHeight / 2
                                let targetIndex = max(0, min(order.count - 1, Int((absoluteY / stride).rounded())))

                                if targetIndex != dragCurrentIndex,
                                   let currentIdx = order.firstIndex(where: { $0.id == item.id }) {
                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
                                        let destination = targetIndex > currentIdx ? targetIndex + 1 : targetIndex
                                        order.move(fromOffsets: IndexSet(integer: currentIdx), toOffset: destination)
                                    }
                                    dragCurrentIndex = targetIndex
                                    FeedbackHelper.tick()
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    draggingId = nil
                                    dragOffsetY = 0
                                    dragStartIndex = 0
                                    dragCurrentIndex = 0
                                }
                                onDragChanged?(false)
                            }
                    )
            }
        }
        .coordinateSpace(name: "seqList")
    }

    // MARK: - Row card

    @ViewBuilder
    private func rowCard(index: Int, item: SequenceItem, isDragging: Bool) -> some View {
        let bgColor: Color = isDragging ? Color.white.opacity(0.14) : Color.white.opacity(0.08)
        let borderColor: Color = isDragging ? Color.white.opacity(0.3) : Color.white.opacity(0.1)

        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20, alignment: .center)

            Text(item.text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(isDragging ? .white.opacity(0.7) : .white.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(borderColor, lineWidth: 1))
        .shadow(color: isDragging ? .black.opacity(0.4) : .clear, radius: 8, y: 4)
        .contentShape(Rectangle())
    }

    // MARK: - Check

    private func checkOrder() {
        var results: [String: Bool] = [:]
        for (i, item) in order.enumerated() {
            results[item.id] = item.id == items[i].id
        }
        evalResults = results
        checked = true
        allCorrect = results.values.allSatisfy { $0 }
        if allCorrect {
            FeedbackHelper.correct()
            onSolve()
        } else {
            FeedbackHelper.wrong()
        }
    }
}
