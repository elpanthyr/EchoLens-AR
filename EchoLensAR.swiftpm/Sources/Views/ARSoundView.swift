import SwiftUI
import RealityKit
import ARKit

struct ARSoundView: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Bindable var anchorEngine: SpatialAnchorEngine
    @Bindable var visionProcessor: VisionProcessor
    @Environment(\.deviceLayout) var layout

    @State private var showControls = true
    @State private var centerFlashSound: DetectedSound?
    @State private var notificationBannerSound: DetectedSound?
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            arLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            peripheralGlowOverlay
                .allowsHitTesting(false)

            if let flashSound = centerFlashSound {
                CenterFlashView(category: flashSound.category)
                    .id(flashSound.id)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack {
                if let bannerSound = notificationBannerSound {
                    NotificationBannerView(sound: bannerSound) {
                        withAnimation(.spring(duration: 0.4)) {
                            notificationBannerSound = nil
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }
                Spacer()
            }
            .allowsHitTesting(notificationBannerSound != nil)
            .zIndex(100)

            VStack {
                hudOverlay
                Spacer()
            }
            .padding(.top, 8)
            .allowsHitTesting(false)

            VStack {
                Spacer()
                if let latest = soundManager.detectedSounds.first {
                    HapticFeedbackView(sound: latest)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, round(80 * layout.scale))
            .allowsHitTesting(false)

            if let queueMsg = soundManager.demoQueueMessage {
                VStack {
                    Spacer()
                    Text(queueMsg)
                        .font(.system(size: layout.subtitle, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, round(140 * layout.scale))
                }
                .animation(.spring(duration: 0.4), value: soundManager.demoQueueMessage)
                .allowsHitTesting(false)
                .zIndex(99)
            }
        }
        .safeAreaInset(edge: .bottom) {
            controlBar
                .padding(.bottom, 4)
        }
        .onChange(of: soundManager.detectedSounds) { _, newSounds in
            if let latest = newSounds.first {
                anchorEngine.clearAllEntities()

                anchorEngine.addSoundEntity(for: latest, cameraTransform: nil)

                let azimuth = abs(latest.estimatedAzimuth ?? Double.pi)
                if azimuth < Double.pi / 4 {
                    withAnimation(.easeIn(duration: 0.2)) {
                        centerFlashSound = latest
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.6))
                        withAnimation(.easeOut(duration: 0.3)) {
                            if centerFlashSound?.id == latest.id {
                                centerFlashSound = nil
                            }
                        }
                    }
                }

                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    notificationBannerSound = latest
                }
                Task { @MainActor in
                    let dismissDelay = latest.category.totalAlertDuration
                    try? await Task.sleep(for: .seconds(dismissDelay))
                    withAnimation(.spring(duration: 0.3)) {
                        if notificationBannerSound?.id == latest.id {
                            notificationBannerSound = nil
                        }
                    }
                    anchorEngine.removeSoundEntity(id: latest.id)
                    soundManager.detectedSounds.removeAll { $0.id == latest.id }
                }
            }
        }
    }

    @ViewBuilder
    private var arLayer: some View {
        #if targetEnvironment(simulator)
        simulatorBackground
        #else
        RealityView { content in
        } update: { content in
          
            for entity in anchorEngine.pendingEntities {
                content.add(entity.anchor)
            }
            anchorEngine.acknowledgePendingEntities()

            for id in anchorEngine.pendingRemovals {
                if let entity = anchorEngine.activeEntities[id] {
                    content.remove(entity.anchor)
                }
            }
            anchorEngine.acknowledgePendingRemovals()
        }
        #endif
    }

    private var simulatorBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: 0.6, saturation: 0.15, brightness: 0.12),
                    Color(hue: 0.55, saturation: 0.20, brightness: 0.18),
                    Color(hue: 0.5, saturation: 0.10, brightness: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PerspectiveGridView()
                .opacity(0.08)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Label("DEMO MODE", systemImage: "play.rectangle.fill")
                        .font(.system(size: layout.tiny, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, round(12 * layout.scale))
                        .padding(.vertical, round(6 * layout.scale))
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(.bottom, round(100 * layout.scale))
            }

            simulatorSoundEntities
        }
    }

    private var simulatorSoundEntities: some View {
        GeometryReader { geo in
            ForEach(Array(soundManager.detectedSounds.prefix(1).enumerated()), id: \.element.id) { index, sound in
                SimulatedSoundEntityView(sound: sound)
                    .position(simulatedPosition(for: sound, in: geo.size))
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(duration: 0.6, bounce: 0.3), value: sound.id)
            }
        }
    }

    private func simulatedPosition(for sound: DetectedSound, in size: CGSize) -> CGPoint {
        let azimuth = sound.estimatedAzimuth ?? 0.0
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.3

        let x = center.x + CGFloat(sin(azimuth)) * radius
        let y = center.y - CGFloat(cos(azimuth)) * radius * 0.6

        return CGPoint(x: x, y: y)
    }

    private var hudOverlay: some View {
        VStack(spacing: 8) {
            HStack(spacing: round(6 * layout.scale)) {
                Circle()
                    .fill(soundManager.isListening ? .green : .red)
                    .frame(width: round(8 * layout.scale), height: round(8 * layout.scale))
                    .opacity(soundManager.isListening ? (isBreathing ? 0.5 : 1.0) : 1.0)
                    .scaleEffect(soundManager.isListening ? (isBreathing ? 1.2 : 1.0) : 1.0)
                    .animation(
                        soundManager.isListening ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                        value: isBreathing
                    )
                    .onChange(of: soundManager.isListening) { _, listening in
                        if listening {
                            isBreathing = true
                        } else {
                            isBreathing = false
                        }
                    }
                    .onAppear {
                        if soundManager.isListening {
                            isBreathing = true
                        }
                    }
                Text(soundManager.isListening
                     ? (soundManager.isDemoMode ? "Demo Active" : "Listening")
                     : "Paused")
                    .font(.system(size: layout.hudStatus, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .liquidGlassPill()

            if !soundManager.detectedSounds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: round(8 * layout.scale)) {
                        ForEach(soundManager.detectedSounds.prefix(5)) { sound in
                            SoundPillView(sound: sound)
                        }
                    }
                    .padding(.horizontal, layout.pagePadding)
                }
                .animation(.spring(duration: 0.4), value: soundManager.detectedSounds.count)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sound detection HUD")
    }

    private var peripheralGlowOverlay: some View {
        ZStack {
            ForEach(anchorEngine.offScreenIndicators) { indicator in
                PeripheralGlowView(indicator: indicator)
            }
        }
    }

    private var controlBar: some View {
        HStack(spacing: round(20 * layout.scale)) {
            Button {
                if soundManager.isListening {
                    soundManager.stopListening()
                } else {
                    soundManager.startListening()
                }
            } label: {
                Image(systemName: soundManager.isListening ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: round(24 * layout.scale)))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(soundManager.isListening ? "Pause detection" : "Resume detection")

            Button {
                soundManager.detectedSounds.removeAll()
                anchorEngine.clearAllEntities()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: round(24 * layout.scale)))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Clear all detected sounds")
        }
        .frostedToolbar()
    }
}

