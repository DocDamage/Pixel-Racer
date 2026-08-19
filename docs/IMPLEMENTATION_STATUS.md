# Pixel Track Works — Implementation Status

This document tracks the actual state of the Godot implementation against the detailed Pixel Track Works design plan. It is intentionally conservative: implemented foundations are distinguished from final production polish and manual release QA.

## Current milestone

The branch now contains a broad playable pre-1.0 implementation rather than only the original vertical slice.

The core loop is live:

**Build → Test Drive → Return to Builder → Adjust → Configure Event → Race → Earn/Progress**

The original Wheels in Pixels assets, browser files, manifests, and authored JS vehicle configuration remain preserved in the repository.

---

## Phase status

### Phase 0 — Project Foundation — IMPLEMENTED
- Godot 4.7.x project.
- 640×360 internal pixel-first viewport.
- nearest-neighbor rendering and 2D pixel snapping.
- game/save/settings/input autoloads.
- Windows export preset.
- original asset pack preserved in place.
- existing `js/config/vehicleData.js` reused as the authored vehicle source.

### Phase 1 — Vehicle Prototype — IMPLEMENTED
- arcade forward/lateral velocity model.
- acceleration, braking, reverse, speed-aware steering and drag.
- collision slowdown and reset-to-last-valid-track position.
- 16-direction vehicle sprite-sheet frame selection.
- camera follow and speed look-ahead.
- configurable camera feedback.

### Phase 2 — Surface Physics — IMPLEMENTED
- asphalt, grass, sand, dirt and gravel.
- grip, rolling resistance and maximum-speed multipliers.
- painting dirt/sand/gravel over an existing road changes the driveable road surface rather than only the ground below it.
- mixed/rally surfaces preserve road width and route metadata.

### Phase 3 — Track Data Model — IMPLEMENTED
- schema-versioned `TrackData` source of truth independent from rendering.
- terrain, roads, environment objects, race objects, event presets and metadata.
- smart cardinal connection masks.
- discrete road widths: Narrow / Standard / Wide / Extra Wide.
- route definitions for main, pit and alternate routes.
- route metadata migrates during load for older schema-v1 tracks.
- serialization/deserialization, clone support and dirty tracking.

### Phase 4 — Track Renderer — IMPLEMENTED FOUNDATION
- data-driven terrain and road rendering.
- smart connected-road visuals and curbs.
- width-aware road rendering.
- Start/Finish, checkpoints, validation markers and editor grid.
- cyan pit-route and amber alternate-route authoring indicators.

Remaining production work:
- deeper use of the bundled track/decor sprite sheets instead of relying primarily on procedural road geometry.
- larger environment/decor palette and production scenery composition.

### Phase 5 — Builder Core — IMPLEMENTED
- builder camera and placement cursor.
- road and terrain painting.
- freehand Draw-a-Track rasterization.
- pit and alternate-route tools.
- Start/Finish, checkpoints and environment objects.
- erase, undo and redo.
- Shift-drag region selection.
- copy / cut / paste.
- rotate and mirror clipboard.
- region delete.
- eyedropper.
- selection-based Ctrl+1 main / Ctrl+2 pit / Ctrl+3 alternate classification.
- keyboard, mouse and controller pathways.

### Phase 6 — Race Logic — IMPLEMENTED
- countdown.
- ordered required checkpoints.
- shortcut-protected laps.
- lap and total timing.
- penalties.
- finish state.
- pit-lane speed detection and timed speeding penalties.
- route-aware official main circuit.
- shared race-progress tracker with lap progress, P-position and immutable finish order.

### Phase 7 — Instant Test Loop — IMPLEMENTED
- editor and runtime stay in the same loaded world.
- editor camera state is preserved.
- test vehicle spawns from Start/Finish or valid road fallback.
- unsaved edits survive Build → Test → Edit.

