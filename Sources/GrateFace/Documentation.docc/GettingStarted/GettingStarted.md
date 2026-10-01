# Getting started

Turn supplied artwork into a Photos face file that Watch can import.

@Options {
    @TopicsVisualStyle(detailedGrid)
}

## Overview

GrateFace includes a neutral single-photo Photos-face seed. Pass upright pixel images as `CGImage` values; the writer replaces the seed's photo and mask resources and returns a unique temporary file URL. A separate exported Photos face can be selected when experimenting with its style or layout.

## Topics

### Generate

- <doc:BuildPhotosFace>
- ``GrateFace/GrateFaceWriter``

### Recover

- ``GrateFace/GrateFaceError``
