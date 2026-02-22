@preconcurrency import AVFoundation
import Observation

@Observable
@MainActor
final class AlertSoundPlayer {

    var isEnabled: Bool = true
    var volume: Float = 1.0

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var stopTimers: [String: Timer] = [:]

    func setup() {
        for category in SoundCategory.allCases {
            let wavData = generateWAV(for: category)
            do {
                let player = try AVAudioPlayer(data: wavData)
                player.volume = volume
                player.prepareToPlay()
                audioPlayers[category.rawValue] = player
            } catch {
                print("[EchoLens] Alert player setup error for \(category): \(error)")
            }
        }
    }

    func playAlert(for sound: DetectedSound) {
        guard isEnabled else { return }

        if audioPlayers.isEmpty { setup() }

        let identifier = sound.customDisplayName ?? sound.category.rawValue

        if audioPlayers[identifier] == nil {
            if let customName = sound.customDisplayName {
                let wavData = generateCustomWAV(for: customName)
                do {
                    let player = try AVAudioPlayer(data: wavData)
                    player.volume = volume
                    player.prepareToPlay()
                    audioPlayers[identifier] = player
                } catch {
                    print("[EchoLens] Custom alert player setup error for \(customName): \(error)")
                }
            } else {
                let wavData = generateWAV(for: sound.category)
                do {
                    let player = try AVAudioPlayer(data: wavData)
                    player.volume = volume
                    player.prepareToPlay()
                    audioPlayers[identifier] = player
                } catch {
                     print("[EchoLens] Alert player setup error for \(sound.category): \(error)")
                }
            }
        }

        guard let player = audioPlayers[identifier] else { return }

        stopTimers[identifier]?.invalidate()

        player.volume = volume
        player.currentTime = 0
        player.numberOfLoops = -1
        player.play()

        let totalDuration = sound.category.totalAlertDuration
        stopTimers[identifier] = Timer.scheduledTimer(withTimeInterval: totalDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopAlert(identifier: identifier)
            }
        }
    }

    func stopAlert(identifier: String) {
        audioPlayers[identifier]?.stop()
        stopTimers[identifier]?.invalidate()
        stopTimers.removeValue(forKey: identifier)
    }

    func stopAll() {
        for (identifier, _) in audioPlayers {
            stopAlert(identifier: identifier)
        }
    }

    private func generateWAV(for category: SoundCategory) -> Data {
        let sampleRate: Double = 44100
        let duration: Double
        let samples: [Float]

        switch category {
        case .doorbell:
            duration = category.chimeDuration
            samples = generateDingDong(sampleRate: sampleRate, duration: duration)
        case .siren:
            duration = category.chimeDuration
            samples = generateSweep(sampleRate: sampleRate, duration: duration,
                                     startFreq: 440, endFreq: 880)
        case .babyCrying:
            duration = category.chimeDuration
            samples = generateTripleChime(sampleRate: sampleRate, duration: duration)
        case .smokeAlarm:
            duration = category.chimeDuration
            samples = generateStaccato(sampleRate: sampleRate, duration: duration, freq: 2600)
        case .humanScreaming:
            duration = category.chimeDuration
            samples = generateDescendingSweep(sampleRate: sampleRate, duration: duration,
                                              startFreq: 1200, endFreq: 400)
        case .childrenShouting:
            duration = category.chimeDuration
            samples = generateAlternatingBells(sampleRate: sampleRate, duration: duration)
        }

        return createWAVData(samples: samples, sampleRate: Int(sampleRate))
    }

    private func generateCustomWAV(for name: String) -> Data {
        let sampleRate: Double = 44100
        let lowered = name.lowercased()
        let seed = abs(name.hashValue)
        let samples: [Float]

        if lowered.contains("gun") || lowered.contains("explosion") || lowered.contains("shatter") || lowered.contains("crash") {
            let duration: Double = 0.5
            let startFreq = 800.0 + Double(seed % 400)
            samples = generateStaccato(sampleRate: sampleRate, duration: duration, freq: startFreq)
        } else if lowered.contains("engine") || lowered.contains("motor") || lowered.contains("machine") || lowered.contains("truck") || lowered.contains("train") {
            let duration: Double = 2.0
            let startFreq = 100.0 + Double(seed % 100)
            let endFreq = 150.0 + Double(seed % 100)
            samples = generateSweep(sampleRate: sampleRate, duration: duration, startFreq: startFreq, endFreq: endFreq)
        } else if lowered.contains("alarm") || lowered.contains("siren") || lowered.contains("emergency") || lowered.contains("horn") || lowered.contains("alert") {
            let duration: Double = 2.0
            let startFreq = 600.0 + Double(seed % 200)
            let endFreq = 1200.0 + Double(seed % 400)
            samples = generateAlternatingBells(sampleRate: sampleRate, duration: duration, freq1: startFreq, freq2: endFreq)
        } else if lowered.contains("car") || lowered.contains("vehicle") {
            let duration: Double = 1.0
            let freq = 400.0 + Double(seed % 300)
            samples = generateSweep(sampleRate: sampleRate, duration: duration, startFreq: freq, endFreq: freq + 50)
        } else if lowered.contains("bird") || lowered.contains("chirp") || lowered.contains("dog") || lowered.contains("bark") || lowered.contains("cat") || lowered.contains("meow") {
            let duration: Double = 0.8
            let startFreq = lowered.contains("bird") ? 2000.0 : 500.0
            samples = generateStaccato(sampleRate: sampleRate, duration: duration, freq: startFreq + Double(seed % 300))
        } else if lowered.contains("scream") || lowered.contains("shout") || lowered.contains("yell") || lowered.contains("cry") {
            let duration: Double = 1.5
            let startFreq = 800.0 + Double(seed % 200)
            let endFreq = 400.0 + Double(seed % 200)
            samples = generateDescendingSweep(sampleRate: sampleRate, duration: duration, startFreq: startFreq, endFreq: endFreq)
        } else {
            let method = seed % 4
            let duration: Double = 1.8
            let startFreq = Double(400 + (seed % 600))
            let endFreq = Double(800 + (seed % 1000))
            
            switch method {
            case 0:
                samples = generateSweep(sampleRate: sampleRate, duration: duration, startFreq: startFreq, endFreq: endFreq)
            case 1:
                samples = generateAlternatingBells(sampleRate: sampleRate, duration: duration, freq1: startFreq, freq2: endFreq)
            case 2:
                samples = generateStaccato(sampleRate: sampleRate, duration: duration, freq: startFreq)
            default:
                samples = generateDingDong(sampleRate: sampleRate, duration: duration, freq1: endFreq, freq2: startFreq)
            }
        }
        
        return createWAVData(samples: samples, sampleRate: Int(sampleRate))
    }

    private func generateDingDong(sampleRate: Double, duration: Double, freq1: Double = 880, freq2: Double = 660) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)
        let transition = Int(Double(count) * 0.4)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            let freq: Double = i < transition ? freq1 : freq2
            let halfIdx = i < transition ? i : i - transition
            let halfLen = i < transition ? transition : count - transition
            let decay = exp(-3.0 * Double(halfIdx) / Double(halfLen))
            let envelope = Float(decay) * 0.45
            samples[i] = Float(sin(2.0 * .pi * freq * t)) * envelope
        }
        return samples
    }

    private func generateSweep(sampleRate: Double, duration: Double,
                                startFreq: Double, endFreq: Double) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)

        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let sweepPos = sin(2.0 * .pi * 1.5 * progress)
            let freq = startFreq + (endFreq - startFreq) * (0.5 + 0.5 * sweepPos)
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - 0.5 * progress) * 0.4
            samples[i] = Float(sin(2.0 * .pi * freq * t)) * envelope
        }
        return samples
    }

    private func generateTripleChime(sampleRate: Double, duration: Double) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)
        let chimeLength = Int(sampleRate * 0.3)
        let chimeGap = Int(sampleRate * 0.55)

        for chime in 0..<3 {
            let start = chime * chimeGap
            for i in 0..<chimeLength {
                let idx = start + i
                guard idx < count else { break }
                let t = Double(idx) / sampleRate
                let decay = exp(-4.0 * Double(i) / Double(chimeLength))
                let envelope = Float(decay) * 0.4
                samples[idx] = Float(sin(2.0 * .pi * 1047.0 * t)) * envelope
            }
        }
        return samples
    }

    private func generateStaccato(sampleRate: Double, duration: Double, freq: Double) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)
        let onSamples = Int(sampleRate * 0.04)
        let cycleSamples = Int(sampleRate * 0.07)

        for i in 0..<count {
            let posInCycle = i % cycleSamples
            if posInCycle < onSamples {
                let t = Double(i) / sampleRate
                let globalEnvelope = Float(1.0 - Double(i) / Double(count)) * 0.4
                samples[i] = Float(sin(2.0 * .pi * freq * t)) * globalEnvelope
            }
        }
        return samples
    }

    private func generateDescendingSweep(sampleRate: Double, duration: Double,
                                          startFreq: Double, endFreq: Double) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)

        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let freq = startFreq + (endFreq - startFreq) * progress
            let t = Double(i) / sampleRate
            let tremolo = 0.6 + 0.4 * sin(2.0 * .pi * 6.0 * t)
            let envelope = Float((1.0 - 0.6 * progress) * tremolo) * 0.45
            samples[i] = Float(sin(2.0 * .pi * freq * t)) * envelope
        }
        return samples
    }

    private func generateAlternatingBells(sampleRate: Double, duration: Double, freq1: Double = 880, freq2: Double = 1100) -> [Float] {
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)
        let bellLength = Int(sampleRate * 0.18)
        let bellGap = Int(sampleRate * 0.28)
        let frequencies: [Double] = [freq1, freq2]

        var bellIndex = 0
        var pos = 0
        while pos < count {
            let freq = frequencies[bellIndex % frequencies.count]
            for i in 0..<bellLength {
                let idx = pos + i
                guard idx < count else { break }
                let t = Double(idx) / sampleRate
                let decay = exp(-5.0 * Double(i) / Double(bellLength))
                let envelope = Float(decay) * 0.4
                samples[idx] = Float(sin(2.0 * .pi * freq * t)) * envelope
            }
            pos += bellGap
            bellIndex += 1
        }
        return samples
    }

    private func createWAVData(samples: [Float], sampleRate: Int) -> Data {
        let bytesPerSample = 2
        let numChannels = 1
        let dataSize = samples.count * bytesPerSample
        let fileSize = 44 + dataSize

        var data = Data(capacity: fileSize)

        data.append(contentsOf: "RIFF".utf8)
        data.append(littleEndian: UInt32(fileSize - 8))
        data.append(contentsOf: "WAVE".utf8)

        data.append(contentsOf: "fmt ".utf8)
        data.append(littleEndian: UInt32(16))
        data.append(littleEndian: UInt16(1))
        data.append(littleEndian: UInt16(numChannels))
        data.append(littleEndian: UInt32(sampleRate))
        data.append(littleEndian: UInt32(sampleRate * numChannels * bytesPerSample))
        data.append(littleEndian: UInt16(numChannels * bytesPerSample))
        data.append(littleEndian: UInt16(16))

        data.append(contentsOf: "data".utf8)
        data.append(littleEndian: UInt32(dataSize))

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * Float(Int16.max))
            data.append(littleEndian: int16)
        }

        return data
    }
}

private extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { buffer in
            self.append(contentsOf: buffer)
        }
    }
}
