# Current Swift Mac verification — 2026-11-10

## v0.23.0 source baseline and native compatibility — 2026-11-10

The Swift branch merges stable Rust v0.23.0 (`5d0e892e`), preserving the earlier
port commits. Local and fork `main` independently fast-forwarded to upstream
`776e468e`.

The official Rust 0.23.0 Mac CLI wrote v1, v2, v3, v4 and gzip-v4 fixtures with
editable vector art, a Twist effect and an image. After a save by the Swift CLI,
Rust reopened all five. The decoded document data, image bytes and the +37°
Twist angle matched across the round trip.

A separate Rust 0.21.0 v4 fixture reproduced a Twist sign flip on reopening a
Swift save in Rust 0.23.0. Swift now retains the generator Rust uses to interpret
the original angle. The fixture now reopens at +37° after a Swift save. All eight
`NativeV4Tests` passed with Xcode 27.3 beta 1 (`27C5020n`). The source update was
verified through the CLIs and did not replace either installed app.

## v0.21.0, bitmap Paste and portable upstream addition — 2026-11-04

Local main fast-forwarded to stable v0.21.0,11862f61198c8f62c0b22b6c9a331cc5950ac98d.
All four dirty tracked files reapplied without conflicts;276 pre-existing Apple/handoff
files matched their preservation hashes immediately afterward. The186,327,040-byte
source/Git archive is verified (SHA25616e81ce3cd1a795e128b23e4ad06708cc644548446e86ec40aedb6eb38dd8b2b).
Recovery stash dbd27f407cacd016e9d68ea574d736e1e52937c7 remains retained. Ignored builds/
evidence stayed in place. No source commit, push, PR or Rust-app replacement occurred.

The pinned shared craft-libs contract still uses native versions1–4,8192-byte inline
threshold and the existing binary marker. The official Rust0.21 Mac CLI archive's
published checksum was verified. Its v1/v2 legacy, v3, v4 and gzip-v4 writer outputs
pass Swift read/write → Rust reopen, with exact document and decoded-image bytes.
Swift still limits files to64MB and accepts writer-produced object envelopes; upstream
also reads ordered array envelopes and permits larger resources. No codec rewrite.

The full Xcode27.3 beta1/27C5020n gate passes195 checks:115Core +76Mac +4CLI, without
compiler warnings. The focused clipboard/native checks cover22 distinct tests. The
original disabled-Paste regression failed first; its enabled/import/Undo path now
passes. TIFF fidelity compares every decoded pixel against the original after a
probe confirmed Device RGB color management, rather than assuming a pure RGB triplet.
All compilation used one nice15 job, with heavy checks sequential. No long trace or
full Rust build/test suite ran.

PNG/TIFF Paste now prepares bounded image data on a per-canvas serial utility actor,
then uses the existing VectorFragment/DrawingCommand/CanvasDocument Undo path. PNG
bytes remain intact; TIFF becomes lossless PNG at its physical resolution. Native
artwork/SVG and meaningful text keep priority; blank text can yield a bitmap. Target
changes refuse stale results, another Paste supersedes pending work, and canvas
teardown cancels it. Limits are16MB,32MP and16384px per side. Broader formats, profile
conversion and multi-app/hardware fidelity remain open.

G2-signed package.NNi7gl is installed at /Applications/VectorCraft Swift.app. Strict
signature verification passes with Team Z5F6B8QVKJ. Installed and packaged executable
SHA256:831d030264535bcdba4f0ba5bc4020cefc2d82e2961acc44e7eddb9d905d238b.
Native Edit → Paste imports the original320x160PNG at the viewport center; native
Save retains its exact PNG bytes in v4. One Undo/Save restores the exact original
file; Redo/Save restores the exact pasted snapshot. Native PNG export is612x792,
SHA25694960fcb666c6e192faefee3bf6f4234e2f477bb48f7485f36748d20ca2a6721,
and was visually inspected. Full quit/relaunch/Open confirms the saved bitmap on
canvas. Automation timeouts required a fresh chooser selection; a one-second sample
showed an idle event loop, and no app fix was inferred from that tooling interruption.
Both CLI readers also reopen the native UI save. The successful clipboard test restored
the original clipboard; the app was quit after final acceptance.

Packaging is self-contained in apple/ with local license texts/NOTICE. This Mac's
G2 signing, Source Sans fonts and local Vectorify branding now come from the ignored
local-build.env; its existing appearance is preserved. Local fonts are cached in
ignored build inputs and match installed bytes, so upstream Rust asset paths are no
longer needed. Private branding and Cortex notes are also ignored by Git. A separate default-package
check passes ad-hoc strict signing with no private icon/fonts, then restores the local
settings. The portable source export includes source/tests/licensed resources with
file hashes, and excludes private assets/configuration, fonts, builds, verification
artifacts and Cortex notes. Its extracted package parses without parent Rust files.
One-time registration adds65 asset rows, preserves existing root text and is byte-
identical on a second run. No separate full build from the extracted copy was repeated.
Actual upstream acceptance/publication remains separate; see INTEGRATION.md.

The original Rust executable retains its recorded hash. No user document was opened
or written; historical Smartlist paths were unavailable for a fresh hash comparison.
No build/test/clipboard helper remains active after verification. No permission,
headless-service, iPhone, cloud or personal-skill change. Full Mac parity, visual frame
browsing, deeper screenshot composition, native card/Finder drag acceptance and
physical trackpad feel remain open.

Evidence: verification/upstream-v021-20261104.json; build/current-v021-evidence.txt;
UPSTREAM_V021_PLAN.md, UPSTREAM_V021_REVIEW.md and INTEGRATION_PLAN.md. Earlier
checkpoints below retain their original toolchain and proof level.

## Visual screenshot layout chooser — 2026-10-31

Installed G2-signed `build/package.VesCOA/VectorCraft Swift.app` at the canonical Mac
path. Package and installed executable SHA-256 both equal
`97884f0db019a1dff777562c74cc897538d77a21483ba981d726126e3b3f27d0`;
normal-session strict signature verification passes. Selected Xcode27.2/27B52.

New Slots and selected Layout now open the same compact five-choice visual gallery.
Original vector schematics use the shared Core device placement and current device/
artboard aspect; they resolve no images or files. Selected state and named accessibility
IDs are present. These are schematics, not live composition renders. New Slots uses
representative portrait geometry and changes the current inspector's future-slot default.
Selected Layout invokes the existing setTemplate command and native document Undo.

Native acceptance proved Escape dismissal and a New Slots default change leave exact
saved bytes untouched. Choosing Phone Off Bottom then activating slot2 saved that
template on the new board. Undo restored exact original bytes. That check exposed an
existing invalid selected-artboard index after Undo removed the selected last board;
the editor now repairs only invalid indices, restores the insertion target and fits
the remaining board. Final installed acceptance retains selected slot1 and Layout
controls after that Undo. Valid selections keep their view and insertion target.

Choosing Phone Off Top moved the existing device/caption, refreshed its card and
saved native v4. One Undo/Save restored exact source bytes; Redo/Save restored the
edited snapshot. Native close/reopen retained the layout and gallery checkmark.
Image resources and binary arena bytes are unchanged. CLI Export Used produced
exactly one1206x2622PNG, inspected visually, excluding the nine unused slots.

Initial12 focused checks and final8 repair checks passed without compiler warnings:
14 distinct checks across both runs. Geometry covers20 combinations of layout,
portrait/landscape and iPhone/iPad; native tests cover resources, foreign data,
one-step Undo/Redo and usable selection after removing a slot. No broad suite or
performance trace was repeated; the last broad184-test run remains historical below.
All builds used one nice15 job. Verification used a5KB synthetic native project and
32x64 original test image. Both saved Smartlist projects and Rust app retain their
recorded hashes. Test app/compilers are stopped; previous installations remain in Trash.

Evidence: `verification/layout-gallery-20261031.json`, `LAYOUT_GALLERY_PLAN.md`,
`build/layout-gallery-20261031/` and focused/final-package/install logs dated20261031.
Visual device-frame browsing, deeper template composition, physical trackpad feel,
native drag acceptance, larger performance budgets and full Mac parity remain open.

## Previous checkpoint: cached screenshot card images — 2026-10-31

Canonical installed app matches G2-signed `build/package.ZU3FNB/VectorCraft Swift.app`;
executable SHA-256 `e8309dcd66d7809b6582cc855c23004dfc68c9bdd4f18dbee2e0277d263b0a20`.
Selected Xcode27.2/27B52. All20 focused checks pass (17Core +3Mac), without compiler
warnings. The last broad suite is the184-test run below; it was not repeated.

The serial ScreenshotPreview actor now owns a synchronous image-preview cache and
passes it through the existing PNG renderer for cards only. Shared image resolutions
can be reused across card redraws; the existing resource/blob/linked-file identities
invalidate stale pixels. Default PNG/export calls omit this cache. Existing cancellation,
geometry, screen clipping and original-resource paths are retained.

One paired three-card comparison (iPhone, Duo, iPad), each rendered twice sequentially,
measured605.1→925.8ms for the first pass and464.2→79.7ms for the repeated pass. Initial
proxy creation was slower in this sample; the improvement is repeated rendering, not
an established cold-load reduction. Machine load varied. This is not native UI timing
or OS disk-cold proof. Before/after cards were inspected; resampling may differ slightly
at thumbnail size. One original-resolution CLI PNG is byte-identical to the prior
baseline, SHA-256 `bbb94f37fd58ea7ef2ad42247b9cd98d8c0313a44abcdcb2e505ee605d8a0e32`.

Installed local-copy cold-open, composition-card loading, scrolling device rows,
inline headline edit/card refresh, native Save/Undo and workspace fit were observed.
The edited snapshot retains original image resources and blob bytes; Undo/Save restores
the exact original document bytes. Both saved user projects and Rust executable retain
their recorded hashes. No user document, permission, signing policy or original asset
was changed. Work used one nice15 compiler job; no long trace or full export batch.
All three device rows and fitted canvas images finished loading; no loading/unavailable
indicator remained. The saved test app was quit afterward. Busy-session total completion
time, large-scene budgets, physical trackpad feel,
native drag acceptance and full Mac parity remain open.

Evidence: `verification/card-previews-20261031.json`, `CARD_PREVIEW_PLAN.md`,
`build/card-previews-20261031/` and focused/package/install logs dated20261031.
Pre-change source is retained in that folder's `source-before.tar`.

## Previous checkpoint: deferred canvas image previews — verified 2026-10-31

The prior installed G2-signed checkpoint was `build/package.MQ3MmO/VectorCraft Swift.app`,
executable SHA-256 `6da59ab88c2a2386dce6a1065d2b084717281fb714d21913bf0fa1c5a89c3ad1`.
Normal-session strict signature verification and the installed/package hash match
pass. Xcode27.2/27B52 is verified at `/Applications/Xcode-27.2.0.app`; the selected
SDK migration passed24 focused checks and the already-built full184-test suite
(109Core +71Mac +4CLI). Historical27B48 proof below retains its actual toolchain.

Canvas draw now queues deduplicated immutable visible-image requests. One utility
actor decodes them sequentially, validates the source before publishing, coalesces
queued viewport work, retains an existing image during zoom and cancels on teardown.
Loading/unavailable states are visible. Deferred proxies cap4096px; originals and
exports retain their full resolution. The128MiB cache budget is advisory; larger
working sets and extreme-zoom fidelity remain open.

One paired1024x768 bitmap sample of the preserved21-board Smartlist copy at3.92%
measured2222.6ms synchronous cold-cache draw versus114.3ms deferred first draw.
Sequential image completion took2013.4ms, then redraw156.0ms. All24 requested images
were stored, totaling968192decoded bytes, with no requests left and completed pixels
identical to the synchronous result. Text/metadata were warm; this is neither OS
disk-cold nor native UI timing, and the first draw precedes complete image loading.
The original-resolution PNG matches the earlier baseline byte-for-byte.

Installed cold-open, linked frames, fitted navigation, cached image at100% while a
new resolution loads, inline double-click text edit, Save and Undo/Save were observed
using a local copy only. The saved edited snapshot contains the new headline with
unchanged image resources/blob bytes; Undo/Save restores the exact source file hash.
Both saved user iCloud projects and the Rust executable retain their recorded hashes.
The app was quit immediately when the owner paused. A one-second sample confirms
ImageIO work on the utility worker, while small cards still decode original PNGs on
their other utility worker. Completion in that busy session was prolonged; no smooth
hardware or end-to-end loading-time claim follows. Card downsampling is the next
bounded increment. No long profiling capture, new permission or iPhone work.

Packaging uses one job at nice15. The extra Darwin background I/O policy was removed
after its launcher stalled in dyld; the retry completed. Evidence:
`verification/cold-previews-20261031.json`, `build/cold-previews-20261030/`,
`build/cold-preview-focused-final-27B52-20261030.log`,
`build/cold-preview-suite-27B52-20261030.log` and
`build/cold-preview-package-final-27B52-20261030.log`.

## Previous checkpoint: low-impact thumbnail scheduling — 2026-10-30

Installed `build/package.EZblNp/VectorCraft Swift.app` at the canonical Swift path.
Packaged and installed executable SHA-256 both equal:
`04d148fcae97791719c47b42a70160ee6d99007edfd0ffe80969cd6df5be770f`.
The approved G2 signature strictly verifies. The previous bundle is recoverable in
Trash; original Rust app/data and both saved Smartlist projects are unchanged.

Each editor now shares one actor renderer among its screenshot cards. Synchronous
raster work inside that actor cannot overlap another card's work from that editor;
card tasks use utility priority and retain cancellation before/after rendering.
There is no global renderer/cache or alternate export path. The package script now
runs compilation with `--jobs 1`, background task policy and nice15. One compiler at
nice15 was observed during verification; unrelated busy system processes were left alone.

