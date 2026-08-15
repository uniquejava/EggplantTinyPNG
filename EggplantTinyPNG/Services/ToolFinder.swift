import Foundation

enum ToolFinder {
    /// Locates `pngquant` / `oxipng` the same way as obsidian-cos-images:
    /// PATH → ~/.local/bin → Homebrew → app Resources (for bundled binaries later).
    static func find(_ name: String) -> String? {
        if let path = which(name) {
            return path
        }

        var candidates: [String] = []
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        candidates.append((home as NSString).appendingPathComponent(".local/bin/\(name)"))
        candidates += [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]

        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            let dir = exe.path
            candidates += [
                (dir as NSString).appendingPathComponent(name),
                (dir as NSString).appendingPathComponent("bin/\(name)"),
                (dir as NSString).appendingPathComponent("../Resources/\(name)"),
                (dir as NSString).appendingPathComponent("../Resources/bin/\(name)"),
            ]
        }

        let fm = FileManager.default
        for c in candidates {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: c, isDirectory: &isDir), !isDir.boolValue {
                return c
            }
        }
        return nil
    }

    private static func which(_ name: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (path?.isEmpty == false) ? path : nil
        } catch {
            return nil
        }
    }
}
