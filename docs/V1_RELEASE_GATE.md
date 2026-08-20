# Pixel Track Works — V1 Release Gate

This file records the release gate that must be satisfied before PR #1 leaves draft and before the project is labeled production `1.0.0`.

The current development identity is `0.9.0-dev.1`. `project.godot` is the authoritative human-readable version. CI derives the Windows numeric resource version, artifact name, ZIP name, checksum name, and release manifest from it.

## Automated gate

The exact release-candidate head must pass all of the following with official Godot 4.7.1:

- release metadata and Windows-version consistency
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
- controller InputMap, contextual pause/Test Drive, and runtime focusability audit
- release-readiness contract regressions
- deterministic stress tests
- strict Windows export
- versioned release bundle construction
- release manifest, exact-content, ZIP-integrity, and SHA-256 verification
- normal packaged Windows headless boot
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

Drift scoring requires sufficient forward speed, lateral slip, drift angle, track occupancy, and real frame-to-frame movement. It grows a bounded combo multiplier, breaks and briefly locks scoring on collision, tracks travel/net progress/rotation, and rejects closed donut loops with poor net progress.

Manual balance testing is still required because automated anti-exploit coverage cannot determine final game feel.

## Garage persistence-to-physics gate

`GarageManager` automatically loads persisted state when constructed. A fresh manager used by race setup must reproduce persisted ownership, tuning, and upgrades so Garage changes affect actual race physics rather than existing only in menu state.

## Controller structural gate

CI checks that:

- all essential driving actions exist and have gamepad coverage
- Start is contextual: Test Drive in Builder, Pause while driving
- F5 is contextual: Test Drive in Builder, Pause while driving
- Esc/Cancel cannot directly abandon Test Drive or a race
- pausing preserves the active Test Drive/race mode
- core Godot UI navigation actions exist
- the main runtime scene instantiates headlessly
- every instantiated `Button`, `OptionButton`, `SpinBox`, slider, `LineEdit`, and `CheckBox` is focusable

This blocks obvious mouse-only and direct-exit regressions. It does **not** replace the required physical Xbox/XInput, PlayStation-style, and generic-controller manual audit.

## Release bundle gate

The automated development bundle is versioned as:

```text
PixelTrackWorks-<project-version>-Windows-x64.zip
PixelTrackWorks-<project-version>-Windows-x64.zip.sha256
```

The ZIP must contain exactly the approved flat bundle files:

- `PixelTrackWorks.exe`
- `README.md`
- `QUICK_START.md`
- `RELEASE_NOTES.md`
- `ASSET_ATTRIBUTION.md`
- `VERSION.txt`
- `RELEASE_MANIFEST.json`
- `LICENSE` only when the repository actually contains a release license file

`RELEASE_MANIFEST.json` records the product version, derived Windows version, source commit, CI commit, Godot version, platform, executable size/hash, and exact bundle file list. The Windows job re-verifies the downloaded ZIP and checksum before extraction and boot.

## Current hard blocker outside code

The following five V1 presentation assets still need to be committed and measured:

- `Body-Idle-Right.png`
- `Body-Running-Right.png`
- `Head-Idle-Right.png`
- `Head-Running-Right.png`
- `PORTRAITS.png`

Until those binaries are present, atlas geometry must remain unguessed and the visible on-foot/portrait requirement remains incomplete.

## Manual release certification still required

Even a fully green automated gate is insufficient for production `1.0.0`. The following still require real manual execution:

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
