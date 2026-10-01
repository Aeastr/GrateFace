import Foundation
import ZIPFoundation

/// A file listed inside a `.watchface` archive.
public struct FaceArchiveEntry: Identifiable {
    public let path: String
    public let uncompressedBytes: Int64
    public let isDirectory: Bool

    public var id: String { path }
}

/// The read-only inventory of a watch face file, including non-Photos faces.
public struct FaceArchiveReport {
    public let bundleIdentifier: String?
    public let entries: [FaceArchiveEntry]
}

/// Lists archive contents without extracting files or changing the supplied face.
public struct FaceArchiveInspector {
    public init() {}

    /// Reads an archive index and its small `face.json` header when present.
    ///
    /// - Parameter url: A local `.watchface` file URL available to the caller.
    /// - Returns: Paths, uncompressed sizes, and the face bundle identifier if found.
    /// - Throws: An archive or input error. It does not validate import compatibility.
    public func inspect(_ url: URL) throws -> FaceArchiveReport {
        let archive = try Archive(url: url, accessMode: .read)
        var entries: [FaceArchiveEntry] = []
        var bundleIdentifier: String?
        for entry in archive {
            guard entries.count < 512 else {
                throw GrateFaceError.invalidTemplate("the archive contains too many entries")
            }
            entries.append(FaceArchiveEntry(path: entry.path,
                                            uncompressedBytes: Int64(entry.uncompressedSize),
                                            isDirectory: entry.type == .directory))
            if entry.path == "face.json", entry.uncompressedSize <= 1_000_000 {
                var data = Data()
                try archive.extract(entry, consumer: { data.append($0) })
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    bundleIdentifier = json["bundle id"] as? String
                }
            }
        }
        return FaceArchiveReport(bundleIdentifier: bundleIdentifier, entries: entries)
    }
}
