# Pixel Track Works

**Current development version:** `0.9.0-dev.1`

Pixel Track Works is a Godot 4.7.x top-down arcade racing game and track-construction sandbox built around the **Wheels in Pixels** foundation and the normalized runtime art catalog in this repository.

The central loop runs in one live world:

**Build → Test Drive → Return to Builder → Adjust → Configure Event → Race → Progress**

Test Drive uses the same world and track data as the Builder. It does not require an export, a scene reload, or a separate test map.

## Current playable implementation

### Track builder

- Schema-versioned authoritative `TrackData` model independent of rendering.
- Smart N/E/S/W road connections and freehand **Draw-a-Track** rasterization.
- Narrow, Standard, Wide, and Extra Wide roads.
- Asphalt, grass, sand, dirt, and gravel handling surfaces.
- Main, pit, and alternate routes with route-aware validation.
- Strict closed main circuit plus validated two-interface bypass routes.
- Pit-lane speed limits and race-time speeding penalties.
- Start/Finish, ordered checkpoints, validation markers, and issue-cell highlighting.
- Region selection, copy, cut, paste, rotate, mirror, delete, and eyedropper.
- Undo/redo, track ratings, preview generation, and autosave support.
- Atomic track save/load/delete with corruption, backup, and interrupted-write recovery.

### Driving and racing

- 16-direction vehicle rendering using the bundled vehicle catalog.
- Existing authored vehicle data from `js/config/vehicleData.js` remains the vehicle source.
- Arcade acceleration, braking, reverse, speed-aware steering, grip, drag, collision response, and recovery.
- Surface-specific handling, oil hazards, movable props, skid marks, smoke, and nitro VFX.
- Drift scoring with collision locks and donut/wall-riding exploit rejection.
- Circuit, Time Trial, Sprint, Checkpoint Rush, Drift Trial, and Elimination.
- Event Setup UI with configurable laps and opponents.
- Shared race progress, checkpoint-protected laps, penalties, live position, and immutable finish order.
- AI lookahead, curvature speed planning, braking skill, avoidance, drafting, overtaking bias, personality, mistakes, boost use, and stuck recovery.
- Up to 11 AI opponents for 12 racers total.

### Garage, career, and championships

- Full bundled vehicle roster with persistent ownership and color selection.
- Engine, transmission, tires, brakes, suspension, weight, and nitro upgrades.
- Stock, Street, Sport, and Race upgrade tiers.
- Persistent tuning applied to real player physics.
- Credits, reputation, venue progression, builder contracts, and unlock tables.
- Seven career tiers from **Backyard Racer** through **Track Architect**.
- Seven tier-gated championships with P1 completion rewards and sponsor streaks.

### Records, ghosts, and sharing

- Per-track, per-vehicle, and per-mode records.
- Best Time Trial ghost loading, GO-synchronized recording/playback, and atomic replacement only by a faster completed lap.
- Track Library cards with preview, rating, records, and ghost state.
- Modern single-file `.pixeltrack` export, inspection, preview, confirmation, import, and duplicate-ID protection.
- Legacy JSON remains import-compatible inside the reviewed sharing flow; it is no longer a separate primary user path.

### Assets and presentation

- 83 approved logical runtime assets and 31 approved Builder placeables.
- Four deterministic nearest-neighbor runtime atlases.
- Native, Club Circuit, and Pro Circuit visual themes with safe fallback where CraftPix orientation is not proven.
- Data-driven team, driver, avatar, and standings presentation without hidden physics bonuses.
- Animated crowds and pit-crew strips, dynamic hazards/props, collision effects, and an in-game Asset Gallery.
- Procedural vehicle audio, gameplay/UI/progression SFX, adaptive music, and ambience.
- Mode transitions, race presentation, dialogue/radio foundations, and persistent once-only dialogue state.

Character and portrait architecture is present, but the final supplied character source sheets are still required before the visible on-foot/portrait release blocker can be cleared. Missing directional animation is not fabricated.

## Launch from source

Open the repository root in **Godot 4.7.1** and run the project.

The internal presentation target is **640×360**, nearest-neighbor filtered, with 2D transform and vertex pixel snapping.

## Builder controls

All gameplay actions are rebindable in Settings.

