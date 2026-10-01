# Exactograph

## Face representation

`face.json` uses `face type: bundle` and identifies `com.apple.NTKExactitudesFaceBundle`. The observed customization fields are `color`, `style`, and `background`, with values `exactitudes.hardware.gold`, `closed`, and `backgroundOff`. These are symbolic settings; the archive contains no separate dial assets.

## Complication representation

All four corner slots use widget descriptors with `type: 56`:

| Slot | App | Descriptor `kind` |
| --- | --- | --- |
| Top left | Weather | `com.apple.weather.widget.uv` |
| Top right | Weather | `com.apple.weather.widget.temperature` |
| Bottom left | Timers | `TimerWidget` |
| Bottom right | Activity | `ActivityRingsComplication` |

The Timer descriptor also has a base64 `intent`. It decodes to a binary property list with an `NSKeyedArchiver` root and `INIntent`/`INCodable` objects; the other three slots have no encoded intent. `metadata.json` gives both Weather slots the same app bundle ID and item ID even though their descriptor kinds differ. In this face, the metadata item ID alone does not identify which Weather widget is selected.
