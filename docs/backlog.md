# Backlog and chunking

Plan for building Rona with a Supabase backend. This document orders the work into chunks and marks what can run in parallel and what must run in sequence.

## Status on 7 November

Done: Wave 0, lane A, lane B, D3, D4, and the whole of Wave 2 (E0 to E4); details in [handover.md](handover.md). Not started: lane C (C3 was due on 7 Nov and C4 on 8 Nov, so it is the critical path now), D1, D2, D5, Wave 3 and Wave 4. The port source is `PuffyPond2` `main`, which changed the canvas, the characters and the templates after this plan was first written; the chunk tables below already follow it.

## Scope and decisions

The decisions below are recorded in [ADR 0001](adr/0001-backend-architecture.md). The data model is in [data-model.md](data-model.md).

- **Platform:** iPad only, landscape, full screen only (`UIRequiresFullScreen = YES`). No Mac, Catalyst, Stage Manager or split view.
- **Backend:** Supabase for auth, Postgres (paintings, session stats, daily quest) and Storage (painting PNGs).
- **Engine unchanged in kind:** Metal wet-paint simulation, SceneKit stages, Vision hand and body pose, all on device.
- **Local first:** every page must work against a local gallery store, so feature work never waits on the network. Supabase sync is layered on top.
- **Privacy:** the camera feed never leaves the device. Only derived movement stats are uploaded. The app is for children and the stats are health-adjacent, so row level security is strict and the Storage bucket is private.
- **Code layout:** keep the existing feature grouping, each feature split into `Core/` (pure logic, unit tested), `Shell/` (SceneKit, Metal, camera, audio, files, network) and `Views/` (SwiftUI).

This reverses the PuffyPond2 README promise of "No network, no accounts". Wave 0 decides how.

## Legend

- **SEQ**: must run after the chunks it depends on, and usually blocks others.
- **PAR**: can run in parallel with other PAR chunks in the same wave, once its dependencies are done.
- **Needs**: the chunks that must be finished first.

## Wave 0: Foundations (all SEQ)

| ID | Chunk | Mode | Needs | Done when |
|---|---|---|---|---|
| 0.1 | Product decisions and ADR | SEQ | none | ADR records: auth model (Sign in with Apple, anonymous-first or not), parental consent approach for a children's app, what is synced (PNG, stats, timelapse or not), local-first sync policy, what is never uploaded |
| 0.2 | Project skeleton | SEQ | 0.1 | iPad-only Xcode project, landscape lock, `UIRequiresFullScreen`, feature folders, test target, CI, `supabase init` with local stack, `supabase-swift` via SPM |
| 0.3 | Contracts | SEQ | 0.2 | ERD and schema draft in [data-model.md](data-model.md), domain types (`Painting`, `SessionStats`, `TemplateID`), and repository protocols (`GalleryRepository`, `StatsRepository`, `QuestSource`). This is the seam that lets Wave 1 run in parallel |

## Wave 1: Four parallel lanes

Chunks inside a lane are SEQ unless noted. The lanes are PAR with each other.

### Lane A: Backend

| ID | Chunk | Needs |
|---|---|---|
| A1 | Migrations: `profiles`, `paintings`, `painting_stats` (no `daily_quest`; the quest is computed on the client) | 0.3 |
| A2 | Row level security policies | A1 |
| A3 | Storage bucket `paintings` (private) and its policies | A1 |
| A4 | pgTAP tests for RLS and Storage access | A2, A3 |
| A5 | `delete-account` edge function: remove the user's Storage objects, then the auth user (required by App Store guideline 5.1.1(v)) | A1, A3 |
| A6 | Cleanup job for abandoned anonymous users and old tombstones (optional) | A1 |

### Lane B: Input

| ID | Chunk | Mode | Needs |
|---|---|---|---|
| B1 | `HandTracker`, `HandPose`, `OneEuroFilter` (camera plus Vision, open/fist with hysteresis, smoothing) | PAR | 0.2 |
| B2 | `DistanceGate`, `SwipeDetector`, `HandFrameRelay` | PAR | 0.2 |
| B3 | Touch and Apple Pencil fallback input | PAR | 0.2 |

### Lane C: Paint engine

