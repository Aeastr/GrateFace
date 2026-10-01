import ClockKit
import GrateFace
import PhotosUI
import SwiftUI

@MainActor
final class LabModel: ObservableObject {
    @Published private(set) var templateName: String?
    @Published private(set) var archiveReport: FaceArchiveReport?
    @Published private(set) var artwork: UIImage?
    @Published private(set) var mask: UIImage?
    @Published private(set) var generatedURL: URL?
    @Published var previewCornerRadius: Double = 220 {
        didSet { generatedURL = nil }
    }
    @Published var status = "Choose artwork. The built-in Photos face is ready."

    private var templateURL: URL?

    func useBuiltInTemplate() {
        templateURL = nil
        templateName = nil
        archiveReport = nil
        generatedURL = nil
        status = "Using the built-in Photos face."
    }

    func importTemplate(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        templateURL = nil
        templateName = nil
        archiveReport = nil
        generatedURL = nil
        do {
            let data = try Data(contentsOf: url)
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("template-\(UUID().uuidString).watchface")
            try data.write(to: copy, options: .atomic)
            archiveReport = try FaceArchiveInspector().inspect(copy)
            templateURL = copy
            templateName = url.lastPathComponent
            status = "Custom template loaded. Its images will be replaced in the generated face."
        } catch {
            status = "Could not open the face: \(error.localizedDescription)"
        }
    }

    func importArtwork(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                status = "The selected photo could not be opened."
                return
            }
            artwork = image
            generatedURL = nil
            status = "Artwork selected (\(Int(image.size.width)) × \(Int(image.size.height)))."
        } catch {
            status = "Could not open the photo: \(error.localizedDescription)"
        }
    }

    func importMask(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            guard let image = UIImage(data: try Data(contentsOf: url)) else {
                status = "The selected mask could not be opened."
                return
            }
            mask = image
            generatedURL = nil
            status = "Mask loaded. White areas will appear in front of the clock."
        } catch {
            status = "Could not open the mask: \(error.localizedDescription)"
        }
    }

    func clearMask() {
        mask = nil
        generatedURL = nil
        status = "Mask removed. The generated face will have no depth effect."
    }

    func makeTestMask() {
        guard let artwork, let pixels = Self.uprightCGImage(artwork) else {
            status = "Choose artwork before making a test mask."
            return
        }
        let size = CGSize(width: pixels.width, height: pixels.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        mask = renderer.image { context in
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: size.width * 0.22,
                                             y: size.height * 0.12,
                                             width: size.width * 0.56,
                                             height: size.height * 0.25),
                         cornerRadius: size.width * 0.06).fill()
        }
        generatedURL = nil
        status = "Test mask made. Its white shape should overlap the clock."
    }

    func generate() {
        guard let artwork, let artworkImage = Self.uprightCGImage(artwork) else {
            status = "Choose valid artwork first."
            return
        }
        let maskImage = mask.flatMap(Self.uprightCGImage)
        guard mask == nil || maskImage != nil else {
            status = "The mask could not be rendered."
            return
        }
        do {
            let writer = GrateFaceWriter(templateURL: templateURL,
                                         previewCornerRadius: CGFloat(previewCornerRadius))
            if let maskImage {
                generatedURL = try writer.makeFace(artwork: artworkImage, mask: maskImage)
            } else {
                generatedURL = try writer.makeFace(artwork: artworkImage)
            }
            status = "Face generated. Add it to Watch or share the file."
        } catch {
            generatedURL = nil
            status = error.localizedDescription
        }
    }

    func addToWatch() async {
        guard let generatedURL else { return }
        do {
            try await CLKWatchFaceLibrary().addWatchFace(at: generatedURL)
            status = "The face was handed to Watch. Check it on your paired watch."
        } catch {
            status = "Watch could not add the face: \(error.localizedDescription)"
        }
    }

    private static func uprightCGImage(_ image: UIImage) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }
}
