# Photos watch face investigation

I used a `Photos.watchface` file exported from my watch and a paired iPhone and Apple Watch running watchOS 27 for the initial experiment. I tested the diagnostic files on that watch. The private source export, its photo, and the diagnostic face files are not included in GrateFace. The package includes a neutral seed derived from that export; every photo, mask, and snapshot payload was replaced, and the photo identifier was regenerated. The face style and layout metadata remain from the export. The seed itself has not been imported on a watch, but a mask-free face generated from it by `GrateFaceWriter` has now been added and displayed on a watch. Results below distinguish **device observations**, **archive inspection**, and **inferences**; an archive that opens as ZIP is not necessarily a face Watch will accept.

A separate [landscape example face](../../Examples/PhotosLandscape.watchface) was rebuilt from a later supplied export. Its embedded images were re-encoded, its export-specific photo identifier and resource filenames were replaced, and its ZIP timestamps were reset. The landscape itself was retained. This example is separate from the bundled seed and has not been tested on a watch.

I started investigating because I could choose **Create Watch Face** when sharing a photo from Photos, but did not see that action when sharing a Deco export. Apple documents importing an existing face file through ClockKit; I found no documented API in that flow for composing a new Photos face from an arbitrary app image. I exported a Photos face to test whether its embedded artwork could be replaced.

## What worked

I confirmed that replacing the Photos face's embedded HEIC artwork can produce a face that adds to Watch and displays the replacement image. A new local photo identifier is accepted. For a face without a foreground subject, removing the mask references also produces an accepted face. For a depth face, Watch accepted newly generated, nonempty grayscale mask PNGs and the masked artwork visibly overlapped the clock. This establishes that the original photo and original subject mask are not required for the tested template.

The controlled diagnostic experiments cover **one exported face and one paired watchOS 27 setup**. A later writer-generated file was also confirmed on a watch, but its watch model and OS version were not recorded. These results do not establish a general `.watchface` authoring specification, support for every Photos layout, or compatibility with other watchOS versions and watch models.

## The observed archive

The supplied file is a ZIP archive with 13 entries:

| Entry | Observed role |
| --- | --- |
| `face.json` | Face bundle and style configuration. Its `bundle id` is `com.apple.NTKParmesanFaceBundle`, the source of the GrateFace name. The observed version is 4. |
| `metadata.json` | Device and complication metadata. The observed version is 2, `device_size` is 8, and both complication slots are Off. |
| `Resources/Images.plist` | Version 2 image list. It has one photo entry, a `localIdentifier`, layout variants, a preferred time layout, base-image filenames, mask references for three layouts, and crop data. |
| Four `Resources/base_*.heic` files | Artwork for `xst`, `st`, `mt`, and `ll` layouts. Each is 552 × 672 pixels in this export. |
| Three `Resources/mask_*.png` files | Grayscale masks for `xst`, `st`, and `mt`; the `ll` layout has no mask reference. Each is 552 × 672 pixels. The original masks contain values across 0–255, including soft edges. |
| `snapshot.png` | RGBA preview image, 799 × 919 pixels in this export. |
| `no_borders_snapshot.png` | RGBA preview image, 624 × 744 pixels in this export. |
| `Resources/` | ZIP directory entry. |

The `Images.plist` layout array also contains a small entry without a base image. The four named HEICs are the actual artwork slots observed here. The source plist has `originalCrop`, `timeLayout`, and `userEdited` values for those slots. I left the face style, complication metadata, and crop/time-layout values alone in the successful diagnostic swaps. Their full semantics are not yet known.

Neither `face.json` nor `metadata.json` changed in the controlled image, mask, or local-identifier variants. The generic rejection therefore has no observed connection to a change in those two metadata files. A change to the plist's `localIdentifier` was accepted, although broader metadata edits remain untested.

In this format, the base **artwork** files are HEIC; the **masks and snapshots** are PNG. There were no JPEG assets in the observed archive. The original payload entries use ZIP deflate compression, with a separate uncompressed directory entry. The Python diagnostic swaps preserved the original entry order and ZIP entry metadata while replacing selected payloads. The later Swift writer test establishes import for one mask-free output; it does not cover masks or other configurations.

