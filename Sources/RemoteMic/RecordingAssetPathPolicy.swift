import Foundation

enum RecordingAssetPathPolicy {
    static func resolvedURL(relativePath: String, rootDirectoryURL: URL) -> URL? {
        guard !relativePath.isEmpty,
              !relativePath.hasPrefix("/"),
              !relativePath.hasSuffix("/"),
              !relativePath.contains("\\")
        else { return nil }

        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty else { return nil }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        for componentSlice in components {
            let component = String(componentSlice)
            guard !component.isEmpty,
                  component != ".",
                  component != "..",
                  component.unicodeScalars.allSatisfy(allowed.contains)
            else { return nil }
        }

        let root = rootDirectoryURL.standardizedFileURL
        let candidate = root.appendingPathComponent(relativePath).standardizedFileURL
        guard candidate.path != root.path,
              candidate.path.hasPrefix(root.path + "/")
        else { return nil }
        return candidate
    }

    static func isSafe(relativePath: String, rootDirectoryURL: URL) -> Bool {
        resolvedURL(relativePath: relativePath, rootDirectoryURL: rootDirectoryURL) != nil
    }
}
