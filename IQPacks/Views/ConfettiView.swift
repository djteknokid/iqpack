import SwiftUI

// MARK: - Shared glow colors

private let glowColors: [Color] = [
    .cyan, .yellow, .pink, .green, .purple, .orange, .mint, .white
]

// MARK: - Success effect (confetti + fireworks)

struct SuccessEffectView: View {
    var body: some View {
        ZStack {
            ConfettiView()
            FireworksView()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Confetti

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let shape: ConfettiShape
    let rotationSpeed: Double
    let delay: Double
    let hSpeed: CGFloat
}

private enum ConfettiShape { case circle, rect, star }

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var trigger = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiParticleView(particle: p, screenHeight: geo.size.height, trigger: trigger)
                }
            }
            .onAppear {
                particles = (0..<60).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        color: glowColors.randomElement()!,
                        size: CGFloat.random(in: 5...11),
                        shape: [ConfettiShape.circle, .rect, .star].randomElement()!,
                        rotationSpeed: Double.random(in: 180...540),
                        delay: Double.random(in: 0...0.4),
                        hSpeed: CGFloat.random(in: -40...40)
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { trigger = true }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let screenHeight: CGFloat
    let trigger: Bool
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.2

    var body: some View {
        Group {
            switch particle.shape {
            case .circle: Circle()
            case .rect: RoundedRectangle(cornerRadius: 2).frame(width: particle.size * 0.6, height: particle.size)
            case .star: Image(systemName: "star.fill").resizable()
            }
        }
        .frame(width: particle.size, height: particle.size)
        .foregroundStyle(particle.color)
        .shadow(color: particle.color.opacity(0.9), radius: 6)
        .shadow(color: particle.color.opacity(0.5), radius: 12)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(x: particle.x + offsetX, y: offsetY)
        .onAppear { if trigger { animate() } }
        .onChange(of: trigger) { if trigger { animate() } }
    }

    private func animate() {
        offsetY = -30; opacity = 0; scale = 0.2; rotation = 0
        let dur = Double.random(in: 1.6...2.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
            withAnimation(.easeOut(duration: 0.15)) { opacity = 1; scale = 1 }
            withAnimation(.easeIn(duration: dur)) {
                offsetY = screenHeight + 60
                offsetX = particle.hSpeed * CGFloat(dur)
                rotation = particle.rotationSpeed
            }
            withAnimation(.easeIn(duration: 0.5).delay(dur - 0.5)) { opacity = 0 }
        }
    }
}

// MARK: - Fireworks

private struct FireworkShot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let delay: Double
}

private struct FireworkSpark: Identifiable {
    let id = UUID()
    let angle: Double
    let speed: CGFloat
    let size: CGFloat
}

struct FireworksView: View {
    @State private var shots: [FireworkShot] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(shots) { shot in
                    FireworkView(shot: shot)
                }
            }
            .onAppear {
                shots = (0..<5).map { i in
                    FireworkShot(
                        x: CGFloat.random(in: geo.size.width * 0.15 ... geo.size.width * 0.85),
                        y: CGFloat.random(in: geo.size.height * 0.1 ... geo.size.height * 0.45),
                        color: glowColors.randomElement()!,
                        delay: Double(i) * 0.55
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FireworkView: View {
    let shot: FireworkShot
    @State private var sparks: [FireworkSpark] = []
    @State private var triggered = false

    var body: some View {
        ZStack {
            ForEach(sparks) { spark in
                FireworkSparkView(spark: spark, origin: CGPoint(x: shot.x, y: shot.y),
                                  color: shot.color, triggered: triggered)
            }
        }
        .onAppear {
            sparks = (0..<24).map { i in
                FireworkSpark(
                    angle: Double(i) / 24.0 * 360.0,
                    speed: CGFloat.random(in: 60...130),
                    size: CGFloat.random(in: 3...7)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + shot.delay) {
                triggered = true
            }
        }
    }
}

private struct FireworkSparkView: View {
    let spark: FireworkSpark
    let origin: CGPoint
    let color: Color
    let triggered: Bool

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: spark.size, height: spark.size)
            .shadow(color: color.opacity(0.95), radius: 5)
            .shadow(color: color.opacity(0.6), radius: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: origin.x + x, y: origin.y + y)
            .onAppear { if triggered { burst() } }
            .onChange(of: triggered) { if triggered { burst() } }
    }

    private func burst() {
        opacity = 1; scale = 1; x = 0; y = 0
        let rad = spark.angle * .pi / 180
        let dx = cos(rad) * spark.speed
        let dy = sin(rad) * spark.speed
        withAnimation(.easeOut(duration: 0.7)) {
            x = dx; y = dy
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.35)) {
            opacity = 0; scale = 0.3
        }
    }
}
