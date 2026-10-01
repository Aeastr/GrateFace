# Watch face research

I inspected six `.watchface` files exported from my watch on 1 October 2026: Exactograph, Activity Digital, Solar Analog, Solar Analog 2, Solar Analog 3, and Modular. This is format exploration, separate from the Photos generator. The exports remain outside the repository; no archive, snapshot, or personal complication payload is checked in.

## How these were inspected

Each file opens as a ZIP archive. I listed its entries, parsed `face.json` and `metadata.json`, checked the ZIP members for read errors, and compared corresponding members across the three Solar Analog exports. I did not change or import any face on a watch.

## Shared structure

| Export | `face.json` identity | Complication slots in `face.json` | Archive entries |
| --- | --- | ---: | ---: |
| Exactograph | `face type: bundle`; `com.apple.NTKExactitudesFaceBundle` | 4 | 4 |
| Activity Digital | `face type: activity digital`; no `bundle id` key | 3 | 4 |
| Solar Analog (all three) | `face type: bundle`; `com.apple.NTKGladiusFaceBundle` | 2 | 6 each |
| Modular | `face type: whistler-digital`; no `bundle id` key | 6 | 4 |

- Every export has `face.json`, `metadata.json`, `snapshot.png`, and `no_borders_snapshot.png`. None has a `Resources` directory or separate dial artwork. The archives do not contain the watch's rendering assets.
- All six have `face.json` version `4`, `metadata.json` version `2`, `device_size: 8`, and `forMigration: false`. The meaning and compatibility range of `device_size: 8` were not tested.
- Every `snapshot.png` is 799 × 919 pixels and includes a watch bezel; every `no_borders_snapshot.png` is 624 × 744 pixels and omits that bezel.
- The three Solar Analog ZIPs also have `complicationData/` and `complicationData/subdial-top/`, but both are empty directory entries. The top subdial's sample template is instead present in `metadata.json` as `CLKComplicationTemplateDigitalTime`.
- `face.json` uses slot names with spaces (`subdial top`, `bottom center`), while `metadata.json` uses hyphens (`subdial-top`, `bottom-center`). This matters when comparing the two files.
- `metadata.json` includes display names and app identifiers for complications. `face.json` gives the selected apps and, for some widget complications, a descriptor with a `kind` and an encoded `intent`. Use those fields to inventory saved complication choices.

## Face notes

- [Photos](Photos/Findings.md)
- [Exactograph](Exactograph/Findings.md)
- [Activity Digital](ActivityDigital/Findings.md)
- [Solar Analog, including all three variants](SolarAnalog/Findings.md)
- [Modular](Modular/Findings.md)

## Broader questions

- Compare another watch size or OS export to learn whether `device_size`, preview dimensions, and face versions change together.
- For any future archive writer, determine which fields are required by an importing watch. The presence of readable JSON and a valid ZIP does not establish that edited faces can be imported.
