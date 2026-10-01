import CoreGraphics
import Foundation
import UniformTypeIdentifiers

/// Draws the Photos preview silhouette without inheriting artwork from the template.
enum FacePreviewRenderer {
    // Measured from an exported 799 × 919 Photos snapshot. The aperture is
    // 624 × 744, centered 87.5 points inside the framed preview.
    private static let frameSize = CGSize(width: 799, height: 919)
    private static let photoSize = CGSize(width: 624, height: 744)
    private static let photoRect = CGRect(x: 87.5, y: 87.5, width: 624, height: 744)
    private static let blackInset: CGFloat = 35.5
    private static let grayInset: CGFloat = 51.5

    static func render(artwork: CGImage, framed: Data, unframed: Data,
                       cornerRadius: CGFloat) throws -> (Data, Data) {
        guard cornerRadius.isFinite, cornerRadius >= 1, cornerRadius <= 312 else {
            throw GrateFaceError.invalidImage("the preview corner radius must be between 1 and 312")
        }
        let (frameWidth, frameHeight) = try FaceImageCodec.dimensions(of: framed, name: "snapshot.png")
        let (photoWidth, photoHeight) = try FaceImageCodec.dimensions(of: unframed,
                                                                     name: "no_borders_snapshot.png")
        let photo = try FaceImageCodec.render(artwork, width: photoWidth, height: photoHeight,
                                               grayscale: false)
        let bare = try context(width: photoWidth, height: photoHeight)
        bare.scaleBy(x: CGFloat(photoWidth) / photoSize.width,
                     y: CGFloat(photoHeight) / photoSize.height)
        bare.addPath(outline(in: CGRect(origin: .zero, size: photoSize),
                             offset: 0, radius: cornerRadius))
        bare.clip()
        bare.interpolationQuality = .high
        bare.draw(photo, in: CGRect(origin: .zero, size: photoSize))

        let caseContext = try context(width: frameWidth, height: frameHeight)
        caseContext.scaleBy(x: CGFloat(frameWidth) / frameSize.width,
                            y: CGFloat(frameHeight) / frameSize.height)
        caseContext.setFillColor(red: 67.0 / 255.0, green: 67.0 / 255.0,
                                 blue: 69.0 / 255.0, alpha: 1)
        caseContext.addPath(outline(in: photoRect, offset: grayInset, radius: cornerRadius))
        caseContext.fillPath()
        caseContext.setFillColor(gray: 0, alpha: 1)
        caseContext.addPath(outline(in: photoRect, offset: blackInset, radius: cornerRadius))
        caseContext.fillPath()
        caseContext.saveGState()
        caseContext.addPath(outline(in: photoRect, offset: 0, radius: cornerRadius))
        caseContext.clip()
        caseContext.interpolationQuality = .high
        caseContext.draw(photo, in: photoRect)
        caseContext.restoreGState()

        guard let framedImage = caseContext.makeImage(), let bareImage = bare.makeImage() else {
            throw GrateFaceError.invalidImage("the preview could not be rendered")
        }
        return (try FaceImageCodec.encode(framedImage, as: .png),
                try FaceImageCodec.encode(bareImage, as: .png))
    }

    private static func context(width: Int, height: Int) throws -> CGContext {
        guard width > 0, height > 0, width <= 8192, height <= 8192,
              let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw GrateFaceError.invalidTemplate("the preview has unsupported dimensions")
        }
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        return context
    }

    /// A squircle-style corner with curvature that eases into its straight sides.
    /// The bezel paths follow its outward normals, so their thickness stays constant.
    private static func outline(in rect: CGRect, offset: CGFloat, radius: CGFloat) -> CGPath {
        let radius = Double(radius)
        let power = 3.5
        let positionPower = 2.0 / power
        let normalPower = 2.0 * (power - 1.0) / power
        let left = Double(rect.minX), right = Double(rect.maxX)
        let top = Double(rect.minY), bottom = Double(rect.maxY)
        let distance = Double(offset)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: left + radius, y: top - distance))

        for corner in 0..<4 {
            let centerX = corner == 0 || corner == 1 ? right - radius : left + radius
            let centerY = corner == 0 || corner == 3 ? top + radius : bottom - radius
            for step in 0...512 {
                let angle = Double(step) * .pi / 1024.0
                let sine = sin(angle), cosine = cos(angle)
                let a = pow(sine, positionPower), b = pow(cosine, positionPower)
                let normalA = pow(sine, normalPower), normalB = pow(cosine, normalPower)
                let length = hypot(normalA, normalB)
                let na = normalA / length, nb = normalB / length
                let x: Double, y: Double
                switch corner {
                case 0: // Top right
                    x = centerX + radius * a + distance * na
                    y = centerY - radius * b - distance * nb
                case 1: // Bottom right
                    x = centerX + radius * b + distance * nb
                    y = centerY + radius * a + distance * na
                case 2: // Bottom left
                    x = centerX - radius * a - distance * na
                    y = centerY + radius * b + distance * nb
                default: // Top left
                    x = centerX - radius * b - distance * nb
                    y = centerY - radius * a - distance * na
                }
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
