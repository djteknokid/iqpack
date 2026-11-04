import SwiftUI
import AudioToolbox

struct CardGameView: View {
    let pack: Pack
    @EnvironmentObject var userProgress: UserProgress
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int
    @State private var solved = false
    @State private var firstTry = true
    @State private var cardVisible = false
    @State private var celebrating = false
    @State private var timerProgress: CGFloat = 1.0
    @State private var autoAdvanceTask: Task<Void, Never>? = nil
    @State private var scrollDisabled = false

    init(card: Card, pack: Pack) {
        self.pack = pack
        let idx = pack.cards.firstIndex(where: { $0.id == card.id }) ?? 0
        _currentIndex = State(initialValue: idx)
    }

    private var card: Card { pack.cards[currentIndex] }
    private var isLastCard: Bool { currentIndex >= pack.cards.count - 1 }

    private var headerHeight: CGFloat {
        switch visualMode {
        case .focus: return 140
        case .media: return 180
        case .story: return 260
        }
    }

    private var visualMode: VisualMode {
        guard pack.headerImageUrl != nil else { return .focus }
        switch card.mechanic {
        case .sequence, .matching, .grouping, .ranked, .imageChoice:
            return .focus
        case .multipleChoice(_, _, let url) where url != nil:
            return .media
        default:
            return .story
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 0).id("top")

                        headerSection

                        questionCard
                            .offset(y: cardVisible ? 0 : 60)
                            .opacity(cardVisible ? 1 : 0)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .scrollIndicators(.hidden)
                .scrollDisabled(scrollDisabled)
                .onChange(of: currentIndex) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }

            // Confetti + fireworks
            if celebrating {
                SuccessEffectView()
                    .ignoresSafeArea()
                    .zIndex(99)
                    .transition(.opacity)
            }

            // Success snackbar
            if celebrating {
                VStack {
                    Spacer()
                    celebrationSnackbar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(pack.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Text(card.topic)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            solved = userProgress.isSolved(card.id)
            animateCardIn()
        }
        .onChange(of: currentIndex) {
            solved = userProgress.isSolved(card.id)
            animateCardIn()
        }
    }

    // MARK: - Celebration overlay

    // MARK: - Celebration snackbar

    private var celebrationSnackbar: some View {
        VStack(spacing: 0) {
            // Timer bar at the very top of the snackbar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(maxWidth: .infinity, maxHeight: 3)
                Rectangle()
                    .fill(isLastCard ? Color.yellow : Color.green)
                    .frame(width: UIScreen.main.bounds.width * timerProgress, height: 3)
                    .animation(.linear(duration: 2.7), value: timerProgress)
            }

            HStack(spacing: 12) {
                Image(systemName: isLastCard ? "trophy.fill" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isLastCard ? .yellow : .green)

                Text(isLastCard ? "Pack complete!" : "Correct!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 4)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let parallaxOffset = minY > 0 ? -minY * 0.4 : 0
            let scale = minY > 0 ? 1 + minY * 0.001 : 1.0

            ZStack {
                if let url = pack.headerImageUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            headerFallback
                        }
                    }
                    .frame(width: geo.size.width, height: headerHeight + max(0, minY))
                    .offset(y: parallaxOffset)
                    .scaleEffect(scale, anchor: .top)
                    .clipped()
                } else {
                    headerFallback
                        .frame(width: geo.size.width, height: headerHeight)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .bottom)

                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.6), radius: 4)
                            Text(card.topic.uppercased())
                                .font(.caption2)
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        progressBadge
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(height: headerHeight)
    }

    private var headerFallback: some View {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.12, blue: 0.05), .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var progressBadge: some View {
        let count = userProgress.solvedCount(in: pack)
        return Text("\(count) / \(pack.cardCount)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Question card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(card.question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.horizontal, 24)

            Group {
                switch card.mechanic {
                case .sequence(let items):
                    SequenceGameView(items: items, onSolve: markSolved, onDragChanged: { scrollDisabled = $0 })
                case .grouping(let zones, let items):
                    GroupingGameView(zones: zones, items: items, onSolve: markSolved)
                case .matching(let pairs):
                    MatchingGameView(pairs: pairs, onSolve: markSolved)
                        .padding(.horizontal, -12)
                case .ranked(let items):
                    RankedGameView(items: items, onSolve: markSolved)
                case .multipleChoice(let options, let correctIds, let mediaUrl):
                    MultipleChoiceGameView(options: options, correctIds: correctIds, mediaUrl: mediaUrl, onSolve: markSolved)
                case .imageChoice(let options, let correctIds):
                    ImageChoiceGameView(options: options, correctIds: correctIds, onSolve: markSolved)
                case .pronunciation(let audioUrl, let phonetic, let definition):
                    PronunciationGameView(audioUrl: audioUrl, phonetic: phonetic, definition: definition, onSolve: markSolved)
                case .visualRecognition(let imageIds, let options, let correctId, let explanation):
                    VisualRecognitionGameView(imageIds: imageIds, options: options, correctId: correctId, explanation: explanation, onSolve: markSolved)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(Color.black)
        .id(currentIndex) // force full redraw on advance
    }

    // MARK: - Helpers

    private func animateCardIn() {
        cardVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                cardVisible = true
            }
        }
    }

    private func markSolved() {
        if !solved {
            userProgress.markSolved(card.id, in: pack, firstTry: firstTry)
            solved = true
        }
        triggerCelebration()
    }

    private func triggerCelebration() {
        timerProgress = 1.0
        withAnimation(.easeOut(duration: 0.2)) { celebrating = true }

        // Drain bar after overlay has appeared
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timerProgress = 0
        }

        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) { celebrating = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    advanceOrDismiss()
                }
            }
        }
    }

    private func advanceOrDismiss() {
        if isLastCard {
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                cardVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                firstTry = true
                currentIndex += 1
            }
        }
    }
}

private enum VisualMode {
    case story, media, focus
}
