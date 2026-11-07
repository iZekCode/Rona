# ADR 0001: Supabase backend decisions

- Status: accepted
- Date: 2026-11-04
- Backlog: [backlog.md](../backlog.md)
- Data model: [data-model.md](../data-model.md)

## Context

Rona is a children's rehabilitation-style painting app. The earlier PuffyPond2 prototype kept everything on the device (`Application Support/Gallery/`, one PNG and one JSON sidecar per painting) with no network and no accounts. Rona adds a Supabase backend. Because the users are children and the movement stats are health-adjacent, the decisions below set what leaves the device, who owns it, and who can act on it.

## Decisions

### 1. Platform: iPad only, landscape, full screen

`UIRequiresFullScreen = YES`, no Mac, Catalyst, Stage Manager or split view. This removes live window resizing from `CanvasLayout` and `EaselScene`.

### 2. Auth: anonymous first, upgrade to Sign in with Apple

After consent (decision 4) the app signs in anonymously, so a child can paint without any account screen. The anonymous user is later upgraded with `linkIdentity` (Sign in with Apple), which keeps the same `user_id`, so no data migration is needed. Sign in with Apple needs no separate review, only the paid Apple Developer account that TestFlight needs anyway. Google sign-in is not offered, so guideline 4.8 is satisfied by Sign in with Apple alone.

Consequence: if the app is deleted or the iPad is replaced before the account is linked, the anonymous user and its data are orphaned. The upgrade prompt must be visible enough to prevent this.

### 3. Data owner: one account is one child

`profiles` is 1:1 with `auth.users`. Row level security is `user_id = auth.uid()` everywhere. No child-profile switching and no parent-with-many-children model in v1.

### 4. Consent first, no parental gate for now

A consent screen (privacy policy link, parent confirmation) is shown before the first launch flow. No anonymous user is created before consent. The app stores the consent locally and in `profiles` (`consented_at`, `consent_version`); a new `consent_version` asks again.

Amended 2026-11-05: this decision first also had a separate parental gate (linking Sign in with Apple, deleting the account, any link out of the app). It was built in chunk E0 and then removed on the owner's call: whether the app goes in the Kids Category, and so whether a gate is needed, is decided later, before the App Store submission (chunk I3). Until then the upgrade button, account deletion and the privacy policy link are plain buttons, so a child can reach them. The gate was a keypad that asks for three digits written as words; it was never committed.

### 5. What is uploaded

- Painting PNG: yes.
- Session stats (ROM, heatmap, grip cycles, hand dominance, as one JSON document): yes.
- Timelapse recording: no in v1. It stays on the device. `paintings.recording_path` is reserved and null, and a `recordings/` path is reserved in Storage. Before uploading, measure size (average and p95), use a compact binary format, upload lazily on Wi-Fi, and cap the size per recording.
- Raw camera frames: never.

A painting restored from the server without a recording opens like a legacy painting: interactive immediately, no Replay.

### 6. Source of truth: local first, sync in the background

The UI reads and writes only the local store. A sync engine pushes through an outbox with retry and backoff, and pulls on a new device or after reinstall.

- Painting ids are UUIDs created on the client, so retries are idempotent. Upload the PNG first, then insert the row.
- Conflicts: last write wins (one account, one child, paintings are close to immutable).
- Deletes are tombstones (`deleted_at`) so they propagate to the other devices. (Amended 7 Nov 2026: this used to say "and relock templates correctly". Templates no longer lock, see decision 8.)
- Uploads use a background `URLSession`.

### 7. Daily quest: computed on the client, same for every child

`quest(for date)` picks from the fixed pool by a stable hash of the local date (never Swift's per-launch randomized `Hasher`), and is never the same as the previous day's pick. A `questPoolVersion` guards the pool: entries are only appended, or the version is bumped when the pool changes. No `daily_quest` table, no server involvement. The `QuestSource` protocol allows a server source later.

Amended 7 Nov 2026: the pool is now the whole template catalog (39 templates), not a separate ten-quest list, because the prototype made the quest of the day one of the templates. The rules above are unchanged, and since the pool is bigger and the ids are stored with paintings, appending is the only safe change. The prototype's own picker rolls randomly and stores the result on the device, which breaks "same for every child", so it is rewritten, not ported.

### 8. Templates: fixed, authored, ported from the existing app

The 39 templates in `Templates/Core` are ported: nine abstract shapes, the first ten pictures (the old quest pool) and twenty newer pictures, in four levels. Template difficulty and reach are authored on purpose to widen range of motion, so they are not generated. A `TemplateSource` seam is kept in Core so a generated source (Image Playground plus Vision contours, in free mode) can be added after v1 without touching the pages.

Amended 7 Nov 2026: templates no longer unlock one after another. The prototype's `main` opens every template from the start and sorts them by level, so unlock state is not derived from the gallery any more and deleting a painting relocks nothing. If a progression is wanted again, derive it from the non-deleted paintings as before; it still needs no column.

## Consequences

- Backend scope is small: `profiles`, `paintings`, `painting_stats`, one private Storage bucket, and a `delete-account` edge function.
- Account deletion must also remove Storage objects, which do not cascade from the database. This is required by App Store guideline 5.1.1(v) and applies to anonymous accounts too.
- Privacy policy and consent text must name the uploaded movement stats.
- Onboarding gains one screen (consent).
- If the app is later placed in the Kids Category, guideline 1.3 limits third-party analytics and ads and expects a parental gate for outbound links. That decision, and with it the gate, is open until I3.

## Rejected alternatives

- Online-first: fails offline and makes every save wait for the network.
- Parent account with many child profiles: more RLS and UI than 12 days allow, and no current need.
- Server-generated daily quest: adds a table, a function and an offline cache for no gain, since a date hash already gives every child the same quest.
- Uploading the timelapse in v1: size is unmeasured and the timing data is more sensitive than the final painting.
- Generating templates with an on-device model: not deterministic across devices, cannot guarantee therapeutic difficulty, and needs Apple Intelligence capable devices.