## Experiment log

Every diagnostic variant started from the same face I exported. “Adds” means I imported it on iPhone and confirmed the replacement grid on the watch, rather than judging only the Watch app preview. All inspected ZIPs passed CRC checks; that check says nothing about Watch acceptance.

| Variant | Controlled change from the source or working swap | Device result |
| --- | --- | --- |
| Original `Photos.watchface` | None | **Adds successfully** on the same paired iPhone/watch. This is the compatibility control. |
| `Deco-Diagnostic.watchface` | Replaced four HEIC bases, both snapshots, and three masks with all-black images; assigned a new photo identifier. | **Rejected** with the generic watchOS-version error. Its Watch app preview displayed the Deco grid, showing that preview rendering is not proof of import. |
| `Deco-MinimalSwap.watchface` | Replaced only four HEIC bases and both snapshots. Kept the original masks, plist, and photo identifier. | **Adds** and shows the Deco grid on the watch. This proved replacement artwork can work. |
| `Deco-BlankMasks.watchface` | Working minimal swap plus three all-black mask PNGs; mask references stayed in the plist. | **Rejected** with the same watchOS-version error. |
| `Deco-NewIdentifier.watchface` | Working minimal swap plus a new `localIdentifier` in `Images.plist`; resource filenames stayed the same. | **Adds** and shows the Deco grid. A changed local identifier is not what caused the diagnostic rejection. |
| `Deco-NoMasks.watchface` | Working minimal swap plus removal of all three `mask` dictionaries from `Images.plist`. The old mask PNG files were left in the diagnostic ZIP but no longer referenced. | **Adds** and shows the Deco grid. The old PNGs remaining in this *prototype* are a privacy reason not to distribute it. |
| `Deco-GeneratedMask` | Working minimal swap plus three newly generated, nonempty grayscale mask PNGs. The sample mask is a blurred rounded rectangle. | **Adds** and shows the Deco grid; I confirmed artwork visibly overlaps the clock. |
| `Deco-PlistRoundTrip.watchface` | A plist serialization control with no intended value change. | **Not device-tested.** It was unnecessary after the no-mask and new-identifier results. |
| `Deco-ConsistentIdentifier.watchface` | An identifier/resource-name exploration. | **Not device-tested.** Do not infer that renaming every resource works. |
| [`WriterImportTest.watchface`](../../Examples/WriterImportTest.watchface) | `GrateFaceWriter` generated four new HEIC artwork assets and both previews from distinctive test art using the bundled seed; it removed all mask references and files and assigned a new photo identifier. ZIP integrity and resource counts were checked before import. | **Adds and displays on watch.** The user confirmed the colored artwork appeared on the watch on 2026-10-01. Watch model and OS version were not recorded. |

The all-black masks were valid PNGs with the expected dimensions and their ZIP checks passed. Since removing mask references worked and replacing masks with a nonempty generated shape also worked, the observed rejection is tied to the **referenced empty mask content in this template**, not to changing image bytes in general or to the actual watchOS version. I have not established Apple's exact mask validation rule: it may involve nonempty coverage, time overlap, or another property. I cannot claim every nonblack mask is valid.

The successful no-mask prototype retained unreferenced PNGs, so it only proves that removing the plist references can allow import. It does **not** prove that keeping the old PNGs is necessary. GrateFace deliberately removes them when writing a mask-free output, to avoid carrying the source subject silhouette.

The successful `Deco-NoMasks` variant rewrote the XML plist through a property-list serializer, so byte-for-byte plist formatting is not required for that tested change. The successful `Deco-NewIdentifier` variant changed only the local identifier while leaving resource filenames with the old UUID suffix. Their values did not have to match in this template; renaming all resource files remains untested.

## Failure and confusing states