Twelve focused tests pass (7 Core + 5 Mac) without compiler warnings in
`build/low-impact-focused-20261030.log`. Existing thumbnail pixel/clipping, resource
invalidation and native document/Undo checks exercise the production path. The new
canceled-work test proves cancellation wins before board lookup/raster work. The last
broad run remains the prior103 Core +68 Mac +4 CLI suite; it was not repeated here.

The installed app cold-opened a tiny two-board synthetic project. Blue/green portrait
cards appeared; rotating the first board updated its landscape thumbnail. Native Undo
restored both portrait cards, and Save restored the exact original file bytes. The
rotated and original snapshots are retained under `build/resume-20261030/`. The saved
test app was quit afterward; no compiler, profiler or export job remains from this run.
All21 native PNGs from the previous checkpoint match CLI output; that full export batch
was checked from existing files, not regenerated. No fresh profiling capture was made.
Scheduling alone is not a new measured latency/memory claim; cold decoding remains
tracked separately as `issue_01m65h65mtcnnhaexbc6qq8nv8`. Physical trackpad feel, native
drag acceptance and wider Illustrator parity remain open. No iPhone or publication.

Evidence: `build/resume-20261030/verification-report.json`, focused/package/install
logs and `LOW_IMPACT_WORK_PLAN.md`. Pre-change source is preserved in
`build/resume-20261030/source-before-thumbnail-scheduling.tar`.

## Previous increment: image previews, agent commands and resumed checkpoint — 2026-10-30

The prior installed G2-signed release was `build/package.kFG7wX/VectorCraft Swift.app`.
Its executable SHA-256, checked again on resume:
`368707103f854b828bba24767dfbe1b256ade3077c2911ec23a8f76505460578`.
Strict signature/Team Z5F6B8QVKJ passed before the pause. Xcode 27.2/27B48 was
reverified on resume. 103 Core + 68 Mac + 4 CLI tests passed in the final October 29
suite, `build/performance-agent-final-tests-20261029.log`, without compiler warnings.

Changes: canvas-owned ImageIO previews at viewport resolution with a 128 MiB advisory
NSCache budget, offscreen screenshot-board culling when artboard clipping is enabled,
document-derived preview warnings, and affected-only card refreshes. Exports retain
fresh validation and the uncached original-resource path. Embedded replacement/Undo,
linked-file replacement/hash checks, clipping and native warning refresh have focused
coverage. No new dependency or image conversion of the stored originals was needed.

The owner's Smartlist magazine reference was inspected read-only:
`SmartMagManager+Images.cachedImage(for:size:matching:)` uses ImageIO thumbnails,
CGImage-backed UIImages and NSCache. The Mac adaptation uses that underlying approach
with per-canvas ownership and preserves native pixel transforms; no Smartlist source
was changed. The frame library's already-approved folder scope now lasts with the
editor rather than ending after catalog loading. Cold reopen resolves all 21 linked
frames, including 20 CLI-authored paths without per-file bookmarks, without another
chooser or document rewrite. Resource restoration refreshes warnings and thumbnails.

Recorded production-Core bitmap samples use identical 1024x768 contexts and the same
21-board/42-image/184-nominal-megapixel local copy. The original baseline warm overview
median was about1094.5ms. An adjacent later baseline/update run measured1687.5→30.6ms
warm overview,268.7→29.5ms fitted and127.4→15.5ms actual size. Machine load varied;
these are repeatable-input measurements, not fixed frame-rate guarantees. Updated
first overview draw was839.9ms in that pair; an earlier updated cold run was slower.
Benchmark peak footprint rose161.4→185.9MB (about23MiB) for the retained preview images.
Three sampled original-resolution exports are byte-identical before/after.

Actual installed 40-second Time Profiler recordings cover opening the copy, iPhone
and Duo card selection, pan, Fit Workspace and Actual Size. Longest hang dropped
3.05→1.17s; both recordings contain six detected stalls. Initial image decoding and
native cold-start work remain material. The intermediate trace with unavailable
frame paths is retained but is not the accepted full-resource comparison. No physical
pinch/haptic claim follows from these automated actions. No new trace was recorded
on October30 while the user's Mac was busy.

The file-based CLI now exposes schema-versioned scene/slot geometry, object IDs,
text editability, requested/resolved fonts and resource status; stdin JSON, dry-run,
compact mutation responses and populated-only bulk export use canonical Core paths.
Four CLI tests and the production-binary Smartlist-copy workflow verify dry-run byte
identity, failed-batch atomicity, native edit/reopen, unknown/resource preservation,
original extracted image bytes and exactly21 populated PNG exports. Summary output
is146020bytes vs roughly1.31MB for the native JSON inspection in that fixture, without
image payloads or bookmark capabilities. See `AGENT_WORKFLOW.md`; live unsaved-GUI
control and the wider Rust command/MCP surface remain gaps.

