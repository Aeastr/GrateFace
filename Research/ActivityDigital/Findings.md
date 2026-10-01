# Activity Digital

## Face representation

`face.json` uses `face type: activity digital` directly and has no `bundle id` key. The observed customization fields are `color: white` and `detail: seconds`. The archive has no separate Activity artwork or resource directory.

## Complication representation

| Slot | `face.json` representation | `metadata.json` bundle ID |
| --- | --- | --- |
| Top left | Weather conditions widget descriptor, `type: 56` | `com.apple.weather.watchapp` |
| Top right | `app: workout` with no descriptor | `com.apple.SessionTrackerApp` |
| Bottom center | Heart Rate widget descriptor, `type: 56` | `com.apple.HeartRate` |

The Workout selection is a built-in shorthand in `face.json`, while metadata resolves it to an app bundle ID. That difference is useful when interpreting slots: absence of a descriptor does not mean the slot is unset.
