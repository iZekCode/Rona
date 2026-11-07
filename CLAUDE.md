# Rona

Rona is an iPad painting app for children. They paint in the air: a fist and an arm sweep lay wet oil paint on an easel, tracked by the front camera (Vision hand and body pose). Movement stats (range of motion, reach, grip cycles, heatmap, hand dominance) are recorded per painting. Backend: Supabase.

Code to port from lives in `../PuffyPond2` (read-only reference, do not edit it).

## Read first

- `docs/handover.md`: current status, next step, and where to port code from.
- `docs/adr/0001-backend-architecture.md`: the locked product and backend decisions.
- `docs/data-model.md`: data model, RLS, Storage, Swift contracts.
- `docs/backlog.md`: chunked backlog with sequential/parallel marks and the 15 Nov 2026 timeline.

## Locked decisions (details in the ADR)

- iPad only, landscape, full screen (`UIRequiresFullScreen`). No iPhone, no Mac.
- Consent first (no parental gate for now; decided before the App Store submission); anonymous sign-in after consent; upgrade with `linkIdentity` (Sign in with Apple). One account is one child.
- Upload painting PNG and session stats. Timelapse stays local in v1. Camera frames never leave the device.
- Local-first: the UI reads only the local store; a sync engine (outbox, client UUIDs, tombstones, last-write-wins) talks to Supabase.
- Daily quest is computed on the client from a stable hash of the local date, same for every child. No `daily_quest` table.
- Templates are authored, not generated.

## Code layout

Top-level folders under `Rona/`:

- `App/`: entry point, `Route`, `AppRouter`, and `AppServices`, the composition root that builds every concrete type.
- `DesignSystem/`: visual tokens and shared components. Depends on nothing else in the app.
- `Engines/`: capabilities used by two or more pages (`Input`, `Motion`, `Paint`, `Characters`, `Audio`).
- `Features/`: one folder per page (`Home`, `Consent`, `Account`, `GetReady`, `Templates`, `Canvas`, `Review`, `Gallery`, `Report`, `Timelapse`).
- `Data/`: models and repository protocols shared across the app in `Data/Core/` (`Painting`, `SessionStats`, rows, auth and sync contracts); the local store, Supabase and the sync engine in `Data/Shell/`.
- `Resources/`: asset catalog, voice clips, model files.

Each engine, page and `Data/` splits into the subfolders it needs:

- `Core/`: pure logic. Imports only Foundation, simd or CoreGraphics. No SceneKit, Metal, Vision, AVFoundation, SwiftUI, no clock, randomness or file I/O. Unit tests live here.
- `Shell/`: everything that touches the outside world (SceneKit, Metal, camera, audio, files, network) and the `@Observable` stages that drive a page.
- `Views/`: SwiftUI pages and overlays.

Dependency rules:

- A page uses `Engines/`, `DesignSystem/` and `Data/Core/`. It reaches another page through `AppRouter` and `Route`, and reaches storage through the repository protocols in `Data/Core/`, which `AppServices` wires to the local store.
- An engine uses other engines and `Data/Core/`.
- `Data/Shell/` uses `Data/Core/`.
- A type shared by several areas (a model, a protocol that `Data/Shell/` implements) lives in `Data/Core/`, not in the page that uses it first.

`RonaTests/` mirrors this tree, one folder per engine, page or `Data`.

## Working rules

- Work chunk by chunk from the backlog, in dependency order. Mark a chunk done in `docs/handover.md`.
- Port from `../PuffyPond2` with its tests. Do not copy a large file wholesale; bring the pure `Core` piece and its test first.
- Update the ADR when a locked decision changes. Do not change one silently.
- Everything user-facing for children stays simple and low-text.
