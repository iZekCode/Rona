# Rona: product spec

## What Rona is

Rona is a painting game for children on the iPad. There is no pen and no finger painting needed. The child stands or sits about one meter from the iPad, makes a fist and sweeps an arm through the air, and real-looking wet oil paint appears on an easel on the screen. A small paint character follows each hand and does the painting.

The game is built to get children moving their arms, shoulders and hands in a fun way. While they paint, the app quietly measures how they move (how high they reach, how far they stretch, how often they grip) so a parent or therapist can look back at it later. Rona is a game first. It is not a medical device, and the movement numbers are estimates, not clinical measurements.

Rona is a rebuild of an earlier prototype called PuffyPond2, now with accounts and a cloud backup.

## Who it is for

- **Main player:** a child who benefits from big, playful arm movement, for example a child doing movement exercises at home or in a clinic.
- **Grown-up in the background:** a parent or therapist who agrees to the privacy terms, watches progress in the report, and keeps the account safe.
- **One account is one child.** The app is not built for several children sharing one profile.

## Goals

- A child can start painting within seconds, with no sign-up wall.
- Painting feels smooth and alive: paint appears right where the hand moves, with no lag.
- The game rewards coming back: a new quest every day, shapes and pictures from easy to hard that are all open from the start, and a gallery that fills up.
- Paintings and progress survive a lost or replaced iPad.
- The app works with no internet at all. The internet is only for backup.
- The camera picture never leaves the iPad.

## Not part of this version

- iPhone, Mac, or split-screen and window resizing. Rona is iPad only, landscape, full screen.
- Several children under one account.
- Sharing paintings with other people, public galleries, or social features.
- Video export or screen recording.
- Templates made by an AI model. The shapes are drawn by hand on purpose, so their difficulty can be controlled.
- Uploading the replay recordings (see "Replay of how a painting was made").
- Any claim that the movement numbers are a medical measurement.

## How a session goes

1. **First launch.** A short consent screen for the grown-up. Nothing is created or stored on the server until they agree.
2. **Home.** Three big choices: start painting, see the gallery, see the report.
3. **Choose what to paint.** Free painting on a blank canvas, or trace a dotted shape.
4. **Get ready.** A skeleton outline shows where to stand. The child steps back until the shoulders fit the band, holds still while a ring fills, and the canvas opens by itself. A skip button is always there.
5. **Paint.** Fist to paint, open hand to move without painting. Four sleeping characters wait along the bottom edge; rub the character that follows your hand over one to wake it and paint with its colour. A settings menu (top left) holds character size, sound, restart canvas, save image, the guide and quit.
6. **Save image.** The finished painting moves to the review page.
7. **Review and play.** The paint floats on a stretchy see-through sheet. The child can grab it, pull it, push ripples and splashes, and watch it spring back. A silly tune plays. Playing never changes the saved picture.
8. **Save to gallery** or **keep drawing** on the same canvas.
9. **Gallery.** The painting hangs in a treehouse among the branches, next to the others.
10. **Report.** Later, a grown-up opens a calendar, picks a day, and sees that day's paintings and movement numbers.

Without a camera, every step also works by touch (and Apple Pencil), so the app is never stuck.

## Features

### Painting with your hands

- The iPad's front camera follows both hands and the upper body, on the device.
- A closed fist paints. An open hand only moves the character. A fist that is loosening keeps painting for a moment so strokes do not break.
- The paint is simulated like real wet oil: flat strokes with bristle grooves and ragged edges, thick blobs that sag a little, and paint that dries over time. Faster strokes look smoother, slow strokes keep the full texture.
- New paint covers old paint.
- The canvas fills the whole screen and the camera picture covers it edge to edge. There are no paint pots, bubbles or colour chips, so nothing covers the painting. A button in the top right corner (the eye) only shows or hides the camera picture.

### The four paint characters

- **Ladybug:** red.
- **Butterfly:** blue.
- **Frog:** green.
- **Snail:** orange. It always shows its side.

One character, one colour. The four wait in a row along the bottom edge, asleep (still, eyes closed, quiet) until a buddy comes near. Rub the buddy over one to wake it; the buddy becomes that character. There is no eraser and no blender any more.

### Templates and the daily quest

