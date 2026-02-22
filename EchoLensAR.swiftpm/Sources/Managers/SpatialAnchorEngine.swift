import SwiftUI
import RealityKit
import Observation
import simd

@Observable
@MainActor
final class SpatialAnchorEngine {

    var activeEntities: [UUID: SoundEntity] = [:]
    var offScreenIndicators: [OffScreenIndicator] = []

    var pendingEntities: [SoundEntity] = []

    var pendingRemovals: [UUID] = []

    var entityLifetime: TimeInterval = 8.0

    func addSoundEntity(for sound: DetectedSound, cameraTransform: simd_float4x4?) {
        pruneExpiredEntities()

        let isDuplicate = activeEntities.values.contains { entity in
            entity.category == sound.category &&
            abs(entity.timestamp.timeIntervalSinceNow) < 2.0
        }
        guard !isDuplicate else { return }

        let entity = createEntity(for: sound, cameraTransform: cameraTransform)
        activeEntities[sound.id] = entity
        pendingEntities.append(entity)
        updateOffScreenIndicators()
    }

    func clearAllEntities() {
        for (id, _) in activeEntities {
            pendingRemovals.append(id)
        }
        activeEntities.removeAll()
        offScreenIndicators.removeAll()
    }

    func acknowledgePendingEntities() {
        pendingEntities.removeAll()
    }

    func acknowledgePendingRemovals() {
        pendingRemovals.removeAll()
    }

    func removeSoundEntity(id: UUID) {
        guard activeEntities[id] != nil else { return }
        pendingRemovals.append(id)
        activeEntities.removeValue(forKey: id)
        updateOffScreenIndicators()
    }

    func pruneExpiredEntities() {
        let now = Date()
        let expired = activeEntities.filter { _, entity in
            now.timeIntervalSince(entity.timestamp) > entityLifetime
        }
        for (id, _) in expired {
            pendingRemovals.append(id)
            activeEntities.removeValue(forKey: id)
        }
    }

    private func createEntity(for sound: DetectedSound, cameraTransform: simd_float4x4?) -> SoundEntity {
        let mesh = MeshResource.generateSphere(radius: 0.08)

        var material = SimpleMaterial()
        let uiColor = UIColor(sound.category.color)
        material.color = .init(tint: uiColor.withAlphaComponent(0.7))

        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        modelEntity.name = "\(sound.category.displayName) detected, confidence \(Int(sound.confidence * 100)) percent"

        let azimuth = sound.estimatedAzimuth ?? Double.random(in: -Double.pi...Double.pi)
        let distance: Float = 2.0
        let x = Float(sin(azimuth)) * distance
        let z = Float(-cos(azimuth)) * distance
        let y: Float = Float.random(in: -0.3...0.5)

        // FinalMatrix = CameraMatrix * TranslationMatrix
        let baseTransform = cameraTransform ?? matrix_identity_float4x4
        
        var translation = matrix_identity_float4x4
        translation.columns.3 = SIMD4<Float>(x, y, z, 1.0)
        
        let finalTransform = simd_mul(baseTransform, translation)

        let anchor = AnchorEntity(.world(transform: finalTransform))
        anchor.addChild(modelEntity)

        addPulseAnimation(to: modelEntity)

        return SoundEntity(
            id: sound.id,
            anchor: anchor,
            modelEntity: modelEntity,
            category: sound.category,
            azimuth: azimuth,
            timestamp: sound.timestamp
        )
    }

    private func addPulseAnimation(to entity: ModelEntity) {
        let originalScale = entity.scale
        let scaledUp = originalScale * 1.3

        var transform = entity.transform
        transform.scale = scaledUp

        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: 0.8,
            timingFunction: .easeInOut
        )
    }

    func updateOffScreenIndicators() {
        offScreenIndicators = activeEntities.compactMap { _, entity in
            let azimuth = entity.azimuth
            let halfFOV = Double.pi / 4

            guard abs(azimuth) > halfFOV else {
                return nil
            }

            let edge: OffScreenIndicator.ScreenEdge
            let normalizedPos: CGFloat

            if azimuth > halfFOV {
                edge = .trailing
                normalizedPos = CGFloat(min(1.0, (azimuth - halfFOV) / (Double.pi - halfFOV)))
            } else {
                edge = .leading
                normalizedPos = CGFloat(min(1.0, (abs(azimuth) - halfFOV) / (Double.pi - halfFOV)))
            }

            return OffScreenIndicator(
                id: entity.id,
                category: entity.category,
                edge: edge,
                normalizedPosition: normalizedPos,
                angle: azimuth
            )
        }
    }
}

struct SoundEntity: Identifiable, @unchecked Sendable {
    let id: UUID
    let anchor: AnchorEntity
    let modelEntity: ModelEntity
    let category: SoundCategory
    let azimuth: Double
    let timestamp: Date
}
