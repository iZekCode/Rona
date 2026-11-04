# Handover

Rona is the rebuild of the PuffyPond2 prototype with a Supabase backend. Due date: Sunday 15 November 2026. Planning was done on Wednesday 4 November 2026.

## Status

| Chunk | State |
|---|---|
| 0.1 Product decisions and ADR | done: `docs/adr/0001-supabase-backend.md` |
| 0.2 Project skeleton | done (see below) |
| 0.3 Contracts (ERD, Swift protocols) | done: `docs/supabase-erd.md` and the Swift types (see below) |
| A1 Migrations | done: `supabase/migrations/` (see below) |
| A2 RLS policies | done: `add_rls_policies` migration |
| A3 Storage bucket | done: `create_paintings_bucket` migration |
| A4 pgTAP tests | done: `supabase/tests/database/rls.test.sql`, run by the `database` CI job |
| A5 delete-account function | done: `supabase/functions/delete-account` |
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

## Chunk A1 result

Four migrations in `supabase/migrations/`, checked on the local stack with `supabase db reset`:

- `create_profiles`: id references `auth.users` with cascade, consent columns, timestamps.
- `add_updated_at_trigger`: `set_updated_at()` and the trigger on `profiles`.
- `create_paintings`: client-made uuid id, `user_id` with cascade, tombstone `deleted_at`, partial index for the gallery, trigger.
- `create_painting_stats`: one row per painting with a jsonb document and `schema_version`.

All tables have RLS enabled and no policies yet, so the API denies everything until A2. `painting_stats` uses a composite foreign key `(painting_id, user_id)` to `paintings(id, user_id)`, which makes the database guarantee that stats belong to the same user as the painting (the ERD is updated). Tested in a rolled-back transaction: trigger bumps `updated_at`, a mismatched user is rejected, deleting an `auth.users` row removes profile, paintings and stats.

## Chunk A2 result

`add_rls_policies` creates 11 policies for role `authenticated`: select, insert and update on `profiles` (no delete, that goes through `delete-account`), and select, insert, update and delete on `paintings` and `painting_stats`, all on the owner id with `(select auth.uid())`. Checked by hand in rolled-back transactions as two users: each sees only its own rows, cannot insert or move a row to the other user, cannot update the other's rows, cannot delete a profile, and `anon` sees nothing. The automated version is A4.

## Chunk A3 result

`create_paintings_bucket` creates the private bucket `paintings` (PNG only, 10 MB limit, a guess to adjust once real painting sizes are known) and four policies on `storage.objects`: the first folder of the object path must equal `auth.uid()`. Checked through the real Storage API with two anonymous users: a user can upload, read and delete in their own folder, cannot upload into another user's folder (RLS error), cannot read or delete another user's file, a text file is rejected, and the public URL gives nothing. Automated version: A4.

## Chunk A4 result

`supabase/tests/database/rls.test.sql` has 18 pgTAP tests, run with `supabase test db` (needs the local stack). They act as user A, user B and `anon`, and cover reading, inserting, updating, handing over and deleting rows in the three tables, the composite foreign key of `painting_stats`, uploading into and reading from Storage folders, the private bucket, and the cascade when a user is deleted. The `database` job in `.github/workflows/ci.yml` starts the stack without the services the tests do not need and runs `supabase test db`. Breaking one policy on purpose made the matching tests fail. Two limits: deleting from `storage.objects` is blocked by Supabase except through the Storage API, so that case was checked by hand in A3 and is not in pgTAP; and the MIME and size limits are enforced by the Storage API, so they are not covered either.

## Chunk A5 result

`supabase/functions/delete-account` (Deno, `supabase-js`): POST only, takes the caller from the verified bearer token (never from the body), removes all files under `paintings/{user_id}/` through the Storage API in pages of 100, then deletes the auth user, which cascades to profile, paintings and stats. `verify_jwt = false` in `config.toml` (the CLI template default, because the new API keys are not JWTs); the function verifies the token itself with `auth.getUser`. Tested locally with `supabase functions serve` and two anonymous users: GET gives 405, no or bad token gives 401 and deletes nothing, a valid call gives 204 and removes the user, profile, paintings, stats and files of that user only, and the same token gives 401 afterwards. Not tested: a user with more than 100 files (the paging loop), and a failure halfway (a retry is safe because files go first and removing nothing is fine). The client must call it only behind the parental gate (chunk E0). Not in CI yet.

## Next step: Wave 1 other lanes

Lane A is done except the optional cleanup job (A6). Next: lanes B (input), C (paint engine) and D (independent pieces) from the backlog, and then the backend bridge (E0 consent and gate, E1 auth).

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
