# Pixel Track Works — Quick Start

## Launch

1. Extract the complete Windows ZIP to a writable folder.
2. Run `PixelTrackWorks.exe`.
3. No Godot installation is required for the packaged build.

Keep the files together inside the extracted folder.

## Build your first track

1. Start from the main menu and enter the Builder.
2. Paint a connected road loop.
3. Place a Start/Finish object on the main road.
4. Place the required checkpoints in route order.
5. Watch the validation feedback while editing.
6. Use **Test Drive** to drive the current unsaved track immediately.
7. Return to the Builder, fix the layout, and save when satisfied.

`TrackData` is the authoritative track state, so the same track data is used by rendering, validation, AI, racing, save/load and sharing.

## Random Track Lab

Choose Random Track to generate an editable course.

Available controls include:

- style: Circuit / Mixed / Rally / Oval / Technical
- map size
- complexity
- road width
- scenery density
- deterministic seed

Use **Generate**, edit the result normally, Test Drive it, and save it like any authored track.

## Race

The current event modes are:

- Circuit
- Time Trial
- Sprint
- Checkpoint Rush
- Drift Trial
- Elimination

Events can use up to 12 racers total.

During races:

- ordered checkpoints protect lap progress
- standings use the shared race-progress tracker
- drifting earns score and nitro
- race-radio messages are non-blocking and do not pause driving

## Garage and Career

Garage progression includes:

- vehicle purchases
- paint variants
- upgrades
- tuning

Career progression includes:

- credits
- reputation
- seven tiers
- builder contracts
- championship milestones
- unlocks

Progress is saved automatically using validated temporary files and last-known-good backups.

## Sharing tracks

Use the Track Sharing screen to export a `.pixeltrack` file.

A `.pixeltrack` package includes:

```text
track.json
metadata.json
preview.png   # when available
```

Before importing a `.pixeltrack`, the game checks package/schema compatibility and shows metadata/preview information when available.

Legacy JSON track import remains supported.

## Player data

Typical local data paths inside Godot's user-data directory are:

```text
user://tracks/<track_id>/track.json
user://ghosts/<track_id>/<vehicle>_<mode>.json
user://track_exports/
```

Do not manually edit active save files while the game is running.

## Accessibility and controls

Settings include persistent rebinding, UI scale, large text, flash reduction, camera-shake control, vibration controls, steering sensitivity, auto accelerate/brake, traction/drift/recovery/track-edge assists, boost hold/toggle, volume controls and display-mode preferences.

The final V1 controller/resolution hardware matrix must be completed before the release candidate is promoted to production 1.0.0.

## Current pre-1.0 character-art limitation

The development branch already contains the character movement, venue sequencing, portrait dialogue and race-radio architecture. The supplied body/head/portrait source sheets still need to be committed and measured before visible asset-backed walk-to-car/location sequences can be certified.

This limitation must be removed before final V1 publication.
