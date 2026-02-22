import SwiftUI

struct OnboardingView: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Binding var isOnboardingComplete: Bool
    @Environment(\.deviceLayout) var layout

    @State private var currentStep = 0
    private let totalSteps = 4

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    featuresStep.tag(1)
                    microphoneStep.tag(2)
                    readyStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.5), value: currentStep)

                bottomControls
                    .padding(.bottom, 40)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: layout.sectionSpacing) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.7, brightness: 0.9),
                                    Color(hue: 0.75, saturation: 0.6, brightness: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: layout.deviceClass == .iPhone ? 2 : 3
                        )
                        .frame(
                            width: layout.onboardingRing(index: i),
                            height: layout.onboardingRing(index: i)
                        )
                        .opacity(0.3 - Double(i) * 0.1)
                }

                Image(systemName: "ear.and.waveform")
                    .font(.system(size: layout.heroIcon))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.55, saturation: 0.7, brightness: 0.9),
                                Color(hue: 0.75, saturation: 0.6, brightness: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("EchoLens AR")
                .font(.system(size: layout.heroTitle, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("See the sounds around you.\nAugmented reality for the hearing-impaired.")
                .font(.system(size: layout.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer()
        }
        .padding(.horizontal, layout.pagePadding)
        .adaptiveWidth()
    }

    private var featuresStep: some View {
        VStack(spacing: layout.sectionSpacing) {
            Spacer()

            Text("What EchoLens Detects")
                .font(.system(size: layout.title, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ForEach(SoundCategory.allCases) { category in
                    HStack(spacing: layout.cardPadding) {
                        Image(systemName: category.sfSymbol)
                            .font(.system(size: layout.listIcon, weight: .semibold))
                            .foregroundStyle(category.color)
                            .frame(width: layout.featureIcon, height: layout.featureIcon)
                            .background(category.color.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.displayName)
                                .font(.system(size: layout.body, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(featureDescription(for: category))
                                .font(.system(size: layout.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .liquidGlassCard(cornerRadius: layout.cardRadius * 0.7, padding: layout.cardPadding * 0.75)
                }
            }

            Spacer()
        }
        .padding(.horizontal, layout.pagePadding)
        .adaptiveWidth()
    }

    private var microphoneStep: some View {
        VStack(spacing: layout.sectionSpacing) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: layout.permissionIcon))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.variableColor.iterative, isActive: true)

            Text("Microphone Access")
                .font(.system(size: layout.title, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("EchoLens needs your microphone to detect\nenvironmental sounds in real-time.\n\nAll audio is processed on-device and\nnever recorded or uploaded.")
                .font(.system(size: layout.subtitle, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if !soundManager.permissionGranted {
                Button {
                    Task {
                        await soundManager.requestPermission()
                    }
                } label: {
                    Label("Allow Microphone", systemImage: "mic.fill")
                        .font(.system(size: layout.body, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, layout.cardPadding)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: layout.cardRadius * 0.7))
                }
                .padding(.horizontal, 40)
            } else {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .font(.system(size: layout.body, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
            }

            Spacer()
        }
        .padding(.horizontal, layout.pagePadding)
        .adaptiveWidth()
    }

    private var readyStep: some View {
        VStack(spacing: layout.sectionSpacing) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: layout.permissionIcon))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("You're All Set!")
                .font(.system(size: round(28 * layout.scale), weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Point your camera at your environment.\nEchoLens will visualize sounds in AR.")
                .font(.system(size: layout.subtitle + 1, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer()
        }
        .padding(.horizontal, layout.pagePadding)
        .adaptiveWidth()
    }

    private var bottomControls: some View {
        VStack(spacing: layout.sectionSpacing) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step == currentStep ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(
                            width: step == currentStep ? round(24 * layout.scale) : round(8 * layout.scale),
                            height: round(8 * layout.scale)
                        )
                        .animation(.spring(duration: 0.3), value: currentStep)
                }
            }

            Button {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                } else {
                    withAnimation(.spring(duration: 0.5)) {
                        isOnboardingComplete = true
                    }
                }
            } label: {
                Text(currentStep < totalSteps - 1 ? "Continue" : "Get Started")
                    .font(.system(size: layout.buttonText, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: layout.maxContentWidth == .infinity ? .infinity : layout.maxContentWidth - 64)
                    .padding(.vertical, layout.cardPadding)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.55, saturation: 0.7, brightness: 0.8),
                                Color(hue: 0.65, saturation: 0.6, brightness: 0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: layout.cardRadius * 0.8)
                    )
                    .shadow(color: Color(hue: 0.6, saturation: 0.5, brightness: 0.5).opacity(0.3),
                            radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, layout.pagePadding)

            if currentStep < totalSteps - 1 {
                Button("Skip") {
                    withAnimation(.spring(duration: 0.5)) {
                        isOnboardingComplete = true
                    }
                }
                .font(.system(size: layout.subtitle, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }
        }
    }

    private func featureDescription(for category: SoundCategory) -> String {
        switch category {
        case .siren:            return "Emergency vehicle alerts"
        case .doorbell:         return "Doorbell & door knock detection"
        case .babyCrying:       return "Infant crying notifications"
        case .smokeAlarm:       return "Smoke & fire alarm warnings"
        case .humanScreaming:   return "Human screaming detection"
        case .childrenShouting: return "Children shouting alerts"
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.6, saturation: 0.15, brightness: 0.10),
                Color(hue: 0.65, saturation: 0.20, brightness: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Onboarding") {
    OnboardingView(
        soundManager: SoundAnalyzerManager(),
        isOnboardingComplete: .constant(false)
    )
    .preferredColorScheme(.dark)
}