Before the pause, native Export Used finished successfully after cold reopen. On
resume, all21 native PNG files were checked byte-for-byte against the CLI exports;
all match. Both saved Smartlist iCloud documents and the profiling copy still match
their recorded hashes. No user composition was changed. Original Rust executable
remains `b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.
Evidence: `verification/smartlist-performance-20261029-ymvj_0v_/`, specifically
`comparison.json`, `final-hangs-summary.txt`, `agent-cli-report.json` and
`resume-export-preservation-report.json`. The independently reviewed agent-operation
Module update was owner-approved, saved and exactly verified as VectorCraft Swift v3
with Mac apps as its sole direct Dependency.

The low-impact scheduling follow-up above is tracked in `LOW_IMPACT_WORK_PLAN.md`. Full Illustrator parity, cold-load budgets, drag/hardware feel and broader
SVG/gradient acceptance remain open. No iPhone, system-permission change, worktree,
commit, push or publication occurred.

## Previous increment: visual screenshot cards and placement — 2026-10-29

The installed G2-signed release is `build/package.B9N1DM/VectorCraft Swift.app`.
Packaged and installed executable SHA-256:
`eb0fc4dae9293852c32fdd296292e2a4c99e962c0a74f48e1df83a2955d4c235`.
Normal-session `codesign --verify --strict` passes (Team Z5F6B8QVKJ).

- 100 Core + 67 Mac tests pass in `build/screenshot-flow-verified-suite-20261029.log`.
  Focused red checks first exposed missing placement/move commands. Coverage includes
  sparse multi-file placement, occupied-slot skipping, capacity/invalid-data rollback,
  resource-preserving swaps, thumbnail bounds, clipping pixels, native Undo/Redo,
  scoped provider transfer, PNG file-provider bytes and cross-document refusal.
- Native inspector shows isolated composition thumbnails, ten numbered slots, selected
  state, selected controls first and disclosed crop fields. Resized-window and clipped
  screenshot previews were visually inspected. Clipping retains outside editable geometry.
- Native multi-file picker replaced slot3 and created slot4; one Undo restored the exact
  original JSON envelope. `04-multi-image-import` and `05-multi-image-undone` preserve proof.
- Final installed menu swap moved board6 from slot3 to1 and board1 from1 to3. Saved
  snapshots06/07/08 independently verify swap, exact Undo and exact Redo. Normal Quit,
  cold launch and native v4 reopen pass. Screenshots mode now follows async document load.
- Final native PNG Export Used produced only slots1/3; both are byte-identical to the
  prior slots1/8 exports. Original screenshot bytes, original three-row/five-board project
  and original Rust executable are unchanged. PNG was inspected. Earlier native SVG/PDF
  batch proof remains valid; those formats were not rerun for this UI increment.

Native drag limitation: an earlier build delivered slot8-to3 (`03-card-drag-moved`).
Later CUA card/Finder gestures did not consistently deliver drops, so final-build card
swaps and external file drops are not claimed as runtime proof. Native provider/file
loading and canvas acceptance/Undo are tested; menu/picker paths are installed proof.
A stack sample caught earlier mixed Transferable drags delaying Quit in
`NSFilePromiseProvider` (`build/screenshot-flow-drag-hang-20261029.sample.txt`). Card
sources now register only custom local data, with no file promise; normal Quit after
cancellation passes. Actual hands-on drag and physical trackpad feel remain open.

One verification shortcut arrived before the export chooser and ungrouped only the
working test copy. That snapshot09 was preserved, the exact saved Undo copy restored
while the app was quit, and native cold launch/export repeated with observed dialog
transitions. The final working copy matches snapshot05 exactly.

Evidence: `verification/screenshot-flow-20261029/native-flow-report.json`.
Backup: `build/screenshot-flow-preserve-20261029-40f50df2/`. Current issue
`issue_01m64crsxh1gx8s7bqaz7pv7xx` stays in progress for drag acceptance. Larger visual
template/frame selection, pose automation, localization depth, self-contained linked
SVG and wider Illustrator parity remain open. Mac first; no iPhone, permissions,
worktree, branch, commit, push or publication. No new durable Module change was needed.

## Previous increment: slots, viewport containment and crop layouts — 2026-10-29

That increment used `build/package.e2ikid/VectorCraft Swift.app`, installed at
`/Applications/VectorCraft Swift.app`. Its executable SHA-256 is
`c7b60d307cec4d8d3b805d7a1934263e955130a94a3ff24972240f981e97ce6d`.
The approved G2 signature strictly verifies in the normal login session, Team Z5F6B8QVKJ.
No signing, container, entitlement or system-permission changes were needed.

The owner clarified that quick top/bottom compositions crop a phone off one edge of
one screenshot. Picasso was inspected through a new blank local project; existing
Picasso projects, source and assets were untouched. Native screenshot rows now expose
ten numbered slots in the canvas and inspector. Empty slots create native artboards
only when activated; imports and ordinary artwork edits mark a slot used. Include in
Export also allows an explicit inclusion/exclusion choice. New iPhone Duo rows are one
family with per-slot inner/outer output dimensions and rotation; original device-frame
poses remain selectable separately through Device Frame. Legacy Duo preset IDs load.
Phone Off Top/Bottom apply to the selected screenshot and preserve image bytes and
uniform device aspect. Ordinary tools, native v4 storage and Undo remain canonical.

Canvas clipping is explicit in AppKit and the drawing context. The pre-fix installed
app visibly painted over the left tools/top chrome at 100%. The updated installed app
stays inside its viewport at 100%/125%, after panning and zooming. Zoom uses a 90 ms
screen-synchronized transition; pan deltas are unchanged. Physical pinch/haptic feel is
not measured by these automated interactions.

Verification: 96 Core + 62 Mac tests passed in the broad run. A final focused run passed
three canvas tests, including one additional empty-slot/Zoom test (63 Mac tests total).
The overflow and missing combined Duo regression checks first failed against the old
behavior. Tests cover sparse slots, limit/occupied-slot refusal, source preservation,
Duo dimensions/orientation, isolated export, command Undo/Redo and zoom cancellation.
The installed app activated slot8 on the canvas, imported the existing fictional PNG,
saved both edge-crop layouts, and restored exact native snapshots through Undo/Redo.
Adding/undoing a combined Duo row also restored the prior three-row document exactly.
Full quit/cold launch and native v4 reopen passed. Final canonical PID observed:89858.

Native Export Used produced exactly two files (slots1 and8) for EACH of PNG, PDF and
SVG, excluding the other28 slots across three rows. PNG sizes were2622x1206 and1206x2622;
PDF has one1206x2622-point page for slot8. PNG/PDF crop output was visually inspected.
The existing slot1 PNG remains byte-identical to its previous native export. Original
imported screenshot bytes remain SHA-256
`c7b80e7706cb91d7870fdcc2d14a08b86c14c025ca0db896f547520d6ee54ee7`.
The official Rust0.18 CLI reads the saved v4 file with six artboards and no warnings.
SVG retains external original-frame links, so its portability limit remains.

The user's original three-row/five-board document is byte-identical to the preserved
copy. Verification edits live only in `Verification/screenshot-slots-20261029/`.
Source/document backup: `build/screenshot-ux-preserve-20261029-a483abb4/`.
Report: `Verification/screenshot-slots-20261029/native-slots-report.json`.
Logs: `build/screenshot-slots-*-20261029.log`. Root Rust source/app and other dirty work
are preserved; no branch, worktree, commit, push or publication. Full Illustrator parity
remains incomplete; iPhone is deferred. Cortex issue:`issue_01m648x2dpgd73dg936ts6b1zf`.
The owner approved the independently reviewed Cortex screenshot requirements update;
it was saved and verified by an exact post-save Flash with Mac apps as sole Dependency.
The complete reviewed before/after is in `apple/CORTEX_SCREENSHOT_UX_PROPOSAL.md`.

---

# Swift Mac verification — 2026-10-12

Verified on this Apple silicon Mac with macOS 27.0.1 and Xcode 27.1 RC, build 27A9275.
Installed release: `/Applications/VectorCraft Swift.app`, version 0.1.0 (1).
No iPhone deployment, iCloud account provisioning, commit, push or publication occurred.

## Automated evidence

`swift test --package-path apple --scratch-path /private/tmp/vectorcraft-swift-build -c release`
passed **20 core tests and 3 native AppKit/document tests**, with no compiler warnings.
The selected `DEVELOPER_DIR` was pinned to the release candidate. The complete log is
`/private/tmp/vectorcraft-swift-release-tests.log`.

The focused checks cover native versions/legacy anchors, four real upstream example
trees and image payloads, unknown metadata retention, gzip/truncation, bounded and
invalid input, atomic failures and inherited locks, grouping/duplicate IDs/order,
curve handles and anchor deletion, point-text shaping/transform/export, refusal to
flatten unsupported text, moved gradient placement, stroke/fill/opacity pixels,
unsupported/bitmap-glyph export warnings, paragraph/small-caps preservation and export
blocking, and persisted native/PNG/SVG/PDF artifacts. The paragraph regression failed
before the warning fix: SVG export incorrectly succeeded with no preview warning.
Native tests deliver AppKit mouse events for drawing, movement, node editing and pen
handles, and exercise real UndoManager undo/redo.

The release bundle passed `codesign --verify --strict`; installed and packaged
executables share SHA-256
`f73bc127441878f1a29c9da42ede27391bc346a8a04e0b940ac10e15cb02547c`.
Its entitlements contain only App Sandbox and user-selected read/write file access.
Swift format lint, shell syntax, property-list lint and `git diff --check` passed.

The asset scan reproduced the current `xtask/src/assets.rs` extension/directory rules
against Git's tracked and nonignored untracked file list: **315 assets, none missing
an ASSETS.md entry**. All three copied Vectorify PNG hashes match their source files.
Cargo is unavailable here, so `cargo xtask assets`, full Rust CI, WASM and performance
budgets were not run. Rust implementation files were not changed.

## Installed application evidence

The native release was launched from its canonical installed path and inspected
visually through CUA. Checks used synthetic artwork only.

1. Opened the native document picker; iCloud Drive appeared as a system location.
2. Created a rectangle, dragged it, undid and redid movement, saved with the native
   dialog, closed and reopened the document. Added point text and saved it.
3. After installing the final release, reopened that document through the new native
   reader; both the moved rectangle and text were present.
4. Drew a three-anchor Bézier curve using two drag-created handle pairs and Return.
   Switched to Nodes, dragged its final anchor, then verified Undo restored dimensions
   from 416.02 × 135.79 to 377.5 × 69.02 and Redo restored the edited curve. Saved.
5. Exported SVG, PNG and PDF through all three native export dialogs. Files were
   written to `apple/verification/mac-release.{svg,png,pdf}`. PNG is 800 × 800; PDF has
   one page. The PNG was visually checked against the canvas.
6. Zoomed the window from 1100 × 720 to approximately 1470 × 923 points. The artboard
   fit changed from 64% to 91%; native toolbar, sidebar and scrollable inspector
   remained usable. The smaller window was also inspected.
7. After the final warning amendment and reinstall, opened a synthetic document with
   centered paragraph text and small caps. Limited Preview explicitly listed both
   limitations and Export was disabled. Added a layer and saved through the native
   document system; inspection confirmed the paragraph and character fields remained.
   Reopened the supported document and confirmed Export remained enabled.

The existing Rust 0.4.0 CLI read the final native file successfully: one layer,
two paths and one text object, with Helvetica resolved exactly and no missing glyphs.
It also imported the generated SVG and rendered `mac-release-svg-rust.png` with no
warnings. Visual inspection confirmed curve, text outlines and rectangle placement;
the SVG's transparent background differs intentionally from PNG's white artboard.
Earlier `swift-verification.vectorcraft` was independently rendered by that Rust CLI.

Local verification artifacts are gitignored under `apple/verification/`. Screenshots
of the native editor were inspected in the chat; no third-party artwork was used.

## Limits and preservation

This verifies the initial Mac editing and persistence path, not full Rust/Illustrator
parity. Unsupported source data can be retained without a faithful preview, and its
export is blocked. Font substitution and bitmap glyphs are disclosed. SVG/PDF import,
large-document performance, broader accessibility and cross-device iCloud sync remain
unverified or unimplemented, as described in README.md.

The original Rust app and upstream source are preserved. Previous Swift installations
were moved recoverably to Trash. No files were permanently removed. The Vectorify
source project was only read. Its icon's publication rights remain unresolved.
The administrator enable prompt was canceled; Xcode's headless MCP service stays
disabled. The reviewed Cortex Module proposal remains unsaved pending owner approval.

## Rust workspace appearance — 2026-10-13

The owner's follow-up requested the same workspace appearance as the Rust app,
implemented in Swift. Reference was the installed Rust 0.4.0 app and owning
`theme.rs`, `toolbar.rs`, `dock.rs`, `chrome.rs`, `canvas.rs` and icon sources.
Both apps displayed the same synthetic native document before the color-edit check.
The initial `plan/` source directory is absent in this checkout.

The installed release now uses the medium-dark source palette and existing licensed
Source Sans UI fonts, 65 attributed PDF vector glyphs, matching categorized tools,
application/document bars, Properties/Layers dock, panel rail, selection handles,
floating contextual bar and hint/status bars. Fonts register only in this process.
Missing tools/panels are disabled with accurate help, rather than claiming their
Rust engine behavior exists.

Final release tests passed **21 core tests and 3 native tests** without compiler
warnings. The new alignment check proves artboard/multiple-object alignment, group
preservation and atomic rejection of invalid inputs. Test and packaging logs:
`/private/tmp/vectorcraft-swift-workspace-tests.log` and
`/private/tmp/vectorcraft-swift-workspace-package.log`.

Final package: `apple/build/package.LTfyLM/VectorCraft Swift.app`. Its executable and
the canonical installed executable share SHA-256
`f9bdb76d1f77867e0eb1deb6955cf182f661f4af1241ba72135bb9a674a5da98`.
Strict codesign verification, Swift-format lint, shell syntax, plist lint and
`git diff --check` passed. Entitlements remain App Sandbox and user-selected read/write.
The asset check reproduced xtask's rules: **380 assets, none unattributed**. Packaged
Source Sans fonts and their license match the existing Rust source bytes. Cargo is
still unavailable; Rust CI/WASM/performance checks were not run, and Rust code did
not change.

Installed CUA checks:

- Compared selected and unselected artwork against Rust at approximately 1470 × 923
  points; both show 91.25% artboard fit. Checked native window zoom to about 1450 × 903
  and 88.75% fit. This is limited resize evidence, not a complete tiny-window audit.
- Activated command search with ⌘K, filtered `ellipse`, chose the tool, drew an
  ellipse and verified native document Undo removed it. Center alignment changed
  the existing rectangle's X from 523.27 to 400; undo from the canvas restored it.
- Switched Layers/Properties, changed the dock from 300 to 380 points through its
  accessible resize action and restored it. Checked single/double tool columns and Home.
- The first custom color-well activation did not provide a reliable full picker.
  The final control explicitly activates AppKit's shared color panel for mouse and
  accessibility presses. Entered `FF8000` in native RGB hex controls; the fill well,
  paint proxy, floating bar and artwork all updated. Saved the native document,
  closed it and relaunched the installed app; orange fill `1, 0.501961, 0` remained.
  A recoverable copy of its prior blue document remains under `apple/verification/`.
- Home's Letter preset created a separate native document with 612 × 792 dimensions.
  Clicked the Type tool and canvas, entered `Workspace test`, and saved through the
  native Save dialog to `workspace-letter-type.vectorcraft`. Byte inspection confirmed
  artboard dimensions and point text. Closed it and returned to the main saved drawing.
- File → Export → SVG wrote `workspace-match.svg` through the native export dialog.
  The original Rust CLI converted it to `workspace-match-rust.png` without warnings;
  visual inspection confirmed the curve, outlined text and orange rectangle.

Final local editor capture: `apple/verification/workspace-swift-installed.png`.

The system Open/Save/export/text/color interfaces and initial document picker retain
native macOS behavior. The editor styling is a close source-based match, not a claim
of pixel-perfect or full feature parity. Advanced features and cross-device sync
remain limited as above. The original Rust app is untouched, old Swift installations
are recoverable in Trash, and no iPhone work, Module write, commit or publication occurred.

## Inline text and draggable palettes — 2026-10-17

The owner reported that double-clicking text did not edit it and dragging the Type
tool opened a native popup. Both behaviors were reproduced in the prior installed
build using a synthetic document. The same follow-up requested draggable toolbars
and Illustrator parity in Swift as the product target. The latter remains an open
backlog in `ILLUSTRATOR_PARITY.md`, separate from these repaired interactions.

The final release passes **24 core and 6 native AppKit/document tests**, without
compiler warnings, using Xcode 27.1 RC build 27A9275 and the release configuration.
Logs: `/private/tmp/vectorcraft-inline-tests.log`,
`/private/tmp/vectorcraft-inline-format.log`, and
`/private/tmp/vectorcraft-inline-package.log`. The focused native regressions for
missing double-click editing and Type-drag failed against the original implementation
before the fix. New checks cover live text persistence and session undo/redo,
rectangular frame wrapping, overset/reflow without font scaling, native round-trip,
SVG/PDF export, and protection of unsupported/malformed frames and advanced options.
Native text input has its own local typing UndoManager; document undo coalesces each
editing session. Broader IME and multilingual input have not been manually audited.

Final package: `apple/build/package.kgxHAp/VectorCraft Swift.app`.
Packaged and canonical installed executables share SHA-256:
`44f0d784661a067cb9ca580da20dbefe6d9523a9ca19a14c30489feee6304376`.
Strict codesign verification, Swift format lint, shell syntax, plist lint and
`git diff --check` pass. Entitlements remain App Sandbox and user-selected file
read/write. The reproduced xtask asset scan reports **380 assets, none unattributed**.
No new assets or dependencies were added. Rust source did not change; Cargo, full
Rust CI, WASM and performance budgets were not run.

Installed CUA evidence, at approximately 1470 × 853 points:

1. Double-clicked existing point text and selected a word in an on-artboard
   `Edit Point Text` native text view. Replaced it, saved while the editor remained
   active, finished, and verified document Undo/Redo restored the old/new text.
2. Dragged the Type tool across the canvas. It opened a 330 × 180 on-artboard
   `Edit Area Text` frame without a sheet. Typed a paragraph and saved while active;
   visible lines wrapped, and the source retained the complete paragraph.
3. Reopened through the installed app after replacement. Both text objects survived.
   Selected the area frame and observed its red overflow marker. Changing height
   from 180 to 300 displayed the complete paragraph and removed the marker while
   the font remained Helvetica 32. Corner-resize event integration uses the same
   reflow command; this installed check exercised the numeric height control.
4. Double-clicked point text again, pasted two lines (`Native inline editing` and
   `Saved while typing`), and saved with the caret active. Used a detached Properties
   palette to change its size from 32 to 28. The document retained both edits.
5. Dragged the Tools grip to detach it, moved the floating palette, and docked it
   using its separate accessible Dock button. Detached Properties, used its font-size
   control, then Essentials → Reset Workspace restored docking. Repeated detachment
   in the final installed package and double-clicked area text with both palettes
   floating; the actual native text selection appeared on the artwork.
6. Exported SVG through File → Export. The preserved Rust 0.4.0 CLI read the saved
   native document as two text objects, with Helvetica resolved exactly and no
   missing glyphs. It rendered the SVG to `text-editing-svg-rust.png` without warnings;
   visual inspection confirmed the two-line point text and the complete wrapped area
   paragraph. SVG retains transparent background.
7. Quit, installed the final package, relaunched, and reopened
   `text-editing-20261017.vectorcraft`. The multiline text, font-size change and area
   dimensions persisted. Double-clicked the saved area paragraph and inspected its
   native caret/word selection alongside both floating palettes.

Artifacts are local and gitignored under `apple/verification/`:
`text-editing-20261017.vectorcraft`, `text-editing-20261017.svg`,
`text-editing-svg-rust.png`, and `inline-text-floating-palettes.png`.
The prior synthetic source document is preserved. The obsolete sheet source was
moved recoverably to Trash, as were replaced app installations. The Rust app and
Vectorify source remain preserved. No iPhone work, Xcode permission changes, commit,
push or publication occurred. The independently reviewed Cortex project proposal
remains unsaved pending the owner's answer to the explicit Module change request.

Limitations: only supported single-style point/rectangular area text is editable.
Rich ranges, paragraph options, arbitrary frames, text paths, threading and vertical
text remain open. Skewed/reflected inline editing is refused. Floating palettes stay
inside each document window; external palettes, grouped docking and saved custom
workspaces remain open. Narrow-window behavior and broad accessibility/performance
coverage need additional work. The October 13 text-dialog description above is
historical; this follow-up replaces that entry path with direct canvas editing.

## Grid snapping and native snap feedback — 2026-10-18

The owner explicitly started the full Illustrator-parity goal in Swift, Mac first.
This is its first increment, not completion of the full goal. The separately
approved VectorCraft Swift Cortex Module was created and flashed with exact content
and its sole direct Dependency, Mac apps; see `CORTEX_MODULE_PROPOSAL.md`.

Final Xcode 27.1 RC release and focused follow-up checks pass: **27 core + 12 native
tests**, no compiler warnings. The full release run passed 27 core/11 native; the
added multi-selection case and the other five snapping-native checks then passed in
`/private/tmp/vectorcraft-snap-multiselection-tests.log`. This proves a selection snaps
as one unit while retaining distances between its objects. New checks exercise the real canvas event path for live preview/commit,
off-grid starting geometry, Save/undo/redo, Control bypass at release, visible/hidden
and selected group targets, screen-scaled edge/center tolerance, drawing, anchors,
resizing and palette grid/docking. Existing text/document/rendering tests also pass.
Logs: `/private/tmp/vectorcraft-snap-final-tests.log`,
`/private/tmp/vectorcraft-snap-format.log`, and
`/private/tmp/vectorcraft-snap-final-package.log`.

Final package: `apple/build/package.l86zkp/VectorCraft Swift.app`. Packaged and
canonical installed executables share SHA-256:
`df16eb116195bfbcc774183b40e4be24254302ef3a69beb127b019e220f5425a`.
Strict codesign, Swift format, shell/plist lint and whitespace checks passed.
Entitlements remain only App Sandbox and user-selected file read/write. No new
assets or dependencies were added; the current asset check found 380 assets with no
missing attribution. Rust source, CI/WASM and Rust performance
budgets were not changed or rerun.

Installed synthetic CUA checks:

- Opened a fresh two-rectangle native file, enabled Snap to Grid and Grid separately
  in Essentials. Dragging the off-grid first rectangle from bounds origin 53,67
  placed it at 70,90 while retaining 100×80 dimensions (Properties center 120,130).
  Undo restored center 103,107; Redo and another grid drag produced center 190,140.
- Dragged near the second rectangle's left/top edges. The first rectangle aligned
  to bounds origin 200,200, center 250,240. It touches the second rectangle's left
  edge at x=300 and shares its y=200 top. Native saving retained the precise points.
  Transient guide presence/clearing during drag is covered by native event tests;
  the automation's drag call ends before an installed screenshot can capture them.
- Detached Tools at an 8-point workspace grid position, moved it again, and detached
  Properties. Inspected both floating palettes, then used their separate Dock buttons.
  The screenshot shows Tools at approximately 224,160 and Properties at 992,144
  window points, consistent with the grid. Exact state policy and bypass are tested.
- Exported SVG through the native dialog. The preserved Rust CLI rendered it to
  `snapping-svg-rust.png` without warnings. Visual inspection confirmed the aligned
  rectangles and preserved dimensions; the document grid is absent from artwork export.
- Quit, installed the final package (including mixed-visible-group target protection),
  relaunched, reopened the saved file and selected the first rectangle. Properties
  retained center 250,240, width 100 and height 80.

Local, gitignored artifacts: `apple/verification/snapping-20261018.vectorcraft`,
`snapping-20261018.svg`, `snapping-svg-rust.png`, and `snapping-floating-palettes.png`.
The prior open document was saved before replacement, and old installations remain
recoverable in Trash. The original Rust app and unrelated files remain preserved.

Haptic requests use the selected SDK's `NSAlignmentFeedbackFilter`, feeding actual
drag events and previous/default/aligned view positions and synchronizing accepted
feedback with drawing. The platform may suppress feedback based on hardware, touch
state or system preferences. Automated events cannot verify physical sensation.
Hands-on Force Touch/Magic Trackpad feel, complete pinch/pan/rotation gesture fidelity,
relative spacing/sizing guides, persistent document guides, saved workspace settings,
narrow-window accessibility and large-document snapping performance remain open.
Grid snapping and Smart Guides are independently switchable; freehand pencil stays
continuous. Control bypass is covered by actual native event tests, not a physical
modifier-drag check. The active full-parity goal remains in progress.

## Pathfinder and compound paths — 2026-10-18

Nine destructive commands now implement Unite, Minus Front, Intersect, Exclude,
Divide, Trim, Merge, Crop and Minus Back. Core Graphics normalization respects each
source fill rule and retains editable cubic geometry. Selected sibling paths or
compound paths are replaced at the frontmost selected stacking position. Output
paint ownership follows the operation; Trim/Merge/Crop remove strokes. Compound
Make/Release, explicit Nonzero/Even-Odd rules, constituent anchor editing and nested
empty-container cleanup use the same atomic document commands and Undo path.

Final release tests: **34 core + 14 native tests passed**, including all nine
parameterized geometry cases, expected region/paint ownership, curves, holes, locked
or empty atomic failure, foreign fields, legacy v1 DrawCraft coordinate format,
unsupported compound protection, native round trip, SVG/PDF output, actual canvas
anchor events and CanvasDocument undo/redo. The nested final-contour deletion test
failed before the fix with two assertions, then passed in the complete release run.
Logs: `/private/tmp/vectorcraft-pathfinder-nested-before.log`,
`/private/tmp/vectorcraft-pathfinder-final-tests.log` and
`/private/tmp/vectorcraft-pathfinder-final-package.log`.

Package: `apple/build/package.K43RVb/VectorCraft Swift.app`. Strict codesign passed;
packaged and canonical installed executables share SHA-256
`114a53d03714ea5643d182eb477df3f2f46c45bc38982b64f7f73d72c3992e92`.
No new assets, fonts or dependencies were added. The original Rust app/source and
prior Swift app (recoverable in Trash) remain preserved.

Installed synthetic CUA checks:

- The Pathfinder rail opens a real panel; all nine operations enable for two
  selected paths. Unite yielded one front-blue path with bounds 360×360. Undo
  restored the original two paths.
- Command search filtered to Minus Front and produced the red 240×240 L-shaped
  surviving region. Undo restored both operands. Object → Pathfinder → Divide
  created a group of three faces. Native saving retained one red and two blue
  faces, with each face's source `unknown.nativeProof` field preserved.
- ⌘8 made a compound with the backmost red appearance. Even-Odd in the panel
  produced a transparent overlap hole. Nodes dragged the inner constituent corner
  from 220,220 to approximately 239.83,230.22; native saving retained both children,
  their IDs and foreign data. ⌥⇧⌘8 released it to two paths; Undo restored the compound.
- Exported Divide and edited compound SVG through native dialogs. The preserved
  Rust CLI reads both native files (three paths in a group; two paths in a compound)
  and renders both SVGs without warnings. Visual inspection confirmed face paint,
  the edited contour and transparent hole.
- Quit the canonical app, relaunched and reopened the saved compound. The edited
  geometry, red appearance, 360×360 bounds and Even-Odd panel value remained.

Local gitignored artifacts: `apple/verification/pathfinder-20261018.vectorcraft`,
`pathfinder-divide-20261018.vectorcraft`, `pathfinder-{divide,compound}-20261018.svg`,
`pathfinder-{divide,compound}-rust.png`, and `pathfinder-installed.png`.

Boundaries: empty-area operations report an error without deleting source artwork.
Outline/Trap, live compound shapes, group/cross-container operands, advanced options
and larger geometry performance remain open. Unsupported non-path compound content
is retained, protected from editing and disclosed as Limited Preview with export
blocked. The installed check exposed an existing ⌘A conflict with the standard
disabled Select All item; menu selection and marquee still work. That keyboard
regression is the next focused fix. These results do not complete P09/P11 or the
full active Mac parity goal. Rust CI/WASM and Rust performance gates were not rerun.

## Native Select All routing — 2026-10-18

Installed Pathfinder verification exposed ⌘A doing nothing on the canvas. Edit had
a disabled standard `selectAll:` item followed by a duplicate custom command. The
canvas now implements the native responder action using the existing editable,
visible, unlocked top-level artwork policy. The duplicate command and its unused
focused callback were removed. NSTextView and inspector fields retain platform
selection behavior through their own responders.

The new canvas regression failed before the fix (unhandled selector and empty
selection); the inline text check already passed. Afterward both passed, as did all
**16 native tests in five suites** covering selection, text, snapping, Pathfinder,
canvas events and document undo. No compiler warnings remained in the final run.
The core was unchanged after the preceding 34-test pass. Logs:
`/private/tmp/vectorcraft-select-all-before.log`,
`/private/tmp/vectorcraft-select-all-final-tests.log`,
`/private/tmp/vectorcraft-select-all-native-tests.log`,
`/private/tmp/vectorcraft-select-all-format.log`, and
`/private/tmp/vectorcraft-select-all-package.log`.

Final package: `apple/build/package.PkXHuU/VectorCraft Swift.app`. Packaged and
canonical installed executables share SHA-256
`15d01ac0e9f348cdb6ec5e93fa84f34f51d44d321010e257a2204a4dec3d083e`.
Strict codesign, affected-file Swift format and whitespace checks passed. Entitlements
and assets are unchanged; the policy scan found 380 assets and no missing attribution.

Installed CUA checks in the dedicated synthetic `selection-20261018.vectorcraft`:
clicked artwork, pressed ⌘A and observed two selected paths. Edit showed one enabled
native Select All item. Created inline text, typed “Select all check”, pressed ⌘A
and observed that exact selected character range. Replaced it with “Native selection
works” and saved while typing. Finished editing and pressed ⌘A: all three artwork
objects selected. Focused the inspector Width field and pressed ⌘A: only its “370.75”
contents selected, while artwork selection remained unchanged. File inspection
confirmed two preserved paths/foreign fields and the replaced text. Quit, relaunched,
reopened the native file and verified text/geometry remained and ⌘A again selected
three objects. Screenshot: `apple/verification/selection-installed.png`.

This resolves the specific shortcut conflict recorded above. Full keyboard/VoiceOver
coverage and the rest of P04/P05/P34 remain open. Native serialization/export logic,
Rust, iPhone work and system permissions were unchanged. Full parity remains active.

## Transform modifiers and atomic copies — 2026-10-18

Shift-click now defers deselection until release, allowing a drag to retain the
selection. Shift-move projects onto the nearest horizontal/vertical/45-degree line;
grid and smart attraction remain on that line and draw only guides actually matched.
The shared transform command supports copying, allocating fresh IDs recursively and
inserting a transformed copy after each original. Duplicate uses the same path.
Command previews carry their resulting selection so copies, rather than originals,
receive the selection outline. Original document data remains unchanged until commit.

All eight drawn bounding-box handles now resize, including the previously inert
side handles. Shift preserves proportions, Option scales around the center, and
rectangular area text reflows at its existing font size. The Rotate tool supports
Shift 45-degree increments and Option copy. Preview and commit recompute release
location/modifiers; Escape cancels without allocating persistent IDs or undo entries.

Before implementation, five native regressions failed with 33 assertions/issues.
The final full release run passed **37 core + 23 native tests** with no compiler
warnings. Coverage includes all handles, constrained grid/smart guides, nested copy
IDs/metadata/paint/order, locked/invalid atomic failures, native round trip/SVG,
copy preview/selection/one-step Undo/Redo, release modifier changes, cancellation,
area-text reflow, plus existing document/text/Pathfinder/snapping tests. A focused
follow-up adds distinct 45-degree and 90-degree rotation cases. Logs:
`/private/tmp/vectorcraft-transform-before.log`,
`/private/tmp/vectorcraft-transform-final-tests.log`,
`/private/tmp/vectorcraft-transform-angles-tests.log`,
`/private/tmp/vectorcraft-transform-format.log`, and
`/private/tmp/vectorcraft-transform-package.log`.

Package: `apple/build/package.ld0OYr/VectorCraft Swift.app`. Packaged and canonical
installed executable SHA-256:
`015308ea9e99fbcfdee9979a33214671e76cfb75d40deb5ab2d2a04714b32d09`.
Strict Swift-bundle signature, formatting, shell/plist and whitespace checks passed.
No new assets, dependencies, permissions or Rust source changes were introduced.

Installed CUA checks used `transforms-20261018.vectorcraft`, a fresh synthetic
100×80 rectangle at bounds origin 53,67. Dragged its right-side handle rightward
while also moving the pointer vertically: width became 160, while height stayed 80
and y stayed 67 (Properties center 133,107). One Undo restored 100×80; Redo restored
160×80. Shift-click toggled selection off/on. Duplicate invoked the shared copy
command: original ID 2 stayed at 53,67; new ID 6 appeared at 73,87, both 160×80,
retaining `unknown.modifierProof` and `unknown.nativeProof`. One Undo removed the
copy, Redo restored it, and Select All showed two objects. Native Save retained the
geometry and foreign fields. Quit, relaunched the canonical app, reopened the file,
and confirmed two objects with combined center 143,117 and bounds 180×100.

Native SVG export was read/rendered by the preserved Rust CLI without warnings;
visual inspection confirmed the two rectangles. Local artifacts:
`apple/verification/transforms-20261018.{vectorcraft,svg}`,
`transforms-svg-rust.png` and `transforms-installed.png`.

CUA cannot hold a modifier across its separate drag operation. Attempts to do so
produced ordinary moves, which were undone before the recorded resize/copy workflow.
Exact Shift/Option drag paths are verified with actual AppKit events in native tests;
physical modifier/trackpad gestures and haptic sensation remain unverified. This
increment does not complete P04/P05: rotation-aware boxes, custom origins, cursor
and stationary modifier feedback, Transform Again/Each, reflect/shear, distribution
and group/isolation selection depth remain open. Rust CI/WASM/performance were not run.

Separate read-only finding: strict signature verification of the untouched original
`/Applications/VectorCraft.app` reports “code has no resources but signature indicates
they must be present.” Its CLI still reads native data and renders SVG successfully.
The original bundle was not altered or re-signed; this is separate from the passing
Swift bundle signature and does not block further Swift implementation.

## Whole-group selection and nested isolation — 2026-10-18

Selection clicks, marquees and Select All now target whole groups; Nodes retains
leaf/anchor access. Double-click, Object and Layers commands enter group/layer
isolation. The editor owns a nested scope stack with parent/Document breadcrumbs,
Exit Isolation and canvas Escape. Hit tests, selection, snapping, Layers and insertion
use that scope, and the document command boundary rejects outside targets atomically.
Outside artwork dims once per branch without changing native data or export opacity.
Deleted, moved, hidden or locked scopes reconcile after document changes and Undo.

Before implementation, native group click/drag and marquee checks failed three
assertions; direct constituent anchor editing already passed. A further native
coalesced-drag case found marquee release-position recomputation missing, now fixed.
The final full release run passed **40 core + 29 native tests** without compiler
warnings. Coverage includes group/direct targets, scope/visibility/locks, scoped snap
targets and insertion, outside-command atomicity/no Undo registration, inline text,
nested exits, invalid scope reconciliation, one-step Undo/Redo, native round trip,
SVG/PDF output and pixel-level isolation presentation versus normal rendering.

Logs: `/private/tmp/vectorcraft-group-before.log`,
`/private/tmp/vectorcraft-isolation-tests.log`,
`/private/tmp/vectorcraft-isolation-final-tests.log`,
`/private/tmp/vectorcraft-isolation-format.log`, and
`/private/tmp/vectorcraft-isolation-package.log`. The intermediate pixel test used
the wrong bitmap y direction; after correcting the test coordinate setup, the final
pixel assertions pass and prove an outside group is faded once, not per descendant.

Package: `apple/build/package.ATXE9k/VectorCraft Swift.app`. Packaged and canonical
installed executables share SHA-256
`21d8488f759702dd259876a10c12827c14e9af5d6cd45a99b0bdd603815ec7fd`.
Strict codesign, strict source/test Swift formatting, shell/plist and whitespace
checks passed. The attribution scan found 380 assets with zero missing records;
no new assets, dependencies, permissions or Rust source changes were introduced.

Installed CUA verification used `group-isolation-20261018.vectorcraft`, a synthetic
Outer Group containing Inner Pair (red/blue paths) and a green path, with an orange
path outside. Clicking red selected Outer Group (280×260). Dragging it moved all
three members by the same displacement, preserved the orange path and foreign
fields, and one Undo restored their original coordinates. Double-clicking twice
entered Outer Group then Inner Pair, with the green/orange paths visibly dimmed.
An outside click did not select orange; ⌘A selected only the two inner members.

Created a rectangle in Inner Pair, undid it, redid it and saved. Created inline text
“Inside group text” and saved while typing. Native inspection confirms both new
objects (IDs 14/15) are children of Inner Pair (ID 10); the original red/blue/green/
orange coordinates, IDs and unknown fields remain intact, including both group
metadata fields. The scoped Layers tree shows only Inner Pair and its four children;
New Layer and Drawing Layer are disabled. Parent breadcrumb then Escape returned
through the levels. Selected Layer 1 and used Object → Enter Isolation; ⌘A selected
its two direct selectable objects (Outer Group and orange), with layer creation
disabled in that scope.

Exported SVG while Inner Pair isolation was active. It retains all artwork at normal
opacity, including green and orange outside the scope. The preserved Rust CLI reads
the native file as two groups, one layer, five paths and one text object, and renders
the SVG without warnings. Visual inspection confirms full-color shapes and text.
Quit was confirmed through the app inventory, then the canonical app was relaunched
and the file reopened: all content/colors remained, with no persisted isolation.

Local gitignored artifacts: `apple/verification/group-isolation-20261018.{vectorcraft,svg}`,
`group-isolation-svg-rust.png`, `group-isolation-nested.png`,
`group-isolation-layers.png`, and `group-isolation-reopened.png`.

Single-object isolation, repeated Group Selection hierarchy clicks, lasso,
multi-anchor/segment selection, clipping-selection depth, broad keyboard/VoiceOver
coverage and large-document performance remain open. Physical modifier/trackpad
gestures and haptic sensation remain unverified. Rust CI/WASM/performance were not
rerun. This closes the bounded increment, not P04/P11 or the active full-parity goal.

## Transform Again — 2026-10-18

CanvasDocument now remembers the last successful affine transform and its copy flag.
Object → Transform → Transform Again, ⌘D and command search apply it to the current
editable selection through the existing atomic command/Undo path. Duplicate remains
available without the conflicting shortcut. Style/selection changes retain history;
failed or identity transforms do not replace it. Applying/opening a snapshot resets
history. Rectangular text-frame reflow clears affine memory, since repeating a stale
move or scaling its glyphs would not repeat frame reflow correctly.

Five new document tests and an extended real AppKit Option-drag test cover repeated
move/copy, fresh copy IDs/paint/foreign fields, current-selection targeting,
scale/rotation replacement, failed/no-op retention, isolation rejection and native
Undo/Redo, snapshot reset and frame-reflow clearing. All **34 native release tests in
eight suites passed** without warnings. The Core source is unchanged from the
preceding **40-test release pass** above. An initial fixture tried to group one object,
which the existing command correctly rejects; the corrected two-object group passed.
Logs: `/private/tmp/vectorcraft-transform-again-tests.log`,
`/private/tmp/vectorcraft-transform-again-native-tests.log`,
`/private/tmp/vectorcraft-transform-again-format.log`, and
`/private/tmp/vectorcraft-transform-again-package.log`.

Package: `apple/build/package.UL1Vjm/VectorCraft Swift.app`. Packaged and canonical
installed executables share SHA-256
`e8613282b061f593fd8ae9b201b4f8597c4d11cb0a1c5c04cf6587904464e347`.
Strict codesign, strict source/test formatting, plist/shell and whitespace checks
passed. The app was confirmed stopped before replacement; the prior Swift bundle
remains recoverable in Trash. No assets, dependencies, permissions or Core/Rust code
changed during this increment.

Installed CUA checks used `transform-again-20261018.vectorcraft`, initially one
100×80 rectangle at 60,80. Shift-Right moved it 10 points; two ⌘D repeats moved it to
90,80 without duplication. One Undo restored x=80; Redo restored x=90. Command search
filtered to Transform Again and moved it to 100,80. Numeric Width=200 scaled it about
its left edge; ⌘D repeated the 2× horizontal scale to width=400, height=80 and center
300,120. Object → Transform exposes an enabled Transform Again command.

Created inline text “Repeat shortcut check” and saved while typing. Transform Again
was visibly disabled in Object → Transform during that text session. Finished text,
exported SVG, quit (confirmed in app inventory), relaunched the canonical app and
reopened the file. The 400×80 rectangle and text remained. With the rectangle selected,
Transform Again was disabled because repeat history is transient. Native inspection
confirms one rectangle with original ID 2 and `unknown.repeatProof`, final anchors
100,80 through 500,160, plus the inline text. The preserved Rust CLI reads one path,
one text object and one layer, and renders the exported SVG without warnings; visual
inspection confirms the rectangle and text.

Local gitignored artifacts: `apple/verification/transform-again-20261018.{vectorcraft,svg}`,
`transform-again-svg-rust.png`, and `transform-again-reopened.png`.
Copy repetition is covered by native events; installed modifier-drag hardware feel
remains unverified because CUA does not hold modifiers across drag. Transform Each,
reflect/shear, frame-reflow repetition, rotation-aware boxes/origins, distribution
and other P05 gaps remain open. This is another bounded increment of the active
full Mac parity goal; iPhone, publication and Rust CI/WASM/performance remain deferred.

## Transform Each, Reflect and Shear — 2026-10-18

The shared command supports per-root percentage scale, movement, counterclockwise
rotation, X/Y reflection, nine-point references and seeded randomness. Selected
groups remain units; parent/child selections transform once. Numeric Reflect and
Shear dialogs use combined selection references and horizontal/vertical/custom axes.
The matching workspace forms provide Preview, Cancel, Copy and OK. Preview runs the
same atomic command on a transient drawing; commit checks for a stale source before
entering CanvasDocument. Transform Again retains individual parameters or affine
matrices with copy intent. Stroke weights remain unchanged.

Full release tests passed **45 core + 38 native tests**, with no compiler warnings.
Coverage includes all nine references, separate centers, direction/custom axes,
seeded random repeatability, nested copies/foreign metadata, v1 DrawCraft and v3
round trips, SVG/PDF, invalid/locked/scoped atomicity, native Undo/Redo, preview/cancel/
copy, individual repeat on a different object, stale snapshot rejection and protected
reflected-text editing. A focused follow-up adds Transform Each to the valid-group
outside-command policy checks; all three scope tests pass. The first compile caught
a missing MainActor annotation on the new test fixture. An initial text assertion
tested Core formatting eligibility rather than the canvas transform guard; the final
test exercises the actual canvas refusal and confirms the text remains unchanged.

Logs: `/private/tmp/vectorcraft-individual-focused.log`,
`/private/tmp/vectorcraft-individual-focused-fixed.log`,
`/private/tmp/vectorcraft-individual-final-tests.log`,
`/private/tmp/vectorcraft-individual-scope-tests.log`,
`/private/tmp/vectorcraft-individual-final-format.log`, and
`/private/tmp/vectorcraft-individual-package.log`.
Package: `apple/build/package.y6D1Ut/VectorCraft Swift.app`. Packaged and canonical
installed executables match SHA-256
`e97104aa469f5e10d56cfdbd8acb0eb2524ca9ae807f54d90d8506f66faf98ec`.
Strict codesign, strict source/test formatting, shell/plist and whitespace checks pass.
The app was confirmed stopped before install, with the prior Swift bundle retained
recoverably in Trash. No new assets/dependencies, system permissions or Rust edits.

Installed CUA checks used a synthetic red L at 80,80 (60×80) and blue rectangle at
260,80 (100×100). ⌥⇧⌘D opened Transform Each for both. Entered 50% horizontal/vertical
scale and a 20,30 offset, then canceled: original canvas/file/ID counter remained,
and Transform Again stayed disabled. Command search successfully dismissed its sheet
and opened Transform Each. The same settings with Copy produced ID 14 at 115,130
(30×40) and ID 15 at 305,135 (50×50), with originals intact. ⌘D repeated individual
copies to ID 16 at 142.5,170 (15×20) and ID 17 at 337.5,177.5 (25×25). Undo/Redo and
native Save retained the six paths and each source's foreign metadata.

Object → Transform → Reflect opened the numeric form. Chose Left reference and Copy
with the vertical axis: new ID 18 mirrors the L to bounds 20,80 (60×80), preserving
ID 2. Search opened Shear for that copy. A 90° shear displayed a finite-result error
and disabled Copy/OK. A 45° custom-axis trial committed to 55×150 bounds and was undone.
A fresh horizontal 45° shear committed, then survived Undo/Redo and Save at bounds
10,80 (110×80), center 65,120. Native inspection confirms all seven exact bounds,
original IDs/coordinates and foreign fields. The preserved Rust CLI reads one layer
and seven paths, and renders the native-dialog SVG export without warnings. Visual
inspection confirms the final geometry. Quit was confirmed through app inventory;
relaunch/reopen preserved the art, and native Select All selected seven objects.

Local gitignored artifacts: `apple/verification/individual-transforms-20261018.{vectorcraft,svg}`,
`individual-transforms-svg-rust.png`, `individual-transforms-installed.jpg` and
`individual-transforms-reopened.jpg`.

Preview command/state, nonmutation and cancellation are proven in native tests, and
the installed restored/committed canvas states were inspected. CUA's screenshot of
an open sheet captures the sheet itself, so the live canvas behind the open dialog
was not directly captured. No claim of physical modifier/trackpad or haptic feel is
made. Absolute scaling, stroke/effect/corner/pattern options, canvas Reflect/Shear
tools/arbitrary origins, rotation-aware boxes, frame-reflow repeat, distribution,
large-document performance and broad keyboard/VoiceOver remain open. Rust CI/WASM,
iPhone and cross-device checks were not run. Full Mac parity remains active.

## 2026-10-18 — native artwork clipboard and paste placement

The current installed release is `apple/build/package.TIasg1/VectorCraft Swift.app`,
installed at `/Applications/VectorCraft Swift.app`. Both executables share SHA-256
`d6f5a64cc4bd758db6740c55f978527474dc6cf6c91cbea662ce61a94f8d6e4c`; strict signature verification passed. Prior Swift installs were preserved
in Trash. All **54 core and 43 native release tests** pass without compiler warnings.
Logs: `/private/tmp/vectorcraft-clipboard-final-tests.log`,
`/private/tmp/vectorcraft-clipboard-focused-final.log`,
`/private/tmp/vectorcraft-clipboard-final-package.log` and
`/private/tmp/vectorcraft-clipboard-final-format.log`. Strict Swift format, shell/plist
checks and `git diff --check` passed. No new assets or dependencies were introduced.

Core coverage proves selected-root/compound policy, paint order, one transform per
root, fresh IDs including resource art/masks, reference closure/cycles, name/ID conflicts,
foreign metadata, legacy anchors and area frames, numeric/resource/scope rejection,
bounded decoding and native/export round trips. The exact-node preservation check
failed before reference traversal stopped adding null fields; its failing log is
`/private/tmp/vectorcraft-clipboard-preservation-red.log`. Native tests use independent
pasteboards and verify responder actions, clipboard replacement, one-step document
Undo/Redo, failed Cut preservation, isolation and text/inspector focus. A direct
NSTextView pasteboard-writing assertion was removed because it tested framework
behavior; character Copy/Paste was then verified in the installed text editor.

Installed native workflow proof:
- Copy a group in `clipboard-source-20261018.vectorcraft`; open a separate destination
  and use ⌘V. The group is centered at the actual viewport center (400,400), 280×100.
- Undo removes the whole pasted group; Redo restores it. ⇧⌘V keeps source bounds
  (80,80)–(360,180). ⌘F/⌘B produce the saved sibling order `[2,3,6,12,9]`.
- ⌘X removes the selected group and Undo restores it. Character ⌘A/⌘C/⌘V in inline
  text produces `Clipboard textClipboard text`; finishing and pasting on canvas
  creates a separate editable `Clipboard text` object. Inspector field Copy/Paste
  retains its numeric value. Special artwork paste commands disable in both text
  and inspector focus after the focus-state fix.
- Copy a group, quit and relaunch the app, reopen and Paste in Place. Fresh group
  17 and children 18/19 retain source object metadata. Native Save, another relaunch,
  reopen and Select All show eight roots. Destination metadata remains intact;
  no unselected source document metadata travels with the fragment.
- Export through File → Export SVG. The untouched installed Rust CLI opens and
  renders both the saved native document and its SVG without warnings. Both PNGs
  were visually inspected for shapes, text and stacking; this is interoperability
  evidence, not a claim of pixel-identical renderers.

Artifacts under ignored `apple/verification/`: `clipboard-source-20261018.vectorcraft`,
`clipboard-destination-20261018.vectorcraft`, `clipboard-destination-20261018.svg`,
`clipboard-installed-reopened.jpg`, `clipboard-final-reopened.jpg`,
`clipboard-native-rust.png` and `clipboard-svg-rust.png`.

Remaining P29/P27 gaps: external SVG/PDF/image input, all-artboards paste, Remember
Layers, anchor-only copying, complex live kinds, threaded text, conflict-choice UI,
linked-art depth and cross-profile conversion. Referenced missing definitions (including
unmaterialized default brushes) fail explicitly. Unsupported native art can retain
its data with zero-offset placement; unsupported repositioning is rejected atomically.
Cold-open artboard fitting was independently inconsistent (91.25% versus 92.17% for
612×792); it is tracked separately under P02 and does not change clipboard coordinates.
Physical trackpad/haptic feel, broad VoiceOver, larger clipboard performance, Rust CI
and WASM were not run in this Swift-only increment. Full Mac parity remains active.

## 2026-10-18 — loaded-artboard fitting and queued native Save

Final package: `apple/build/package.BqT0UB/VectorCraft Swift.app`, installed at the
canonical `/Applications/VectorCraft Swift.app`. Packaged/installed executable SHA-256:
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`.
Strict signature verification and strict formatting of affected sources/tests pass.
All **47 native release tests in 12 suites** pass without compiler warnings:
`/private/tmp/vectorcraft-native-file-final-tests.log`. Core is unchanged from the
preceding 54-test release pass. Packaging and format logs:
`/private/tmp/vectorcraft-save-final-package.log`,
`/private/tmp/vectorcraft-save-final-format.log`.

