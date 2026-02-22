// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "EchoLensAR",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .iOSApplication(
            name: "EchoLensAR",
            targets: ["EchoLensAR"],
            bundleIdentifier: "com.echolens.ar",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ],
            capabilities: [
                .microphone(purposeString: "EchoLens AR needs microphone access to detect environmental sounds like sirens, doorbells, and alarms."),
                .camera(purposeString: "EchoLens AR uses the camera to render augmented reality overlays showing detected sounds.")
            ],
            additionalInfoPlistContentFilePath: "Info.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "EchoLensAR",
            path: "Sources"
        )
    ]
)
