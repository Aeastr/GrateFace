# Build a Photos face

Create a new face file, then ask Watch to import it on iPhone.

The artwork is the complete image the wearer sees. If part of it should appear in front of the watch time, prepare a full-canvas grayscale mask in your app:

```swift
import ClockKit
import GrateFace

let faceURL = try GrateFaceWriter().makeFace(artwork: artwork, mask: subjectMask)
try await CLKWatchFaceLibrary().addWatchFace(at: faceURL)
```

The example images are supplied by the host app. The mask must match the artwork's pixel dimensions. White pixels make artwork cover the time; black pixels leave it visible. Omit `mask:` if there is no intended overlap. Referenced all-black masks failed in the tested face, so omit a mask instead of passing an empty one.

Generation and Watch import report separate errors. A generated archive can still be refused by the Watch app, including on a future watchOS version. The returned file is in a temporary directory; keep it available until import or sharing finishes, and copy it if it must persist. To experiment with another exported Photos face, initialize `GrateFaceWriter(templateURL:)`.
