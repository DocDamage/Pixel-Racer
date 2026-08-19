# Pixel Track Works

A Godot 4.7.x top-down arcade racing game and track-construction sandbox built around the **Wheels in Pixels** assets already stored in this repository.

The central product loop runs in one live world:

**Build → Test Drive → Return to Builder → Adjust → Configure Event → Race → Progress**

Testing an edit does not require exporting a map, reloading the level, or leaving the builder scene.

## Current playable implementation

### Track builder
- Authoritative schema-versioned `TrackData` model independent of rendering.
- Smart N/E/S/W road connection masks.
- Standard road painting plus freehand **Draw-a-Track**.
- Narrow / Standard / Wide / Extra Wide road widths.
- Asphalt, grass, sand, dirt and gravel handling surfaces.
- Surface painting changes the actual driveable road physics.
- Start/Finish and ordered checkpoints.
- Pit and alternate-route classification.
- Route-aware validation: official main circuit stays a strict closed loop while legal bypasses may leave/rejoin it at two interfaces.
- Pit-lane speed limits and race-time speeding penalties.
- Cyan pit and amber alternate-route editor indicators.
- Shift-drag region selection.
- Copy / cut / paste / rotate / mirror / delete.
- Eyedropper.
- Undo / redo.
- Continuous validation with highlighted issue cells.
- Track ratings and preview PNG generation.
- Atomic save/load/delete, JSON import and portable package export.

### Driving and racing
- 16-direction vehicle sprites from the bundled asset pack.
- Existing authored vehicle definitions are read from `js/config/vehicleData.js` rather than replaced.
- Arcade acceleration, braking, reverse, steering, grip, drag and collision response.
- Surface-specific handling.
- Drift scoring, drift-earned nitro, smoke, nitro VFX and skid marks.
- Controller vibration and configurable camera feedback.
- Checkpoint-protected laps, penalties and timing.
- Shared route-aware race progress, live P-position and stable finish order.
- Live top-five standings overlay.
- Circuit, Time Trial, Sprint, Checkpoint Rush, Drift Trial and Elimination.
- Event Setup UI with configurable lap/opponent counts.
- AI lookahead, curvature speed planning, braking skill, personalities, avoidance, overtaking bias, drafting, boost behavior and stuck recovery.
- Up to 11 AI opponents / 12 racers total.

### Time Trial, records and ghosts
- Per-track/per-vehicle/per-mode records.
- Fixed-interval ghost recording and interpolated visual playback.
- Existing best ghost loads before Time Trial.
- Recorder and playback start exactly on GO.
- Only a faster completed lap atomically replaces the best ghost.
- Track Library surfaces preview, rating, records and ghost presence.

### Garage and career
- Full bundled vehicle roster.
- Credit-based vehicle purchasing and paint variants.
- Engine, transmission, tires, brakes, suspension, weight and nitro upgrades.
- Stock / Street / Sport / Race upgrade tiers.
- Persistent tuning applied to player physics.
- Seven career tiers from **Backyard Racer** through **Track Architect**.
- Builder contracts with requirements, credits and reputation.
- Construction and vehicle-class unlock tables.
- Seven tier-gated championships.
- Menu championship selector.
- P1 race result completes the championship and awards career rewards.

### Accessibility and settings
- Persistent keyboard/gamepad remapping.
- In-game press-next-input rebinding for keys, buttons and axes.
- UI scale and large text.
- camera shake.
- flash intensity.
- steering sensitivity.
- auto acceleration and auto braking.
- traction, drift, recovery and track-edge assists.
- hold/toggle boost.
- controller vibration and strength.
- master/music/SFX volume settings model.
- windowed/fullscreen/borderless selection.

## Launch

Open the repository root in **Godot 4.7.x** and run the project.

Internal resolution is **640×360** with nearest-neighbor pixel rendering and 2D pixel snapping.

## Builder controls

