import Observation
import Foundation

@Observable
@MainActor
final class SpatialAudioSimulator {

    var isActive: Bool = false
    var currentSourceCategory: SoundCategory?
    var currentAzimuth: Double = 0

    private var demoTimer: Timer?

    weak var soundManager: SoundAnalyzerManager?

    private var sequenceIndex: Int = 0
    private let demoSequence: [(SoundCategory, Double)] = [
        (.doorbell,   Double.pi / 4),
        (.siren,      -Double.pi / 2),
        (.babyCrying,  Double.pi * 0.85),
        (.smokeAlarm,  0.0),
        (.siren,      Double.pi * 0.6),
        (.doorbell,   -Double.pi / 4),
    ]

    func start() {
        guard !isActive else { return }
        isActive = true
        sequenceIndex = 0
        startDemoLoop()
    }

    func stop() {
        demoTimer?.invalidate()
        demoTimer = nil
        isActive = false
        currentSourceCategory = nil
    }

    private func startDemoLoop() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            guard isActive else { return }
            playNextInSequence()
        }

        demoTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playNextInSequence()
            }
        }
    }

    private func playNextInSequence() {
        guard isActive else { return }

        let (category, azimuth) = demoSequence[sequenceIndex % demoSequence.count]
        sequenceIndex += 1

        currentSourceCategory = category
        currentAzimuth = azimuth

        soundManager?.injectSpatialDetection(
            category: category,
            confidence: Double.random(in: 0.85...0.96),
            azimuth: azimuth
        )
    }
}
