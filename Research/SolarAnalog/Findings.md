# Solar Analog

## Face representation

Solar Analog uses `face type: bundle` and `bundle id: com.apple.NTKGladiusFaceBundle`. Across the three samples, the face structure and complication choices stay fixed. The only `face.json` differences are in `customization`:

| Export | `color` | `content` | `style` |
| --- | --- | --- | --- |
| Solar Analog | `gladius.special.graphite` | `light 0` | `style 2` |
| Solar Analog 2 | `seasons.fall2026.burgundy` | `light 0` | `style 2` |
| Solar Analog 3 | `seasons.fall2026.burgundy` | `light 1` | `style 0` |

From the first sample to the second, only `color` changes in `face.json`. From the second to the third, `content` and `style` change together, so these samples do not isolate the role of either field. Both PNG preview members have different bytes in each sample; the serialized settings are the useful controlled comparison here.

## Complications and archive entries

`subdial top` is stored in `face.json` as `app: digital time`, while `metadata.json` maps `subdial-top` to `com.apple.nanotimekit.time` and provides a `CLKComplicationTemplateDigitalTime` sample template. It has no metadata item ID. `subdial bottom` is an Activity widget descriptor with `type: 56` and `kind: ActivityRingsComplication`.

The `metadata.json` files are byte identical across all three samples. Each ZIP has the same six entry paths, including empty `complicationData/` and `complicationData/subdial-top/` directories. Thus, in these samples, the sample template resides in metadata rather than as a file inside the named directory.
