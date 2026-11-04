# Handover

Rona is the rebuild of the PuffyPond2 prototype with a Supabase backend. Due date: Sunday 15 November 2026. Planning was done on Wednesday 4 November 2026.

## Status

| Chunk | State |
|---|---|
| 0.1 Product decisions and ADR | done: `docs/adr/0001-supabase-backend.md` |
| 0.3 Contracts (ERD, Swift protocols) | done as docs: `docs/supabase-erd.md`; the Swift types and protocols are not written yet |
| 0.2 Project skeleton | **next, not started** |
| Everything else | not started |

## Next step: chunk 0.2

The Xcode project is still the default template. Fix it:

- `TARGETED_DEVICE_FAMILY = 2` (iPad only) for the app and test targets, not `"1,2"`.
- Landscape only (`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`: `LandscapeLeft`, `LandscapeRight`).
- Add `UIRequiresFullScreen = YES`.
- Check `IPHONEOS_DEPLOYMENT_TARGET` (currently 27.0; the prototype was built with Xcode 26). Pick the lowest iPadOS that supports what is needed.
- Camera usage description (`NSCameraUsageDescription`) in the app settings.
- Create the feature folders under `Rona/` (`App`, `Input`, `Canvas`, `Critters`, `Review`, `Gallery`, `Stats`, `Templates`, `Audio`, `Consent`, `Sync`), each with `Core`, `Shell`, `Views` where needed. Mirror the same under `RonaTests/`.
- `supabase init`, local stack with Docker, and add `supabase-swift` through Swift Package Manager.
- CI: build and run the unit tests.
- Add a `.gitignore` (there is none yet) covering `xcuserdata/` and `.DS_Store`, and untrack the `xcuserdata` file that is already committed (`git rm --cached`).

Then write the Swift contracts from `docs/supabase-erd.md` (chunk 0.3, code part): `Painting`, `SessionStats`, `GalleryRepository`, `StatsRepository`, `QuestSource`.

After Wave 0 merges, the four lanes (A backend, B input, C paint engine, D independent) can run as separate sessions or worktrees. See the backlog.

## Where to port code from

The reference repo is `../PuffyPond2` (path: `/Users/filbertnaldowijaya/Documents/GitHub/PuffyPond2`, branch `feat/treehouse-garden-theme`). Its `README.md` has a file-by-file table. Mapping to Rona chunks:

| Chunk | Source in PuffyPond2 (`PuffyPond/…`) |
|---|---|
| B1 Hand input | `Input/Core/HandPose.swift`, `OneEuroFilter.swift`; `Input/Shell/HandTracker.swift`, `HandInput.swift` |
| B2 Distance and swipe | `Input/Core/DistanceGate.swift`, `SwipeDetector.swift`; `Input/Shell/HandFrameRelay.swift` |
| C1 Paint simulation | `Canvas/Shell/PaintLayer.swift`, `PaintShaders.metal` |
| C2 Pure canvas rules | `Canvas/Core/*` (`BrushStyle`, `StrokeBook`, `StrokePoint`, `StrokePath`, `CanvasLayout`, `PotRub`, `Hint`, `FrameTiming`, `Paint`, `PaintTool`) |
| C3 Easel scene | `Canvas/Shell/EaselScene.swift`, `Studio.swift`, `Toybox.swift`, `Effects.swift`, `CanvasPhotoBooth.swift`, `MeshBuilder.swift` |
| D1 Audio | `Audio/Shell/GrooveDSP.swift` |
| D2 Templates and quest | `Templates/Core/*` (9 templates, 10-quest pool; make the quest deterministic, see the ADR) |
| F1 to F5 Critters | `Critters/Core/*`, `Critters/Shell/*` |
| G1 Get ready | `Canvas/Views/InstructionView.swift` |
| G2 Review | `Review/Core/SheetSolver.swift`, `SheetGestures.swift`; `Review/Shell/ReviewStage.swift`; `Review/Views/ReviewView.swift` |
| G3 Gallery | `Gallery/Core/Painting.swift`, `Gallery/Shell/GalleryHall.swift`, `Gallery/Views/*` |
| G4 Report | `Stats/Core/*`, `Stats/Views/ReportView.swift` |
| H1 Canvas page | `Canvas/Shell/Playground.swift`, `Stats/Core/SessionRecorder.swift` |
| I1 Timelapse | `Timelapse/*` and `docs/superpowers/specs/2026-11-03-timelapse-replay-design.md` |
| I2 NCA | `NCA/nca.bin`, `tools/nca/*` |

Port with the matching tests from `PuffyPondTests/`. The prototype's own `Gallery` store writes PNG plus JSON sidecar files; Rona replaces it with `LocalGalleryStore` behind `GalleryRepository`.

## Open points to confirm early

- Whether the app is registered in the App Store Kids Category (affects analytics rules and the parental gate; guideline 1.3).
- Apple's requirements for accounts used by children, and the exact privacy policy and consent wording that names the uploaded movement stats.
- Final minimum iPadOS version.
- The Metal frame budget on a non-Pro iPad (chunk C4 is a gate before pages are built on the engine).