### Phase 8 — Validation — IMPLEMENTED
- missing Start/Finish.
- Start/Finish off track or off main route.
- track-too-short detection.
- disconnected main route.
- strict unbranched closed main loop.
- checkpoint placement/order checks.
- required checkpoints constrained to main route.
- optional route validation.
- optional routes must be simple paths with exactly two valid parent-route interfaces.
- malformed pit/alternate routes block official racing.
- pit speed-limit validation.
- highlighted issue cells.
- route count and optional-route metadata.

### Phase 9 — Drift & Nitro — IMPLEMENTED FOUNDATION
- intentional handbrake grip break.
- slip-based drift scoring.
- drift-earned nitro.
- nitro acceleration and top-speed extension.
- bundled smoke/nitro sprite-sheet VFX.
- fading skid marks.
- flash-intensity accessibility scaling.
- boost/drift/collision controller vibration.

Remaining production work:
- richer impact sparks/debris and environment reactions.
- final drift scoring/tuning balance pass.

### Phase 10 — Vehicle Roster — IMPLEMENTED
- runtime catalog consumes the existing 22-car / 4-bike authored JS definitions.
- bundled color variants.
- full roster used by Garage and AI.

### Phase 11/12 — AI Foundation & Competition — IMPLEMENTED FOUNDATION
- route-filtered main racing line.
- speed-scaled lookahead.
- upcoming-curvature speed planning.
- braking and corner skill.
- aggression, consistency, mistake rate, line bias and overtaking bias.
- nearby-racer avoidance.
- drafting detection and straight-line boost behavior.
- stuck recovery.
- shared standings engine.
- up to 11 AI opponents / 12 racers total.

Automated stress coverage:
- deterministic 12-racer path setup and avoidance context.

Remaining production work:
- manual multi-car contact/overtaking tuning.
- runtime FPS profiling on target Windows hardware with a live 12-car field.

### Phase 13 — Race Modes — IMPLEMENTED
- Circuit.
- Time Trial.
- Sprint.
- Checkpoint Rush.
- Drift Trial.
- Elimination.
- Event Setup UI.
- configurable lap/opponent presets.
- live P-position/top-five standings overlay.

### Phase 14 — Garage — IMPLEMENTED FOUNDATION
- full vehicle roster browser.
- credit-based vehicle purchases.
- paint/color selection.
- engine, transmission, tires, brakes, suspension, weight and nitro upgrade groups.
- Stock / Street / Sport / Race tiers.
- persistent tuning backend integrated into player physics.

Remaining production work:
- richer vehicle preview/presentation and final tuning UX.

### Phase 15 — Career — IMPLEMENTED FOUNDATION
- persistent career profile.
- credits and reputation.
- seven tiers from Backyard Racer through Track Architect.
- venue level.
- construction and vehicle-class unlock tables.
- ten builder contracts with requirement evaluation and claim rewards.
- seven tier-gated championship definitions.
- menu-accessible championship selector.
- race finish position drives championship P1 completion/rewards.
- sponsor streak tracking.

Remaining production work:
- deeper venue presentation and sponsor/championship content dressing.
- multi-event championship series if expanded beyond the current one-event tier championship model.

### Phase 16 — Advanced Builder — IMPLEMENTED FOUNDATION
- region transforms.
- Draw-a-Track.
- four road widths.
- pit-lane classification.
- alternate-route classification.
- serialized route definitions.
- strict parent/bypass semantics.

Remaining production work:
- race rules that intentionally choose/use alternate routes.
- pit service/strategy gameplay beyond lane classification and speed enforcement.
- advanced manual racing-line editor.

### Phase 17 — Procedural Tracks — IMPLEMENTED FOUNDATION
- seeded deterministic generator.
- Circuit, Mixed and Rally styles.
- stepped/chicane layout variation.
- generated Start/Finish and checkpoints.
- editable generated tracks.
- generated-track validation.

Automated stress coverage:
- 60 generated tracks across all three styles and multiple map sizes.
- 96×96 large-track graph validation.

