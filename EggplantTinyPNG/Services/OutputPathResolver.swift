import Foundation

enum OutputPathResolver {
    static let suffix = "-tiny"

    /// `photo-tiny.jpg` — same-name collision → `photo-tiny-1.jpg`, `-2`, …
    static func autoExportURL(for source: URL) -> URL {
        let dir = source.deletingLastPathComponent()
        let ext = source.pathExtension
        let base = source.deletingPathExtension().lastPathComponent + suffix

        let fm = FileManager.default
        var candidate = dir.appendingPathComponent(base).appendingPathExtension(ext)
        var n = 1
        while fm.fileExists(atPath: candidate.path) {
            candidate = dir
                .appendingPathComponent("\(base)-\(n)")
                .appendingPathExtension(ext)
            n += 1
        }
        return candidate
    }

    /// Preview name shown in the queue before write completes.
    static func predictedFileName(for source: URL) -> String {
        let base = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension
        return "\(base)\(suffix).\(ext)"
    }
}
