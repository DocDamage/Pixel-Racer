# Pixel Track Works — V1 Release Gate

This file records the release gate that must be satisfied before PR #1 leaves draft and before the project is labeled production `1.0.0`.

## Automated gate

The exact release-candidate head must pass all of the following with official Godot 4.7.1:

- project import with parser/compiler/script-load error rejection
- core regressions
- track schema migration regressions
- shared race-standings regressions
- drift-scoring exploit regressions
- presentation/dialogue/collision regressions
- parameterized procedural-generation regressions
- `.pixeltrack` sharing round trips
- track save corruption/recovery regressions
- ghost restart/recovery regressions
- Garage/Career profile persistence regressions
- once-only dialogue persistence regressions
- controller InputMap and runtime focusability audit
- release-readiness contract regressions
- deterministic stress tests
- strict Windows export
- release ZIP integrity checks
- SHA-256 generation
- packaged Windows headless boot
- packaged Windows release self-test

The packaged release self-test runs inside the exported `PixelTrackWorks.exe` and verifies on the fresh Windows runner:

- writable `user://` track save/reload
- raceable generated-track reload
- ghost save/reload
- validated backup recovery after a deliberately corrupted primary profile file
- preview generation
- `.pixeltrack` export/inspection/import
- duplicate track-ID protection
- cleanup of self-test data

A normal packaged boot is run separately before the self-test.

## Drift anti-exploit baseline

Drift scoring is no longer raw lateral-slip accumulation.

The scoring model now requires:

- sufficient forward speed
- sufficient lateral slip
- a minimum drift angle
- actual track occupancy
- real frame-to-frame movement

It also:

- grows a bounded combo multiplier over sustained valid drifts
- breaks the combo on vehicle collision
- applies a short post-impact scoring lock to discourage wall-riding
- tracks combo travel, net progress and accumulated rotation
- rejects closed donut loops when the car accumulates near-full rotation with poor net progress

Manual balance testing is still required because automated anti-exploit coverage cannot determine final game feel.

## Garage persistence-to-physics gate

`GarageManager` automatically loads persisted state when constructed.

This matters because race vehicles create a fresh manager to calculate the player's effective vehicle definition. Regression coverage now proves that a persisted Engine upgrade loaded by a fresh manager changes the effective race definition rather than existing only in menu/profile data.

## Controller structural gate

CI now checks that:

- all essential driving actions exist
- every essential driving action has at least one gamepad binding
- core Godot UI navigation actions exist
- the main runtime scene can instantiate headlessly
- every instantiated `Button`, `OptionButton`, `SpinBox`, slider, `LineEdit`, and `CheckBox` is focusable

This blocks obvious mouse-only regressions. It does **not** replace the required physical Xbox/XInput, PlayStation-style, and generic-controller manual audit.

## Release bundle gate

The Windows ZIP must contain at least:

- `PixelTrackWorks.exe`
- `README.md`
- `QUICK_START.md`
- `RELEASE_NOTES.md`
- `ASSET_ATTRIBUTION.md`
- `LICENSE` when the repository contains a release license file

The Windows smoke job verifies these files after extraction before booting the executable.

## Current hard blocker outside code

The following five V1 presentation assets still need to be committed and measured:

- `Body-Idle-Right.png`
- `Body-Running-Right.png`
- `Head-Idle-Right.png`
- `Head-Running-Right.png`
- `PORTRAITS.png`

Until those binaries are present, atlas geometry must remain unguessed and the visible on-foot/portrait requirement remains incomplete.

## Manual release certification still required

Even a fully green automated gate is insufficient for production 1.0.0. The following still require real manual execution:

- clean Windows machine unzip/launch/build/save/race/relaunch test
- 12-car 1080p performance profile against the stable 60 FPS target
- Xbox/XInput controller audit
- PlayStation-style controller audit
- generic DirectInput audit where hardware is available
- UI scale and large-text matrix
- 720p / 1080p / 1440p / high-DPI resize matrix
- full vehicle-roster handling and collision-shape playtest
- final drift feel, donut, and wall-riding balance pass
- asset-backed character/portrait/venue presentation in the packaged build
- audio/music/ambience mix and fatigue pass
- packaged restart/migration/import/export/ghost/Garage/Career persistence QA

PR #1 remains draft until these requirements are satisfied.
