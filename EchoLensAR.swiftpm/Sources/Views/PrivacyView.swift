import SwiftUI

struct SettingsPrivacyView: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Bindable var spatialSimulator: SpatialAudioSimulator
    @Bindable var alertPlayer: AlertSoundPlayer
    @Bindable var hapticEngine: HapticEngine
    @Bindable var customSoundStore: CustomSoundStore
    @Environment(\.deviceLayout) var layout

    @State private var showLockScreenPreview = false
    @State private var showAddSound = false
    @AppStorage("runInBackground") private var runInBackground = true

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: layout.sectionSpacing) {
                        demoSettingsSection
                        activeAlertsSection
                        heroSection
                        privacyCards
                        howItWorksSection
                        footerSection
                    }
                    .padding(.horizontal, layout.pagePadding)
                    .padding(.top, 12)
                    .padding(.bottom, layout.tabBarBottomPadding)
                    .adaptiveWidth()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showLockScreenPreview) {
                LockScreenPreview(soundManager: soundManager)
            }
            .sheet(isPresented: $showAddSound) {
                AddSoundView(store: customSoundStore, soundManager: soundManager)
            }
        }
    }

    private var demoSettingsSection: some View {
        VStack(spacing: round(12 * layout.scale)) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: layout.settingIcon, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("Demo Features")
                    .font(.system(size: layout.title * 0.75, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
            }

            settingRow(
                icon: "speaker.wave.3.fill",
                iconColor: .blue,
                title: "Spatial Audio Demo",
                subtitle: "Plays 3D-positioned tones and simulates detection",
                trailing: {
                    AnyView(
                        Toggle("", isOn: Binding(
                            get: { spatialSimulator.isActive },
                            set: { enabled in
                                if enabled { spatialSimulator.start() }
                                else { spatialSimulator.stop() }
                            }
                        ))
                        .labelsHidden()
                    )
                }
            )

            settingRow(
                icon: "bell.and.waves.left.and.right.fill",
                iconColor: .orange,
                title: "Alert Sounds",
                subtitle: "Play audible chimes when sounds are detected",
                trailing: {
                    AnyView(
                        Toggle("", isOn: Binding(
                            get: { alertPlayer.isEnabled },
                            set: { alertPlayer.isEnabled = $0 }
                        ))
                        .labelsHidden()
                    )
                }
            )

            settingRow(
                icon: "iphone.radiowaves.left.and.right",
                iconColor: .green,
                title: "Haptic Vibration",
                subtitle: "Vibrate device when sounds are detected",
                trailing: {
                    AnyView(
                        Toggle("", isOn: Binding(
                            get: { hapticEngine.isEnabled },
                            set: { hapticEngine.isEnabled = $0 }
                        ))
                        .labelsHidden()
                    )
                }
            )

            settingRow(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .indigo,
                title: "Run in Background",
                subtitle: "Continue detecting sounds while app is minimized",
                trailing: {
                    AnyView(
                        Toggle("", isOn: $runInBackground)
                            .labelsHidden()
                    )
                }
            )

            Button {
                showAddSound = true
            } label: {
                settingRow(
                    icon: "plus.circle.fill",
                    iconColor: .mint,
                    title: "Add Custom Sound Alert",
                    subtitle: "Browse \(CustomSoundStore.allClassifierLabels.count)+ sound types from Apple ML",
                    trailing: {
                        AnyView(
                            Image(systemName: "chevron.right")
                                .font(.system(size: layout.subtitle, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        )
                    }
                )
            }

            Button {
                showLockScreenPreview = true
            } label: {
                settingRow(
                    icon: "lock.fill",
                    iconColor: .purple,
                    title: "Preview Lock Screen",
                    subtitle: "See how alerts appear on the iOS Lock Screen",
                    trailing: {
                        AnyView(
                            Image(systemName: "chevron.right")
                                .font(.system(size: layout.subtitle, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        )
                    }
                )
            }
        }
    }

    private var activeAlertsSection: some View {
        VStack(spacing: round(12 * layout.scale)) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: layout.settingIcon, weight: .semibold))
                    .foregroundStyle(.indigo)
                Text("Active Alerts")
                    .font(.system(size: layout.title * 0.75, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(SoundCategory.allCases.count + customSoundStore.customCategories.count)")
                    .font(.system(size: layout.subtitle, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ForEach(SoundCategory.allCases, id: \.self) { cat in
                HStack(spacing: 10) {
                    Image(systemName: cat.sfSymbol)
                        .font(.system(size: layout.caption + 2, weight: .bold))
                        .foregroundStyle(cat.color)
                        .frame(width: round(28 * layout.scale), height: round(28 * layout.scale))
                        .background(cat.color.opacity(0.15), in: Circle())
                    Text(cat.displayName)
                        .font(.system(size: layout.body, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Built-in")
                        .font(.system(size: layout.tiny, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }

            ForEach(customSoundStore.customCategories) { custom in
                HStack(spacing: 10) {
                    Image(systemName: custom.sfSymbol)
                        .font(.system(size: layout.caption + 2, weight: .bold))
                        .foregroundStyle(custom.color)
                        .frame(width: round(28 * layout.scale), height: round(28 * layout.scale))
                        .background(custom.color.opacity(0.15), in: Circle())
                    Text(custom.displayName)
                        .font(.system(size: layout.body, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()

                    Button {
                        soundManager.queueCustomAlertForDemo(custom)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: round(18 * layout.scale)))
                            .foregroundStyle(.green)
                    }

                    Button {
                        withAnimation { customSoundStore.removeCategory(id: custom.id) }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: round(18 * layout.scale)))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius, padding: layout.cardPadding * 1.25)
    }

    private func settingRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: layout.cardPadding) {
            Image(systemName: icon)
                .font(.system(size: layout.settingIcon, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: layout.settingIconBG, height: layout.settingIconBG)
                .background(iconColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: layout.subtitle + 1, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: layout.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing()
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius * 0.8, padding: layout.cardPadding)
    }

    private var heroSection: some View {
        VStack(spacing: layout.cardPadding) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.55, saturation: 0.6, brightness: 0.7),
                                Color(hue: 0.65, saturation: 0.5, brightness: 0.4)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: round(50 * layout.scale)
                        )
                    )
                    .frame(width: round(80 * layout.scale), height: round(80 * layout.scale))

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: round(36 * layout.scale)))
                    .foregroundStyle(.white)
            }

            Text("Your Privacy, Protected")
                .font(.system(size: layout.title * 0.9, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("EchoLens AR processes everything on your device.\nNo data ever leaves your iPhone or iPad.")
                .font(.system(size: layout.subtitle, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius * 1.2, padding: layout.cardPadding * 1.5)
    }

    private var privacyCards: some View {
        VStack(spacing: round(12 * layout.scale)) {
            PrivacyCardRow(
                icon: "mic.slash.fill", iconColor: .red,
                title: "No Audio Recorded",
                description: "Microphone audio is analyzed in real-time and immediately discarded."
            )
            PrivacyCardRow(
                icon: "icloud.slash.fill", iconColor: .orange,
                title: "No Data Uploaded",
                description: "All ML models run locally using Apple's on-device frameworks."
            )
            PrivacyCardRow(
                icon: "cpu.fill", iconColor: .blue,
                title: "On-Device AI",
                description: "Sound classification uses Apple's SoundAnalysis framework with the Neural Engine."
            )
            PrivacyCardRow(
                icon: "eye.slash.fill", iconColor: .purple,
                title: "Camera Stays Private",
                description: "AR camera frames are processed for object detection only and never stored."
            )
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: layout.cardPadding) {
            Text("How It Works")
                .font(.system(size: layout.title * 0.75, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: round(12 * layout.scale)) {
                ProcessStep(number: 1, title: "Listen",
                    description: "Microphone audio streams through Apple's SoundAnalysis classifier")
                ProcessStep(number: 2, title: "Classify",
                    description: "Neural Engine identifies sirens, doorbells, baby crying, and smoke alarms")
                ProcessStep(number: 3, title: "Verify",
                    description: "Vision framework checks the camera for matching visual objects")
                ProcessStep(number: 4, title: "Display",
                    description: "AR overlays show alerts in 3D space — or as edge glow indicators if off-screen")
            }
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius, padding: layout.cardPadding * 1.25)
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "apple.logo")
                .font(.system(size: layout.settingIcon))
                .foregroundStyle(.secondary)

            Text("Built with Apple's on-device ML frameworks")
                .font(.system(size: layout.caption, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.6, saturation: 0.12, brightness: 0.10),
                Color(hue: 0.7, saturation: 0.15, brightness: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct PrivacyCardRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Environment(\.deviceLayout) var layout

    var body: some View {
        HStack(alignment: .top, spacing: layout.cardPadding) {
            Image(systemName: icon)
                .font(.system(size: layout.settingIcon, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: layout.settingIconBG, height: layout.settingIconBG)
                .background(iconColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: layout.subtitle + 1, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: layout.caption + 1, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }

            Spacer()
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius * 0.8, padding: layout.cardPadding)
        .accessibilityElement(children: .combine)
    }
}

private struct ProcessStep: View {
    let number: Int
    let title: String
    let description: String
    @Environment(\.deviceLayout) var layout

    var body: some View {
        HStack(alignment: .top, spacing: round(12 * layout.scale)) {
            Text("\(number)")
                .font(.system(size: layout.subtitle, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: round(26 * layout.scale), height: round(26 * layout.scale))
                .background(Circle().fill(Color.accentColor.gradient))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: layout.subtitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: layout.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Settings & Privacy") {
    SettingsPrivacyView(
        soundManager: SoundAnalyzerManager(),
        spatialSimulator: SpatialAudioSimulator(),
        alertPlayer: AlertSoundPlayer(),
        hapticEngine: HapticEngine(),
        customSoundStore: CustomSoundStore()
    )
    .preferredColorScheme(.dark)
}