Remaining production work:
- more generator families such as city grids, point-to-point rally and figure-eight layouts.
- procedural scenery pass.

### Phase 18 — Ghosts & Records — IMPLEMENTED
- fixed-interval transform/speed recording.
- interpolated playback.
- per-track/per-vehicle/per-mode best records.
- visual ghost playback component.
- best Time Trial ghost auto-loads and starts on GO.
- recorder starts on GO rather than during countdown.
- only a faster lap atomically replaces the best ghost.
- Track Library surfaces record/ghost presence.

### Phase 19 — Sharing Foundation — IMPLEMENTED
- atomic local track saves.
- track deletion.
- JSON import.
- portable package directories containing `track.json` and `metadata.json`.
- optional `preview.png` packaging.
- package validation.
- duplicate-ID handling on import.
- generated track preview PNGs.

Remaining production work:
- a more polished import/export browser and user-facing package workflow.
- online sharing/workshop remains post-1.0 unless scope changes.

### Phase 20 — UX & Accessibility — IMPLEMENTED FOUNDATION
- controller-aware input map.
- persistent keyboard/gamepad key/button/axis remapping.
- in-game press-next-input rebinding UI.
- UI scale.
- large text.
- camera shake control.
- flash intensity.
- colorblind indicator preference model.
- steering sensitivity.
- auto acceleration.
- auto braking.
- traction assist.
- drift assist.
- recovery assist.
- track-edge assist.
- hold/toggle boost.
- controller vibration and strength.
- master/music/SFX settings model.
- windowed/fullscreen/borderless setting.

Remaining production work:
- full manual controller-focus audit across every modal and card.
- visual review of large-text and UI-scale combinations on multiple resolutions.

### Phase 21 — Polish — PARTIAL
Implemented:
- smoke.
- nitro VFX.
- skid marks.
- route authoring visualization.
- camera shake/feedback.
- controller vibration.

Still required:
- engine/tire/impact/nitro/UI audio implementation.
- music.
- crowd/environment ambience.
- stronger crash sparks/debris/environment reactions.
- final screen transitions and cohesive visual pass.
- deeper use of bundled track/decor assets.

### Phase 22 — QA & Release — STRONG FOUNDATION, MANUAL QA REMAINS
Automated CI currently includes:
- official Godot 4.7.1 download.
- headless project import/parser gate.
- core regression suite.
- route/pit validation tests.
- race-position/finish-order tests.
- deterministic stress suite.
- 60 generated-track validation cases.
- 96×96 large-track graph test.
- 12-racer AI path/avoidance-context test.
- 100 serialization round trips.
- large preview render test.
- Windows export using official Godot 4.7.1 templates.
- `PixelTrackWorks.exe` existence check.
- ZIP integrity/content verification.
- SHA-256 generation.
- CI artifact upload.

Still required before declaring a production V1.0 release:
- clean Windows-machine launch test.
- real keyboard/mouse + multiple-controller manual test.
- manual 12-car runtime FPS/profile pass on target hardware.
- save/import/export/ghost persistence test across actual application restarts.
- compact/normal/high-DPI UI and accessibility visual QA.
- final audio/music/content polish.
- final release versioning/package naming/release notes.
- installer/signing only if desired for distribution.

---

## Honest current state

The project is no longer just a prototype. The central builder/racer loop, advanced builder foundations, six event modes, AI racing, garage progression, career progression, championships, procedural tracks, records/ghosts, sharing, accessibility/rebinding, stress testing and Windows artifact production are implemented.

It is **not yet an honest production V1.0** because the remaining work is concentrated in art/audio/content polish and manual release QA rather than missing core architecture.

The current development priority is therefore:

1. keep the exact PR head green in Godot 4.7.1 CI;
2. deepen bundled track/environment art integration;
3. add audio/music/crash/environment feedback;
4. complete manual controller/accessibility/performance QA;
5. package and sign off the first release candidate.