| Action | Keyboard / Mouse | Controller |
|---|---|---|
| Place / paint | Left mouse / Enter | A |
| Erase | Right mouse / Backspace | B |
| Pan | Arrow keys | Left stick / D-pad UI navigation |
| Zoom | Mouse wheel | — |
| Previous / next tool | Q / E | LB / RB |
| Road | 1 | toolbar |
| Draw-a-Track | 2 | toolbar |
| Pit route | 3 | toolbar |
| Sand / Dirt / Grass | 4 / 5 / 6 | toolbar |
| Start / Checkpoint / Barrier | 7 / 8 / 9 | toolbar |
| Erase tool | 0 | toolbar |
| Alternate route tool | B | toolbar |
| Select region | Shift + left-drag | — |
| Copy / Cut / Paste | Ctrl+C / Ctrl+X / Ctrl+V | UI/context controls |
| Assign selection to Main / Pit / Alternate | Ctrl+1 / Ctrl+2 / Ctrl+3 | UI/context controls |
| Rotate / mirror clipboard | R / M | UI/context controls |
| Cycle road width | T | UI/context controls |
| Eyedropper | X / middle mouse | X |
| Delete selected region | Delete | UI/context controls |
| Undo / Redo | Z / Y | UI |
| Save / Load | F2 / F3 | UI |
| Test Drive | F5 | Start |

## Driving controls

Defaults are fully rebindable in Settings.

| Action | Keyboard | Controller |
|---|---|---|
| Accelerate | W / Up | RT |
| Brake / Reverse | S / Down | LT |
| Steer | A/D or Left/Right | Left stick |
| Handbrake | Space | B |
| Nitro | Shift | A |
| Reset | R | Y |
| Return from Test Drive | F5 / Esc | Start |

## Track architecture

`TrackData` is the source of truth. Rendering, validation, AI, race progress, serialization, procedural generation, sharing and undo/redo consume the same model. The visual road layer is deliberately not authoritative.

Saved tracks live under:

```text
user://tracks/<track_id>/track.json
```

Track packages are exported under:

```text
user://track_exports/<track_name>_<track_id>/
    track.json
    metadata.json
    preview.png        # when available
```

Best ghosts live under:

```text
user://ghosts/<track_id>/<vehicle>_<mode>.json
```

## Automated validation

The GitHub Actions workflow downloads the official **Godot 4.7.1** binary and export templates.

The exact PR head is gated by:

```text
Godot headless import/parser
→ core regressions
→ race-position/finish-order regressions
→ deterministic large-track / 12-racer stress tests
→ Windows release export
→ ZIP integrity/content verification
→ SHA-256 checksum
→ workflow artifact upload
```

Local commands with Godot available:

```bash
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/run_race_progress_tests.gd
godot --headless --path . --script res://tests/run_stress_tests.gd
```

The stress suite covers 60 generated tracks across Circuit/Mixed/Rally styles, a 96×96 large track, 12-racer AI path setup, 100 serialization round trips and large preview rendering.

## What still separates this branch from a production V1.0

Core architecture is largely implemented. Remaining release work is concentrated in:

- deeper use of the bundled track/decor sprite sheets;
- larger environment/decor content palette;
- engine/tire/impact/nitro/UI audio and music;
- crowd/environment ambience and richer crash feedback;
- manual multi-car contact/overtaking tuning;
- manual 12-car runtime FPS profiling on target Windows hardware;
- full controller-focus, large-text, UI-scale and high-DPI visual QA;
- clean-machine save/import/export/ghost persistence testing;
- final versioning, release notes and distribution packaging.

See `docs/IMPLEMENTATION_STATUS.md` for the phase-by-phase status.

## Repository note

The existing web files (`index.html`, `js/config`, `js/core`), manifests, vehicle catalog and original asset directories are intentionally preserved. The Godot implementation reuses them rather than deleting or rewriting that work.
