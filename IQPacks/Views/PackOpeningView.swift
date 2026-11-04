import SwiftUI
import UIKit

struct PackOpeningView: View {
    let pack: Pack
    let firstCard: Card
    let onOpened: () -> Void

    @State private var tearProgress: CGFloat = 0
    @State private var isTriggered = false
    @State private var bottomFalling = false
    @State private var packGone = false

    private let packWidth: CGFloat = UIScreen.main.bounds.width - 64
    private let packHeight: CGFloat = (UIScreen.main.bounds.width - 64) * (490.0 / 280.0)
    private let tearFraction: CGFloat = 0.13

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.065, blue: 0.11).ignoresSafeArea()

            RadialGradient(
                colors: [.yellow.opacity(0.13), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 52)

                VStack(spacing: 8) {
                    Text(pack.name.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(.yellow.opacity(0.8))
                    Text("Open Your Pack")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }

                Spacer()

                ZStack {
                    // Bottom portion — slides down on open
                    packImage
                        .mask(bottomMask)
                        .offset(y: bottomFalling ? packHeight * 0.85 : 0)
                        .opacity(packGone ? 0 : 1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.72), value: bottomFalling)
                        .zIndex(2)

                    // Top tear strip — follows finger, flies off on trigger
                    packImage
                        .mask(topMask)
                        .offset(
                            x: isTriggered ? packWidth * 0.95 : tearProgress * packWidth * 0.4,
                            y: isTriggered ? -packHeight * 0.22 : -tearProgress * 18
                        )
                        .rotationEffect(.degrees(isTriggered ? 22 : tearProgress * 8))
                        .opacity(packGone ? 0 : 1)
                        .animation(
                            isTriggered
                                ? .spring(response: 0.42, dampingFraction: 0.65)
                                : .interactiveSpring(),
                            value: isTriggered
                        )
                        .zIndex(4)

                    // Scratch line during drag
                    if tearProgress > 0 && !isTriggered {
                        tearScratchLine.zIndex(5)
                    }

                    // Gesture zone
                    if !isTriggered {
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: packWidth, height: packHeight * tearFraction * 2)
                            .offset(y: -(packHeight * (1 - tearFraction * 2)) / 2)
                            .gesture(dragGesture)
                            .zIndex(6)
                    }
                }
                .frame(width: packWidth, height: packHeight)

                Spacer()

                if !isTriggered {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                        Text("Swipe across the top to open")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                }

                Spacer().frame(height: 48)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden(isTriggered)
    }

    // MARK: - Pack image

    private var packImage: some View {
        AsyncImage(url: pack.thumbUrl) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            default:
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            }
        }
        .frame(width: packWidth, height: packHeight)
        .shadow(color: .yellow.opacity(0.18), radius: 30)
    }

    // MARK: - Masks

    private var tearY: CGFloat { packHeight * tearFraction }

    private var topMask: some View {
        Rectangle()
            .frame(width: packWidth, height: tearY)
            .offset(y: -(packHeight - tearY) / 2)
            .frame(width: packWidth, height: packHeight)
    }

    private var bottomMask: some View {
        Rectangle()
            .frame(width: packWidth, height: packHeight - tearY)
            .offset(y: tearY / 2)
            .frame(width: packWidth, height: packHeight)
    }

    // MARK: - Scratch line

    private var tearScratchLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.35 * tearProgress))
            .frame(width: packWidth * tearProgress, height: 2)
            .frame(width: packWidth, alignment: .leading)
            .offset(y: -(packHeight / 2) + tearY)
            .allowsHitTesting(false)
    }

    // MARK: - Drag gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isTriggered else { return }
                tearProgress = min(max(value.translation.width / (packWidth * 0.65), 0), 1)
            }
            .onEnded { value in
                guard !isTriggered else { return }
                if value.translation.width > packWidth * 0.4 {
                    triggerOpen()
                } else {
                    withAnimation(.spring()) { tearProgress = 0 }
                }
            }
    }

    // MARK: - Opening sequence

    private func triggerOpen() {
        isTriggered = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            bottomFalling = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onOpened()
        }
    }
}
