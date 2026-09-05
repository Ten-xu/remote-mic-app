// swift-tools-version: 6.2
import Foundation
import PackageDescription

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6"),
    .package(
        url: "https://github.com/GetSayAll/sayall-mac-remote.git",
        revision: "7d1b3c2e1d88913bafaa3a401c939eb218a1f363"
    ),
]
var remoteMicDependencies: [Target.Dependency] = [
    "AudioExceptionGuard",
    "SayAllMCPKit",
    .product(name: "Sparkle", package: "Sparkle"),
    .product(name: "SayAllMacRemoteCore", package: "sayall-mac-remote"),
    .product(name: "SayAllMacRemoteUI", package: "sayall-mac-remote"),
]
var remoteMicTestDependencies: [Target.Dependency] = [
    "RemoteMic",
    .product(name: "SayAllMacRemoteCore", package: "sayall-mac-remote"),
]
let macOSPlatform: SupportedPlatform = ProcessInfo.processInfo.environment["RELEASE_VARIANT"] == "intel"
    ? .macOS(.v13)
    : .macOS(.v14)

// Security-hardened fork policy:
// Do not load proprietary AI, membership, macro, or private artifact packages
// from environment-controlled local paths. This keeps the build graph limited
// to dependencies explicitly declared and reviewable in this manifest.

if let hardwareSimulationPath = ProcessInfo.processInfo.environment[
    "REMOTE_MIC_HARDWARE_SIMULATION_PATH"
], !hardwareSimulationPath.isEmpty {
    packageDependencies.append(.package(path: hardwareSimulationPath))
    remoteMicTestDependencies.append(
        .product(name: "HardwareSimulation", package: "hardware-simulation")
    )
    remoteMicTestDependencies.append(
        .product(name: "XiaomiVoiceRemoteSimulation", package: "hardware-simulation")
    )
}

let package = Package(
    name: "RemoteMic",
    platforms: [macOSPlatform],
    products: [
        .executable(
            name: "RemoteMic",
            targets: ["RemoteMic"]
        ),
        .executable(
            name: "SayAllMCP",
            targets: ["SayAllMCP"]
        )
    ],
    dependencies: packageDependencies,
    targets: [
        .executableTarget(
            name: "RemoteMic",
            dependencies: remoteMicDependencies,
            path: "Sources/RemoteMic"
        ),
        .target(
            name: "AudioExceptionGuard",
            path: "Sources/AudioExceptionGuard",
            publicHeadersPath: "include"
        ),
        .target(
            name: "SayAllMCPKit",
            path: "Sources/SayAllMCPKit"
        ),
        .executableTarget(
            name: "SayAllMCP",
            dependencies: ["SayAllMCPKit"],
            path: "Sources/SayAllMCP"
        ),
        .testTarget(
            name: "RemoteMicTests",
            dependencies: remoteMicTestDependencies + ["SayAllMCPKit"],
            path: "Tests/RemoteMicTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
