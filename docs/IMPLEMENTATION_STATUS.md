# Pixel Track Works — Implementation Status

This document tracks the actual state of the Godot implementation against the detailed Pixel Track Works design plan. It is intentionally conservative: implemented systems are distinguished from final authored-content polish and manual release QA.

## Current milestone

The branch contains a broad playable pre-1.0 implementation rather than only the original vertical slice.

The core loop is live:

**Build → Test Drive → Return to Builder → Adjust → Configure Event → Race → Earn/Progress**

The original Wheels in Pixels assets, browser files, manifests, and authored JS vehicle configuration remain preserved in the repository. The runtime now also has a normalized logical asset layer so gameplay/save data no longer depends on source-pack filenames.

---

## Phase status

### Phase 0 — Project Foundation — IMPLEMENTED
- Godot 4.7.x project.
- 640×360 internal pixel-first viewport.
- nearest-neighbor rendering and 2D pixel snapping.
- game/save/settings/input autoloads.
- Windows export preset.
- original asset packs preserved in place.
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
- runtime oil hazard temporarily reduces grip and applies a bounded slip response without mutating TrackData.

### Phase 3 — Track Data Model — IMPLEMENTED
- schema-versioned `TrackData` source of truth independent from rendering.
- terrain, roads, environment objects, race objects, event presets and metadata.
- smart cardinal connection masks.
- discrete road widths: Narrow / Standard / Wide / Extra Wide.
- route definitions for main, pit and alternate routes.
- route metadata migrates during load for older schema-v1 tracks.
- serialization/deserialization, clone support and dirty tracking.
- logical runtime/builder asset IDs survive save/load, copy/paste and eyedropper round trips.
- visual-theme selection persists through existing track metadata without a schema fork.

### Phase 4 — Track Renderer — IMPLEMENTED FOUNDATION
- data-driven terrain and road rendering.
- smart connected-road visuals and curbs.
- width-aware road rendering.
- Start/Finish, checkpoints, validation markers and editor grid.
- cyan pit-route and amber alternate-route authoring indicators.
- normalized runtime asset catalog with 83 approved logical assets.
- deterministic atlas-backed runtime sprites and animated strips.
- four retained runtime atlases for converted CraftPix and Racing Asset V2 content.
- converted Club Circuit and Pro Circuit visual themes are selectable at runtime.
- theme selection has safe native fallback for missing/unknown theme IDs.
- converted terrain and unambiguous straight-road regions render through the theme catalog.

Remaining production work:
- converted CraftPix corner/complex-road regions remain on the native fallback until orientation metadata is proven; the implementation intentionally does not invent rotations.
- optional additional authored scenery composition beyond the current 31-placeable builder catalog.

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
- 31 approved logical catalog placeables, including crowds, pit crews, buildings, vegetation, rocks, props and oil hazard.
- visible **ASSET ›** and **THEME ›** controls.
- keyboard/gamepad catalog cycling while retaining existing builder behavior.
- catalog objects use the same undo, clipboard, autosave and validation paths as legacy objects.

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
- bounded spark/debris impact particles.
- procedural impact audio.
- flash-intensity accessibility scaling.
- boost/drift/collision controller vibration.

Remaining production work:
- final drift scoring/tuning balance pass.
- optional additional runtime-only environment reaction dressing beyond the already-dynamic tire/barrel props.

### Phase 10 — Vehicle Roster — IMPLEMENTED
- runtime catalog consumes the existing 22-car / 4-bike authored JS definitions.
- bundled color variants.
- full roster used by Garage and AI.
- incomplete converted CraftPix car is explicitly presentation/preview-only and cannot silently enter the gameplay roster.

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
- four data-driven Racing Asset V2 team identities.
- deterministic AI team/driver/avatar/presentation-car assignment.
- team identity is presentation metadata only and introduces no hidden vehicle-physics bonuses.
- live standings surface team identity for rivals.

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
- progression purchase/upgrade audio bridge wired into the release scene.

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
- contract/championship/tier unlock events feed the progression-audio bridge.

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
- bounded procedural scenery pass with clear-generated-scenery support.

Automated stress coverage:
- 60 generated tracks across all three styles and multiple map sizes.
- 96×96 large-track graph validation.

Remaining production work:
- more generator families such as city grids, point-to-point rally and figure-eight layouts if scope expands.

