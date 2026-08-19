# Pixel Track Works — Implementation Status

This branch establishes the first complete playable vertical slice and the architecture needed by the detailed design plan.

## Implemented now

### Phase 0 — Project Foundation
- Godot 4.7 project configuration.
- 640×360 pixel-first rendering configuration.
- Autoloads for game state, saves, settings, and input.
- Existing asset pack preserved in-place.
- Existing authored vehicle catalog reused at runtime.

### Phase 1 — Vehicle Prototype
- Arcade forward/lateral velocity model.
- Acceleration, braking/reverse, speed-aware steering, drag, collision response, camera follow, reset.
- 16-direction sprite-sheet frame selection.

### Phase 2 — Surface Physics
- Asphalt, grass, sand, dirt, and gravel handling profiles.
- Surface-specific grip, rolling resistance, and maximum-speed multipliers.

### Phase 3 — Track Data Model
- Versioned `TrackData` model.
- Terrain, road, objects, race objects, metadata, event presets.
- JSON serialization/deserialization and clone support.
- Dirty tracking.

### Phase 4 — Basic Track Renderer
- Data-driven terrain and road renderer.
- Smart connection mask refresh for edited neighbors.
- Curbs, Start/Finish, checkpoints, validation markers, editor grid.

### Phase 5 — Builder Core
- Placement cursor and editor camera.
- Road/terrain painting, erase, Start/Finish, checkpoints, barriers.
- Undo/redo snapshot stack.
- Keyboard/mouse and controller input pathways.

### Phase 6 — Race Logic
- Ordered checkpoints.
- Lap protection.
- Lap timer, best lap, race finish.
- Countdown.

### Phase 7 — Instant Test Loop
- Same world remains loaded.
- Editor camera state is preserved.
- Test vehicle spawns from Start/Finish or a valid road fallback.
- Returning restores the editor without discarding unsaved edits.

### Phase 8 — Validation
- Missing Start/Finish.
- Track-too-short detection.
- Disconnected roads.
- Closed single-loop requirement for V0.1 official races.
- Checkpoint placement/order validation.
- Branch/road-end warnings.
- Highlighted issue cells.
- Length, corner, and difficulty metadata.

### Phase 9 — Drift & Nitro foundation
- Intentional handbrake grip break.
- Slip-based drift scoring.
- Drift-earned nitro.
- Boost acceleration/top-speed extension.

### Phase 10 — Vehicle Roster foundation
- Runtime parser consumes the existing 22-car/4-bike `js/config/vehicleData.js` definitions.
- Garage vehicle selection uses the full bundled roster.

### Phase 11/12 — AI foundation and competition slice
- Track graph → ordered circuit path.
- Speed-scaled lookahead.
- Steering and corner-speed planning.
- Basic driver personality variation.
- Three-opponent Quick Race.

### Phase 14/15 — Garage and Career foundations
- Garage vehicle selection.
- Persistent career profile.
- Credits, reputation, tiers, contract evaluation.

### Phase 17 — Procedural Track foundation
- Seeded valid-loop generator.
- Terrain variation.
- Generated Start/Finish and checkpoints.
- Generated tracks open directly in the builder.

### Phase 18 — Ghost foundation
- Fixed-interval transform/speed recording.
- JSON save/load.
- Interpolated sampling API.

### Phase 19 — Sharing foundation
- Portable schema-v1 JSON export/import service.
- Duplicate ID handling on import.

### Phase 20 — UX & Accessibility foundation
- Controller-aware input map.
- Persisted traction assist, auto acceleration, recovery assist, large text, and colorblind-indicator preferences.

### Phase 22 — Release foundation
- Windows Desktop export preset.
- Headless core test runner.

## Still required before calling this V1.0

The design document's later production scope is intentionally not misrepresented as finished. Remaining release work includes:

- Region selection/copy/paste/mirror and eyedropper UX.
- Draw-a-track, variable widths, pit lanes, and multi-route circuits.
- Full object/decor catalog integration.
- Smoke/skid-mark/nitro VFX using the included VFX sheets.
- Stronger AI overtaking/avoidance/drafting and full 12-car stress validation.
- Sprint, Drift Event, Elimination, and Checkpoint race-mode rule sets.
- Vehicle purchasing, upgrades, paint UI, and tuning persistence.
- Full career venue progression, sponsor/championship content, and unlock tables.
- Track preview PNG capture and richer Track Library cards.
- In-game file picker for import/export and packaged thumbnail metadata.
- Ghost visual playback and persistent per-track/per-vehicle records.
- Full rebinding UI, UI-scale application, large-text styling pass, and controller focus audit.
- Audio, music, crowd/environment polish, skid marks, smoke, sparks, and camera shake.
- Windows export with Godot 4.7 export templates, clean-machine launch QA, performance/stress tests, and release packaging.

The branch is therefore a **playable core milestone**, not a false claim of completed V1.0.