- **Templates:** 39 pictures to trace, from abstract shapes and simple pictures (heart, cloud, apple) to big ones that stretch into every corner of the canvas, so children slowly widen their reach. They are sorted in four levels, easy first, and all are open from the start. Children are not told a level. The names are in Bahasa Indonesia.
- **Daily quest:** one template each day, the same for every child on the same day and never the same one two days in a row. A finished quest earns a star on the calendar.
- **Trace guide (proposed):** while the child traces a dotted outline, an arrow and a spoken direction in Indonesian ("Naik ke atas!") follow the brush along it. It is not in the first version unless the time allows (backlog chunk D5).

### Review and play

A stretchy sheet that reacts to the hands: a fist grabs a small patch and pulls it, two fists pull two patches apart, a moving open hand pushes ripples and splats (sometimes with a duck). Everything springs back when let go.

### Gallery

- A 3D treehouse deck with paintings on wooden partitions, newest first, and the four garden characters visiting.
- Walk along it with an open-hand sweep (down on the right side for next, on the left for back), or with arrows and swipes.
- A flat 2D grid, grouped by day, for finding a painting fast. Tapping one walks to it in 3D.

### Report

- A month calendar. Days with paintings get a dot, days where the daily quest was done get a star.
- For the chosen day: that day's paintings and movement numbers.
  - Highest reach of the shoulders (left and right) and elbow stretch.
  - Reach height and the area covered.
  - Number of grip cycles.
  - A flag if the child leaned to the side.
  - A heat map of where on the canvas they painted.
  - Which hand did more of the painting.
- Left and right always mean the child's own sides.
- Numbers are recorded only on the painting page and only from camera hands. A painting made by touch shows "No movement data".

### Sound and music

The music and sound effects are made inside the app. A bouncy garden tune plays while painting, a silly kazoo-and-tuba tune plays on the review page, and every character has its own sounds. Music can be turned off. The only recorded audio is the spoken trace guide, if it is included (see above).

### Replay of how a painting was made (planned)

After saving, the painting could first replay itself stroke by stroke in about 15 to 20 seconds, with a note played for every stroke, before the child can play with it. The recording stays on the iPad in this version. This is the first thing to drop if time runs short.

A second replay is planned with it: small camera snapshots of the child painting, played back fast beside the painting's own replay. They stay on the iPad like the rest. Because they show the child, they need a clear line in the consent text, and they are dropped together with the replay if that check is not done in time.

### Account, backup and sync

- The app signs the child in silently as a guest right after the grown-up agrees. No password, no email.
- Later, the grown-up can link a Sign in with Apple account. The same data stays and nothing is lost. This protects paintings if the iPad is lost or replaced.
- Paintings and movement numbers are backed up in the background whenever there is internet. Painting and saving never wait for it.
- A grown-up can delete the account, which removes all its paintings and numbers from the server.

## Privacy and safety

- **Consent first.** A consent screen with a link to the privacy policy comes before anything else. No account is created before the grown-up agrees. If the consent text changes, it is asked again.
- **Camera pictures stay on the iPad.** Only the finished painting and the movement numbers are backed up.
- **Movement numbers are sensitive.** The privacy text must say clearly that they are collected and stored.
- **Private storage.** Each account can only see and change its own data. Paintings are kept in a private folder tied to the account.
- **Data cleanup.** Deleted paintings are removed for good after 90 days. Guest accounts that never saved anything are removed after 30 days. A daily job does this.
- **Open question:** whether the app goes into Apple's Kids category. That decides the rules for analytics and links out, and whether a grown-up check is needed on buttons like account deletion. For now those buttons are plain buttons. It must be decided before the App Store submission.

## Device and platform

- iPad only, landscape only, full screen. No other layouts to support.
- The iPad needs a front camera and a graphics chip that can run the paint simulation at a smooth frame rate. The oldest supported iPad is still to be measured.
- Camera permission is needed for hand painting. If it is refused, touch painting still works.
- The child should have room to stand or sit about one meter from the iPad.

## Tech stack

**App**
- Swift and SwiftUI for the pages.
- SceneKit for the 3D parts: the easel, the characters, the treehouse gallery and the stretchy sheet.
- Metal for the wet paint, simulated on the graphics chip.
- Apple's Vision framework for hand and body tracking, and the camera framework for the video feed, all on the device.
- Music and sound effects are synthesized in code with Apple's audio engine; the trace guide, if included, plays short recorded voice clips.
- Swift Package Manager for dependencies. The Supabase Swift library talks to the backend.

