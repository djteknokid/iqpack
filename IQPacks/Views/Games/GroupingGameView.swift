import SwiftUI
import AudioToolbox

// MARK: - Zone frame preference key

private struct ZoneFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Main view

struct GroupingGameView: View {
    let zones: [Zone]
    let items: [GroupingItem]
    let onSolve: () -> Void

    @State private var assignments: [String: String] = [:]
    @State private var checked = false

    // Drag state
    @State private var draggingItem: GroupingItem? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var dragStartLocation: CGPoint = .zero
    @State private var zoneFrames: [String: CGRect] = [:]
    @State private var hoveringZone: String? = nil

    var unassigned: [GroupingItem] {
        items.filter { assignments[$0.id] == nil }
    }

    var allAssigned: Bool { unassigned.isEmpty }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sort each item into the correct group")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                if !unassigned.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Items to sort:")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        FlowLayout(spacing: 8) {
                            ForEach(unassigned) { item in
                                itemChip(item: item, highlight: nil, fromZone: nil)
                            }
                        }
                    }
                }

                ForEach(zones) { zone in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(zone.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        let assigned = items.filter { assignments[$0.id] == zone.id }
                        ZStack(alignment: .topLeading) {
                            // Zone drop target background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hoveringZone == zone.id
                                    ? Color.white.opacity(0.13)
                                    : Color.white.opacity(0.07))
                                .animation(.easeInOut(duration: 0.15), value: hoveringZone)

                            if assigned.isEmpty {
                                Text("Drop items here")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(12)
                            } else {
                                FlowLayout(spacing: 8) {
                                    ForEach(assigned) { item in
                                        let isDraggingThis = draggingItem?.id == item.id
                                        itemChip(item: item, highlight: nil, fromZone: zone.id)
                                        .opacity(isDraggingThis ? 0.3 : 1)
                                    }
                                }
                                .padding(8)
                            }
                        }
                        .frame(minHeight: 48)
                        // Capture zone frame in coordinate space "grouping"
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ZoneFrameKey.self,
                                        value: [zone.id: geo.frame(in: .named("grouping"))]
                                    )
                            }
                        )
                    }
                }

                if checked {
                    resultView
                }

                if !checked {
                    Button("Check Groups") {
                        checkGroups()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!allAssigned)
                }
            }
            .coordinateSpace(name: "grouping")
            .onPreferenceChange(ZoneFrameKey.self) { zoneFrames = $0 }

            // Floating drag chip
            if let item = draggingItem {
                ItemChip(item: item, highlight: nil, showGrabber: true)
                    .scaleEffect(1.05)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                    .position(dragLocation)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Item chip with drag gesture

    @ViewBuilder
    private func itemChip(item: GroupingItem, highlight: Color?, fromZone: String?) -> some View {
        let isDragging = draggingItem?.id == item.id
        ItemChip(item: item, highlight: isDragging ? nil : highlight, showGrabber: true)
            .opacity(isDragging ? 0.4 : 1)
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .named("grouping"))
                    .onChanged { value in
                        if draggingItem == nil {
                            draggingItem = item
                            dragStartLocation = value.startLocation
                            FeedbackHelper.tap()
                        }
                        dragLocation = value.location
                        hoveringZone = zoneFrames.first(where: { $0.value.contains(value.location) })?.key
                    }
                    .onEnded { value in
                        let dropZone = zoneFrames.first(where: { $0.value.contains(value.location) })?.key
                        if let zoneId = dropZone {
                            // Remove from old zone if re-dragging from a zone
                            assignments.removeValue(forKey: item.id)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                assignments[item.id] = zoneId
                            }
                            FeedbackHelper.match()
                        }
                        draggingItem = nil
                        hoveringZone = nil
                    }
            )
    }

    // MARK: - Result

    private var resultView: some View {
        let allCorrect = items.allSatisfy { assignments[$0.id] == $0.correctGroup }
        return HStack(spacing: 8) {
            Image(systemName: allCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(allCorrect ? .green : .red)
            Text(allCorrect ? "All correct!" : "Not quite — try moving some items")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Check

    private func checkGroups() {
        let allCorrect = items.allSatisfy { assignments[$0.id] == $0.correctGroup }
        if allCorrect {
            checked = true
            FeedbackHelper.correct()
            onSolve()
        } else {
            checked = true
            FeedbackHelper.wrong()
            // Reset checked after a moment so they can keep trying
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                checked = false
            }
        }
    }
}

// MARK: - Item chip

private struct ItemChip: View {
    let item: GroupingItem
    let highlight: Color?
    let showGrabber: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))

            if let emoji = item.emoji, !emoji.isEmpty {
                Text(emoji)
            }
            Text(item.label)
                .font(.subheadline)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.vertical, 7)
        .background(highlight.map { $0.opacity(0.2) } ?? Color.white.opacity(0.13), in: Capsule())
        .overlay(Capsule().strokeBorder(highlight.map { $0.opacity(0.35) } ?? Color.white.opacity(0.15), lineWidth: 1))
        .foregroundStyle(highlight ?? .white)
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            height = y + rowHeight
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
