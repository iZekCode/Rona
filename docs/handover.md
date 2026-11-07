# Handover

Rona is an iPad painting app with a Supabase backend; PuffyPond2 is the reference code it ports from. Due date: Sunday 15 November 2026. Planning was done on Wednesday 4 November 2026.

## Status

| Chunk | State |
|---|---|
| 0.1 Product decisions and ADR | done: `docs/adr/0001-backend-architecture.md` |
| 0.2 Project skeleton | done (see below) |
| 0.3 Contracts (ERD, Swift protocols) | done: `docs/data-model.md` and the Swift types (see below) |
| A1 Migrations | done: `supabase/migrations/` (see below) |
| A2 RLS policies | done: `add_rls_policies` migration |
| A3 Storage bucket | done: `create_paintings_bucket` migration |
| A4 pgTAP tests | done: `supabase/tests/database/rls.test.sql`, run by the `database` CI job |
| A5 delete-account function | done: `supabase/functions/delete-account` |
| A6 Cleanup job | done: `supabase/functions/cleanup` (see below); scheduled on the hosted project on 2026-11-06 (`cleanup-daily`, 03:00 UTC), first scheduled run not checked yet |
| D3 Theme and visual tokens | done: `DesignSystem/Theme.swift` (see below) |
| D4 AppRouter, Route, Home | done: `App/Core/Route.swift`, `App/Shell/AppRouter.swift`, `Features/Home/Views/HomeView.swift` |
| E0 Consent | done: `Features/Consent/` (see below); text and policy URL are placeholders; parental gate dropped for now |
| E1 Auth | done in code: `Features/Account/`, contracts in `Data/Core/AuthState.swift` and `AuthService.swift`, `SupabaseAuthService` in `Data/Shell/` (see below); the Apple link is not tried against a real Apple ID yet |
| E4 Sync engine | done: `SyncEngine`, `SyncPlan`, `BackgroundImageUploader` in `Data/` (see below); nothing calls it after a save yet (H1) |
| E3 Supabase repositories | done: `SupabaseGalleryRepository`, `SupabaseStatsRepository` in `Data/Shell/` (see below) |
| E2 LocalGalleryStore | done: `Data/Shell/LocalGalleryStore.swift` (see below) |
| B1 Hand input, B2 Distance and swipe, B3 Touch and Pencil | done: `Engines/Input/` (see below); the camera and Vision parts are not tried on a device yet |
| File names | done on 2026-11-07: one main type per file. `HandPose.swift` became `HandState.swift` plus `PoseFilter.swift` and `PalmReading.swift`; body types moved from `HandFrame.swift` to `BodyFrame.swift`; `HandTracker` is now `PoseTracker`; `OneEuroFilter2D.swift`, `View+PointerInput.swift`, `SyncContracts.swift` (was `SyncPorts.swift`), `AuthService.swift` split from `AuthState.swift`. The chunk sections below keep the old names |
| Folder layout | done on 2026-11-07: `App`, `DesignSystem`, `Engines`, `Features`, `Data`, `Resources` (rules in `CLAUDE.md`, "Code layout"). The chunk sections below were written before the move and keep the old paths (`Gallery/`, `Stats/`, `Sync/`, `Consent/`, `Input/`) |
| Everything else | not started |

## Chunk 0.2 result