The two navigation regressions cover the asynchronous default→loaded geometry update,
Fit-mode geometry/window resize, actual-size preservation, translated second boards
and independent views. Their initial run failed four assertions in
`/private/tmp/vectorcraft-canvas-fit-red.log`. The native Save tests cover a pending
real NSDocument activity while the main actor stays runnable, ordered Save/Save As
requests and callback completion lifetimes. The initial gate regression failed in
`/private/tmp/vectorcraft-native-save-red.log`; the Save operation boundary is injected
to avoid presenting system panels in unit tests.

Installed QA originally froze during rapid Copy/Paste/Save. The main-thread sample
`/private/tmp/vectorcraft-fit-sample.txt` shows NSDocument waiting on its serialization
semaphore. A responder prototype was bypassed by the built-in Save action; it was
removed. The real `saveItem` command group now schedules native activity asynchronously,
enters its continuation and retains the completion delegate through Save or Cancel.
A command-construction prototype crashed by initializing NSDocumentController before
SwiftUI. The final implementation connects it after launch and passes cold launch.
These observations establish the reproduced command fix, not universal autosave safety.

CUA checks used only synthetic local documents:

- Open 612×792 at **92.17%**, with ordinary Paste centered at **306,396**; open a
  second 1200×300 document at **82.83%**, with Paste centered at **600,150**.