private struct PerspectiveGridView: View {
    var body: some View {
        Canvas { context, size in
            let lineColor: Color = .white
            let lineWidth: CGFloat = 0.5
            let horizon = size.height * 0.5
            let gridLines = 12

            for i in 0...gridLines {
                let t = CGFloat(i) / CGFloat(gridLines)
                let topX = size.width * t
                let path = Path { p in
                    p.move(to: CGPoint(x: topX, y: horizon))
                    let spread = (t - 0.5) * 2.0
                    let bottomX = size.width * 0.5 + spread * size.width * 0.8
                    p.addLine(to: CGPoint(x: bottomX, y: size.height))
                }
                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }

            for i in 1...8 {
                let t = CGFloat(i) / 8.0
                let y = horizon + (size.height - horizon) * t * t
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }

            for i in 0...gridLines {
                let t = CGFloat(i) / CGFloat(gridLines)
                let bottomX = size.width * t
                let path = Path { p in
                    p.move(to: CGPoint(x: bottomX, y: horizon))
                    let spread = (t - 0.5) * 2.0
                    let topX = size.width * 0.5 + spread * size.width * 0.8
                    p.addLine(to: CGPoint(x: topX, y: 0))
                }
                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }
        }
    }
}

private struct SimulatedSoundEntityView: View {
    let sound: DetectedSound
    @Environment(\.deviceLayout) var layout

    enum PulsePhase: CaseIterable {
        case small, large
        var scale: CGFloat {
            switch self {
            case .small: return 0.9
            case .large: return 1.1
            }
        }
    }

    var body: some View {
        PhaseAnimator(PulsePhase.allCases) { phase in
            ZStack {
                Circle()
                    .fill(sound.displayColor.opacity(0.2))
                    .frame(width: layout.entityGlow, height: layout.entityGlow)
                    .blur(radius: 12)

                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                sound.displayColor.opacity(0.8),
                                sound.displayColor.opacity(0.4)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: layout.entitySize / 2
                        )
                    )
                    .frame(width: layout.entitySize, height: layout.entitySize)

                Image(systemName: sound.sfSymbol)
                    .font(.system(size: round(20 * layout.scale), weight: .bold))
                    .foregroundStyle(.white)

                Text(sound.displayName)
                    .font(.system(size: layout.tiny, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(y: layout.entitySize * 0.75)
            }
            .scaleEffect(phase.scale)
        } animation: { _ in
            .easeInOut(duration: 1.2)
        }
        .accessibilityLabel("\(sound.displayName) at \(Int(sound.confidence * 100)) percent confidence")
    }
}

#Preview("AR Sound View") {
    ARSoundView(
        soundManager: {
            let m = SoundAnalyzerManager()
            m.isDemoMode = true
            return m
        }(),
        anchorEngine: SpatialAnchorEngine(),
        visionProcessor: VisionProcessor()
    )
    .preferredColorScheme(.dark)
}