- iPad only (`TARGETED_DEVICE_FAMILY = 2` for all three targets), landscape only, `UIRequiresFullScreen`, `NSCameraUsageDescription` set. Verified in the built `Info.plist`.
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0` (was 27.0). The prototype also targets 17.0; `@Observable` is the newest API it needs, and `supabase-swift` supports far lower. Still to confirm with the Kids Category rules (open points below).
- Feature folders: only `Rona/App/` (`RonaApp.swift`, `Views/ContentView.swift`) and `RonaTests/App/` exist. The other feature folders (`Input`, `Canvas`, `Critters`, `Review`, `Gallery`, `Stats`, `Templates`, `Audio`, `Consent`, `Sync`, each with `Core`, `Shell`, `Views`) are not pre-created: git does not track empty folders, and a `.gitkeep` inside a synchronized Xcode group is copied into the app bundle and breaks the build (duplicate output). Create each folder with its first real file.
- `supabase/` created with `supabase init`. Local `config.toml` has `project_id = "rona"`, `enable_anonymous_sign_ins = true` and `enable_manual_linking = true` (needed for anonymous sign-in and `linkIdentity`). `supabase start` ran and an anonymous sign-up returned `is_anonymous: true`. Needs the Supabase CLI (`brew install supabase/tap/supabase`) and Docker running.
- `supabase-swift` 2.55.6 added through SPM (`Supabase` product on the `Rona` target); `Package.resolved` is committed.
- Shared scheme `Rona` (app plus `RonaTests`). CI is hybrid. The iOS build and `RonaTests` run on Xcode Cloud (workflow lives in App Store Connect, not in the repo; it needs the shared scheme `Rona` and the committed `Package.resolved`). `.github/workflows/ci.yml` keeps only the `database` job (pgTAP), because Xcode Cloud has no Docker. The GitHub runner only had Xcode 26.6, so `objectVersion` in `project.pbxproj` was kept at 77 (Xcode 27 writes 110, which Xcode 26 cannot open); that limit no longer applies once the iOS tests run on Xcode Cloud with Xcode 27. The Xcode Cloud workflow `CI` is set up and build 1 on `main` passed (4 Nov 2026). Start conditions: branch changes on `main`, pull request changes targeting `main`, manual start. One Test action: scheme `Rona`, iPad simulator, `RonaTests` only. Xcode 27.0 crashed once right after the first Start Build (assertion in `XcodeCloudCommandHandler.navigate`); the build had already started. Not checked yet: that a pull request triggers the build, and making that check required in GitHub branch protection.
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

`supabase/functions/delete-account` (Deno, `supabase-js`): POST only, takes the caller from the verified bearer token (never from the body), removes all files under `paintings/{user_id}/` through the Storage API in pages of 100, then deletes the auth user, which cascades to profile, paintings and stats. `verify_jwt = false` in `config.toml` (the CLI template default, because the new API keys are not JWTs); the function verifies the token itself with `auth.getUser`. Tested locally with `supabase functions serve` and two anonymous users: GET gives 405, no or bad token gives 401 and deletes nothing, a valid call gives 204 and removes the user, profile, paintings, stats and files of that user only, and the same token gives 401 afterwards. Not tested: a user with more than 100 files (the paging loop), and a failure halfway (a retry is safe because files go first and removing nothing is fine). Not in CI yet.

## Chunk A6 result

`cleanup` edge function plus the migration `add_abandoned_users_function` and `supabase/functions/_shared/storage.ts` (the file removal that `delete-account` now shares). It purges tombstones older than 90 days and deletes anonymous users older than 30 days with no painting row; the thresholds are constants at the top of `supabase/functions/cleanup/index.ts`. The longer write-up (`docs/cleanup-job.md`) was removed on 2026-11-07 and is still in git history. Tests: `supabase/tests/database/cleanup.test.sql` (7 pgTAP tests, 25 in total), and an end-to-end run on the local stack with four users: only the old abandoned user and the 100-day-old tombstone were removed (with their files), a 10-day-old tombstone and users with a live painting stayed, bad or user tokens got 401, and a second run did nothing. `delete-account` was run again after the refactor and still passes. Not done: a CI job for the functions, and a user with more than 100 files.

## Chunk D3 and D4 result

- `Route` (Core, Foundation only) holds every page. Payloads are ids only (`templateID: String?`, `draftID: UUID`, painting `id`), unlike the prototype, which put `TemplateChoice`, `ReviewDraft` (with images) and `Painting` inside the route. The images and stats of a draft belong to the stage that owns it (H1). `ViewOrigin` moved to the same file.
- `AppRouter` (Shell, `@Observable`) owns the current route; `go(_:)` animates, `home()` goes back. It does not own page state.
- `ContentView` shows `HomeView` and a placeholder page (a button back to Home) for every other route. Each page chunk replaces its case in the `switch`.
- Theme (D3) is the 2D look only: `Theme` (ink, leaf and sunlight backdrop, button tints, title gradient, corner radius, minimum tap 84 pt), `PageBackground`, `BigButton`, `immersive()`. The SceneKit treehouse backdrops and effects of the prototype's treehouse-garden spec belong to C3 and the 3D gallery (G3), not here.
- `uiScale` and `Platform` from the prototype are dropped: the app is iPad only, so sizes are iPad sizes. When porting views, replace `* scale` with the plain number (already 1.2x the prototype's base).
- Copy stays Bahasa Indonesia as in the prototype. The title is "Rona".
- Tests: `RouteTests`, `AppRouterTests` (6 tests; 15 pass in total on the iPad mini simulator). Home checked visually on the simulator.
- Home's buttons go to `.modePicker`, `.gallery3D` and `.report`, which are placeholders until their chunks.

## Chunk E2 result

`LocalGalleryStore` is an actor that implements both `GalleryRepository` and `StatsRepository`. Layout: `Application Support/Gallery/{painting id}/painting.json` (the `Painting` record), `image.png`, `stats.json`. The record is written last, so a folder without one (an interrupted save) is ignored, and a record that does not decode is skipped instead of hiding the whole gallery.

- `delete` is a tombstone: it removes `image.png` and `stats.json` and keeps the record with `deletedAt`. A second delete keeps the first date. `paintings()` hides tombstones; `allPaintings()` (extra, not in the protocol) returns them for the sync engine (E4). E4 decides when a synced tombstone is purged.
- `imageData` and `save(stats)` throw `GalleryStoreError.notFound` for an unknown or deleted painting; `stats(for:)` returns nil for those.
- Saving the same id twice replaces the painting (a retried save is safe).
- Not done: calendar queries (`paintings(on:)`, days with paintings, saved template ids) and the review page's paint-only and bare-canvas photos. They belong to G2 to G4, as pure queries over `[Painting]` and extra files in the painting folder.
- Tests: `LocalGalleryStoreTests` (14).

## Chunk E0 result

- `Consent/Core/ConsentPolicy`: `currentVersion = 1`; `needsConsent(acceptedVersion:)` is true when nothing was accepted or the accepted version is older. Raise the version when the text or what is uploaded changes.
- `Consent/Shell/ConsentStore` (`@Observable`, `UserDefaults`): `acceptedVersion`, `acceptedAt`, `needsConsent`, `accept(at:)`. E1 copies `acceptedAt` and `acceptedVersion` into `profiles` after the first anonymous sign-in.
- `Consent/Views/ConsentView`: four short points (camera stays on the device, what is uploaded, 2D estimates not medical, deletion), a privacy policy link and the agree button. `ContentView` shows it before anything else while `needsConsent` is true; no sign-in or upload exists yet, so nothing runs before consent.
- No parental gate. E0 first had one (a keypad asking three digits written as words, in front of agree, the policy link, link-account and delete-account). It was removed on 5 Nov 2026 before any commit; ADR decision 4 is amended. Link-account, delete-account and the policy link are plain buttons until the Kids Category decision, which is due before the App Store submission (I3).
- Placeholders to replace before the TestFlight build (I3): `ConsentView.privacyPolicyURL` (`https://rona.example/privacy`) and the consent wording, which still needs the Kids Category and Apple child-account decisions below.
- Tests: `ConsentTests` (7). The consent screen was checked on the iPad mini simulator.

