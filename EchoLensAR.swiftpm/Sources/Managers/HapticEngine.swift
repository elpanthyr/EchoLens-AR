import CoreHaptics
import Observation

@Observable
@MainActor
final class HapticEngine {

    var isEnabled: Bool = true
    private var engine: CHHapticEngine?

    func setup() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            self.engine = engine
        } catch {
            print("[EchoLens] Haptic engine setup failed: \(error)")
        }
    }

    func playHaptic(for sound: DetectedSound) {
        guard isEnabled, let engine = engine else { return }

        let pattern: CHHapticPattern
        do {
            if let customName = sound.customDisplayName {
                pattern = try generateCustomHapticPattern(for: customName)
            } else {
                pattern = try hapticPattern(for: sound.category)
            }
        } catch {
            return
        }

        do {
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[EchoLens] Haptic play failed: \(error)")
        }
    }

    private func generateCustomHapticPattern(for name: String) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        let lowered = name.lowercased()
        let seed = abs(name.hashValue)
        
        let intensity = Float(0.5 + (Double(seed % 50) / 100.0))
        let sharpness = Float(0.4 + (Double(seed % 60) / 100.0))
        
        if lowered.contains("gun") || lowered.contains("explosion") || lowered.contains("shatter") || lowered.contains("crash") {
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0))
        } else if lowered.contains("engine") || lowered.contains("motor") || lowered.contains("machine") || lowered.contains("truck") || lowered.contains("train") {
            events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0, duration: 1.5))
        } else if lowered.contains("alarm") || lowered.contains("siren") || lowered.contains("emergency") || lowered.contains("horn") || lowered.contains("alert") {
            for i in 0..<8 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: Double(i) * 0.2))
            }
        } else if lowered.contains("car") || lowered.contains("vehicle") {
            events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0, duration: 0.8))
        } else if lowered.contains("bird") || lowered.contains("chirp") || lowered.contains("dog") || lowered.contains("bark") || lowered.contains("cat") || lowered.contains("meow") {
            for i in 0..<4 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ], relativeTime: Double(i) * 0.15))
            }
        } else if lowered.contains("water") || lowered.contains("drop") || lowered.contains("rain") || lowered.contains("flush") || lowered.contains("splash") {
            for i in 0..<6 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ], relativeTime: Double(i) * (0.1 + Double.random(in: 0...0.1))))
            }
        } else if lowered.contains("music") || lowered.contains("song") || lowered.contains("chime") || lowered.contains("bell") || lowered.contains("ringtone") {
            for i in 0..<5 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ], relativeTime: Double(i) * 0.3))
            }
        } else if lowered.contains("scream") || lowered.contains("shout") || lowered.contains("yell") || lowered.contains("cry") {
            for i in 0..<5 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + Double(i) * 0.1)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.5 + Double(i) * 0.1))
                ], relativeTime: Double(i) * 0.2))
            }
        } else {
            let method = seed % 3
            switch method {
            case 0:
                let count = 3 + (seed % 4)
                for i in 0..<count {
                    events.append(CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                        ],
                        relativeTime: Double(i) * 0.35
                    ))
                }
            case 1:
                events.append(CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: 0,
                    duration: 1.2
                ))
            default:
                let count = 4 + (seed % 3)
                for i in 0..<count {
                    events.append(CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: i % 2 == 0 ? intensity : intensity * 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                        ],
                        relativeTime: Double(i) * 0.2
                    ))
                }
            }
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }

    private func hapticPattern(for category: SoundCategory) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        switch category {
        case .doorbell:
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.3
            ))

        case .siren:
            for i in 0..<6 {
                events.append(CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + Double(i) * 0.1)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: Double(i) * 0.3,
                    duration: 0.25
                ))
            }

        case .babyCrying:
            for i in 0..<4 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: Double(i) * 0.4
                ))
            }

        case .smokeAlarm:
            for i in 0..<8 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: Double(i) * 0.15
                ))
            }

        case .humanScreaming:
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0,
                duration: 1.5
            ))

        case .childrenShouting:
            for i in 0..<5 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: Double(i) * 0.25
                ))
            }
        }

        return try CHHapticPattern(events: events, parameters: [])
    }
}
