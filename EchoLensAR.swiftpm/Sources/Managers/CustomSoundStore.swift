import Observation
import Foundation

@Observable
@MainActor
final class CustomSoundStore {

    var customCategories: [CustomSoundCategory] = []

    private let storageKey = "echolens_custom_sounds"

    private let availableSymbols: [String] = [
        "speaker.wave.3.fill", "megaphone.fill", "bell.fill",
        "phone.fill", "horn.fill", "car.fill",
        "bus.fill", "train.side.front.car", "airplane",
        "ferry.fill", "figure.walk", "figure.run",
        "dog.fill", "cat.fill", "bird.fill",
        "hare.fill", "leaf.fill", "drop.fill",
        "bolt.fill", "flame.fill", "hammer.fill",
        "wrench.fill", "key.fill", "lock.fill",
        "timer", "clock.fill", "alarm.fill",
        "deskclock.fill", "stopwatch.fill",
        "waveform.path.ecg", "stethoscope",
        "cross.fill", "staroflife.fill", "heart.fill",
        "hand.raised.fill", "person.fill", "person.2.fill",
        "person.3.fill", "building.fill", "house.fill",
        "power.fill", "lightbulb.fill", "fanblades.fill",
        "washer.fill", "oven.fill",
        "cup.and.saucer.fill", "cloud.rain.fill",
        "wind", "tornado", "snowflake"
    ]

    private let availableHues: [Double] = [
        0.0, 0.05, 0.08, 0.12, 0.15, 0.20, 0.25, 0.30,
        0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70,
        0.75, 0.80, 0.85, 0.90, 0.95
    ]

    static let allClassifierLabels: [String] = [
        "air_horn_and_truck_horn",
        "aircraft",
        "alarm",
        "alarm_clock",
        "ambulance_siren",
        "applause",
        "bark",
        "bell",
        "bicycle_bell",
        "bird",
        "bird_vocalization_and_bird_call_and_bird_song",
        "boiling",
        "bus",
        "car",
        "car_alarm",
        "car_horn_and_honking",
        "cat",
        "chainsaw",
        "children_playing",
        "chime",
        "church_bell",
        "civil_defense_siren",
        "clapping",
        "clock",
        "conversation",
        "cough",
        "crowd",
        "crying_and_sobbing",
        "dog",
        "door",
        "drill",
        "engine",
        "engine_starting",
        "explosion",
        "fire",
        "fire_alarm",
        "fire_engine_siren",
        "firecracker",
        "fireworks",
        "foghorn",
        "glass",
        "growling",
        "gunshot_and_gunfire",
        "hammer",
        "helicopter",
        "howl",
        "knock",
        "laughter",
        "lawn_mower",
        "meow",
        "microwave_oven",
        "motorcycle",
        "police_car_siren",
        "power_tool",
        "rain",
        "rain_on_surface",
        "ringtone",
        "saw",
        "shatter",
        "ship",
        "shout",
        "slam",
        "sneeze",
        "speech",
        "splash_and_splashing",
        "squeal",
        "steam_whistle",
        "telephone",
        "telephone_bell_ringing",
        "thunder",
        "thunderstorm",
        "toilet_flush",
        "traffic_noise_and_roadway_noise",
        "train",
        "train_horn",
        "train_wheels_squealing",
        "truck",
        "vacuum_cleaner",
        "vehicle",
        "walk_and_footsteps",
        "water",
        "water_tap_and_faucet",
        "whimper",
        "whistle",
        "whistling",
        "wind",
        "wind_chime",
        "yell",
    ]

    init() {
        load()
    }

    var builtInIdentifiers: Set<String> {
        var ids = Set<String>()
        for cat in SoundCategory.allCases {
            for id in cat.classificationIdentifiers {
                ids.insert(id)
            }
        }
        return ids
    }

    var addedIdentifiers: Set<String> {
        Set(customCategories.map { $0.classifierIdentifier })
    }

    func searchResults(for query: String) -> [String] {
        let excluded = builtInIdentifiers.union(addedIdentifiers)
        let available = Self.allClassifierLabels.filter { !excluded.contains($0) }
        if query.isEmpty { return available }
        let lowered = query.lowercased()
        return available.filter { $0.replacingOccurrences(of: "_", with: " ").contains(lowered) }
    }

