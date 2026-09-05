import Foundation
import Testing

@Suite("Hardened compatibility boundary")
struct HardenedCompatibilityBoundaryTests {
    private static let forbiddenTokens = [
        "import Network",
        "import CoreBluetooth",
        "URLSession",
        "NWListener",
        "NWConnection",
        "NWBrowser",
        "webSocketTask",
        "_remotemic._tcp",
        "WebSocket",
        "Bonjour",
    ]

    @Test func compatibilityLayerContainsNoRemoteTransportImplementation() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let paths = [
            "Sources/SayAllMacRemoteCore",
            "Sources/SayAllMacRemoteUI",
        ]

        for relativePath in paths {
            let directory = root.appendingPathComponent(relativePath, isDirectory: true)
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "swift" }

            for file in files {
                let source = try String(contentsOf: file, encoding: .utf8)
                for token in Self.forbiddenTokens {
                    #expect(
                        !source.contains(token),
                        "Hardened compatibility layer must not contain remote transport token: \(token) in \(file.lastPathComponent)"
                    )
                }
            }
        }
    }
}
