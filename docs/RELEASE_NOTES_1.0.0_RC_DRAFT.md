# Pixel Track Works 1.0.0 RC — Draft Release Notes

> This document is a release-candidate draft. Do not publish it as final 1.0.0 notes until `ReleaseReadiness` and manual Windows certification are complete.

## Build tracks and drive them immediately

Pixel Track Works combines the track builder and racing runtime in the same game state. Build a course, press Test Drive, discover a bad corner, return to the Builder, fix it, and drive again without exporting a level.

Builder features include:

- smart connected roads
- four road widths
- Draw-a-Track freehand creation
- asphalt, dirt, gravel, sand and grass handling surfaces
- terrain painting
- pit and alternate routes
- Start/Finish and ordered checkpoints
- continuous validation
- selection, copy/cut/paste, rotate and mirror
- eyedropper
- undo/redo
- generated previews

## Race modes

- Circuit
- Time Trial
- Sprint
- Checkpoint Rush
- Drift Trial
- Elimination

Events support up to 12 racers total.

## Vehicles

The game uses the authored Wheels in Pixels car and bike roster and keeps the original vehicle-stat data as the basis for gameplay tuning.

Features include:

- arcade acceleration/braking/steering
- surface-sensitive grip and rolling resistance
- drift
- nitro
- reset/recovery
- paint variants
- Garage ownership and purchases
- performance upgrades
- tuning
- persistent vehicle selection

Procedural player-engine audio uses distinct profiles for sport, motorcycle, electric, muscle, Grand Prix/formula, rally and heavy/off-road vehicles.

## AI racing

AI racers use the official main route and include:

- speed-scaled lookahead
- curvature-aware braking
- skill/aggression/consistency differences
- mistake rate
- racing-line offsets
- overtaking bias
- nearby-car avoidance
- drafting
- boost decisions
- stuck recovery

Optional-route strategy remains outside the current certified V1 scope unless completed before release.

## Career and Garage

Career progression includes:

- credits
- reputation
- seven tiers
- venue progression
- builder contracts
- championship milestones
- construction/vehicle-class unlocks
- sponsor streaks

Garage/Career state uses validated crash-recovery persistence with last-known-good backup support.

## Procedural tracks

The Random Track Lab supports deterministic generation with:

- seed
- map size
- Circuit / Mixed / Rally / Oval / Technical style
- complexity
- road width
- scenery density

Generated tracks are normal editable tracks and can be changed, tested and saved immediately.

## Ghosts and records

Time Trial includes persistent best ghosts recorded from GO at fixed intervals.

Only a completed faster lap replaces the current best ghost. Ghost persistence includes restart and corruption-recovery regression coverage.

## Track sharing

Tracks can be exported as a portable `.pixeltrack` file containing:

```text
track.json
metadata.json
preview.png   # optional
```

Sharing supports:

- author
- description
- tags
- thumbnail preview
- schema compatibility checks
- duplicate-ID protection
- preview-before-import
- legacy JSON compatibility

## Dialogue and race radio

A modular dialogue layer supports:

- speaker definitions
- portrait atlas regions
- priorities
- conditions
- cooldowns
- once-only flags
- full dialogue outside races
- compact non-blocking race-radio messages while driving

Current race-radio events include GO, position changes around P1, final lap, pit entry/speeding, low nitro, drift milestones, elimination pressure, best lap and race finish.

### Character art status before RC publication

The final V1 visual requirement also includes layered on-foot characters walking to cars/locations and portrait art from the supplied character sheets.

The following source PNGs must be committed, measured and packaged before these release notes can be finalized:

- `Body-Idle-Right.png`
- `Body-Running-Right.png`
- `Head-Idle-Right.png`
- `Head-Running-Right.png`
- `PORTRAITS.png`

The game does not guess their atlas dimensions.

## Audio and atmosphere

Current bounded procedural layers include:

- vehicle engine/tire/boost/impact audio
- UI feedback
- race event cues
- purchase/upgrade/unlock feedback
- game-mode music
- venue/track ambience

A final production mix/fatigue pass is required before release.

## Accessibility and controls

Implemented settings include:

- persistent rebinding
- UI scale
- large text
- flash reduction
- camera-shake control
- controller vibration and strength
- steering sensitivity
- auto accelerate
- auto brake
- traction assist
- drift assist
- recovery assist
- track-edge assist
- hold/toggle boost
- master/music/SFX volume
- window/fullscreen/borderless preferences
- colorblind preference model

Full Xbox/XInput, PlayStation-style and generic-controller certification plus the resolution/UI-scale matrix must be completed before final V1 publication.

## Saves and migration

Track schema migration supports v1 → v2.

Track saves use validated temporary writes and last-known-good backup recovery. Malformed JSON and unsupported future schemas are rejected rather than guessed.

Ghost, Garage and Career state use equivalent validated recovery patterns.

Typical player data locations include:

```text
user://tracks/<track_id>/track.json
user://ghosts/<track_id>/<vehicle>_<mode>.json
user://track_exports/
```

## Windows build and release verification

The strict CI chain includes:

- official Godot 4.7.1 import
- parser/compiler error rejection
- core/migration/standings tests
- presentation/collision tests
- procedural-generation tests
- sharing round trips
- persistence/recovery tests
- release-readiness contracts
- deterministic stress tests
- Windows export
- ZIP integrity verification
- SHA-256 generation
- artifact upload
- packaged Windows EXE smoke boot

CI does not replace the required clean-machine manual test.

## Known limitations before final 1.0.0

These items must remain visible until resolved/certified:

- character/portrait source sheets are not yet committed/measured
- visible asset-backed paddock/walk-to-car sequences are not yet packaged and certified
- 12-car 1080p target-hardware performance certification is pending
- controller hardware matrix is pending
- UI scale/resolution/high-DPI matrix is pending
- full vehicle-feel and drift-exploit audit is pending
- clean Windows machine persistence test is pending
- final audio mix pass is pending
- Garage/Career presentation still has room for final polish

Do not relabel the current development branch as production `1.0.0` until these are closed.