- Set the wide document to Actual Size, resize width to 1000 and save: zoom stays
  **100%** and disk geometry is 1000×300. Undo restores width 1200; explicit Fit
  restores **82.83%**. The separately opened portrait retains its own fitting.
- Rapid Copy/Paste/Save, repeated Paste/Save and Undo/Redo/Save remain responsive.
  Inspector X=310 saves. The portrait source and separate Save As copy each contain
  **60 roots**, next ID 62 and `unknown.fitProof=retained`; the wide file contains
  two roots and preserves that foreign field.
- Cancel Save As, retry and save a new native copy without replacing the source.
  Create untitled inline text, invoke Save, Cancel, retry and save; continue typing
  and Save while the inline editor remains active. After final-bundle relaunch,
  reopening and Edit Text shows exactly **Native Save cancel and retry — saved while typing**.
- Final-bundle rapid Paste/Save/Undo/Save and File → Save both execute the queued
  native path. Runtime log pairs for the installed process appear in
  `/private/tmp/vectorcraft-save-final-installed-runtime.log`.
- Open Recent initially exposed stale KVO-only state. Refresh on native main-window
  changes fixes it: both opened files appear, and selecting the closed inline file
  reopens it. Clear Menu was not used. Close, Close All, Duplicate, Rename, Move and
  native Revert/version entries remain present; destructive version workflows were
  not exercised. Share is disabled when the controller provides no available action.
