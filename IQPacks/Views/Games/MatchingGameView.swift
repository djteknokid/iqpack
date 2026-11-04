import SwiftUI
import AudioToolbox

// MARK: - Anchor preference key

private struct DotAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGPoint>] = [:]
    static func reduce(value: inout [String: Anchor<CGPoint>], nextValue: () -> [String: Anchor<CGPoint>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Main view

struct MatchingGameView: View {
    let pairs: [MatchingPair]
    let onSolve: () -> Void

    @State private var matched: [String: String]
    @State private var shuffledRight: [String]
    @State private var draggingFrom: String? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var anchors: [String: Anchor<CGPoint>] = [:]
    @State private var resolvedPositions: [String: CGPoint] = [:]
    @State private var submitted = false
    @State private var revealed = false
    @State private var wasWrong = false

    var allMatched: Bool { matched.count == pairs.count }
    var allCorrect: Bool { pairs.allSatisfy { matched[$0.left] == $0.right } }

    init(pairs: [MatchingPair], onSolve: @escaping () -> Void) {
        self.pairs = pairs
        self.onSolve = onSolve
        _matched = State(initialValue: [:])
        _shuffledRight = State(initialValue: pairs.map(\.right).shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            connectorBoard

            if wasWrong {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    Text("Not quite — try reconnecting")
                        .font(.subheadline).fontWeight(.medium).foregroundStyle(.white)
                }
            }

            if !submitted {
                submitButton
                    .opacity(allMatched ? 1 : 0.35)
                    .disabled(!allMatched)
            }

            Button("SKIP →") {
                revealed = true
                onSolve()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.35))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Submit button

    private var submitButton: some View {
        Button {
            if allCorrect {
                submitted = true
                FeedbackHelper.correct()
                onSolve()
            } else {
                wasWrong = true
                FeedbackHelper.wrong()
            }
        } label: {
            Text("Submit")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Connector board

    private var connectorBoard: some View {
        GeometryReader { geo in
            ZStack {
                // Committed connection lines (drawn first, behind everything)
                ForEach(pairs, id: \.id) { pair in
                    if let rightLabel = matched[pair.left],
                       let fromAnchor = anchors[pair.left + "-right"],
                       let toAnchor = anchors[rightLabel + "-left"] {
                        let from = geo[fromAnchor]
                        let to = geo[toAnchor]
                        ConnectorLine(from: from, to: to, color: .blue)
                    }
                }

                // Two equal columns
                HStack(alignment: .top, spacing: 28) {
                    VStack(spacing: 8) {
                        ForEach(pairs, id: \.id) { pair in
                            leftRow(pair: pair)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        ForEach(shuffledRight, id: \.self) { right in
                            rightRow(label: right)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Live drag line (top layer)
                if let fromId = draggingFrom,
                   let fromAnchor = anchors[fromId + "-right"] {
                    let from = geo[fromAnchor]
                    Path { p in
                        p.move(to: from)
                        let midX = (from.x + dragLocation.x) / 2
                        p.addCurve(
                            to: dragLocation,
                            control1: CGPoint(x: midX, y: from.y),
                            control2: CGPoint(x: midX, y: dragLocation.y)
                        )
                    }
                    .stroke(Color.blue.opacity(0.7),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                }
            }
            .coordinateSpace(name: "matching")
            .onPreferenceChange(DotAnchorKey.self) { newAnchors in
                anchors = newAnchors
                var positions: [String: CGPoint] = [:]
                for (key, anchor) in newAnchors {
                    positions[key] = geo[anchor]
                }
                resolvedPositions = positions
            }
        }
        .frame(height: CGFloat(max(pairs.count, shuffledRight.count)) * 80 + CGFloat(max(0, pairs.count - 1)) * 8)
    }

    // MARK: - Left row

    @ViewBuilder
    private func leftRow(pair: MatchingPair) -> some View {
        let isConnected = matched[pair.left] != nil

        ZStack(alignment: .trailing) {
            Text(pair.left)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(rowBackground(connected: isConnected), in: RoundedRectangle(cornerRadius: 10))

            // Dot centered on right border
            dotView(id: pair.left + "-right", connected: isConnected)
                .anchorPreference(key: DotAnchorKey.self, value: .center) {
                    [pair.left + "-right": $0]
                }
                .offset(x: 4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !submitted, isConnected else { return }
            matched.removeValue(forKey: pair.left)
            FeedbackHelper.tap()
        }
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named("matching"))
                .onChanged { value in
                    if draggingFrom == nil { }
                    draggingFrom = pair.left
                    dragLocation = value.location
                }
                .onEnded { value in
                    commitDrop(from: pair.left, at: value.location)
                    withAnimation { draggingFrom = nil }
                }
        )
    }

    // MARK: - Right row

    @ViewBuilder
    private func rightRow(label: String) -> some View {
        let connectedLeft = matched.first(where: { $0.value == label })?.key
        let isConnected = connectedLeft != nil

        ZStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(rowBackground(connected: isConnected), in: RoundedRectangle(cornerRadius: 10))

            // Dot centered on left border
            dotView(id: label + "-left", connected: isConnected)
                .anchorPreference(key: DotAnchorKey.self, value: .center) {
                    [label + "-left": $0]
                }
                .offset(x: -4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !submitted, isConnected, let leftKey = connectedLeft else { return }
            matched.removeValue(forKey: leftKey)
            FeedbackHelper.tap()
        }
    }

    // MARK: - Dot view

    private func dotView(id: String, connected: Bool) -> some View {
        let color: Color = connected ? .blue : .white.opacity(0.5)
        return Circle()
            .fill(connected ? color : Color.black)
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(color, lineWidth: 1))
    }

    // MARK: - Drop hit detection

    private func commitDrop(from leftLabel: String, at location: CGPoint) {
        guard !submitted else { return }

        var best: (label: String, dist: CGFloat)? = nil
        for right in shuffledRight {
            let key = right + "-left"
            guard let pos = resolvedPositions[key] else { continue }
            // Use only vertical distance for row snapping — drop anywhere on the right half
            let dy = abs(pos.y - location.y)
            let dx = abs(pos.x - location.x)
            // Accept if within 55pt vertically OR within 100pt total radius
            let vertSnap = dy < 55
            let radSnap = sqrt(dx * dx + dy * dy) < 100
            if (vertSnap || radSnap), best == nil || dy < best!.dist {
                best = (right, dy)
            }
        }

        guard let target = best else { return }

        if let existingLeft = matched.first(where: { $0.value == target.label })?.key {
            matched.removeValue(forKey: existingLeft)
        }
        matched.removeValue(forKey: leftLabel)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            matched[leftLabel] = target.label
        }

        if wasWrong { wasWrong = false }
        FeedbackHelper.select()
    }

    // MARK: - Helpers

    private func rowBackground(connected: Bool) -> Color {
        connected ? Color.blue.opacity(0.15) : Color.white.opacity(0.07)
    }
}

// MARK: - Bezier connector line

private struct ConnectorLine: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
        Path { p in
            p.move(to: from)
            let midX = (from.x + to.x) / 2
            p.addCurve(
                to: to,
                control1: CGPoint(x: midX, y: from.y),
                control2: CGPoint(x: midX, y: to.y)
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .opacity(0.85)
    }
}
