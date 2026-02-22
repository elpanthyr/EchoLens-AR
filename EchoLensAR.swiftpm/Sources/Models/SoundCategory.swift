import SwiftUI

enum SoundCategory: String, CaseIterable, Identifiable, Sendable {
    case siren
    case doorbell
    case babyCrying
    case smokeAlarm
    case humanScreaming
    case childrenShouting

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .siren:            return "Siren"
        case .doorbell:         return "Doorbell"
        case .babyCrying:       return "Baby Crying"
        case .smokeAlarm:       return "Smoke Alarm"
        case .humanScreaming:   return "Screaming"
        case .childrenShouting: return "Children Shouting"
        }
    }

    var sfSymbol: String {
        switch self {
        case .siren:            return "light.beacon.max.fill"
        case .doorbell:         return "door.left.hand.open"
        case .babyCrying:       return "figure.and.child.holdinghands"
        case .smokeAlarm:       return "smoke.fill"
        case .humanScreaming:   return "exclamationmark.triangle.fill"
        case .childrenShouting: return "figure.2.and.child.holdinghands"
        }
    }

    var color: Color {
        switch self {
        case .siren:            return Color(hue: 0.0, saturation: 0.85, brightness: 0.95)
        case .doorbell:         return Color(hue: 0.58, saturation: 0.70, brightness: 0.90)
        case .babyCrying:       return Color(hue: 0.82, saturation: 0.60, brightness: 0.90)
        case .smokeAlarm:       return Color(hue: 0.08, saturation: 0.90, brightness: 0.95)
        case .humanScreaming:   return Color(hue: 0.95, saturation: 0.80, brightness: 0.90)
        case .childrenShouting: return Color(hue: 0.15, saturation: 0.75, brightness: 0.95)
        }
    }

    var confidenceThreshold: Double {
        return 0.80
    }

    var isCritical: Bool {
        switch self {
        case .siren, .smokeAlarm, .humanScreaming: return true
        case .doorbell, .babyCrying, .childrenShouting: return false
        }
    }

    var hapticDescription: String {
        switch self {
        case .siren:            return "Long ramping waves"
        case .doorbell:         return "Ding-dong double tap"
        case .babyCrying:       return "Sharp intermittent pulses"
        case .smokeAlarm:       return "Rapid staccato bursts"
        case .humanScreaming:   return "Urgent escalating pulse"
        case .childrenShouting: return "Rhythmic bouncing taps"
        }
    }

    var demoAzimuth: Double {
        switch self {
        case .doorbell:         return  Double.pi / 4
        case .siren:            return -Double.pi / 2
        case .babyCrying:       return  Double.pi * 0.85
        case .smokeAlarm:       return  0.0
        case .humanScreaming:   return -Double.pi / 4
        case .childrenShouting: return  Double.pi / 2
        }
    }

    var classificationIdentifiers: [String] {
        switch self {
        case .siren:            return ["siren", "civil_defense_siren", "ambulance_siren", "fire_engine_siren", "police_car_siren"]
        case .doorbell:         return ["doorbell", "door_bell"]
        case .babyCrying:       return ["crying_baby", "baby_crying", "infant_crying"]
        case .smokeAlarm:       return ["smoke_detector", "smoke_alarm", "fire_alarm"]
        case .humanScreaming:   return ["screaming", "human_scream", "scream", "yell"]
        case .childrenShouting: return ["children_shouting", "shouting", "children_playing", "child_speech"]
        }
    }

    var chimeDuration: TimeInterval {
        switch self {
        case .doorbell:         return 1.98
        case .siren:            return 2.64
        case .babyCrying:       return 2.38
        case .smokeAlarm:       return 3.30
        case .humanScreaming:   return 2.64
        case .childrenShouting: return 2.42
        }
    }

    var totalAlertDuration: TimeInterval {
        return chimeDuration + 7.0
    }

    static func from(classificationIdentifier: String) -> SoundCategory? {
        let lowered = classificationIdentifier.lowercased()
        return SoundCategory.allCases.first { category in
            category.classificationIdentifiers.contains(where: { lowered.contains($0) })
        }
    }
}

