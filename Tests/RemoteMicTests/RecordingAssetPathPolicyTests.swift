import Foundation
import Testing
@testable import RemoteMic

@Suite("Recording asset path policy")
struct RecordingAssetPathPolicyTests {
    private let root = URL(fileURLWithPath: "/tmp/RemoteMic/Recordings/v1", isDirectory: true)

    @Test func acceptsNormalNestedRecordingPath() {
        let url = RecordingAssetPathPolicy.resolvedURL(
            relativePath: "2026-09-05/session-123/original.m4a",
            rootDirectoryURL: root
        )
        #expect(url?.path == "/tmp/RemoteMic/Recordings/v1/2026-09-05/session-123/original.m4a")
    }

    @Test func rejectsTraversalAndAbsolutePaths() {
        let invalid = [
            "../outside.m4a",
            "a/../../outside.m4a",
            "a/../outside.m4a",
            "./original.m4a",
            "/tmp/outside.m4a",
            "a//original.m4a",
            "a/",
            "a\\..\\outside.m4a",
        ]
        for path in invalid {
            #expect(
                RecordingAssetPathPolicy.resolvedURL(
                    relativePath: path,
                    rootDirectoryURL: root
                ) == nil
            )
        }
    }

    @Test func rejectsUnexpectedCharacters() {
        #expect(!RecordingAssetPathPolicy.isSafe(
            relativePath: "2026-09-05/session/original file.m4a",
            rootDirectoryURL: root
        ))
        #expect(!RecordingAssetPathPolicy.isSafe(
            relativePath: "2026-09-05/session/%2e%2e.m4a",
            rootDirectoryURL: root
        ))
    }
}
