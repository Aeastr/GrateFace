import CoreGraphics
import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

/// Creates a Photos watch face from artwork and an optional prepared mask.
///
/// The default seed contains neutral GrateFace artwork. Each result gets new images
/// and a new photo identifier. Supply a different exported Photos face at initialization
/// only when experimenting with its face style or layout. Apple's face-file writer is
/// not public; this format is experimental and may change with watchOS.
public struct GrateFaceWriter {
    private let templateURL: URL?
    private let previewCornerRadius: CGFloat

    /// Creates a writer using the bundled neutral Photos-face seed.
    ///
    /// Pass a custom template URL only to explore a different exported Photos face.
    /// The output retains that template's face style and complication configuration.
    /// `previewCornerRadius` controls both PNG previews. It uses pixels of the
    /// 624 × 744 unframed reference preview and may be set from 1 through 312.
    public init(templateURL: URL? = nil, previewCornerRadius: CGFloat = 220) {
        self.templateURL = templateURL
        self.previewCornerRadius = previewCornerRadius
    }

    /// Generates a Photos face from finished artwork and an optional prepared mask.
    ///
    /// - Parameters:
    ///   - artwork: Upright, complete artwork. It is cropped to fill the face's image slots.
    ///   - mask: Optional full-canvas grayscale image. White pixels make artwork appear
    ///     in front of the watch time; black pixels keep the time unobstructed. It must
    ///     match `artwork` in pixels. Compose and generate this mask in the host app.
    /// - Returns: A unique temporary `.watchface` URL. Keep the file until sharing or
    ///   Watch import finishes; copy it elsewhere if it must persist.
    /// - Throws: ``GrateFaceError`` or an underlying archive/file error. Successful
    ///   generation does not establish that Watch will accept the face.
    public func makeFace(artwork: CGImage, mask: CGImage? = nil) throws -> URL {
        guard let source = templateURL ?? Bundle.module.url(forResource: "Photos27Seed", withExtension: "watchface") else {
            throw GrateFaceError.invalidTemplate("the bundled Photos-face seed is missing")
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("GrateFace", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let output = directory.appendingPathComponent("GrateFace-\(UUID().uuidString).watchface")
        return try write(templateURL: source, artwork: artwork, foregroundMask: mask, to: output)
    }

    private func write(templateURL: URL, artwork: CGImage, foregroundMask: CGImage?,
                       to outputURL: URL) throws -> URL {
        guard templateURL.standardizedFileURL != outputURL.standardizedFileURL else {
            throw GrateFaceError.outputMatchesTemplate
        }
        guard !FileManager.default.fileExists(atPath: outputURL.path) else {
            throw GrateFaceError.outputAlreadyExists
        }
        guard outputURL.pathExtension.lowercased() == "watchface" else {
            throw GrateFaceError.invalidImage("the output file must end in .watchface")
        }
        if let foregroundMask,
           (foregroundMask.width != artwork.width || foregroundMask.height != artwork.height) {
            throw GrateFaceError.invalidImage("the mask and artwork must have the same dimensions")
        }

        let template = try Archive(url: templateURL, accessMode: .read)
        var order: [String] = []
        var contents: [String: Data] = [:]
        for entry in template {
            let path = entry.path
            guard isAllowed(path), !order.contains(path), order.count < 32 else {
                throw GrateFaceError.unsupportedTemplate("unexpected or repeated archive entry: \(path)")
            }
            order.append(path)
            if entry.type == .directory { continue }
            guard entry.uncompressedSize <= 100_000_000 else {
                throw GrateFaceError.unsupportedTemplate("\(path) is too large")
            }
            var data = Data()
            try template.extract(entry, consumer: { chunk in
                guard data.count + chunk.count <= 100_000_000 else {
                    throw GrateFaceError.unsupportedTemplate("\(path) is too large")
                }
                data.append(chunk)
            })
            contents[path] = data
        }

        guard let faceData = contents["face.json"],
              let face = try JSONSerialization.jsonObject(with: faceData) as? [String: Any],
              face["bundle id"] as? String == "com.apple.NTKParmesanFaceBundle",
              contents["metadata.json"] != nil,
              let plistData = contents["Resources/Images.plist"],
              contents["snapshot.png"] != nil,
              contents["no_borders_snapshot.png"] != nil else {
            throw GrateFaceError.unsupportedTemplate("use a single-photo Photos face exported by Watch")
        }
        guard var plist = try PropertyListSerialization.propertyList(from: plistData,
                                                                     options: [], format: nil) as? [String: Any],
              plist["version"] as? Int == 2,
              var imageList = plist["imageList"] as? [[String: Any]],
              imageList.count == 1,
              var layouts = imageList[0]["layouts"] as? [[String: Any]] else {
            throw GrateFaceError.unsupportedTemplate("the Photos image list has an unknown layout")
        }

        let identifier = UUID().uuidString
        var basePaths = Set<String>()
        var maskPaths = Set<String>()
        for index in layouts.indices {
            guard let baseName = layouts[index]["baseImageName"] as? String else { continue }
            let basePath = "Resources/\(baseName)"
            guard baseName.hasPrefix("base_"), baseName.hasSuffix(".heic"),
                  let original = contents[basePath] else {
                throw GrateFaceError.unsupportedTemplate("an image slot is missing its HEIC")
            }
            basePaths.insert(basePath)
            let (width, height) = try FaceImageCodec.dimensions(of: original, name: basePath)
            let rendered = try FaceImageCodec.render(artwork, width: width, height: height, grayscale: false)
            contents[basePath] = try FaceImageCodec.encode(rendered, as: .heic)

            if let maskInfo = layouts[index]["mask"] as? [String: Any],
               let maskName = maskInfo["imageName"] as? String {
                let maskPath = "Resources/\(maskName)"
                guard maskName.hasPrefix("mask_"), maskName.hasSuffix(".png"),
                      let originalMask = contents[maskPath] else {
                    throw GrateFaceError.unsupportedTemplate("a mask slot is missing its PNG")
                }
                maskPaths.insert(maskPath)
                if let foregroundMask {
                    let (maskWidth, maskHeight) = try FaceImageCodec.dimensions(of: originalMask, name: maskPath)
                    guard maskWidth == width, maskHeight == height else {
                        throw GrateFaceError.unsupportedTemplate("mask and image slot sizes differ")
                    }
                    let renderedMask = try FaceImageCodec.render(foregroundMask, width: width,
                                                                  height: height, grayscale: true)
                    guard FaceImageCodec.hasVisibleMask(renderedMask) else {
                        throw GrateFaceError.invalidImage("an all-black mask failed in the tested Photos face; omit the mask instead")
                    }
                    contents[maskPath] = try FaceImageCodec.encode(renderedMask, as: .png)
                } else {
                    layouts[index].removeValue(forKey: "mask")
                    contents.removeValue(forKey: maskPath)
                }
            }
        }
        guard !basePaths.isEmpty else {
            throw GrateFaceError.unsupportedTemplate("there are no Photos image slots")
        }
        if foregroundMask != nil && maskPaths.isEmpty {
            throw GrateFaceError.unsupportedTemplate("the template has no subject-mask slots")
        }
        let archivedBasePaths = Set(order.filter { $0.hasPrefix("Resources/base_") })
        let archivedMaskPaths = Set(order.filter { $0.hasPrefix("Resources/mask_") })
        guard archivedBasePaths == basePaths, archivedMaskPaths == maskPaths else {
            throw GrateFaceError.unsupportedTemplate("unreferenced photo assets would remain in the face")
        }

        imageList[0]["layouts"] = layouts
        imageList[0]["localIdentifier"] = "\(identifier)/L0/001"
        plist["imageList"] = imageList
        contents["Resources/Images.plist"] = try PropertyListSerialization.data(fromPropertyList: plist,
                                                                                    format: .xml,
                                                                                    options: 0)
        let previews = try FacePreviewRenderer.render(artwork: artwork,
                                                       framed: contents["snapshot.png"]!,
                                                       unframed: contents["no_borders_snapshot.png"]!,
                                                       cornerRadius: previewCornerRadius)
        contents["snapshot.png"] = previews.0
        contents["no_borders_snapshot.png"] = previews.1

        do {
            let output = try Archive(url: outputURL, accessMode: .create)
            for path in order {
                if path == "Resources/" {
                    try output.addEntry(with: path, type: .directory, uncompressedSize: Int64(0),
                                        provider: { _, _ in Data() })
                    continue
                }
                guard let data = contents[path] else { continue }
                try output.addEntry(with: path, type: .file,
                                    uncompressedSize: Int64(data.count),
                                    compressionMethod: .deflate,
                                    provider: { position, size in
                    let start = Int(position)
                    return data.subdata(in: start..<(start + size))
                })
            }
            return outputURL
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    private func isAllowed(_ path: String) -> Bool {
        if ["face.json", "metadata.json", "snapshot.png", "no_borders_snapshot.png",
            "Resources/", "Resources/Images.plist"].contains(path) { return true }
        if path.hasPrefix("Resources/base_"), path.hasSuffix(".heic") { return true }
        if path.hasPrefix("Resources/mask_"), path.hasSuffix(".png") { return true }
        return false
    }
}
