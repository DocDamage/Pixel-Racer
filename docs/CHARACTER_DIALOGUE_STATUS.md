# Character, Venue, Portrait, and Dialogue Status

## Scope

The V1 presentation requirement adds visible on-foot characters, short walk-to-car / walk-to-location sequences, portrait dialogue outside races, and compact non-blocking radio dialogue during races.

The runtime architecture for that requirement is now implemented. The five source PNGs referenced by the project handoff are not currently committed in this repository and are not available to the implementation agent as retrievable binary uploads, so the atlas cannot be measured or enabled yet.

## Required source assets

Expected repository paths are intentionally fixed in `data/characters/character_manifest.json`:

- `res://assets/characters/body/Body-Idle-Right.png`
- `res://assets/characters/body/Body-Running-Right.png`
- `res://assets/characters/head/Head-Idle-Right.png`
- `res://assets/characters/head/Head-Running-Right.png`
- `res://assets/characters/portraits/PORTRAITS.png`

Do not substitute guessed art, inferred frame sizes, or arbitrary portrait crops for these files.

## Implemented runtime architecture

### Character data and actor

- `CharacterDefinition`
  - body/head idle and run sheet paths
  - independent body/head rows
  - measured cell sizes
  - idle/run frame counts
  - walk speed
  - portrait and dialogue profile IDs
- `CharacterCatalog`
  - loads `data/characters/character_manifest.json`
  - refuses to report runtime-ready until the manifest is measured and every required sheet resolves
  - reports actionable asset/geometry issues
- `CharacterActor`
  - `CharacterBody2D`
  - separate body and head sprites
  - nearest-neighbor texture filtering
  - idle/run switching
  - left/right presentation through safe horizontal flipping
  - deterministic animation timing
  - `walk_to`, `stop`, `teleport_to`, facing, and arrival signals

### Venue sequencing

- `VenueController`
  - indexes named `Marker2D` anchors rather than hardcoded dialogue coordinates
- `CharacterSequenceController`
  - walk, face, wait, dialogue, show, and hide steps
  - named routes
  - arrival-driven progression
  - optional short input lock
  - skip support
  - deterministic walk-speed restoration

Recommended V1 anchor names remain:

- `Garage`
- `PlayerCar`
- `TrackEntrance`
- `BuilderStation`
- `EventDesk`
- `Mechanic`
- `SponsorDesk`
- `PitLane`
- `Podium`

### Dialogue data

- `DialogueCharacter`
- `DialogueEntry`
- `DialogueSequence`
- `DialogueCatalog`
- `DialogueManager`
- `DialogueStateStore`

Dialogue entries support:

- stable ID
- speaker ID
- portrait ID
- text
- event
- priority
- duration
- blocking/non-blocking presentation
- condition
- once-only persistence
- cooldown
- arbitrary metadata

True once-only tutorial/story flags persist to `user://dialogue_state.json`. Transient race chatter such as final-lap and elimination warnings is deliberately repeatable in future races.

### Portrait presentation

- `PortraitAtlas`
  - fixed texture path plus measured regions
  - `AtlasTexture` output per portrait
  - validation when regions/assets are missing
- `DialogueOverlay`
  - larger portrait dialogue for non-race conversations/debriefs
- `RaceRadioOverlay`
  - compact edge-of-screen portrait/speaker/text presentation
  - two short lines
  - does not pause physics
  - does not steal race input focus
- `DialoguePresenter`
  - separate CanvasLayer
  - routes active-race non-blocking entries to radio presentation
  - routes blocking/out-of-race or forced-full entries to the full dialogue overlay

### Live dialogue triggers already wired

- pre-race briefing by mode
- countdown GO
- gained P1
- lost P1
- final lap
- pit entry
- pit speeding
- low nitro
- drift-score milestones
- elimination pressure
- new best lap
- race finish
- post-race debrief
- event failure
- first Builder guidance
- Builder validation hints with cooldowns

## Atlas activation procedure

When the five PNGs are available:

1. Commit them at the expected `assets/characters/...` paths.
2. Read the actual image dimensions from the source files.
3. Determine the exact body/head animation cell dimensions and row mapping from the real sheet layout.
4. Determine the exact portrait rectangles in `PORTRAITS.png`.
5. Populate `data/characters/character_manifest.json` with real character definitions and portrait regions.
6. Set the top-level and portrait `measured` flags to `true` only after measurement is verified.
7. Confirm `CharacterCatalog.is_runtime_ready()` returns true.
8. Add atlas regression tests for bounds, frame counts, row mapping, and portrait regions.
9. Build the compact paddock/venue scenes using named anchors.
10. Wire visible pre-race walk-to-car and post-race walk-to-destination sequences.
11. Verify all sequences can be skipped/accelerated after repeat viewing.
12. Verify active-race dialogue remains non-blocking on keyboard/mouse and controller.

## Current blocker

The implementation must not claim the visible character/portrait requirement is production-complete until the actual five PNGs are present, measured, mapped, and tested in a packaged Windows build.

The code intentionally leaves the manifest unmeasured rather than inventing frame sizes. This preserves the handoff's non-negotiable rule and prevents a false-positive V1 status.