### Phase 18 — Ghosts & Records — IMPLEMENTED
- fixed-interval transform/speed recording.
- interpolated playback.
- per-track/per-vehicle/per-mode best records.
- visual ghost playback component.
- best Time Trial ghost auto-loads and starts on GO.
- recorder starts on GO rather than during countdown.
- only a faster lap atomically replaces the best ghost.
- Track Library surfaces record/ghost presence.
- atomic primary/backup/temp-file recovery coverage.

### Phase 19 — Sharing Foundation — IMPLEMENTED
- atomic local track saves.
- track deletion.
- JSON import.
- portable `.pixeltrack` single-file package workflow.
- legacy package-directory compatibility.
- optional preview packaging/restoration.
- package validation.
- duplicate-ID handling on import.
- generated track preview PNGs.

Remaining production work:
- optional additional import/export browser presentation polish.
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
- builder catalog/theme controls use keyboard, controller and focusable UI pathways.

Remaining production work:
- full manual controller-focus audit across every modal and card.
- visual review of large-text and UI-scale combinations on multiple resolutions.

### Phase 21 — Polish — STRONG FOUNDATION
Implemented:
- smoke and nitro sprite-sheet VFX.
- fading skid marks.
- route authoring visualization.
- camera shake/feedback.
- controller vibration.
- bounded spark/debris collision feedback.
- dynamic physical loose tires and safety barrels.
- procedural vehicle audio with distinct bike/electric/muscle/formula/rally/heavy/sport profiles.
- procedural tire/surface/boost/impact audio.
- procedural UI audio.
- gameplay/race event SFX for countdown, GO, checkpoints, laps, records and finish events.
- progression SFX for purchases, upgrades, contracts, championships and tier unlocks.
- adaptive procedural music profiles for menu, builder, race, championship, results and garage contexts.
- procedural crowd/environment ambience.
- normalized converted/native asset integration with 83 runtime assets and 31 approved builder placeables.
- animated crowd and pit-crew strips.
- runtime visual-theme switching with safe native fallback.
- permanent Asset Gallery QA scene with paging, filters, multiple backgrounds, animation playback, pivot/collision guides and 1×/2×/4× inspection.

Remaining production work:
- manual listening/balance pass for procedural audio on real speakers/headphones.
- optional authored soundtrack/SFX replacement if desired; the supplied asset ZIPs contain no WAV/OGG/MP3 audio.
- final screen-transition/cohesion review rather than missing transition architecture.
- final art composition pass and any additional approved asset conversions.
- CraftPix complex road/corner orientation remains gated until real orientation metadata is available.

### Phase 22 — QA & Release — STRONG FOUNDATION, MANUAL QA REMAINS
Automated CI currently includes:
- official Godot 4.7.1 download.
- full `--import` project/parser/resource-import gate.
- core regression suite.
- route/pit validation tests.
- race-position/finish-order tests.
- save recovery and ghost recovery tests.
- asset catalog schema/count contracts for 83 runtime assets and 31 placeables.
- atlas-backed sprite and animated-strip tests.
- oil-hazard behavior tests.
- builder logical-ID placement/eyedropper/serialization tests.
- Asset Gallery scene smoke tests.
- visual-theme persistence/fallback tests.
- deterministic team-presentation tests with no hidden physics bonuses.
- release-scene audio-controller/bridge wiring audit.
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
- packaged Windows executable headless smoke boot on a Windows runner.

Still required before declaring a production V1.0 release:
- interactive clean Windows-machine launch/playthrough test.
- real keyboard/mouse + multiple-controller manual test.
- manual 12-car runtime FPS/profile pass on target hardware.
- save/import/export/ghost persistence test across actual application restarts.
- compact/normal/high-DPI UI and accessibility visual QA.
- manual audio listening/balance QA.
- final release versioning/package naming/release notes.
- installer/signing only if desired for distribution.

---

## Current state

The project is no longer just a prototype. The central builder/racer loop, advanced builder foundations, six event modes, AI racing, garage progression, career progression, championships, procedural tracks/scenery, records/ghosts, sharing, accessibility/rebinding, normalized runtime assets, converted visual themes, data-driven race-team presentation, procedural audio/music/ambience, stress testing and Windows artifact production are implemented.

It is **not yet an honest production V1.0** because the remaining release gates are concentrated in manual playability/performance/accessibility/audio QA and final authored-content composition rather than missing core architecture.

The current development priority is therefore:

1. keep the exact PR head green in Godot 4.7.1 CI and packaged Windows smoke;
2. finish any remaining low-risk Phase 21 cohesion/content polish that can be automated;
3. perform interactive controller/accessibility/audio/performance QA on Windows;
4. fix issues discovered by real playtesting;
5. version, package and sign off the first release candidate.
