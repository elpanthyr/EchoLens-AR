import SwiftUI

@main
struct EchoLensApp: App {
    @State private var soundManager = SoundAnalyzerManager()
    @State private var anchorEngine = SpatialAnchorEngine()
    @State private var visionProcessor = VisionProcessor()
    @State private var spatialSimulator = SpatialAudioSimulator()
    @State private var alertPlayer = AlertSoundPlayer()
    @State private var hapticEngine = HapticEngine()
    @State private var customSoundStore = CustomSoundStore()

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("runInBackground") private var runInBackground = true

    var body: some Scene {
        WindowGroup {
            ContentView(
                soundManager: soundManager,
                anchorEngine: anchorEngine,
                visionProcessor: visionProcessor,
                spatialSimulator: spatialSimulator,
                alertPlayer: alertPlayer,
                hapticEngine: hapticEngine,
                customSoundStore: customSoundStore
            )
            .environment(\.deviceLayout, DeviceLayout.default)
            .preferredColorScheme(.dark)
            .tint(Color(hue: 0.55, saturation: 0.7, brightness: 0.9))
            .onAppear {
                spatialSimulator.soundManager = soundManager
                soundManager.customSoundStore = customSoundStore

                alertPlayer.setup()
                hapticEngine.setup()

                soundManager.onSoundDetected = { [alertPlayer, hapticEngine] sound in
                    alertPlayer.playAlert(for: sound)
                    hapticEngine.playHaptic(for: sound)
                }

                #if targetEnvironment(simulator)
                spatialSimulator.start()
                #endif
            }
            .onChange(of: scenePhase) { _, newPhase in
                soundManager.handleScenePhase(
                    isActive: newPhase == .active,
                    runInBackground: runInBackground
                )
            }
        }
    }
}
