import SwiftUI
import CoreMotion

struct PackListView: View {
    @EnvironmentObject var userProgress: UserProgress
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedPack: Pack? = nil
    @State private var isOpening = false
    @State private var navigateToOpening = false
    @State private var navigateToPack = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("IQPacks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Spacer()
                        HStack(spacing: 20) {
                            NavigationLink(destination: LeaderboardView()) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                            }
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Section tabs
                    HStack(spacing: 0) {
                        SectionPill(label: "In Progress", count: incompletePacks.count)
                        SectionPill(label: "Completed", count: completedPacks.count)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // Pack carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(allPacks) { pack in
                                PackBoosterView(
                                    pack: pack,
                                    isOpening: selectedPack?.id == pack.id && isOpening
                                )
                                .onTapGesture {
                                    openPack(pack)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .frame(maxHeight: .infinity)

                    Spacer(minLength: 32)
                }
            }
            .navigationBarHidden(true)
            // First-time open → pack opening animation
            .navigationDestination(isPresented: $navigateToOpening) {
                if let pack = selectedPack, let card = firstCard(for: pack) {
                    PackOpeningView(pack: pack, firstCard: card) {
                        userProgress.markPackOpened(pack.id)
                        navigateToPack = true
                    }
                    // Drill into CardGameView after animation completes
                    .navigationDestination(isPresented: $navigateToPack) {
                        if let pack = selectedPack, let card = firstCard(for: pack) {
                            CardGameView(card: card, pack: pack)
                        }
                    }
                }
            }
            // Returning players skip straight to cards
            .navigationDestination(isPresented: $navigateToPack) {
                if let pack = selectedPack, let card = firstCard(for: pack) {
                    CardGameView(card: card, pack: pack)
                }
            }
        }
    }

    private var incompletePacks: [Pack] {
        allPacks.filter { userProgress.solvedCount(in: $0) < $0.cardCount }
    }

    private var completedPacks: [Pack] {
        allPacks.filter { userProgress.solvedCount(in: $0) >= $0.cardCount }
    }

    private func firstCard(for pack: Pack) -> Card? {
        pack.cards.first(where: { !userProgress.isSolved($0.id) }) ?? pack.cards.first
    }

    private func openPack(_ pack: Pack) {
        selectedPack = pack
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            isOpening = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isOpening = false
            if userProgress.hasOpenedPack(pack.id) {
                navigateToPack = true
            } else {
                navigateToOpening = true
            }
        }
    }
}

// MARK: - Booster pack card

private struct PackBoosterView: View {
    let pack: Pack
    let isOpening: Bool
    @EnvironmentObject var userProgress: UserProgress
    @StateObject private var motion = MotionManager()

    var solvedCount: Int { userProgress.solvedCount(in: pack) }
    var isComplete: Bool { solvedCount >= pack.cardCount }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Pack image
            AsyncImage(url: pack.thumbUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .offset(x: motion.tiltX * 20, y: motion.tiltY * 14)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    Color.clear
                }
            }
            .frame(width: UIScreen.main.bounds.width - 64)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Progress pill at bottom
            HStack(spacing: 6) {
                if isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
                Text(isComplete ? "Completed" : "\(solvedCount)/\(pack.cardCount) cards")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 16)
        }
        // 3D tilt on the whole card
        .rotation3DEffect(
            .degrees(Double(motion.tiltX) * -22),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
        .rotation3DEffect(
            .degrees(Double(motion.tiltY) * -16),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.6
        )
        .shadow(
            color: .black.opacity(0.5 + Double(abs(motion.tiltX)) * 0.3),
            radius: 24 + abs(motion.tiltX) * 16,
            x: motion.tiltX * -24,
            y: 12 + abs(motion.tiltY) * 8
        )
        .scaleEffect(isOpening ? 1.05 : 1.0)
        .rotationEffect(isOpening ? .degrees(1.5) : .degrees(0))
        .animation(
            isOpening
                ? .spring(response: 0.2, dampingFraction: 0.4).repeatCount(2, autoreverses: true)
                : .default,
            value: isOpening
        )
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

// MARK: - Section pill

private struct SectionPill: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.white.opacity(0.85), in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.1), in: Capsule())
        .padding(.trailing, 8)
    }
}
