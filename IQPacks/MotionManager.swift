import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    @Published var tiltX: CGFloat = 0
    @Published var tiltY: CGFloat = 0

    private let manager = CMMotionManager()

    func start() {
        print("🔵🔵🔵 MotionManager.start() called")
        print("🔵 isDeviceMotionAvailable: \(manager.isDeviceMotionAvailable)")
        print("🔵 isGyroAvailable: \(manager.isGyroAvailable)")

        guard manager.isDeviceMotionAvailable else {
            print("🔴 Device motion NOT available — likely simulator")
            return
        }

        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            if let error {
                print("🔴 Motion error: \(error)")
                return
            }
            guard let motion else { return }
            let clamp: (Double) -> CGFloat = { CGFloat(max(-0.5, min(0.5, $0))) }
            let x = clamp(motion.gravity.x)
            let y = clamp(motion.gravity.y - 0.5)
            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.6)) {
                self.tiltX = x
                self.tiltY = y
            }
        }
        print("🟢 Motion updates started")
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        print("🔵 Motion updates stopped")
    }
}
