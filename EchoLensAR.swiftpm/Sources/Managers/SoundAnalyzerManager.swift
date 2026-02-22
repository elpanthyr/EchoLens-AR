@preconcurrency import AVFoundation
@preconcurrency import SoundAnalysis
import Observation
import Combine

@Observable
@MainActor
final class SoundAnalyzerManager {

    var detectedSounds: [DetectedSound] = []
    var isListening: Bool = false
    var permissionGranted: Bool = false
    var isDemoMode: Bool = false
    var isSpatialDemoMode: Bool = false
    var errorMessage: String?

    var onSoundDetected: ((DetectedSound) -> Void)?

    var customSoundStore: CustomSoundStore?

    var pendingCustomDemoAlerts: [CustomSoundCategory] = []
    var demoQueueMessage: String?

    private var audioEngine: AVAudioEngine?
    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.echolens.audioAnalysis", qos: .userInitiated)
    private var resultsObserver: SoundResultsObserver?
    private var demoTask: Task<Void, Never>?

    private let maxDetectedSounds = 50

    private var pendingDetections: [String: PendingDetection] = [:]
    private let debounceInterval: TimeInterval = 0.6
    private let requiredConfidence: Double = 0.80

    private let demoSequence: [(SoundCategory, Double)] = [
        (.doorbell,         0.92),
        (.siren,            0.88),
        (.humanScreaming,   0.93),
        (.babyCrying,       0.95),
        (.smokeAlarm,       0.91),
        (.childrenShouting, 0.87),
    ]

    init() {
        #if targetEnvironment(simulator)
        isDemoMode = true
        #endif
    }

