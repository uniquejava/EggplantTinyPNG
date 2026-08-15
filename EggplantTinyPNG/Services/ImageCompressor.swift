import Foundation
import UniformTypeIdentifiers

enum ImageCompressor {
    struct Result {
        let data: Data
        let bytes: Int
    }

    struct Error: Swift.Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static let supportedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "webp",
    ]

    static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func compress(fileURL: URL, quality: Int = 80) throws -> Result {
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else {
            throw Error(message: "Empty file")
        }

        let ext = fileURL.pathExtension.lowercased()
        let out: Data
        switch ext {
        case "png":
            out = try PngquantCompressor.compress(pngData: data, quality: quality)
        case "jpg", "jpeg":
            let q = CGFloat(quality) / 100.0
            out = try JPEGCompressor.compress(data: data, quality: q)
        case "webp":
            let q = CGFloat(quality) / 100.0
            out = try WebPCompressor.compress(data: data, quality: q)
        default:
            throw Error(message: "Unsupported type .\(ext)")
        }

        return Result(data: out, bytes: out.count)
    }
}
