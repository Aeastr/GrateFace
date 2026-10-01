# Photos face format

Understand which parts of an exported face are replaced and which remain experimental.

@Options {
    @TopicsVisualStyle(detailedGrid)
}

## Overview

The supported Photos face contains `face.json`, `metadata.json`, two snapshot PNGs, `Resources/Images.plist`, HEIC base images, and optional grayscale mask PNGs. GrateFace accepts one image-list item and the Photos bundle identifier observed in the watchOS 27 export. It rejects unknown archive assets and layouts it cannot map without leaving source images behind.

The package preserves the face style, complication configuration, resource names, and crop metadata from its bundled seed (or an explicitly selected template). It replaces every HEIC base image and both snapshot PNGs, replaces referenced masks when one is supplied, and otherwise removes both mask references and mask files. It generates a new image-list local identifier. The framed preview draws a gray rim and black bezel around the artwork, and the unframed preview uses the same rounded photo shape. Neither preview draws a clock. Set `previewCornerRadius` when creating `GrateFaceWriter` to change the corner reach in both previews.

Apple's public API imports an existing `.watchface` file. I worked out the Photos archive writer from faces exported from my watch and tests on the device; Apple does not document an API for creating these files. Treat a successful ZIP write as a candidate for Watch import, not as proof that a watch accepts the face.

In those device tests, referenced all-black mask PNGs caused a generic “current version of watchOS” rejection even though the original face and image-only replacements added on that same watch. Removing mask references or supplying a nonempty generated mask added successfully. This does not identify Apple's exact validation rule, and the Swift writer has not yet been device-tested.

## Topics

### Related API

- ``GrateFace/GrateFaceWriter``
- ``GrateFace/GrateFaceError``
- ``GrateFace/FaceArchiveInspector``