## Chunk E1 result

- Core: `AuthState`, `AuthService` (restore, sign in anonymously, link Apple), `AuthPlan` (what to do at launch; nothing before consent), `ProfileRepository`, `AccountLinkError.alreadyUsed`. `ConsentRecord` and `ConsentPolicy.needsProfileUpdate` (write the profile row only when it has no consent or an older version) live in `Consent/Core`.
- Shell: `SupabaseConfig` (local URL and the publishable key from `supabase status`; made once in `RonaApp`, because every client shares the Keychain), `SupabaseAuthService`, `SupabaseProfileRepository` (select, then upsert), `AuthStage` (`@Observable`), `AppleNonce` (random nonce, SHA-256 for Apple, original for Supabase).
- `AuthStage.start(agreement:)` runs only with a consent in force (not even a restore before it). It restores the saved session, signs in anonymously when there is none, then makes sure `profiles` holds the consent. It never blocks the UI. A failed restore (offline, expired token) does not fall through to a new anonymous user, which would orphan the paintings on the old one; it sets `failed` and the next call (consent, or the app coming back to the foreground) retries.
- The session is kept in the Keychain by `supabase-swift` (`KeychainLocalStorage` is its default), so there is no code for restore on launch beyond `auth.session`.
- UI: a small account button at the bottom right of Home opens `LinkAccountView`, with the Sign in with Apple button (no name or email scope). It shows the state: not connected, anonymous (button), or linked. No parental gate (ADR decision 4, amended).
- Local config: `supabase/config.toml` enables `[auth.external.apple]` for the native flow with `client_id = "LittleCrew.Rona"` and no secret. The local Auth accepted it and answers a fake ID token with "Unable to detect issuer in ID token for Apple provider".
- Checked on the local stack: no user before consent; an anonymous user and its `profiles` row after consent; a relaunch restores the session and does not rewrite the row (`updated_at` unchanged). Unit tests: `AuthPlanTests`, `AuthStageTests`, `AppleNonceTests`, plus the consent tests (56 tests in all). Running unit tests starts the host app, so with a consent saved in the simulator they also touch the local stack.
- The Sign in with Apple capability is added to the `Rona` target (`Rona/Rona.entitlements`, `CODE_SIGN_ENTITLEMENTS` in the project, automatic signing, team `ZU2326AL7G`). Checked: the entitlement is embedded in the simulator build and the file is not copied into the bundle. `project.pbxproj` now carries this real change, so do not `git checkout` it any more; that would remove the capability. Its `objectVersion` is 110 (Xcode 27); that is fine now because the iOS build and tests run on Xcode Cloud and the GitHub `database` job never opens the Xcode project.
- Not done, needs the owner: try the button on a device or a simulator signed in to an Apple ID, and check the App ID `LittleCrew.Rona` has Sign in with Apple enabled (automatic signing normally does this). For the hosted project, enable the Apple provider in the dashboard with the bundle id as client id.
- Known gap: an Apple account already linked to another user (an earlier iPad) gives `alreadyUsed` and a message. Signing in to that existing account on a new device (restore after reinstall, ADR decision 6) is not built; it needs `signInWithIdToken` and belongs with the pull side of E4.
- Tests that call Supabase through the app are not in CI: Xcode Cloud has no Docker.