    func queueCustomAlertForDemo(_ custom: CustomSoundCategory) {
        pendingCustomDemoAlerts.append(custom)
        demoQueueMessage = "\"\(custom.displayName)\" will be demoed shortly"

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.0))
            if demoQueueMessage?.contains(custom.displayName) == true {
                demoQueueMessage = nil
            }
        }

        if !isListening {
            startDemoMode(skipStandardSequence: true)
        }
    }

    func requestPermission() async {
        #if targetEnvironment(simulator)
        permissionGranted = true
        isDemoMode = true
        return
        #else
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        permissionGranted = granted
        if !granted {
            errorMessage = "Microphone permission is required to detect sounds."
        }
        #endif
    }

    func startListening() {
        guard !isListening else { return }

        if isDemoMode {
            startDemoMode()
            return
        }

        guard permissionGranted else {
            errorMessage = "Microphone permission not granted."
            return
        }

        do {
            try setupAudioSession()
            try setupAudioEngine()
            try setupAnalyzer()
            try audioEngine?.start()
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        if isDemoMode {
            stopDemoMode()
            return
        }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        analyzer = nil
        isListening = false
        pendingDetections.removeAll()
    }

    func injectSpatialDetection(category: SoundCategory, confidence: Double, azimuth: Double) {
        guard !isDemoMode else { return }
        let sound = DetectedSound(
            category: category,
            confidence: confidence,
            estimatedAzimuth: azimuth
        )
        addDetectedSound(sound)
        onSoundDetected?(sound)
    }

    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func handleScenePhase(isActive: Bool, runInBackground: Bool) {
        if isDemoMode { return }
        
        if isActive {
            if !isListening && permissionGranted {
               startListening()
            }
        } else {
            if !runInBackground && isListening {
                stopListening()
            }
        }
    }

    private func setupAudioEngine() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioEngineError.invalidFormat
        }

        let streamAnalyzer = SNAudioStreamAnalyzer(format: format)
        self.analyzer = streamAnalyzer

        nonisolated(unsafe) let analyzerRef = streamAnalyzer
        let queue = self.analysisQueue

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { buffer, time in
            queue.async {
                analyzerRef.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        self.audioEngine = engine
    }

    private func setupAnalyzer() throws {
        guard let analyzer = self.analyzer else { return }

        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTime(seconds: 1.5, preferredTimescale: 48000)
        request.overlapFactor = 0.5

        let observer = SoundResultsObserver { [weak self] extractedResults in
            Task { @MainActor in
                self?.processExtractedResults(extractedResults)
            }
        }
        self.resultsObserver = observer

        try analyzer.add(request, withObserver: observer)
    }

    private func processExtractedResults(_ results: [(identifier: String, confidence: Double)]) {
        let now = Date()

        for (identifier, confidence) in results {
            var builtInCategory = SoundCategory.from(classificationIdentifier: identifier)
            var customInfo: CustomSoundCategory? = nil

            if builtInCategory == nil {
                if let custom = customSoundStore?.customCategories.first(where: { $0.classifierIdentifier == identifier }) {
                    builtInCategory = .doorbell
                    customInfo = custom
                }
            }

            guard let category = builtInCategory else { continue }

            if confidence >= requiredConfidence {
                if let pending = pendingDetections[identifier] {
                    if now.timeIntervalSince(pending.firstSeen) >= debounceInterval {
                        let azimuth = estimateDirection(for: category)
                        let sound = DetectedSound(
                            category: category,
                            confidence: confidence,
                            estimatedAzimuth: azimuth,
                            customDisplayName: customInfo?.displayName,
                            customSfSymbol: customInfo?.sfSymbol,
                            customColorHue: customInfo?.colorHue
                        )
                        addDetectedSound(sound)
                        onSoundDetected?(sound)

                        pendingDetections.removeValue(forKey: identifier)
                    }
                } else {
                    pendingDetections[identifier] = PendingDetection(
                        firstSeen: now,
                        peakConfidence: confidence
                    )
                }
            } else {
                pendingDetections.removeValue(forKey: identifier)
            }
        }

        pendingDetections = pendingDetections.filter { _, pending in
            now.timeIntervalSince(pending.firstSeen) < 3.0
        }
    }

    private func addDetectedSound(_ sound: DetectedSound) {
        detectedSounds.insert(sound, at: 0)
        if detectedSounds.count > maxDetectedSounds {
            detectedSounds = Array(detectedSounds.prefix(maxDetectedSounds))
        }
    }

    private func estimateDirection(for category: SoundCategory) -> Double? {
        return category.demoAzimuth
    }

    private func startDemoMode(skipStandardSequence: Bool = false) {
        isDemoMode = true
        isListening = true
        errorMessage = nil

        demoTask = Task { @MainActor in
            if !skipStandardSequence {
                for (category, confidence) in demoSequence {
                    guard !Task.isCancelled else { break }

                    detectedSounds.removeAll()

                    let sound = DetectedSound(
                        category: category,
                        confidence: confidence,
                        estimatedAzimuth: category.demoAzimuth
                    )
                    addDetectedSound(sound)
                    onSoundDetected?(sound)

                    try? await Task.sleep(for: .seconds(category.totalAlertDuration))
                    guard !Task.isCancelled else { break }

                    detectedSounds.removeAll()

                    try? await Task.sleep(for: .seconds(10.0))
                }
            }

            while !pendingCustomDemoAlerts.isEmpty {
                guard !Task.isCancelled else { break }

                let custom = pendingCustomDemoAlerts.removeFirst()

                detectedSounds.removeAll()

                let sound = DetectedSound(
                    category: .doorbell,
                    confidence: 0.90,
                    estimatedAzimuth: Double.pi / 4,
                    customDisplayName: custom.displayName,
                    customSfSymbol: custom.sfSymbol,
                    customColorHue: custom.colorHue
                )
                addDetectedSound(sound)
                onSoundDetected?(sound)

                try? await Task.sleep(for: .seconds(SoundCategory.doorbell.totalAlertDuration))
                guard !Task.isCancelled else { break }

                detectedSounds.removeAll()

                try? await Task.sleep(for: .seconds(10.0))
            }

            isListening = false
            demoTask = nil
        }
    }

    private func stopDemoMode() {
        demoTask?.cancel()
        demoTask = nil
        isListening = false
        detectedSounds.removeAll()
    }

    private struct PendingDetection {
        let firstSeen: Date
        var peakConfidence: Double
    }

    enum AudioEngineError: Error, LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Audio input format is invalid. Ensure a microphone is connected."
            }
        }
    }
}

private final class SoundResultsObserver: NSObject, SNResultsObserving, Sendable {
    private let handler: @Sendable ([(identifier: String, confidence: Double)]) -> Void

    init(handler: @escaping @Sendable ([(identifier: String, confidence: Double)]) -> Void) {
        self.handler = handler
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        let extracted = classificationResult.classifications.map {
            (identifier: $0.identifier, confidence: Double($0.confidence))
        }
        handler(extracted)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("[EchoLens] Sound analysis error: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("[EchoLens] Sound analysis request completed.")
    }
}
