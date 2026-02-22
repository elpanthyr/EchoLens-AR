import SwiftUI

struct ContentView: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Bindable var anchorEngine: SpatialAnchorEngine
    @Bindable var visionProcessor: VisionProcessor
    @Bindable var spatialSimulator: SpatialAudioSimulator
    @Bindable var alertPlayer: AlertSoundPlayer
    @Bindable var hapticEngine: HapticEngine
    @Bindable var customSoundStore: CustomSoundStore

    @State private var isOnboardingComplete = false
    @State private var selectedTab: AppTab = .ar

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.deviceLayout) var layout

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding && !isOnboardingComplete {
                OnboardingView(
                    soundManager: soundManager,
                    isOnboardingComplete: $isOnboardingComplete
                )
                .transition(.opacity)
                .onChange(of: isOnboardingComplete) { _, completed in
                    if completed {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                mainTabView
                    .transition(.opacity)
                    .onAppear {
                        if !soundManager.isListening {
                            soundManager.startListening()
                        }
                    }
            }
        }
        .animation(.spring(duration: 0.6), value: isOnboardingComplete)
        .animation(.spring(duration: 0.6), value: hasCompletedOnboarding)
    }

    private var mainTabView: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .ar:
                    ARSoundView(
                        soundManager: soundManager,
                        anchorEngine: anchorEngine,
                        visionProcessor: visionProcessor
                    )
                case .sounds:
                    SoundListView(soundManager: soundManager)
                case .settings:
                    SettingsPrivacyView(
                        soundManager: soundManager,
                        spatialSimulator: spatialSimulator,
                        alertPlayer: alertPlayer,
                        hapticEngine: hapticEngine,
                        customSoundStore: customSoundStore
                    )
                }
            }

            VStack {
                Spacer()
                if let message = soundManager.demoQueueMessage {
                    Text(message)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 12)
                }
                floatingTabBar
                    .padding(.bottom, 10)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2), value: soundManager.demoQueueMessage)
    }

    private var floatingTabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: layout.tabIcon, weight: selectedTab == tab ? .bold : .medium))
                            .symbolEffect(.bounce, value: selectedTab == tab)

                        Text(tab.label)
                            .font(.system(size: layout.tabLabel, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? AnyShapeStyle(.thinMaterial)
                            : AnyShapeStyle(.clear),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .accessibilityLabel(tab.accessibilityLabel)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, layout.deviceClass == .iPhone ? 40 : 100)
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case ar
    case sounds
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ar:       return "camera.viewfinder"
        case .sounds:   return "waveform.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .ar:       return "AR View"
        case .sounds:   return "Sounds"
        case .settings: return "Settings"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .ar:       return "Augmented Reality view"
        case .sounds:   return "Detected sounds list"
        case .settings: return "Settings and privacy"
        }
    }
}

#Preview("Content View") {
    ContentView(
        soundManager: SoundAnalyzerManager(),
        anchorEngine: SpatialAnchorEngine(),
        visionProcessor: VisionProcessor(),
        spatialSimulator: SpatialAudioSimulator(),
        alertPlayer: AlertSoundPlayer(),
        hapticEngine: HapticEngine(),
        customSoundStore: CustomSoundStore()
    )
    .preferredColorScheme(.dark)
}
