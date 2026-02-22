import Vision
import CoreImage
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Observation

@Observable
@MainActor
final class VisionProcessor {

    var lastFusionResult: FusionResult?
    var isProcessing: Bool = false

    func analyzeFrame(for sound: DetectedSound, pixelBuffer: CVPixelBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        lastFusionResult = performObjectDetection(for: sound, in: pixelBuffer)
        isProcessing = false
    }

    private func performObjectDetection(for sound: DetectedSound, in pixelBuffer: CVPixelBuffer) -> FusionResult {

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([request])

            if let observations = request.results {
                let matchingLabels = labelsForCategory(sound.category)

                for observation in observations {
                    let identifier = observation.identifier.lowercased()
                    let confidence = observation.confidence

                    if matchingLabels.contains(where: { identifier.contains($0) }) && confidence > 0.3 {
                        return FusionResult(
                            sound: sound,
                            isVisuallyConfirmed: true,
                            boundingBox: nil
                        )
                    }
                }
            }
        } catch {
            print("[EchoLens] Vision processing error: \(error.localizedDescription)")
        }

        return FusionResult(
            sound: sound,
            isVisuallyConfirmed: false,
            boundingBox: nil
        )
    }

    private func labelsForCategory(_ category: SoundCategory) -> [String] {
        switch category {
        case .siren:
            return ["ambulance", "fire truck", "police", "emergency", "vehicle"]
        case .doorbell:
            return ["door", "entrance", "bell", "intercom"]
        case .babyCrying:
            return ["baby", "infant", "child", "person", "face"]
        case .smokeAlarm:
            return ["smoke", "alarm", "detector", "fire", "ceiling"]
        case .humanScreaming:
            return ["person", "face", "human", "crowd"]
        case .childrenShouting:
            return ["child", "person", "playground", "school", "face"]
        }
    }

    func generateDemoFusionResult(for sound: DetectedSound) -> FusionResult {
        let confirmed = Bool.random()
        return FusionResult(
            sound: sound,
            isVisuallyConfirmed: confirmed,
            boundingBox: confirmed ? CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4) : nil
        )
    }
}
