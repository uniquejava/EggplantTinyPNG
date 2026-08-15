import Foundation
import ImageIO
import UniformTypeIdentifiers

enum JPEGCompressor {
    static let defaultQuality: CGFloat = 0.80

    struct Error: Swift.Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func compress(data: Data, quality: CGFloat = defaultQuality) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw Error(message: "Could not decode JPEG")
        }

        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            out, UTType.jpeg.identifier as CFString, 1, nil
        ) else {
            throw Error(message: "Could not create JPEG destination")
        }

        let q = max(0.4, min(1.0, quality))
        CGImageDestinationAddImage(dest, image, [
            kCGImageDestinationLossyCompressionQuality: q,
        ] as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw Error(message: "JPEG encode failed")
        }

        let result = out as Data
        if result.count >= data.count {
            return data
        }
        return result
    }
}

enum WebPCompressor {
    struct Error: Swift.Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Re-encodes via Image I/O when the system WebP encoder is available.
    static func compress(data: Data, quality: CGFloat = 0.80) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw Error(message: "Could not decode WebP")
        }

        let out = NSMutableData()
        let typeID = UTType.webP.identifier as CFString
        guard let dest = CGImageDestinationCreateWithData(out, typeID, 1, nil) else {
            throw Error(message: "WebP encoder unavailable on this system")
        }

        let q = max(0.4, min(1.0, quality))
        CGImageDestinationAddImage(dest, image, [
            kCGImageDestinationLossyCompressionQuality: q,
        ] as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw Error(message: "WebP encode failed")
        }

        let result = out as Data
        if result.count >= data.count {
            return data
        }
        return result
    }
}
