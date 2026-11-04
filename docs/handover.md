# Handover

Rona is the rebuild of the PuffyPond2 prototype with a Supabase backend. Due date: Sunday 15 November 2026. Planning was done on Wednesday 4 November 2026.

## Status

| Chunk | State |
|---|---|
| 0.1 Product decisions and ADR | done: `docs/adr/0001-supabase-backend.md` |
| 0.2 Project skeleton | done (see below) |
| 0.3 Contracts (ERD, Swift protocols) | done: `docs/supabase-erd.md` and the Swift types (see below) |
| Everything else | not started |

## Chunk 0.2 result

- iPad only (`TARGETED_DEVICE_FAMILY = 2` for all three targets), landscape only, `UIRequiresFullScreen`, `NSCameraUsageDescription` set. Verified in the built `Info.plist`.
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0` (was 27.0). The prototype also targets 17.0; `@Observable` is the newest API it needs, and `supabase-swift` supports far lower. Still to confirm with the Kids Category rules (open points below).
- Feature folders: only `Rona/App/` (`RonaApp.swift`, `Views/ContentView.swift`) and `RonaTests/App/` exist. The other feature folders (`Input`, `Canvas`, `Critters`, `Review`, `Gallery`, `Stats`, `Templates`, `Audio`, `Consent`, `Sync`, each with `Core`, `Shell`, `Views`) are not pre-created: git does not track empty folders, and a `.gitkeep` inside a synchronized Xcode group is copied into the app bundle and breaks the build (duplicate output). Create each folder with its first real file.
- `supabase/` created with `supabase init`. Local `config.toml` has `project_id = "rona"`, `enable_anonymous_sign_ins = true` and `enable_manual_linking = true` (needed for anonymous sign-in and `linkIdentity`). `supabase start` ran and an anonymous sign-up returned `is_anonymous: true`. Needs the Supabase CLI (`brew install supabase/tap/supabase`) and Docker running.
- `supabase-swift` 2.55.6 added through SPM (`Supabase` product on the `Rona` target); `Package.resolved` is committed.
- Shared scheme `Rona` (app plus `RonaTests`). CI: `.github/workflows/ci.yml` builds and runs `RonaTests` on an iPad simulator. The GitHub runner has Xcode 26.6 only, so `objectVersion` in `project.pbxproj` is 77 (Xcode 27 writes 110, which Xcode 26 cannot open). Check it stays 77 after editing the project in Xcode 27. The run passes on the runner.
- `.gitignore` added, `xcuserdata` untracked.
- Local checks: `xcodebuild test -scheme Rona -only-testing:RonaTests` on iPad (A16) simulator passes. `RonaUITests` was not run.

## Chunk 0.3 result (code)

Pure `Core` files, Foundation only, all `nonisolated` (the target defaults to `MainActor`, and the sync engine needs these off the main actor):

- `Gallery/Core/Painting.swift`, `GalleryRepository.swift`
- `Stats/Core/SessionStats.swift` (`Side`, `SessionStats`, `schemaVersion = 1`; ported from PuffyPond2), `StatsRepository.swift`
- `Templates/Core/Quest.swift` (`Quest`, `QuestSource`)

Tests: `RonaTests/Gallery/PaintingTests.swift`, `RonaTests/Stats/SessionStatsTests.swift` (9 tests pass on the iPad simulator).

Differences from the ERD sketch and PuffyPond2:

- `Painting` is `Codable` and `Sendable`, and has `isDeleted`. The prototype's `isDailyQuest` and `timelapseVersion` are not carried over: the quest star derives from `templateID`, and the timelapse stays local (chunk I1).
- `Quest` has only `id` and `title`. D2 adds the outline art when it ports the pool.
- `TemplateID` from the backlog is not a type: `templateID` is a `String` (a `TemplateKind` raw value or a quest id), as in the ERD.
- Repository protocols are `Sendable`. `LocalGalleryStore` (E2) and the Supabase repositories (E3) implement them.

## Next step: Wave 1

Wave 0 is complete. Merge it, then start the four lanes (A backend, B input, C paint engine, D independent) as separate sessions or worktrees. Critical path: A1 (migrations), then A2/A3. See the backlog.

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