- Relaunch the final bundle, reopen the portrait, export SVG, and load/render both
  the native file and SVG through the original Rust CLI. Both renders succeed with
  no warnings; inspected PNGs show the same eight occupied red-path positions.

Ignored artifacts: `canvas-fit-20261018.vectorcraft`,
`canvas-fit-wide-20261018.vectorcraft`, `canvas-fit-wide-installed.jpg`,
`native-save-final-20261018.vectorcraft`, `native-save-inline-20261018.vectorcraft`,
`native-save-final-20261018.svg`, `native-save-final-reopened.jpg`,
`native-save-final-rust.png`, `native-save-svg-rust.png` under `apple/verification/`.
One accidentally misnamed synthetic Save As copy and all replaced Swift bundles were
moved recoverably to Trash. The Rust app/source and user files remain preserved.

P02/P33/P35 remain partial: native sharing, broader version/recovery/conflict/cloud
stress, physical trackpad/haptic feel, VoiceOver and large-document budgets remain
open. No iPhone work, system-access expansion, source commit/push or publication
occurred. The full Mac Illustrator-parity goal remains active; SVG/external clipboard
import is next.

## 2026-10-19 — SVG import build ready; signing awaits Keychain approval

All **64 core + 51 native release tests** pass without compiler warnings, using
Xcode 27.1 RC and `apple/build/swiftpm`. Log:
`apple/build/svg-release-green-20261019.log`. The earlier run caught the extreme-arc
fixture's native geometry limit; the corrected test also verifies nearly full arcs
at tiny endpoint separations. Import tests cover path grammar, physical units,
viewBox/transform geometry, CSS/currentColor/visibility, gradient/opacity pixels,
outlined nonuniform strokes, local references, editable text, native persistence,
DTD/entity rejection, unsupported input, geometry/expansion limits, SVG-only/XML
clipboard placement/isolation/atomic Undo, and coordinated source-preserving reads.
SVG export now declares point units to preserve native physical dimensions on reimport.

The production build succeeded in 294.28 seconds without warnings. Packaging is
running at `apple/build/package.iAG6Lj/VectorCraft Swift.app`; log:
`apple/build/package-g2-20261019.log`. Signing is waiting on macOS SecurityAgent for
a Keychain authorization. The owner was asked to handle that prompt because the
computer-use tool prohibits access to SecurityAgent. Keep the running signing
operation (exec session 73959); do not restart it or fall back to ad hoc signing.
No installation or post-transition runtime proof has occurred yet.

The requested identity was verified in the normal login Keychain:
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Developer ID Application: Bizit LLC (Apps),
Team `Z5F6B8QVKJ`, issuer Developer ID Certification Authority G2, valid October 19,
2026 through November 18, 2027. The script pins that exact identity, hardened runtime
and a secure timestamp. Bundle ID remains `com.swiftdev.vectorcraft.mac`; entitlements
remain only App Sandbox and user-selected file read/write. No embedded profile,
iCloud/Keychain restricted capability, global signing workflow or Rust packaging was changed.

Before transition, the existing ad-hoc canonical app opened
`verification/native-save-inline-20261018.vectorcraft`; screenshot:
`verification/signing-before-native-20261019.jpg`. The app was then quit normally.
That native source's SHA-256 is
`55f0d1b2f0b1535b4c73b02fcfefd8ae31bd47648eec661366fbc57ec12f3fd5`.
The synthetic import source's SHA-256 is
`6fbe0466aa9fb18bc82ccfb0e090539db02f07a6ac045eee98bb1c777f0735fd`;
`verification/svg-import-rust-reference-20261019.png` renders it through the original
Rust CLI without warnings. Original Rust executable SHA-256 remains
`b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.

Remaining before closing the SVG/signing issues: finish signing, inspect the embedded
certificate fingerprint/Team/runtime/timestamp and unchanged entitlements, install
with recoverable backup, cold launch, open an existing native file, import and edit
SVG, reject unsupported SVG without changing the document, test installed XML Paste
and Undo/Redo, native Save/relaunch/reopen, and compare exports with the Rust CLI.
Full SVG/CSS, Illustrator parity and physical trackpad/haptic verification remain open.
No notarization, publication, iPhone work, Git writes or permission expansion occurred.

## 2026-10-19 — Xcode 27.2 SVG/gradient source verified; interactive signing required

The owner replaced the toolchain instructions during this work. The exact path
`/Applications/Xcode-beta.app` reports **Xcode 27.2, build 27B5038j**. Packaging pins
that path and rejects a different version/build. No global Xcode selection, MCP
service access, profile or personal skill library was changed.

Current source passes **73 core + 55 native release tests**, without app compiler
warnings. The complete suite is in `build/gradient-complete-27B5038j-20261019.log`;
the subsequent stronger stop-crossing/Delete native check and all 55 native tests
pass in `build/gradient-native-complete-27B5038j-20261019.log`. Strict formatting,
shell syntax and tracked-diff whitespace checks pass. The production package compiles
successfully in `build/gradient-package-g2-27B5038j-20261019.log` (28.93 seconds).

Gradient authoring uses targeted commands for linear/radial fill/stroke paint,
stop insertion/deletion/color/position/opacity, reverse, angle/aspect and canvas
endpoints. Other appearance items, stroke settings and foreign fields are retained.
Native events verify nonpersistent previews, Shift-constrained placement, endpoint
and new-origin grid snapping, Escape, sorted stop crossing with selection/Delete,
and Undo/Redo. The new-origin grid test failed at `(103,107)` before the fix, then
passed at `(100,110)`. Linked/advanced paints and unsupported text are refused.
Existing SVG import, native documents, clipboard, isolation, text and Save tests
remain green under the new SDK. Physical haptic feel is still unverified.

Review found that native `GradientGeom` requires both endpoints, and native stops
must remain ordered. Kind/aspect operations now materialize complete geometry;
insert/move/reverse return the selected stop's new index while preserving native
ordering. Focused contract and real AppKit regressions cover these failure modes.
The earlier unsorted colored-alpha fixture rendered flat in the Rust CLI; after
the fix, its middle row contains 100 distinct colors. This is behavioral evidence,
not merely successful deserialization.

`verification/gradient-20261019/` contains native v1/v3, SVG, PNG and alpha fixtures.
Both native versions and SVG open/render in the original Rust CLI without warnings.
The two opaque radial fixtures visually agree; after compositing Rust's transparent
background on white, mean channel difference is 0.354/255 for native input and
0.396/255 for SVG input (maximum edge-channel difference 15). Swift PNG currently
uses a white background; wider PNG background/options remain a P28 gap.

**Transparency qualification:** ordered variable-opacity stops still differ from
the preserved Rust raster reference: mean red/blue difference about 6.1–6.4/255,
maximum 11, for the three-stop colored fixture. The fixture's insertion preserves
the Swift raster within one channel value. SVG 2 explicitly specifies unpremultiplied
SVG stop-color interpolation:
https://www.w3.org/TR/SVG2/pservers.html#StopColorProperty . The Swift renderer was
not changed to imitate the reference discrepancy. A separate in-app-browser capture
shows the gradient but is not used as a calibrated numeric color oracle; its capture
RGB/color pipeline differs. Keep this cross-renderer qualification open in P13 rather
than claiming universal gradient fidelity. The raw comparison is saved in
`verification/gradient-20261019/gradient-alpha-comparison.json`. The temporary hidden
browser tab and loopback-only server were closed after inspection.

Current staged bundle: `build/package.PuivVG/VectorCraft Swift.app`. Pre-signing
executable SHA-256:
`3dd7265429d43b02c2b2457aed95c867b954fef8f91838503c63ab1bc5c93c13`.
The exact owner-approved G2 identity remains valid/available:
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Team `Z5F6B8QVKJ`.
Local code-signing trust-chain verification succeeds. A read-only normal-session
Security-framework probe returns status 0 and unlocked/readable/writable true for
the login Keychain. Its legacy API deprecation warnings belong to the scratch
probe, not the app build. No secret was accessed/exported or Keychain setting changed.

Background signing still fails with `errSecInternalComponent`. Signing handles
73959, 3692 and 61787 are all terminal; do not poll them as live. The initial RC
snapshot's 248-second internal signing-time/TSA discrepancy was followed by failed
retries, not a verified current release signature. The computer-use tool explicitly
blocks both SecurityAgent and Terminal. A read-only diagnostic approval review
initially timed out; its bounded retry completed successfully. No system clock,
trust, private-key ACL, entitlement, profile or signing-policy changes were made.
No ad-hoc fallback, notarization or publication occurred.

The owner has been asked to run this exact operation in their own Terminal session
and handle any Keychain prompt directly:

```sh
/usr/bin/codesign --force --sign 2F726FB7158503B1340F4F88E1CCA27116E23DB0 --options runtime --timestamp --entitlements '/Users/naftali/Developer/VectorCraft/apple/Resources/VectorCraft.entitlements' '/Users/naftali/Developer/VectorCraft/apple/build/package.PuivVG/VectorCraft Swift.app'
```

Installation and canonical SVG/gradient/panel/color/alpha/G-shortcut focus/inline text,
Clipboard/Undo, native Save/relaunch/reopen and export checks remain pending. The
canonical Swift executable remains
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`;
the original Rust executable remains
`b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.
No worktree, source commit/push, iPhone work or permission expansion occurred.
SVG, gradient and signing issues remain in progress; full Mac parity is not complete.


## 2026-10-19 — signing blocker revalidation and blocked goal status

A third consecutive goal-turn audit found no new package after `package.PuivVG`.
Its executable still hashes to
`3dd7265429d43b02c2b2457aed95c867b954fef8f91838503c63ab1bc5c93c13`.
`codesign --verify --strict` fails with “code has no resources but signature indicates
they must be present.” Metadata shows only the linker's ad-hoc signature, identifier
`VectorCraftMac`, no bound Info.plist/resources and no Team ID. This is not a valid
signed app bundle and was not installed. Canonical executable remains
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`.
No build, test or signing process is live. No completed handle was restarted.

The full goal is blocked on the already requested owner-side interactive signing;
it is not complete, paused, reduced to the current milestone, or replaced. Existing
128-test and production-build evidence remains separate from missing installed
workflow proof. SVG, gradient and signing issues remain in progress. The owner can
run the existing packaging script in Terminal and provide its printed app path or
exact error; then signature verification, recoverable installation and the pending
canonical workflows can continue. No signing-policy or access workaround was made.

## 2026-10-28 — required Xcode RC and approved certificate revalidation

The owner resumed building with the new certificate. The required selected path
`/Applications/Xcode.app` reports **Xcode 27.2, build 27B48**. Packaging now pins and
checks that exact RC instead of the earlier beta. Stale project-local Xcode 27.1
instructions now defer to the owner's current canonical Apple workflow. No Xcode
service, agent/folder grant, Keychain ACL, trust or profile change was made.

The RC release run completed successfully: **73 Core + 55 native tests**, no compiler
warnings. Build time was 853.51 seconds; native tests ran in 5.527 seconds and Core
in 9.860 seconds. This is correctness evidence, not an idle-machine performance
measurement. Full log: `build/release-tests-27B48-20261028.log`. Script syntax,
Info.plist/entitlement lint and tracked diff whitespace checks also passed.