## Chunk E3 result

- Core: `StoragePath.image(userID:paintingID:)` (`{user id}/{painting id}.png`, **lowercase**: the Storage policy compares the first folder with `auth.uid()::text`, and `UUID.uuidString` is uppercase, so an uppercase folder is refused), `PaintingRow` and `StatsRow` (the table rows, with the column names; a nil field is left out of the JSON, so an upsert never overwrites `recording_path` or `deleted_at`).
- Shell: `SupabaseGalleryRepository` and `SupabaseStatsRepository` implement the same protocols as `LocalGalleryStore`. `save` uploads the PNG first (`upsert: true`) and upserts the row second, on the client-made id, so a retry after a failure halfway is safe and no row points at a missing file. `delete` sets `deleted_at` (a tombstone; the cleanup job removes old ones and their files) and throws `GalleryStoreError.notFound` when no row matched. The user id comes from the current session. Stats are one row per painting (`schema_version` plus the `SessionStats` document with its own key names, since the Supabase encoder does not change keys).
- The `profiles` row must exist before the first painting (`paintings.user_id` references it); `AuthStage` already makes sure of that.
- Tests: `StoragePathTests`, `PaintingRowTests`, `StatsRowTests` (66 tests in all), plus `SupabaseRepositoriesIntegrationTests`, skipped unless `TEST_RUNNER_SUPABASE_INTEGRATION=1` (Xcode Cloud has no Docker): it signs in anonymously on the local stack and round-trips a painting and its stats, retries a save, reads the image back, deletes (tombstone) and checks `notFound`. It passes. Each run leaves one anonymous user and a tombstoned painting with its file on the local stack. Not run against the hosted project.
- Not done: `imageData` returns the library's storage error for a missing object instead of `GalleryStoreError.notFound`; the pull side of E4 will need to tell the two apart. There is no paging in `paintings()` (fine at tens of paintings).

