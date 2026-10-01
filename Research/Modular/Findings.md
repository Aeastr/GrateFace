# Modular

## Face representation

`face.json` uses `face type: whistler-digital` directly and has no `bundle id` key. The observed customization fields are `color: multicolor`, `numerals: style 1`, and `background: style 1`. The face has six configured slots, including a date slot that is stored as `app: date` plus `date style: weekday and day` rather than as a widget descriptor.

## Complication representation

| Slot | Representation in `face.json` |
| --- | --- |
| Top left | Activity widget, `ActivityRingsComplication` |
| Center | Calendar widget, `com.apple.CalendarWidget.CalendarTimelineComplication`, with an encoded intent |
| Bottom left and center | Home accessories widgets, `com.apple.NanoHome.NHOAccessoriesWidget`, each with an encoded intent |
| Bottom right | Home widget, `NanoHomeWidget`, with no encoded intent |
| Date | Built-in `app: date`, with no widget descriptor |

The three encoded intents are base64 binary property lists rooted in `NSKeyedArchiver`. The Home accessory payloads contain `INAppIntent` objects; the Calendar payload contains `INIntent`/`INCodable` objects. Their serialized parameters include identifiers tied to my setup, so the raw payloads should remain private.

All three Home slots share the same bundle ID and item ID in `metadata.json` despite having different descriptor kinds and intent presence. That item ID cannot, by itself, distinguish their configurations. The date slot has no metadata item ID and maps to `com.apple.nanotimekit.internal` there; its `face.json` app value is not a bundle ID.