The approved valid signing identity remains
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Developer ID Application: Bizit LLC (Apps),
Team `Z5F6B8QVKJ`. The public certificate was matched by DER SHA-1, its issuer is
Developer ID Certification Authority G2, validity is October 19, 2026 through
November 18, 2027, and `security verify-cert -p codeSign -L` succeeds. No private key
was exported. A fresh production package/sign attempt is in progress; a certificate
and test pass alone do not establish a successful app signature or installation.

Before packaging, both installed executables and synthetic source fixtures retain
all previously recorded hashes: original Rust `b1e51296…94ab604`, canonical Swift
`aea9bc6f…c63d7`, SVG `6fbe0466…735fd` and native document `55f0d1b2…f3fd5`.
The existing October 18 Swift bundle strictly verifies with its ad-hoc signature.
No newer signed package or running build/test/signer/app existed before this run.

### Signing and installation succeeded; OS sandbox startup wait remains

The production package completed successfully using the existing script and approved
new certificate. Log: `build/package-g2-27B48-20261028.log`; reported build duration
2,613.82 seconds (not a performance benchmark). Staged bundle:
`build/package.lrJ2tG/VectorCraft Swift.app`.

`codesign --verify --strict` passes for staged and installed bundles. Embedded leaf
certificate DER SHA-1 exactly matches `2F726FB7158503B1340F4F88E1CCA27116E23DB0`, G2,
Team `Z5F6B8QVKJ`. Signature has hardened-runtime flag `0x10000` and timestamp
October 28, 2026, 01:59:10 local time. Identifier remains
`com.swiftdev.vectorcraft.mac`; Info.plist matches source. The only entitlements remain
App Sandbox and user-selected read/write file access. No notarization or publication.

The recoverable installer replaced `/Applications/VectorCraft Swift.app` after
moving its previous bundle into a unique Trash location. Installed executable SHA-256:
`88014229d3f88402bff6bcbd5badcb623ca92972ad5015abd35974d65c932e40`.
The Rust executable retains its full recorded hash
`b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.
Launch Services returned -10814 when unregistering the never-launched stage after
replacement. Canonical registration was then explicitly completed successfully.
The installer now reports failed build unregistration and continues to the required
canonical registration; shell syntax passes. This script-only fix needs no app rebuild.

A first certificate-extraction diagnostic used the optional prefix argument in the
wrong form, so that diagnostic did not extract a certificate. The corrected
`--extract-certificates=PREFIX` call succeeded, and the embedded fingerprint above
was checked from its output. The deprecated `--entitlements :-` diagnostic warned;
`--entitlements -` rechecked the unchanged values without that warning. Neither was
a production compiler/signature failure.

Computer use launched the canonical process (PID 37111, path verified). Repeated
window reads time out with error -10005 while Finder's native UI remains readable.
No new VectorCraftMac crash report appeared. A three-second sample is saved in
`build/signed-launch-sample-20261028.txt`: all 2,632 main-thread samples wait in
`_libsecinit_appsandbox` → `_xpc_pipe_routine` → `mach_msg2_trap`, under dyld's
libSystem initialization. Application code has not started. Narrow system logs are
in `build/signed-launch-system-20261028.log`; they show AppSandbox startup and TCC
attribution but do not establish the cause of the unresolved OS wait. A platform
Apple-anchor check is not a failure of the separately verified Developer ID signature.

The owner was asked whether a macOS prompt is visible and for its exact wording.
No container reset/migration, Keychain ACL/trust change, security bypass, ad-hoc fallback
or broader permission was attempted. Cold launch, native document access and current
SVG/gradient editing/save/relaunch/reopen/export proof remain pending. Signing itself
is no longer blocked. All three increment issues remain in progress because their
installed acceptance includes cold launch/native access. Full Mac parity stays active.

Independent enumeration of the previous-app Trash backup was blocked by macOS:
`os.scandir('/Users/naftali/.Trash')` returned Operation not permitted. The installer's
successful preserve/move sequence remains the backup evidence; no extra Trash access
was granted. A later Cortex progress-comment call failed at transport send. A complete comment
readback confirmed it was absent before retrying. The successful earlier signing/
install comment is already recorded in the signing issue.

The diagnostic Cortex comment retry succeeded (`comment_01m60jb9h489awrfsb4avt394g`).
A final default-sandbox `codesign` check reported an invalid signature. Immediate
normal-session revalidation passed strict checks for both staged and installed
bundles; both executable hashes still equal `88014229…932e40`, and G2 Team/runtime/
timestamp metadata is unchanged. This is a sandbox-context discrepancy, not evidence
that the installed artifact changed. Use the normal-session verification evidence;
no re-signing or trust change was performed in response.

## 2026-10-28 — continuation identifies the required container-access prompt

The preceding goal turn made concrete progress: RC tests/build/sign/install completed.
This continuation rechecked authoritative external state. The exact same canonical
process, PID 37111, is still live (sleeping, 0% CPU); normal-session strict signature
verification passes and executable SHA-256 remains `88014229…932e40`. No build or
signing job was restarted. Computer use now reports AppleEvent timeout -1712 while
opening that same app. The new two-second sample
`build/signed-launch-recheck-20261028.txt` puts all 1,747 main-thread samples in the
same AppSandbox/XPC wait before application code.

A narrower read of `secinitd`, `containermanagerd` and `sandboxd`, filtered by the
exact app identifier/name or PID, produced the decisive system message. Saved log:
`build/signed-launch-services-recheck-20261028.log`. At 02:02:05.999, secinitd records:

- New identity: `Z5F6B8QVKJ/com.swiftdev.vectorcraft.mac; signer:developer_id`.
- It is not in the ACL for `~/Library/Containers/com.swiftdev.vectorcraft.mac/Data`.
- The old entry has signing identifier `com.swiftdev.vectorcraft.mac` and validation
  category `none`.
- The service is `prompting`.

This establishes that macOS requested authorization for the newly signed app to use
its existing data container. It does not prove that the protected prompt is visible
or has been answered. The owner was asked to respond to that VectorCraft prompt and
report approval or its exact wording. No container reset/move, ACL edit, TCC reset,
Full Disk Access grant, signature fallback, system-service restart or permission
bypass was attempted. No application source change is justified by this OS wait.

Apple's primary reference explains app-container consent for different developer
identities and same-Team access: [What's new in privacy, App Sandbox chapter](https://developer.apple.com/videos/play/wwdc2023/10053/?time=1066).
The local secinitd message, rather than a forum analogy, is the evidence for this
particular startup condition. Crash/inheritance reports with similar stack symbols
were not treated as proof: this process is waiting, has no helper, and has not crashed.

The full Mac parity goal remains active. The signing issue still includes pending
cold-launch/native-document access, and SVG/gradient issues still need installed
editing/Undo/save/reopen/export proof. The startup prompt is the next concrete
external action; adding further source-only features would leave those checks open.

## 2026-10-28 — third consecutive startup-blocker audit

The preceding goal turn was progress: its exact-PID service log identified the
container ACL mismatch and explicit `prompting` state. This continuation revalidated
the live process instead of treating observation timeouts as terminal or starting a
duplicate app/build/signer. PID 37111 remains the canonical installed process,
sleeping at 0% CPU. Normal-session strict signature verification passes and its
SHA-256 still equals
`88014229d3f88402bff6bcbd5badcb623ca92972ad5015abd35974d65c932e40`.

The final two-second sample, `build/signed-launch-final-audit-20261028.txt`, puts all
1,761 main-thread samples in the same `_libsecinit_appsandbox`/XPC/mach-message wait,
before application code. This is the third consecutive goal turn with the same
external startup condition. No owner response to the protected VectorCraft data-access
prompt has arrived. The existing secinitd evidence identifies the new Developer ID
identity as absent from the old container ACL and records macOS requesting approval.

The blocked audit passes: safe local signing/build/diagnostic work is complete, the
signed artifact is unchanged, and installed cold launch/native document/SVG/gradient
acceptance cannot proceed without the OS response. The full goal is being marked
blocked, not complete, paused or narrowed. All pending increment issues stay in
progress; no unverified feature accumulation, permission/ACL/TCC/container change,
system-service restart or ad-hoc fallback was used. The next action is the owner
responding to the VectorCraft macOS data-access prompt, then resuming the full goal.

## 2026-10-29 — current upstream and local Swift fork assessment

Tracking: `issue_01m62zdzdtphms3tmk282xz0pb`. This was a repository/source assessment,
not an upstream integration or a new installed-app validation. All upstream reads
used the connected GitHub tools; no Git fetch, checkout, merge or ref mutation was
needed. Local source and installed apps were not replaced.

### Exact snapshot and divergence

| Item | Verified state |
| --- | --- |
| Local branch/base | `main`, `b64dcc02df4c656255142c0b611711d2717314db`, October 7, v0.4.0 |
| Configured remote | Only `origin`, `https://github.com/storytold/vectorcraft.git` for fetch/push |
| Current upstream main | `2b36d641c10f6831e47269f6e61beeb0ebb0023a`, October 29, 00:02:49 America/New_York |
| Main divergence | 5,497 commits ahead of local base, 0 behind; merge base equals our HEAD |
| Latest stable | v0.18.0, published October 28 at 13:38:39 America/New_York |
| Stable tag commit | `68b68a30acad9b3d8a72802b35f43b82e2bd7d3a` |
| Main after stable | 187 commits, no divergence; therefore stable is 5,310 commits after local base |