**Backend (Supabase)**
- Sign-in: guest sign-in first, then Sign in with Apple linked to the same account.
- Database (Postgres) with three tables: profiles, paintings and painting stats. Row level security makes every row private to its owner.
- Storage: one private bucket for painting images.
- Edge functions: one deletes an account together with its files, one cleans up old data.
- A daily scheduled job calls the cleanup function.

**Quality and delivery**
- Unit tests for all the pure logic (shapes, quest of the day, stroke rules, stats, sync planning).
- Database tests for the privacy rules.
- Xcode Cloud builds and runs the app tests. GitHub Actions runs the database tests.
- TestFlight for builds to testers.

## How the code is organized

Everything is grouped by feature (input, canvas, characters, review, gallery, stats, templates, audio, consent, sync). Inside each feature there are three layers:

- **Core:** plain logic with no screen, camera, sound, network or clock. This is where tests live.
- **Shell:** everything that touches the outside world: the camera, the graphics, the files, the network.
- **Views:** the screens.

Pages only ever talk to the on-device store. Only the sync engine talks to the server.

## How data is kept

- **The iPad is the main copy.** Every painting is saved on the iPad first, so saving is instant and works offline.
- **The server is the backup.** A sync engine keeps a to-do list of changes and sends them when there is internet, retrying if it fails. Each painting gets its own unique id on the iPad, so a retry never makes a duplicate.
- **If two copies disagree, the newest change wins.** One account is one child, so this almost never happens.
- **Deleting is remembered.** A deleted painting is marked as deleted first, so the deletion reaches the other iPad too.
- **A new iPad** downloads the list of paintings and loads full images when they are opened.

## Quality bars

- Painting must stay smooth. Recording movement numbers must never cost frames.
- Saving a painting must never wait for the internet.
- The app must be usable with no camera and no internet.
- The shown final picture must match the saved painting exactly.
- Screens for children use few words and big buttons.
- The first quest and first template must be reachable in a couple of taps after consent.

## What counts as done for the first release

Due date: Sunday, 15 November 2026.

Must have:
- Consent, guest sign-in and the link to Sign in with Apple.
- Painting with hands and with touch, with all four characters (Ladybug, Butterfly, Frog, Snail).
- The templates and the daily quest.
- Review and play page.
- Gallery (a flat grid is enough if the 3D treehouse does not fit).
- Report with the calendar and movement numbers.
- Backup and restore through the server, and account deletion.
- A build on TestFlight.

Drop first, in this order, if time runs short:
1. The neural-network paint texture model.
2. The replay of how a painting was made, with the camera replay.
3. The spoken trace guide, keeping the dotted outline.
4. The 3D treehouse gallery, keeping the flat grid.
5. Extra polish on the review page, keeping grab and release.

## Risks

- **Paint speed on older iPads.** The simulation is heavy. It must be measured early, before more is built on top.
- **Privacy rules for children.** The Kids category decision and the exact consent wording could force changes late.
- **Guest accounts can be orphaned.** If the app is deleted before linking Sign in with Apple, the data is stranded. The prompt to link must be easy to see.
- **Movement numbers are only estimates.** A single front camera sees in 2D. Never describe them as medical measurements.
- **Camera and hand tracking on real iPads.** Much of it has only been tested in the simulator, so it needs real-device testing.
- **Tight schedule.** Roughly twelve days for a full rebuild only works because large parts are ported from the prototype.

## Open questions

- Kids category: yes or no, and what that means for the grown-up check.
- Final wording of the consent screen and the privacy policy page.
- The oldest iPad model to support.
- Whether the replay recordings should ever be backed up, once their size is known.
- How a grown-up should see a child's report if the iPad is shared (for now, they open the app on the child's iPad).

## Words used in this document

- **Quest:** the template of the day, the same for every child.
- **Template:** a dotted shape or picture to trace.
- **Review:** the page after saving where the child can play with the paint.
- **Tombstone:** a "this was deleted" mark kept for a while so deletions can spread to other devices.
- **Guest sign-in:** an account made silently, with no email or password.