| State | What was observed or what the current code reports | Meaning and recovery |
| --- | --- | --- |
| Watch says “This watch face is not available with your current version of watchOS.” | Seen for `Deco-Diagnostic` and `Deco-BlankMasks` on the same watchOS 27 watch that accepted the original and other modified faces. | The message is **not a reliable diagnosis of an old watchOS version** in this experiment. Recheck mask references and generated mask content first. Preserve the exact failing file for comparison. |
| Watch app preview shows the replacement artwork but import fails. | Seen with the first diagnostic face. | Snapshot/preview assets can be displayed before Watch validates the face. Verify addition and artwork on the watch itself. |
| Watch app temporarily shows the source dog image for a generated-mask face. | I inspected the ZIP and found no dog photo in that variant; after refreshing/restarting Watch, the display corrected. | This appears to be stale Watch app preview state. The cache mechanism and key are **not proven**. Inspect archive contents and verify on-watch artwork before treating it as embedded source content. |
| ZIP CRC and resource references are valid. | All inspected diagnostic archives passed structural checks, including rejected ones. | Structural validity alone does not imply Watch acceptance. |
| GrateFace receives an all-black mask. | Its writer is designed to report an artwork error instead of knowingly producing the empty-mask variant that failed the device test. This code path has not been run. | Omit the mask for a flat face or provide a nonempty grayscale mask. |
| GrateFace receives an unsupported template. | It rejects another face bundle, unknown archive entries, multiple-photo layouts, missing referenced assets, or layouts that could leave original artwork behind. | Inspect the face in GrateFace Lab and investigate that format separately; do not silently copy private assets through. |
| File generation succeeds but Watch import fails. | This remains possible. GrateFace Lab reports generation and Watch import separately. | Keep the generated file and the original template for comparison. A completed ZIP write is not an import guarantee. |

GrateFace also reports mismatched artwork/mask sizes and invalid or unreadable images. It creates a unique temporary output URL itself; its internal writer also checks for an existing output or a path matching the input template. Archive, encoding, and file-system errors can propagate. The package was built and the mask-free writer path ran for `WriterImportTest.watchface`; the Lab and the listed error paths have not been run. On this Mac, HEIC encoding failed inside the restricted command sandbox, so the already-built generator was run with normal system access to produce the file.

## Foreground mask model

An app supplies the complete artwork and, when it wants clock overlap, a prepared full-canvas grayscale mask. The app decides how to combine subjects or other visual layers into that mask. GrateFace does not segment subjects or compose layers. The mask and artwork must share pixel dimensions; GrateFace applies the same crop and scale to each Photos layout.

For a wallpaper without an intended clock overlap, use no mask reference. A blank mask is not a safe substitute in the tested format. A mask encodes **occlusion of the watch time**; it is not the whole visual composition.

## Preview work and open questions

The tested swaps replaced both snapshot PNGs with Deco artwork. The generated files could add, but those replacements were not a faithful framed Watch preview. GrateFace now draws a gray rim, black bezel, and rounded photo aperture for `snapshot.png`, with the same rounded aperture for `no_borders_snapshot.png`; neither includes a clock. This geometry was measured from a supplied Apple Photos export. The `WriterImportTest.watchface` preview was inspected before import, and the face added and displayed on the watch. Preview behavior across watch sizes, and whether Watch regenerates or caches either image, still need device verification. The stale dog display should be revisited as part of that work.

Other unanswered questions: different watch sizes and models; alternate time layouts and mask slots; how crop metadata affects arbitrary aspect ratios; multi-photo and shuffle faces; mask pixel requirements and edge treatment in Swift-written files; whether fully renamed resource filenames import; and the structures of other face bundles. `FaceArchiveInspector` can inventory other exports without treating them as Photos faces.

## Platform boundary and evidence

[Apple documents importing an existing `.watchface` file](https://developer.apple.com/documentation/clockkit/sharing-an-apple-watch-face) with [`CLKWatchFaceLibrary.addWatchFace(at:)`](https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface(at:completionhandler:)). The documentation does not provide a public Photos-face file writer. I drew these conclusions from file inspection and tests on my watch, not an Apple-supported authoring contract. GrateFace therefore remains an experimental writer and should surface import failure rather than promise compatibility.