struct DetectedSound: Identifiable, Sendable, Equatable {
    let id: UUID
    let category: SoundCategory
    let confidence: Double
    let timestamp: Date
    let estimatedAzimuth: Double?
    let customDisplayName: String?
    let customSfSymbol: String?
    let customColorHue: Double?

    init(category: SoundCategory, confidence: Double, estimatedAzimuth: Double? = nil,
         customDisplayName: String? = nil, customSfSymbol: String? = nil, customColorHue: Double? = nil) {
        self.id = UUID()
        self.category = category
        self.confidence = confidence
        self.timestamp = Date()
        self.estimatedAzimuth = estimatedAzimuth
        self.customDisplayName = customDisplayName
        self.customSfSymbol = customSfSymbol
        self.customColorHue = customColorHue
    }

    var displayName: String { customDisplayName ?? category.displayName }
    var sfSymbol: String { customSfSymbol ?? category.sfSymbol }
    var displayColor: Color {
        if let hue = customColorHue {
            return Color(hue: hue, saturation: 0.7, brightness: 0.8)
        }
        return category.color
    }

    var isCritical: Bool {
        if let name = customDisplayName {
            let lowered = name.lowercased()
            if lowered.contains("gun") || lowered.contains("fire") || lowered.contains("alarm") || lowered.contains("siren") || lowered.contains("scream") || lowered.contains("shatter") || lowered.contains("explosion") || lowered.contains("emergency") || lowered.contains("smoke") || lowered.contains("cry") || lowered.contains("break") || lowered.contains("crash") {
                return true
            }
        }
        return category.isCritical
    }

    var hapticDescription: String {
        if let name = customDisplayName {
            let lowered = name.lowercased()
            if lowered.contains("gun") || lowered.contains("explosion") || lowered.contains("shatter") || lowered.contains("crash") {
                return "High intensity sharp burst"
            } else if lowered.contains("engine") || lowered.contains("motor") || lowered.contains("machine") || lowered.contains("truck") || lowered.contains("train") {
                return "Continuous heavy rumble"
            } else if lowered.contains("alarm") || lowered.contains("siren") || lowered.contains("emergency") || lowered.contains("horn") || lowered.contains("alert") {
                return "Rapid strong pulses"
            } else if lowered.contains("car") || lowered.contains("vehicle") {
                return "Steady medium vibration"
            } else if lowered.contains("bird") || lowered.contains("chirp") || lowered.contains("dog") || lowered.contains("bark") || lowered.contains("cat") || lowered.contains("meow") {
                return "Short sequential taps"
            } else if lowered.contains("water") || lowered.contains("drop") || lowered.contains("rain") || lowered.contains("flush") || lowered.contains("splash") {
                return "Light irregular droplets"
            } else if lowered.contains("music") || lowered.contains("song") || lowered.contains("chime") || lowered.contains("bell") || lowered.contains("ringtone") {
                return "Melodic rhythmic pulses"
            } else if lowered.contains("scream") || lowered.contains("shout") || lowered.contains("yell") || lowered.contains("cry") {
                return "Urgent escalating pulse"
            }
            let seed = abs(name.hashValue)
            let method = seed % 3
            switch method {
            case 0: return "Pulsing vibration sequence"
            case 1: return "Rapid continuous feedback"
            default: return "Steady alternating taps"
            }
        }
        return category.hapticDescription
    }
}

struct OffScreenIndicator: Identifiable, Sendable {
    let id: UUID
    let category: SoundCategory
    let edge: ScreenEdge
    let normalizedPosition: CGFloat
    let angle: Double

    enum ScreenEdge: Sendable {
        case top, bottom, leading, trailing
    }
}

struct FusionResult: Sendable {
    let sound: DetectedSound
    let isVisuallyConfirmed: Bool
    let boundingBox: CGRect?
}