| Action | Keyboard / Mouse | Controller |
|---|---|---|
| Place / paint | Left mouse / Enter | A |
| Erase | Right mouse / Backspace | B |
| Pan | Arrow keys | Left stick |
| Zoom | Mouse wheel | — |
| Previous / next tool | Q / E | LB / RB |
| Road / Draw / Pit | 1 / 2 / 3 | Toolbar |
| Sand / Dirt / Grass | 4 / 5 / 6 | Toolbar |
| Start / Checkpoint / Barrier | 7 / 8 / 9 | Toolbar |
| Erase tool | 0 | Toolbar |
| Alternate route | B | Toolbar |
| Select region | Shift + left-drag | Context UI |
| Copy / Cut / Paste | Ctrl+C / Ctrl+X / Ctrl+V | Context UI |
| Main / Pit / Alternate assignment | Ctrl+1 / Ctrl+2 / Ctrl+3 | Context UI |
| Rotate / mirror clipboard | R / M | Context UI |
| Cycle road width | T | Context UI |
| Eyedropper | X / middle mouse | X |
| Delete selection | Delete | Context UI |
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
| Pause | Esc / F5 | Start |

Test Drive and races now use the same pause contract. Pausing preserves the active driving mode and offers Resume, Restart Event where applicable, Return to Builder for Test Drive, and Main Menu. Esc/Start no longer abandons a race or Test Drive directly.

## Save locations

Saved tracks:

```text
user://tracks/<track_id>/track.json
```

Portable track packages:

```text
user://track_exports/*.pixeltrack
```

Best ghosts:

```text
user://ghosts/<track_id>/<vehicle>_<mode>.json
```

Garage, Career, settings, input bindings, records, and dialogue state use persistent `user://` storage with atomic or recovery-aware handling where applicable.

## Automated validation and Windows package

GitHub Actions uses the official **Godot 4.7.1** binary and matching export templates. The exact PR head is gated by:

```text
release metadata consistency
→ project import/parser/script-load gate
→ core, migration, race, presentation, generation, sharing, save, ghost, asset, theme, team, audio, polish, drift, profile, dialogue, release-readiness, and controller suites
→ deterministic large-track / 12-racer stress tests
→ Windows x64 release export
→ versioned bundle manifest and exact-content validation
→ ZIP integrity and SHA-256 verification
→ normal packaged Windows boot
→ packaged persistence/ghost/recovery/.pixeltrack self-test
```

The development artifact is versioned from `project.godot`:

```text
PixelTrackWorks-0.9.0-dev.1-Windows-x64.zip
PixelTrackWorks-0.9.0-dev.1-Windows-x64.zip.sha256
```

The ZIP contains the executable, version, release manifest, README, quick start, release notes, and asset attribution. A repository `LICENSE` is included automatically when one exists; no license text is invented by the build.

The packaged self-test runs inside the exported executable on a fresh Windows runner and verifies writable track persistence, generated-track validation, ghost persistence, backup recovery after deliberate corruption, preview generation, `.pixeltrack` export/inspection/import, duplicate-ID handling, and cleanup.

Local examples with Godot available:

```bash
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/run_release_readiness_tests.gd
godot --headless --path . res://tests/controller_audit_runner.tscn
godot --headless --path . --script res://tests/run_stress_tests.gd
```

## What still blocks production V1.0

The project is a broad playable pre-release, not a certified production `1.0.0`. Remaining release gates are:

- Commit, measure, slice, map, and visibly integrate the actual supplied body/head/portrait source sheets.
- Validate the character-to-car, dialogue, portrait, race-radio, and packaged venue presentation using those real files.
- Complete physical Xbox/XInput, PlayStation-style, and generic DirectInput controller audits.
- Complete UI scale, large-text, 720p/1080p/1440p, and high-DPI visual matrices.
- Profile a packaged 12-car 1080p race against the stable 60 FPS target.
- Playtest representative light, heavy, bike, rally, and high-performance vehicle handling/collision shapes.
- Complete manual drift exploit/feel tuning and the full audio/music/ambience fatigue mix.
- Complete clean-machine launch and full application-restart persistence/migration/import/export certification.
- Resolve and document the applicable Wheels in Pixels usage terms without assuming they match the other supplied packs.

PR #1 remains draft and unmerged until the genuine automated and manual release requirements are satisfied. See `docs/IMPLEMENTATION_STATUS.md` and `docs/V1_RELEASE_GATE.md` for the detailed status and release contract.

## Repository preservation

The existing web files (`index.html`, `js/config`, `js/core`), manifests, source asset directories, and authored vehicle catalog remain intentionally preserved. The Godot implementation consumes and normalizes that work rather than deleting it or storing raw source filenames/atlas coordinates in player saves.
