import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum FaceImageCodec {
    static func dimensions(of data: Data, name: String) throws -> (Int, Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw GrateFaceError.invalidTemplate("\(name) cannot be decoded")
        }
        return (image.width, image.height)
    }

    static func render(_ image: CGImage, width: Int, height: Int, grayscale: Bool) throws -> CGImage {
        guard width > 0, height > 0, width <= 8192, height <= 8192 else {
            throw GrateFaceError.invalidTemplate("an image has unsupported dimensions")
        }
        let colorSpace = grayscale ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB()
        let alphaInfo = grayscale ? CGImageAlphaInfo.none.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: colorSpace, bitmapInfo: alphaInfo) else {
            throw GrateFaceError.invalidImage("a drawing context could not be created")
        }
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let scale = max(CGFloat(width) / CGFloat(image.width), CGFloat(height) / CGFloat(image.height))
        let drawnWidth = CGFloat(image.width) * scale
        let drawnHeight = CGFloat(image.height) * scale
        let rect = CGRect(x: (CGFloat(width) - drawnWidth) / 2,
                          y: (CGFloat(height) - drawnHeight) / 2,
                          width: drawnWidth, height: drawnHeight)
        context.interpolationQuality = .high
        context.draw(image, in: rect)
        guard let rendered = context.makeImage() else {
            throw GrateFaceError.invalidImage("the image could not be rendered")
        }
        return rendered
    }

    static func encode(_ image: CGImage, as type: UTType) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            throw GrateFaceError.invalidImage("the \(type.identifier) encoder is unavailable")
        }
        let options: [CFString: Any] = type == .heic
            ? [kCGImageDestinationLossyCompressionQuality: 0.95]
            : [:]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw GrateFaceError.invalidImage("the \(type.identifier) image could not be encoded")
        }
        return data as Data
    }

    static func hasVisibleMask(_ image: CGImage) -> Bool {
        guard let data = image.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return false }
        return (0..<CFDataGetLength(data)).contains { bytes[$0] > 0 }
    }
}