## Chunk E4 result

The sync is push and pull, with real background uploads (ADR decision 6 stands: "uploads use a background URLSession").

- **No separate outbox.** `LocalGalleryStore` keeps `sync.json` next to each painting (`SyncState`: image uploaded, image in flight, stats pushed). The server's list (tombstones included) is the truth about what exists there; the flags only avoid sending the same bytes twice, so a restart or a relaunch by the system picks up where it was. Saving a painting again resets its flags; saving new stats clears `statsPushed`.
- **Core:** `SyncPlan.actions(local:remote:)` turns the two lists into actions: `uploadImage`, `pushRow`, `pushStats`, `pushTombstone`, `applyRemoteTombstone`, `download`. For a painting the server lacks: the image first, then the row, then the stats (the row is pushed only once the image is up, so no row points at a missing file). A delete always wins over pending work; a delete the server never saw needs nothing. `Backoff` doubles from 2 s to 300 s. Ports: `LocalSyncStore`, `RemoteGallery`, `ImageUploader`.
- **Shell:** `SyncEngine` (actor, one run at a time; a call during a run asks for another round). A failed run repeats after the backoff up to 6 times, then waits for the next trigger. A failed image upload retries after the backoff. An image still marked "in flight" that the system no longer knows (the app was force-quit, which cancels background tasks) is cleared and sent again. `BackgroundImageUploader` hands the PNG to a background `URLSession` (session `LittleCrew.Rona.image-upload`, `sessionSendsLaunchEvents`) as a plain Storage upload (raw POST, user token, `x-upsert`); results go to the engine through `onFinish`, buffered until it is set (after a relaunch). `AppDelegate` passes the system's background-events completion handler to the uploader. `SupabaseRemoteGallery` adapts the two Supabase repositories (`SupabaseGalleryRepository` gained `allPaintings()` and `pushRow`).
- **Wiring:** `AppServices.shared` builds the client, sign-in, local store, uploader and engine once, and `bootstrap()` signs in from the saved session and starts the sync, so a background relaunch works with no page on screen. `AuthStage.isReady` (signed in and consent on the profile) enables the engine; triggers are the app becoming active, the network coming back (`NWPathMonitor`), `isReady`, and a finished upload.
- **Tests:** `SyncPlanTests`, `BackoffTests`, `SyncEngineTests` (fakes for the three ports), new `LocalGalleryStoreTests` for the sync state, `AuthStageTests` for `isReady` (106 in all). `SyncIntegrationTests`, skipped unless `TEST_RUNNER_SUPABASE_INTEGRATION=1`, runs two devices of one account on the local stack: A saves a painting and stats and they go up through the real background session, B (empty) pulls image and stats, a delete on A reaches B. It passes, and the local database shows the row, the stats row, the file under the lowercase path, and the tombstone. Not run against the hosted project.
- **Open:**
  - The save flow (H1) must call `AppServices.shared.sync.run()` after a local save; nothing does yet, so only the triggers above start a sync.
  - Not tried by hand: the system relaunching the app in the background to report a finished upload (`handleEventsForBackgroundURLSession`), and an upload that outlives the app on a real iPad.
  - The upload request carries the token taken when it starts. If the system delays it past the token's life (1 hour), it fails and is retried with a fresh one.
  - A tombstoned painting stays on the device as a record (no purge after it is synced), and the pull reads the whole list each run (no paging, no incremental pull); fine at tens of paintings.
  - Pull only matters across devices once "sign in to an existing account on a new device" exists (`signInWithIdToken`, not built).
  - `imageData` still returns the library's storage error for a missing object instead of `GalleryStoreError.notFound`; a failed download is just retried.