| ID | Chunk | Needs |
|---|---|---|
| C1 | `PaintLayer` and Metal shaders (dabs, advection, leveling, mixing, drips, drying, normal map) | 0.2 |
| C2 | Pure rules: `BrushStyle`, `StrokeBook`, `StrokePath`, `CanvasLayout` (fixed per-device fit, no live resize, full-screen canvas), `PotRub` (rubbing a buddy over a sleeping character), `Paint`, `PaintTool`. No `Hint`: it is gone from the prototype | 0.3 |
| C3 | `EaselScene`, `Studio`, `Toybox`, photo booth | C1, C2 |
| C4 | Performance gate: frame budget measured on a non-Pro iPad before any feature is stacked on the engine | C3 |

Until Lane B lands, C1 to C3 use a fake point-stream input.

### Lane D: Independent pieces (all PAR)

| ID | Chunk | Needs |
|---|---|---|
| D1 | Audio: `GrooveDSP`, sound effects, beat clock | 0.2 |
| D2 | Templates: port `TemplateDesign`, `TemplateCatalog` (39 templates in four levels, all open, no unlock chain) and `OutlineArt`. The quest of the day is any template: make it deterministic (stable hash of the local date, never equal to yesterday's, guarded by `questPoolVersion`, pure, behind `QuestSource`). The prototype's `DailyQuestStore` rolls randomly and stores the pick, so this part is a rewrite | 0.3 |
| D3 | Treehouse garden theme and shared visual tokens | 0.2 |
| D4 | `AppRouter`, `Route`, Home page | 0.2 |
| D5 | Trace guide (new in the prototype, needs a scope decision): `TraceGuide` (pure), `GuideArrow`, `GuideVoice`, the 174 voice clips and `tools/voice`. Directions are Bahasa Indonesia. Cut it before anything else if time is short; the dotted outline works without it | D2 |

## Wave 2: Backend bridge

| ID | Chunk | Mode | Needs |
|---|---|---|---|
| E0 | Consent onboarding: consent screen before the first sign-in, `ConsentStore` (local flag with version). The parental gate was dropped for now (ADR 0001, decision 4) | SEQ | D3, D4, 0.3 |
| E1 | Auth: anonymous sign-in after consent, session in Keychain and restore on launch, upgrade through `linkIdentity` with Sign in with Apple, create `profiles` row | SEQ | A1, E0 |
| E2 | `LocalGalleryStore`: file-based implementation of `GalleryRepository` and `StatsRepository` | PAR with E1, E3 | 0.3 |
| E3 | `SupabaseGalleryRepository` and `SupabaseStatsRepository`: Storage upload plus row insert | PAR with E2 | A2, A3, E1 |
| E4 | Sync engine: offline queue, retry, last-write-wins, deletion propagation, uploads through a background `URLSession` (templates no longer lock, so a deletion does not relock anything) | SEQ | E2, E3 |

E2 is deliberately early so that Wave 3 never depends on the network.

## Wave 3: Feature pages

| ID | Chunk | Mode | Needs |
|---|---|---|---|
| F1 | `Critter` base: body rig, face nodes, springs, moods, the sleeping state (`CritterKind`, `Springs`, `Face`, `BuddyMode`, `LimbBundle`) | SEQ | C3 |
| F2 | Ladybug, red (and `LimbBrush`) | PAR | F1 |
| F3 | Butterfly, blue | PAR | F1 |
| F4 | Frog, green (new; replaces Mushroom, there is no eraser any more) | PAR | F1 |
| F5 | Snail, orange (shows its side; it is no longer the blender) | PAR | F1 |
| G1 | Get ready page (skeleton outline, distance ring, Skip) | PAR | B2, D4 |
| G2 | Review page: `SheetSolver`, `SheetGestures`, `PaintMatte`, `ReviewStage` | PAR | B1, C1, E2 |
| G3 | Gallery: 3D treehouse hall plus 2D grid | PAR | D3, E2 |
| G4 | Report: calendar, `DayReport`, heatmap (also per hand: add `sideHeatmaps` to `SessionStats`), hand dominance | PAR | E2 |
| H1 | Canvas page: full-screen canvas, the four sleeping characters along the bottom edge, settings menu (character size, sound, restart canvas, save image, guide, quit), eye button, `Playground`, `SessionRecorder`, Save flow. No pots, bubbles or colour chips | SEQ | B1, B3, C4, D1, D2, F2 to F5, E2 |

## Wave 4: Final layers

| ID | Chunk | Mode | Needs |
|---|---|---|---|
| I1 | Timelapse: `StrokeRecording`, replayers, renderer, and the camera timelapse (small JPEG snapshots of the child, local only, in a `.camera` file). Decide first whether recordings are uploaded to Storage (v1: no). The camera timelapse needs a privacy and consent check before it ships | SEQ | H1 |
| I2 | NCA model: training tools and `nca.bin` packaging | PAR with I1 | 0.2 |
| I3 | Hardening: RLS audit, account and data deletion, privacy review for children, iPad model by iPadOS version test matrix, observability, TestFlight | SEQ | everything else |

## Critical path

```
0.1 -> 0.2 -> 0.3 -> A1 -> A2/A3 -> E1 -> E3 -> E4 -> (Supabase-backed Gallery and Report) -> I3
```

The engine path (Lane B, Lane C, F1 to F5, H1) is not on the critical path, so it can run fully in parallel with the backend path. It only needs `LocalGalleryStore` (E2) to finish the Canvas page.

## Timeline: due Sunday 15 November 2026

Assumptions: planning starts Wednesday 4 November, which leaves 12 days. The existing PuffyPond2 code (a separate, read-only reference repo) is ported and used as reference rather than written blind, and work is split across parallel sessions per lane. Not every chunk fits, so the plan has a cut line (see below).

| Day | Date | Focus | Chunks |
|---|---|---|---|
| Wed | 4 Nov | Decisions and skeleton | 0.1, 0.2 |
| Thu | 5 Nov | Contracts, start lanes | 0.3, then start A1, B1, C1, D4 |
| Fri | 6 Nov | Wave 1 in parallel | A1 to A3, B1 to B3, C1 to C2, D1 to D4 |
| Sat | 7 Nov | Wave 1 in parallel | A4, A5, C3, finish B and D; Wave 1 merge |
| Sun | 8 Nov | Perf gate and auth | C4, E0, E1, E2 |
| Mon | 9 Nov | Backend bridge | E3, F1 |
| Tue | 10 Nov | Critters and sync | F2 to F5 in parallel, E4 |
| Wed | 11 Nov | Pages in parallel | G1, G2, G3, G4 |
| Thu | 12 Nov | Canvas integration | H1 |
| Fri | 13 Nov | End-to-end flow | Home to Canvas to Review to Gallery to Report, synced through Supabase; bug fixing |
| Sat | 14 Nov | Hardening lite and release build | I3 subset: RLS audit, account and data deletion, privacy check, TestFlight build |
| Sun | 15 Nov | Buffer and submission | Fixes only, no new work |

### Milestones

- **Thu 5 Nov:** Wave 0 done, contracts merged. Lanes can start.
- **Sat 7 Nov:** Wave 1 merged. Backend schema with RLS tested, engine paints with a fake input.
- **Mon 9 Nov:** perf gate passed (C4) and auth working on a device.
- **Wed 11 Nov:** all feature pages exist against `LocalGalleryStore`.
- **Fri 13 Nov:** full flow works end to end with Supabase sync. Feature freeze.
- **Sun 15 Nov:** delivered.

### Cut line if time slips

Drop in this order, keeping the core flow (paint, save, gallery, report, sync) intact:

1. I2 NCA model.
2. I1 Timelapse (including the camera timelapse).
3. D5 trace guide voice (keep the dotted outline; drop the arrow and the spoken directions).
4. A6 cleanup job for anonymous users and tombstones. A5 `delete-account` is required and is not cut.
5. G3 3D gallery hall (ship the 2D grid only).
6. Review page polish (G2), keeping only grab and release.

### Checkpoints that need a decision

- **Wed 4 Nov (0.1):** auth model and consent approach must be decided on day one. Every day this slips moves the whole critical path.
- **Sun 8 Nov (C4):** if the Metal engine misses the frame budget on the target iPad, stop and fix it before building pages on top.
- **Wed 11 Nov:** if H1 is not startable by Thursday morning, apply the first three cuts.

## Risks

- **0.1 is the biggest risk.** A wrong call on consent, auth or what gets uploaded forces schema and RLS rework.
- **Metal performance on older iPads** (C4). Measure before building on top of the engine.
- **Screen size variance.** Full screen only removes resizing, but iPad models differ in aspect ratio, so test `CanvasLayout` on at least two or three sizes.
- **Pose stats are 2D estimates** from the front camera, not clinical measurements. Keep that wording in any user-facing privacy or data text.

## Suggested split into sessions

Lanes A, B, C and D are independent enough for separate sessions or worktrees once Wave 0 is merged. Lanes that write the same files should not run together: A is backend files only, B is `Input/`, C is `Canvas/`, D touches `Audio/`, `Templates/`, `App/` and `Home/`.
