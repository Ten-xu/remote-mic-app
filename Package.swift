// swift-tools-version: 6.2
import Foundation
import PackageDescription

let useHardenedRemoteCompatibility = ProcessInfo.processInfo.environment[
    "REMOTE_MIC_HARDENED_REMOTE"
] == "1"

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6"),
]
if !useHardenedRemoteCompatibility {
    packageDependencies.append(
        .package(
            url: "https://github.com/GetSayAll/sayall-mac-remote.git",
            revision: "7d1b3c2e1d88913bafaa3a401c939eb218a1f363"
        )
    )
}

var remoteMicDependencies: [Target.Dependency] = [
    "AudioExceptionGuard",
    "SayAllMCPKit",
    .product(name: "Sparkle", package: "Sparkle"),
]
var remoteMicTestDependencies: [Target.Dependency] = ["RemoteMic"]

if useHardenedRemoteCompatibility {
    remoteMicDependencies.append("SayAllMacRemoteCore")
    remoteMicDependencies.append("SayAllMacRemoteUI")
    remoteMicTestDependencies.append("SayAllMacRemoteCore")
} else {
    remoteMicDependencies.append(
        .product(name: "SayAllMacRemoteCore", package: "sayall-mac-remote")
    )
    remoteMicDependencies.append(
        .product(name: "SayAllMacRemoteUI", package: "sayall-mac-remote")
    )
    remoteMicTestDependencies.append(
        .product(name: "SayAllMacRemoteCore", package: "sayall-mac-remote")
    )
}

let macOSPlatform: SupportedPlatform = ProcessInfo.processInfo.environment["RELEASE_VARIANT"] == "intel"
    ? .macOS(.v13)
    : .macOS(.v14)

// Security-hardened fork policy:
// Do not load proprietary AI, membership, macro, or private artifact packages
// from environment-controlled local paths. This keeps the build graph limited
// to dependencies explicitly declared and reviewable in this manifest.
//
// REMOTE_MIC_HARDENED_REMOTE=1 selects the local, inert compatibility modules
// using the same module names as the upstream package. This lets the host source
// remain unchanged while the private dependency is progressively replaced.

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
        .target(
            name: "SayAllMacRemoteCore",
            path: "Sources/SayAllMacRemoteCore"
        ),
        .target(
            name: "SayAllMacRemoteUI",
            dependencies: ["SayAllMacRemoteCore"],
            path: "Sources/SayAllMacRemoteUI"
        ),
        .testTarget(
            name: "RemoteMicTests",
            dependencies: remoteMicTestDependencies + ["SayAllMCPKit"],
            path: "Tests/RemoteMicTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