Primary sources: [latest release](https://github.com/storytold/vectorcraft/releases/tag/v0.18.0),
[pinned comparison](https://github.com/storytold/vectorcraft/compare/b64dcc02df4c656255142c0b611711d2717314db...2b36d641c10f6831e47269f6e61beeb0ebb0023a),
[release-to-main comparison](https://github.com/storytold/vectorcraft/compare/68b68a30acad9b3d8a72802b35f43b82e2bd7d3a...2b36d641c10f6831e47269f6e61beeb0ebb0023a).

The checkout is a local Swift variant of the original repository, without a separate
personal-fork remote or committed Swift branch. The connected profile identified
nickname `SwiftDevStudent`; repository search for that account plus `vectorcraft`
with forks included returned no matching accessible repository. This does not prove
that no private, renamed or other-owner fork exists. No new fork was created.

GitHub's compare file list stops at 300 paths. To avoid treating that as the complete
diff, the nontruncated recursive upstream tree was compared against all 1,288 local
HEAD file entries, by path, blob SHA and mode. Upstream has 2,291 file entries;
1,280 added paths, 593 modified paths and 277 removed paths were found. These are
path comparisons before rename detection, not semantic change or rename counts.
No upstream path is under `apple/`. All four locally modified tracked files
(`ASSETS.md`, `NOTICE`, `README.md`, `ROADMAP.md`) are also modified upstream; the
entire Swift port is untracked. Preserve those edits and their attribution content
before attempting any future integration.

### Where the original is holding

The pinned [upstream roadmap](https://github.com/storytold/vectorcraft/blob/2b36d641c10f6831e47269f6e61beeb0ebb0023a/ROADMAP.md)
still labels the product **alpha**. It estimates feature depth at about 75% and
full-Illustrator readiness at about 62%; those are the original author's estimates,
not independently measured behavior and not the Swift port's scores. Its stated
remaining blockers include reliable `.ai` exchange, interaction fidelity, real-machine
startup/stability, performance and advanced feature depth.

Material additions since the v0.4 baseline include shared docking with tab reordering,
splits, resizable floating panel groups and persistent workspaces; floating panels
in OS windows in v0.18; broader text (threading fixes, Touch Type, ruby and color-font
support); Effect Gallery and 57 Photoshop-style filters as reported by the roadmap;
initial 3D types; Affinity import; SVG/PDF/AI/EPS fidelity fixes, snapping and tool
interaction fixes, and substantial input-budget/security work. This assessment did
not run or behaviorally verify those upstream features.

Dependency/build changes also matter: the original now pins shared `craft-libs`
PDF/print/path/UI/keymap/window/update dependencies and egui 0.37 plus patched egui
and winit revisions. Rust MSRV remains 1.95. These affect a Rust reference build;
they do not implement the same behaviors in the independent Swift package.
[Upstream manifest](https://github.com/storytold/vectorcraft/blob/2b36d641c10f6831e47269f6e61beeb0ebb0023a/Cargo.toml).
The upstream `docs/gaps.md` is over 1 MiB and the content API returned no inline text;
it was not treated as read evidence. The roadmap, release notes, trees and targeted
source/test files supplied the findings above.

### Priority compatibility gap: native v4

The [stable serializer](https://github.com/storytold/vectorcraft/blob/68b68a30acad9b3d8a72802b35f43b82e2bd7d3a/crates/format/src/lib.rs)
sets `VERSION = 4`, and `SaveOptions::default` uses that version. In v4, resources
of at least 8 KiB may be placed after JSON, separated by `\n\0VCBLOBS\0`, and JSON
entries refer to `[offset, length]` blobs instead of inline base64. Images, placed
documents, embedded PDF data and profiles can use that representation. Existing
upstream tests explicitly exercise v4 compressed/uncompressed roundtrips, v3 inline
compatibility and invalid/truncated blob offsets.

Our `Sources/VectorCraftCore/NativeFormat.swift` accepts only `(1...3)` and parses
one JSON envelope; `rejectsFutureVersionsDeepNestingAndInvalidGeometry` explicitly
expects v4 to be rejected. This is a confirmed source-level interoperability gap:
default saves from current upstream cannot be opened by this Swift reader. Upstream
still supports writing older v1–v3 files. The Swift gap requires real bounded v4
parsing/preservation/save/roundtrip work; widening the version guard alone is not a
valid fix. The parity matrix now names v4 explicitly. No production format code or
test behavior was changed during this assessment.

### CI evidence and update recommendation

On the pinned main SHA, GitHub reported the core Ubuntu gate and four test shards
successful, SonarCloud Code Analysis failed, and FreeBSD checks still running. On
the stable SHA, the returned checks include successful test shards and macOS universal
release packaging, but SonarCloud Code Analysis also failed. Only 30 of 42 stable
checks were returned by that bounded query, so this is not an all-checks-green claim.
[Main checks](https://github.com/storytold/vectorcraft/commit/2b36d641c10f6831e47269f6e61beeb0ebb0023a/checks),
[stable checks](https://github.com/storytold/vectorcraft/commit/68b68a30acad9b3d8a72802b35f43b82e2bd7d3a/checks).
No fresh local Rust build, CI or installed-upstream workflow check was run.

Recommendation: yes, refresh the upstream reference baseline, using pinned v0.18.0
as the initial integration target rather than a moving main. First preserve the
uncommitted Swift port and four overlapping tracked edits. Then resolve the source/
license/documentation integration deliberately, retaining original app/data and
Swift ownership. Port native v4 compatibility first, with bounded resource parsing,
legacy roundtrips, unknown-data retention and current-Rust interoperability checks;
use current docking, snapping and text regressions to prioritize later Swift work.
A Rust-source sync alone cannot update Swift behavior. Existing installed SVG/gradient
acceptance and the recorded OS container-approval condition remain separate work.
No merge, reset, commit, push, branch/worktree creation, source publication, app install
or system permission change was performed by this assessment.


## v0.18.0 baseline and native v4 — 2026-10-29

The owner explicitly authorized preserving all local work, updating the baseline to
v0.18.0, adding Swift native v4 support and continuing the Mac port. Existing `main`
fast-forwarded from `b64dcc02df4c656255142c0b611711d2717314db` to exact release commit
`68b68a30acad9b3d8a72802b35f43b82e2bd7d3a`. Every local insertion in ASSETS, NOTICE,
README and ROADMAP was merged while retaining every upstream line. All 322 pre-existing
Swift/verification files were byte-identical immediately after the baseline update.
No branch, worktree, new source commit, push or publication was created.

The complete checkout before updating, including `.git`, ignored artifacts and the
other workstream's in-progress screenshot additions, is recoverable from:

- `apple/build/preservation-20261029-c41vl6yl/complete-checkout.tar`
- Original independently verified copy: `/private/tmp/vectorcraft-preserve-20261029-c41vl6yl/complete-checkout.tar`
- Size: 855,970,304 bytes; SHA-256 `64891b9ab4755d0aab912f850129e886b0d0415669eb2852f269ce80f6b4f660`.

All 2,259 nonvolatile files matched the archive; active build-cache files were captured
but excluded from content comparison. The durable project copy's complete checksum
also matched. Preservation manifests, root merge intermediates and verification JSON
are beside the archive. Final review found no missing pre-existing Apple files.

### Native format and regression evidence

Swift now reads native v4 JSON followed by the `\n\0VCBLOBS\0` binary arena, compressed
or plain. Each known resource range must use nonnegative integer offset/length within
the arena; truncated, fractional and overflowing ranges fail. The existing 64 MiB
compressed/decompressed/file limits and 128-level JSON bound remain. Known image/profile
aliases validate without a data copy per alias. Loaded opaque bytes and foreign fields
remain intact. New large inline images/profiles use binary descriptors at the upstream
8 KiB threshold. New documents use 4; loaded 1–3 preserve their format/version and inline
resources. Saving removes stale cached preview/PDF data as before. Opaque unused arena
bytes remain to protect unknown references; compaction and a save-version selector are
not implemented. This preserves profiles; it does not implement color management.

Image rendering, warning detection, PNG/SVG/PDF export, fragment copying and resource
collision handling now carry or materialize the arena correctly. A private clipboard
fragment contains referenced resources independently of the source offsets. Profile
payloads are preserved/materialized; existing unsupported cross-profile paste behavior
remains explicit. Paste preflights native size before mutating the drawing.

The two initial regressions failed against the pre-v4 implementation: binary suffix
input was rejected and large inline output lacked the marker/blob descriptor.
`apple/build/native-v4-red-20261029.log` records those failures. After implementation:

- **89 Core tests / 13 suites passed**: `apple/build/native-v4-core-tests-20261029.log`.
- **59 native Mac tests / 16 suites passed**: `apple/build/native-v4-mac-tests-20261029.log`.
- The focused v4 suite passed again after formatting: `apple/build/native-v4-final-focused-20261029.log`.
- Strict Swift format lint passed for the codec, fragment integration and new tests;
  property-list/shell syntax and `git diff --check` passed. No app compiler warnings
  appeared in the successful normal-session test/release logs.

The tests cover binary image render/export/clipboard collisions, unknown data, profiles,
aliases and stable repeated saves, gzip/truncation, invalid ranges/markers, legacy 1–3,
and native CanvasDocument snapshot/Undo/Redo with its binary resources. The other chat's
source-only screenshot pass was frozen and hash-checked before builds. Its font traits,
same-size image pose, resource reuse, outer-Layers insertion/isolation/Undo and valid
transparent proxy regressions also pass. A screenshot row-position assertion needed a
numeric tolerance; the separate compiled-CLI diagnostic returns exactly 2782. The broader
suite initially failed inside the tool sandbox because NSFileCoordinator could not reach
its service and NSPasteboard returned null; rerunning in the normal login session passed.
That environment restriction did not require an application workaround.

### Official Rust interoperability

Downloaded only the official v0.18.0 universal CLI for isolated verification; the installed
Rust application was not replaced. Release ZIP size 115,481,401 and SHA-256
`694d216cc0ac8ff32dc1c32ffa318da9e5229d58bc821e378eef6f3739286744` matched the release
metadata before safe extraction. Its `--version` reports 0.18.0.

The Rust CLI read a synthetic 64×64 PNG in a genuine v4 binary section and saved gzip v4
and inline v3 files. Swift read both, moved the image through Drawing.perform, saved v4,
extracted the exact original PNG and exported PNG/SVG/PDF. Rust reopened and rendered
Swift's saved file with no warnings. Document metadata/unknown sentinel and the affine
edit remained correct. Extracted PNG SHA-256 equals the original:
`100dcb4e9e37547f3a9026882b9f6e0b3fd4a5518418e704ddeaf921bb9de80b`.
Swift's 64×64 rendered image crop is pixel-identical to the original. Rust's filtering
and transparent page background differ; whole-image pixel parity is not claimed.
Fixtures/logs and machine-readable verification are under
`apple/Verification/native-v4-20261029/`.

Independent ScreenshotMaker release-CLI checks passed in separate fixture/output paths:
native v4/image extraction/reopen, unknown fields, crop/pose, no identical-image blob
or file growth, four rows/ten-board cap/nonoverlap and exact-size opaque PNG/clipped
SVG/PDF. Pixel checks cover upright images before/after rotation, crop clipping, actual
locally linked device-frame apertures, valid proxy and export refusal when a frame is
missing. The reports were read from:

- `/Users/naftali/Developer/ScreenshotMaker/verification/outputs/vectorcraft-20261029-013306-821303/report.json`
- `/Users/naftali/Developer/ScreenshotMaker/verification/outputs/pixels-20261029-013306-826051/report.json`

These are source/CLI/pixel checks; they are not installed screenshot UI proof. No
third-party frame assets were added to this repository. Rust source CI/WASM/performance
were not run; no Rust implementation was edited beyond the upstream fast-forward.

### Signed installation and exact remaining blocker

Verified `/Applications/Xcode.app` reports Xcode 27.2 build 27B48 and pinned DEVELOPER_DIR.
The release built and signed through the existing package script, producing
`apple/build/package.MnSTIR/VectorCraft Swift.app`, then installed through the existing
recoverable installer at `/Applications/VectorCraft Swift.app`. The previous Swift
installation went to a unique Trash destination. Build-bundle unregister returned
-10814 and the installer continued with canonical registration as designed.

Package and installed signatures strictly verify. Installed/package executable SHA-256:
`c6bbaeca142b9cdf6b79897704e1ec8341ba881bbabed08b40eec881ede2a61d`.
Public leaf certificate fingerprint is exactly the approved
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Developer ID Application Bizit LLC (Apps),
Team Z5F6B8QVKJ, valid 2026-10-19 to 2027-11-18, with hardened runtime and secure timestamp.
Its three entitlements are App Sandbox, user-selected read/write and the preserved
screenshot integration's existing app-scoped bookmarks entitlement. No signing/Keychain,
container/ACL, trust, Xcode access or system permission change was made. Original Rust
app executable still hashes to
`b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.

Canonical CUA launch created PID 19453 but UI reading timed out. All 1,722 main-thread
samples in the fresh two-second sample wait in `_libsecinit_appsandbox`/XPC/mach_msg,
before application code. The exact secinitd log at 01:32:04 EDT says the Developer ID
identity is not in the existing container ACL and macOS is `prompting`. See
`apple/build/native-v4-installed-launch-sample-20261029.txt` and
`apple/build/native-v4-installed-container-prompt-20261029.log`. The process was left
in place; the owner was asked to respond. No consent bypass or repeated relaunch.

Current installed v4 Open/edit/Undo/Save/reopen/export, SVG/gradient workflows and
physical trackpad feel remain unverified. Full Mac Illustrator parity remains open;
iPhone work remains deferred. The bounded baseline/v4 implementation is complete;
existing signing/SVG/gradient Issues retain their pending installed acceptance.


## Installed Screenshots workspace acceptance — 2026-10-29

The owner requested continuing as needed and a status of ScreenshotMaker integrated
into VectorCraft. The ScreenshotMaker coordinator explicitly froze shared source,
build/install and CUA ownership for this check. The current cavity-clipping source
checkpoint matched all five recorded hashes; package iFFL8E strictly verified and
installed recoverably. Its native window opened normally. The previous container
startup wait is resolved; no container/ACL/Keychain/trust, signing identity, Xcode
access or system-permission workaround was performed.

All following interactions used the canonical `/Applications/VectorCraft Swift.app`
through CUA and fictional artwork, with snapshots under
`apple/Verification/screenshot-native-20261029/`:

1. Created a native document, opened Screenshots, added an iPhone Medium row, imported
   the fictional PNG through the native picker, chose the local AppleDevices folder,
   and applied its original portrait frame. The document retains a scoped frame bookmark.
2. Double-clicked into the artwork group, then double-clicked its headline to edit
   inline. Changed it to “Create Better / Screenshots.” Native Save wrote v4 with a
   binary resource section. Independently read snapshots show Undo restoring the original
   headline and Redo restoring the edit.
3. Applied scale 1.15 / crop 0.03,-0.02. Reimporting the same-size original retained the
   exact image node, affine/crop and resource identity. An ordinary Rectangle drawn with
   the existing canvas tool became a child of the screenshot content group.
4. Rotated the board and saved 2622×1206 geometry. Undo restored the full earlier document;
   Redo restored the exact rotated document. Added another board and a Duo Inner row,
   producing two rows/three boards. Rotating the second board moved the downstream row
   from y2782 to y1366; Undo restored the entire original document exactly.
5. Native Save/close/reopen retained the edited text, vector path, image, frame, crop,
   rows and geometry. The saved PNG resource is byte-identical to the source image.
   Setting language metadata to he-IL saved correctly; native Undo restored the document.
   This is metadata behavior, not automatic translation.
6. Used native File → Export menus for PNG, SVG and PDF. PNG is 2622×1206 RGB (opaque).
   PDF is one 2622×1206pt page; its Poppler rendering was visually checked against the
   native canvas, including headline, vector shape and original local frame. SVG embeds
   the screenshot and links the original local frame; it is not self-contained. The
   existing consumer portability limit remains explicit.

A real UI-state defect appeared during native checks: selecting an empty board retained
another board's crop values. Before changing source, its file was preserved at
`apple/build/screenshot-native-before-crop-reset-20261029.swift`. The only application
source edit adds refresh()'s missing else defaults in ScreenshotWorkspaceControls.
The old installed UI reproduced it; the final installed UI resets empty-board fields
to 1/0/0/Fill and restores 1.15/0.03/-0.02 on returning to the populated board. No test
infrastructure was added for this low-impact state reset; production compilation and
that exact installed interaction prove the change.

Final production package: `apple/build/package.UEYp6W/VectorCraft Swift.app`, built
through the existing pinned Xcode 27.2 RC build 27B48 script. Package/installed executable
SHA-256 is `f09660c868532d338c24047131b8f605cea630e70c38042c09beae8c582c2948`.
Strict normal-session signature verification passes, with Team Z5F6B8QVKJ, hardened runtime,
timestamp and the existing approved G2 identity. The prior bundle was preserved in a
unique Trash location. After a normal quit, the final installed app cold-launched and
reopened the v4 screenshot document with its linked frame, without another picker.
Last observed canonical PID 62624. The source PNG stays byte-identical and the final
saved document equals the before-reopen snapshot after Undo restores the metadata/layout.
The sample is left open in Screenshots/Fit Workspace for the owner.

Machine-readable checks, exact file hashes, snapshots and exports:
`apple/Verification/screenshot-native-20261029/native-workflow-report.json`.
Build/install logs use `apple/build/screenshot-native-*-20261029.log`.
The original Rust app executable remains
`b1e51296d8652fb28a881af2904ccb242fb8d9dac805b342e6dcff15494ab604`.
The last broad automated pass remains 89 Core + 59 Mac tests; the coordinator's subsequent
focused cavity checks and independent frame-pixel reports are recorded separately.
An unchanged full suite was not rerun for the two-line crop-panel reset.

The screenshot integration now has installed workflow evidence. Current-board export,
local external frame links, manual language documents and limited templates are its
present boundaries; no generic plugin-loader, self-contained linked-frame SVG, automatic
translation, App Store upload or full Illustrator parity is claimed. Broader SVG-import
and gradient-authoring installed acceptance remains separate. Mac comes before iPhone.
No source commit, push, new worktree, publication, or permanent deletion occurred.