## Chunk B1, B2 and B3 result

Ported from `PuffyPond2/Input/` (lane B, one branch `feat/input`).

- **Core** (all `nonisolated`, Foundation, simd or CoreGraphics only): `HandPose` (`HandPose`, `HandState`, `PalmReading`, `PoseFilter`), `OneEuroFilter2D`, `DistanceGate`, `SwipeDetector`, `HoverDwell` (hover-and-hold buttons for the review page and gallery; not in the backlog, but it sits in the same prototype folder and is tiny), `PointerTracker` (new, B3).
- **`HandFrame.swift` is a split of the prototype's `HandTracker.swift`.** The value types (`HandJoint`, `HandObservation`, `HandFrame`, `BodyJoint`, `BodyPoint`, `BodyFrame`) and the finger counting (`PalmReading.init(_:aspect:)`, moved from `HandInput.swift`) now live in Core without Vision, so they are unit tested. Only the `visionName` mappings stay in Shell.
- **Shell:** `PoseTracker` (was `HandTracker`; front camera plus Vision hand and body pose), `CameraPreviewLayer`, `HandInput` (matches hands to slots, smooths, predicts; `ingest(_:now:)` takes the time so tests can drive it), `HandFrameRelay`, `PointerInput`. **Views:** `PointerSurface.swift` (`.pointerInput(_:)`).
- **Dropped from the prototype:** the `cameraTimelapse` recorder in `HandTracker` (the timelapse is I1; it needs a hook that offers each pixel buffer, add it then), `rotationAngle` and the macOS and iPhone branches (iPad only: the rotation coordinator always runs), `Platform.isPad`.
- **B3 touch and Pencil:** `PointerTracker` turns a touch position (view UV) into the prototype's pointer hand (`HandState.pointer`, always a fist, slot 0). `.pointerInput(_:)` is a `DragGesture(minimumDistance: 0)` overlay, which takes both a finger and the Pencil. The page adds the overlay only over the canvas (it takes every touch in its frame), and merges `PointerInput.hand()` with the camera hands once per frame. `SwipeDetector` already ignores pointer hands. Not built: Pencil-only erasing (the prototype had a `pointerErases` setting on the canvas) and Pencil hover; both belong with H1.
- **Tests (50 new, 156 in all, iPad mini simulator):** ported `DistanceGateTests`, `HoverDwellTests`, `SwipeDetectorTests`; `PoseFilterTests` (the pose rules from the prototype's `HandControlTests`; its buddy-mode and paint-tool half goes with F1 and C2); new `OneEuroFilterTests`, `HandFrameTests`, `HandInputTests`, `PointerTrackerTests`.
- **Not done, needs a device:** `PoseTracker` (permission flow, 720p at 60 fps, mirroring and rotation on both landscape sides), the finger-count threshold (`1.12`) and the `DistanceGate` band (`0.13` to `0.22`, still an estimate from the field of view). Nothing starts the tracker yet: G1 (get ready) and H1 (canvas) own that, and `NSCameraUsageDescription` is already set.

## Hosted Supabase project

- Project `Rona`, ref `smbsoovlrylahmrqsryw`, region ap-southeast-1 (Singapore), free plan (a free project is paused after 7 days without activity; think about a paid plan before release). Created 4 Nov 2026 with Data API on, "automatically expose new tables" on (the migrations have no table `grant`s and rely on it) and automatic RLS on.
- Pushed with `supabase db push --remote`: all 7 migrations. Checked there: 3 tables with RLS, 11 table policies and 4 Storage policies, private PNG bucket (10 MB), and `authenticated` can select, insert, update and delete on the three tables. `anon` has the same default table grants, but no policy, so RLS refuses it.
- Supabase CLI 3.0 targets the local stack by default: use `--remote` for `db push` and `db query` against the linked project (`--read-only` for a query that only reads). A deploy job must pass it too.
- Auth settings set by hand in the dashboard (not from `config.toml`: `supabase config push` would overwrite them with the local values, including `site_url`): anonymous sign-ins on, manual linking on, Apple provider on with client id `LittleCrew.Rona`, no secret, "Allow users without an email" on.
- Which server the app uses (`SupabaseConfig`): the simulator uses the local stack, a device and release builds use the hosted project, and the environment variables `SUPABASE_URL` and `SUPABASE_KEY` (Edit Scheme, Run, Arguments) override both. Do not commit the scheme with such a variable in it.
- Checked on an iPad against the hosted project: anonymous sign-in, the `profiles` row (consent version 1) and the Sign in with Apple link (the user is no longer anonymous, provider `apple`).
- Functions `delete-account` and `cleanup` are deployed (`supabase functions deploy --use-api --yes`, version 1, `verify_jwt = false` as in `config.toml`; they check the bearer token themselves). Checked on the hosted project with a throwaway anonymous user: no token gives 401, GET gives 405, `cleanup` refuses the publishable key (401); with the user's token the profile, painting, stats and the Storage file were all created (RLS and the bucket policies let the owner write), `delete-account` gave 204 and removed the user, profile, painting, stats and file, and the same token then gave 401.
- The daily schedule of `cleanup` was set up on 2026-11-06 (`pg_cron` job `cleanup-daily`, `0 3 * * *` UTC, key in Vault; a manual test call returned 200). Still to check: `cron.job_run_details` and `net._http_response` after the first scheduled run.
- Not done: CD (GitHub Actions for `db push --remote` and `functions deploy`, Xcode Cloud archive and TestFlight).

## Next step: other lanes

Done: lane A, lane B, D3, D4, E0, E1, E2, E3, E4 (the whole backend bridge). Next: lane C (paint engine; C1 and C2 first, C4 is the frame-budget gate) and the rest of D (D1 audio, D2 templates and quest), then the pages (Wave 3) on top of `LocalGalleryStore`. G1 (get ready) is now unblocked by B2, and G3 and G4 only need E2 and D3. Settle the Kids Category and consent wording points below before the TestFlight build.

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

Where each piece lands in Rona: canvas rules and `PaintLayer` in `Engines/Paint/`, critters in `Engines/Characters/`, `SessionRecorder` in `Engines/Motion/`, `GrooveDSP` in `Engines/Audio/`, `Painting` and `SessionStats` already in `Data/Core/`, voice clips and `nca.bin` in `Resources/`, each page in `Features/<Page>/`.

Port with the matching tests from `PuffyPondTests/`. The prototype's own `Gallery` store writes PNG plus JSON sidecar files; Rona replaces it with `LocalGalleryStore` behind `GalleryRepository`.

## Open points to confirm early

- Whether the app is registered in the App Store Kids Category (affects analytics rules and whether a parental gate is needed again; guideline 1.3). Decide before the App Store submission (I3).
- Apple's requirements for accounts used by children, and the exact privacy policy and consent wording that names the uploaded movement stats.
- Final minimum iPadOS version.
- The Metal frame budget on a non-Pro iPad (chunk C4 is a gate before pages are built on the engine).
