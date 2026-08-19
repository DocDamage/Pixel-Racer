# Pixel Track Works

A Godot 4.7.x top-down arcade racer built around the **Wheels in Pixels** asset pack already stored in this repository.

The central product loop is implemented as a single live world:

**Build → Test Drive → Return to Builder → Adjust → Race**

No track export, scene reload, or compile step is required to test an edit.

## Current playable implementation

- Smart cardinal road connections with N/E/S/W bitmasks.
- Authoritative `TrackData` model independent of rendering.
- Grass, asphalt, sand, dirt, and gravel surface physics.
- Mouse + keyboard + controller-friendly track construction controls.
- Road, terrain, Start/Finish, checkpoints, barriers, erase, undo, and redo.
- Shift-drag region selection with copy/cut/paste, rotate, mirror, delete, and eyedropper workflows.
- Continuous validation with highlighted invalid cells.
- Atomic JSON track save/load plus portable JSON export/import services.
- Instant in-place test drive.
- 16-direction sprite-sheet vehicle rendering using the bundled vehicle art.
- Existing vehicle definitions are read from `js/config/vehicleData.js` rather than replaced.
- Arcade acceleration, braking, reverse, steering, lateral grip, collision response, reset, drift scoring, and nitro.
- Bundled smoke and nitro sprite sheets animate during drifts and boost.
- Checkpoint-protected lap timing and best-lap tracking.
- Data-driven rules for Circuit, Time Trial, Sprint, Checkpoint Rush, and Drift Trial; the current menu Quick Race launches Circuit while the other rules are ready for the race-setup UI pass.
- Quick Race with generated AI racing-line traversal and three opponents.
- Procedural valid-loop track generation.
- Ghost recording/playback data model.
- Garage vehicle selection.
- Career profile/contracts foundation with credits, reputation, and tiers.
- Accessibility/assist settings persisted in `user://settings.json`.
- Windows Desktop export preset.

## Launch

Open the repository root in **Godot 4.7.x** and run the project.

The intended internal resolution is **640×360** with nearest-neighbor pixel rendering.

## Builder controls

| Action | Keyboard / Mouse | Controller |
|---|---|---|
| Place | Left mouse / Enter | A |
| Erase | Right mouse / Backspace | B |
| Pan | Arrow keys | Left stick / D-pad UI navigation |
| Zoom | Mouse wheel | — |
| Previous / next tool | Q / E | LB / RB |
| Road / Sand / Dirt / Grass | 1 / 2 / 3 / 4 | toolbar |
| Start / Checkpoint / Barrier / Erase | 5 / 6 / 7 / 8 | toolbar |
| Select region | Shift + left-drag | — |
| Copy / Cut / Paste | Ctrl+C / Ctrl+X / Ctrl+V | UI/context later |
| Rotate / mirror clipboard | R / M | UI/context later |
| Eyedropper | X / middle mouse | X |
| Delete selected region | Delete | UI/context later |
| Rotate barrier | R (when clipboard empty) | toolbar/context |
| Undo / Redo | Z / Y | UI |
| Save / Load | F2 / F3 | UI |
| Test Drive | F5 | Start |

## Driving controls

| Action | Keyboard | Controller |
|---|---|---|
| Accelerate | W / Up | RT |
| Brake / Reverse | S / Down | LT |
| Steer | A/D or Left/Right | Left stick |
| Handbrake | Space | B |
| Nitro | Shift | A |
| Reset | R | Y |
| Return from Test Drive | F5 / Esc | Start |

## Data architecture

`TrackData` is the source of truth. Rendering, validation, AI, serialization, and runtime collisions all consume the same model. The visual road layer is deliberately not authoritative, which keeps migration, procedural generation, sharing, and undo/redo independent of Godot scene state.

Saved tracks use schema version 1 and live under:

```text
user://tracks/<track_id>/track.json
```

Manual export packages currently use portable JSON in:

```text
user://track_exports/
```

## Headless core tests

With a Godot 4.7.x executable available:

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

The suite covers smart-road masks, serialization, circuit validation, builder clipboard transforms, race-mode presets, and deterministic procedural validity.

## Repository note

The existing web files (`index.html`, `js/config`, `js/core`) and original asset directories are intentionally preserved. The Godot runtime reuses the existing vehicle configuration rather than deleting or rewriting that work.
