import Foundation

enum OutputPathResolver {
    static let suffix = "-tiny"

    /// Always: `photo-tiny-yyyyMMdd-HHmmss.jpg`
    /// Same-second collision → `photo-tiny-yyyyMMdd-HHmmss-1.jpg`
    static func autoExportURL(for source: URL, now: Date = Date()) -> URL {
        let dir = source.deletingLastPathComponent()
        let ext = source.pathExtension
        let base = source.deletingPathExtension().lastPathComponent
        let stamp = timestampString(from: now)

        let fm = FileManager.default
        var candidate = dir
            .appendingPathComponent("\(base)\(suffix)-\(stamp)")
            .appendingPathExtension(ext)

        var n = 1
        while fm.fileExists(atPath: candidate.path) {
            candidate = dir
                .appendingPathComponent("\(base)\(suffix)-\(stamp)-\(n)")
                .appendingPathExtension(ext)
            n += 1
        }
        return candidate
    }

    static func timestampString(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }

    /// Preview name shown in the queue before write completes.
    static func predictedFileName(for source: URL, now: Date = Date()) -> String {
        let base = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension
        return "\(base)\(suffix)-\(timestampString(from: now)).\(ext)"
    }
}