    func addCategory(identifier: String) {
        let displayName = identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        let usedHues = Set(customCategories.map { $0.colorHue })
        let hue = availableHues.first { !usedHues.contains($0) } ?? Double.random(in: 0...1)

        let symbol = Self.icon(for: displayName) ?? {
            let usedSymbols = Set(customCategories.map { $0.sfSymbol })
            return availableSymbols.first { !usedSymbols.contains($0) } ?? "waveform"
        }()

        let category = CustomSoundCategory(
            classifierIdentifier: identifier,
            displayName: displayName,
            sfSymbol: symbol,
            colorHue: hue
        )
        customCategories.append(category)
        save()
    }

    func removeCategory(id: UUID) {
        customCategories.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(customCategories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var decoded = try? JSONDecoder().decode([CustomSoundCategory].self, from: data) else {
            return
        }
        
        for i in 0..<decoded.count {
            if let mappedSymbol = Self.icon(for: decoded[i].displayName) {
                decoded[i].sfSymbol = mappedSymbol
            }
        }
        
        customCategories = decoded
    }

    static func icon(for displayName: String) -> String? {
        let lowered = displayName.lowercased()
        if lowered.contains("gun") || lowered.contains("shoot") || lowered.contains("fire") || lowered.contains("explosion") {
            return "target"
        } else if lowered.contains("car") || lowered.contains("vehicle") || lowered.contains("truck") || lowered.contains("bus") || lowered.contains("horn") || lowered.contains("honk") {
            return "car.fill"
        } else if lowered.contains("bird") || lowered.contains("chirp") {
            return "bird.fill"
        } else if lowered.contains("dog") || lowered.contains("bark") || lowered.contains("growl") || lowered.contains("howl") || lowered.contains("whimper") {
            return "dog.fill"
        } else if lowered.contains("cat") || lowered.contains("meow") {
            return "cat.fill"
        } else if lowered.contains("water") || lowered.contains("drop") || lowered.contains("rain") || lowered.contains("splash") || lowered.contains("flush") || lowered.contains("boil") || lowered.contains("steam") {
            return "drop.fill"
        } else if lowered.contains("alarm") || lowered.contains("siren") || lowered.contains("emergency") || lowered.contains("alert") || lowered.contains("clock") || lowered.contains("timer") {
            return "bell.fill"
        } else if lowered.contains("door") || lowered.contains("knock") {
            return "door.left.hand.open"
        } else if lowered.contains("baby") || lowered.contains("cry") || lowered.contains("sob") {
            return "figure.and.child.holdinghands"
        } else if lowered.contains("scream") || lowered.contains("shout") || lowered.contains("yell") || lowered.contains("speech") || lowered.contains("conversation") || lowered.contains("crowd") || lowered.contains("laugh") || lowered.contains("cough") || lowered.contains("sneeze") {
            return "person.wave.2.fill"
        } else if lowered.contains("engine") || lowered.contains("motor") || lowered.contains("machine") || lowered.contains("tool") || lowered.contains("drill") || lowered.contains("saw") || lowered.contains("hammer") || lowered.contains("wrench") || lowered.contains("vacuum") || lowered.contains("mower") {
            return "wrench.and.screwdriver.fill"
        } else if lowered.contains("music") || lowered.contains("song") || lowered.contains("ringtone") || lowered.contains("chime") || lowered.contains("bell") {
            return "music.note"
        } else if lowered.contains("wind") || lowered.contains("storm") || lowered.contains("thunder") {
            return "wind"
        } else if lowered.contains("train") {
            return "train.side.front.car"
        } else if lowered.contains("glass") || lowered.contains("shatter") {
            return "squareshape.split.2x2"
        } else if lowered.contains("phone") || lowered.contains("telephone") {
            return "phone.fill"
        } else if lowered.contains("aircraft") || lowered.contains("helicopter") || lowered.contains("plane") {
            return "airplane"
        } else if lowered.contains("ship") || lowered.contains("boat") || lowered.contains("ferry") || lowered.contains("foghorn") {
            return "ferry.fill"
        }
        return nil
    }
}
