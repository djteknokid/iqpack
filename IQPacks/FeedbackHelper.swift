import AudioToolbox
import UIKit
import AVFoundation

enum FeedbackHelper {

    private static var players: [String: AVAudioPlayer] = [:]

    static func configureAudioSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
            // Pre-generate all tones so first tap has no delay
            preload()
        }
    }

    private static func preload() {
        _ = player(key: "tap",     frequency: 1400, duration: 0.08, volume: 0.7)
        _ = player(key: "tick",    frequency: 1600, duration: 0.05, volume: 0.6)
        _ = player(key: "correct", frequency: 880,  duration: 0.18, volume: 0.8)
        _ = player(key: "correct2",frequency: 1320, duration: 0.22, volume: 0.75)
        _ = player(key: "wrong",   frequency: 220,  duration: 0.25, volume: 0.7)
        _ = player(key: "wrong2",  frequency: 180,  duration: 0.2,  volume: 0.65)
        _ = player(key: "match",   frequency: 660,  duration: 0.12, volume: 0.7)
    }

    // Returns a ready-to-play AVAudioPlayer backed by a generated sine wave
    private static func player(key: String, frequency: Double, duration: Double, volume: Float) -> AVAudioPlayer? {
        if let existing = players[key] { return existing }
        guard let data = generateWav(frequency: frequency, duration: duration, volume: volume),
              let p = try? AVAudioPlayer(data: data) else { return nil }
        p.volume = 1.0
        p.prepareToPlay()
        players[key] = p
        return p
    }

    // Generate a raw WAV in memory — no file, no bundle needed
    private static func generateWav(frequency: Double, duration: Double, volume: Float) -> Data? {
        let sampleRate: Int = 44100
        let numSamples = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / Double(sampleRate)
            let envelope = exp(-t * 10.0)          // exponential decay
            let attack = min(1.0, t / 0.005)        // 5ms attack
            let sine = sin(2.0 * .pi * frequency * t)
            let value = sine * envelope * attack * Double(volume)
            samples[i] = Int16(clamping: Int(value * Double(Int16.max)))
        }

        // Build WAV header
        let dataSize = numSamples * 2
        var wav = Data()
        func appendUInt32(_ v: UInt32) { var x = v.littleEndian; wav.append(contentsOf: withUnsafeBytes(of: &x, Array.init)) }
        func appendUInt16(_ v: UInt16) { var x = v.littleEndian; wav.append(contentsOf: withUnsafeBytes(of: &x, Array.init)) }

        wav.append(contentsOf: "RIFF".utf8)
        appendUInt32(UInt32(36 + dataSize))
        wav.append(contentsOf: "WAVE".utf8)
        wav.append(contentsOf: "fmt ".utf8)
        appendUInt32(16)           // chunk size
        appendUInt16(1)            // PCM
        appendUInt16(1)            // mono
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))  // byte rate
        appendUInt16(2)            // block align
        appendUInt16(16)           // bits per sample
        wav.append(contentsOf: "data".utf8)
        appendUInt32(UInt32(dataSize))
        samples.withUnsafeBytes { wav.append(contentsOf: $0) }

        return wav
    }

    // MARK: - Public API

    static func correct() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let light = UIImpactFeedbackGenerator(style: .light)
        heavy.prepare(); medium.prepare(); light.prepare()
        AudioServicesPlaySystemSound(1166)
        heavy.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { medium.impactOccurred(intensity: 0.8) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { light.impactOccurred(intensity: 0.6) }
    }

    static func wrong() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        AudioServicesPlaySystemSound(1167)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
        play("tap")
    }

    static func select() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
        AudioServicesPlaySystemSound(1118)
    }

    static func tick() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
        play("tick")
    }

    static func match() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        play("match")
    }

    private static func play(_ key: String) {
        guard let p = players[key] else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            p.currentTime = 0
            p.play()
        }
    }
}
