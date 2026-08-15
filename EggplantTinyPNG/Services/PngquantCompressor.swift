import Foundation

/// TinyPNG-style PNG compression via local `pngquant` (+ optional `oxipng`),
/// mirroring `obsidian-cos-images/compress_png.go`.
enum PngquantCompressor {
    static let defaultQuality = 80

    struct Error: Swift.Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Maps UI quality (1–100) to pngquant `--quality=min-max`.
    static func qualityRange(_ quality: Int) -> (min: Int, max: Int) {
        var maxQ = quality
        if maxQ < 40 { maxQ = 40 }
        if maxQ > 100 { maxQ = 100 }
        var minQ = maxQ - 35
        if minQ < 0 { minQ = 0 }
        return (minQ, maxQ)
    }

    static func compress(pngData: Data, quality: Int = defaultQuality) throws -> Data {
        guard let pngquant = ToolFinder.find("pngquant") else {
            throw Error(message: "pngquant not found (brew install pngquant)")
        }

        let fm = FileManager.default
        let inURL = fm.temporaryDirectory.appendingPathComponent("etiny-in-\(UUID().uuidString).png")
        let outURL = fm.temporaryDirectory.appendingPathComponent("etiny-out-\(UUID().uuidString).png")
        defer {
            try? fm.removeItem(at: inURL)
            try? fm.removeItem(at: outURL)
        }

        try pngData.write(to: inURL)

        let range = qualityRange(quality)
        var code = try runPngquant(
            bin: pngquant,
            input: inURL,
            output: outURL,
            min: range.min,
            max: range.max
        )
        // 99 = could not meet min quality — retry with floor 0 (TinyPNG is aggressive).
        if code == 99 {
            code = try runPngquant(
                bin: pngquant,
                input: inURL,
                output: outURL,
                min: 0,
                max: range.max
            )
        }

        switch code {
        case 0:
            break
        case 98:
            throw Error(message: "pngquant: result was not smaller than input")
        case 99:
            throw Error(message: "pngquant: could not reach quality ≤\(range.max) without excessive loss")
        default:
            throw Error(message: "pngquant exited with code \(code)")
        }

        // Best-effort lossless second pass.
        if let oxipng = ToolFinder.find("oxipng") {
            _ = try? runOxipng(bin: oxipng, path: outURL)
        }

        let data = try Data(contentsOf: outURL)
        guard !data.isEmpty else {
            throw Error(message: "pngquant produced empty output")
        }
        return data
    }

    private static func runPngquant(
        bin: String,
        input: URL,
        output: URL,
        min: Int,
        max: Int
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = [
            "--quality=\(min)-\(max)",
            "--speed=3",
            "--strip",
            "--force",
            "--output", output.path,
            input.path,
        ]
        let errPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    private static func runOxipng(bin: String, path: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = ["-o", "2", "-s", "--", path.path]
        process.standardError = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw Error(message: "oxipng failed")
        }
    }
}
