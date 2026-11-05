# Full Illustrator parity in Swift — work resumed 2026-11-04

## Current checkpoint — 2026-11-04: v0.21.0 and portable Swift integration

The source baseline is v0.21.0/11862f61. A verified source/Git archive and retained
recovery stash preserve the earlier work. Official upstream v1/v2/v3/v4/gzip-v4 files
pass Swift read/write and Rust0.21 reopen with document/image bytes unchanged.

195 checks pass on Xcode27.3/27C5020n (115Core +76Mac +4CLI). PNG/TIFF bitmap Paste
now prepares images on a serial utility actor and uses canonical commands/Undo.
Installed menu Paste, exact PNG preservation, Save, one-step Undo/Redo and PNG export
pass. Native cold reopen and both CLI readers also reopen the saved file.

The Swift addition is now self-contained under apple/: local licenses/NOTICE,
portable packaging, a source-only export with hashes and one-time idempotent asset
registration. Local G2 signing, Source Sans fonts and Vectorify branding come from an
ignored local-build.env; the default packager also passes without private inputs.
No Rust code/Cargo patch is needed. See [INTEGRATION.md](INTEGRATION.md) and
[UPSTREAM_V021_REVIEW.md](UPSTREAM_V021_REVIEW.md). Nothing is committed or published.
Full Mac parity and deeper Picasso-style screenshot composition remain ongoing.

## Previous: visual screenshot layouts and Undo repair — 2026-10-31

Installed G2-signed `apple/build/package.VesCOA/VectorCraft Swift.app`, SHA-256
`97884f0db019a1dff777562c74cc897538d77a21483ba981d726126e3b3f27d0`.
Both New Slots and Layout use five original vector schematic choices, sharing actual
Core positioning and preserving canonical command/Undo ownership. Opening/dismissing
does not write the document; choosing a future-slot default also leaves saved bytes
unchanged. Native apply/Undo/Redo/save/reopen and selected checkmark pass. A real
last-slot Undo bug found during acceptance is fixed: controls/insertion/fit recover
to a valid board. Native Undo restores exact bytes, image resources/blobs are intact,
and populated-only export writes one PNG from the synthetic ten-slot project.
14 distinct focused checks pass across initial12/final8 runs on27B52. One nice15
build job, no broad suite or profiling, small synthetic fixture only. User projects
and Rust unchanged; no jobs remain. See `apple/verification/layout-gallery-20261031.json`
and `apple/VERIFICATION.md`. Visual frame browsing, expanded composition, native drag,
hardware feel and full Mac parity remain open. Mac first; no publication or iPhone.

## Previous checkpoint: cached screenshot card images — 2026-10-31

Canonical app matches G2-signed `apple/build/package.ZU3FNB/VectorCraft Swift.app`;
SHA-256 `e8309dcd66d7809b6582cc855c23004dfc68c9bdd4f18dbee2e0277d263b0a20`.
One actor-owned image cache reuses display-sized pixels for cards, through the existing
renderer. Exports continue using originals.20 focused checks pass on27B52; the last
broad suite remains184. Three-card repeated render improved464.2→79.7ms; first pass
was slower605.1→925.8ms. Native card loading/refresh, inline edit/Save/Undo and fit pass
on a local copy; exact source bytes restored, original PNG unchanged. Both user
projects/Rust preserved. See `apple/verification/card-previews-20261031.json` and
`apple/VERIFICATION.md`. One nice15 compiler job, no long trace. Larger scene/cold
completion budgets, hardware feel, native drag acceptance and full parity remain open.

## Previous checkpoint: deferred canvas image previews — 2026-10-31

Installed G2-signed checkpoint: `apple/build/package.MQ3MmO/VectorCraft Swift.app`;
SHA-256 `6da59ab88c2a2386dce6a1065d2b084717281fb714d21913bf0fa1c5a89c3ad1`.
Xcode27.2/27B52:24 focused and184 total checks pass. Image decoding is now serial
utility work outside canvas draw, with viewport coalescing, stale-source rejection,
cached zoom fallback, cancellation and visible status. One bitmap pair measured
2222.6→114.3ms first draw, followed by2013.4ms image completion; final pixels and the
original-resolution export are unchanged. This is not native UI or OS-cold timing.
Installed copy-only cold-open/fit/zoom/text/Save/Undo pass; Undo restores exact bytes.
Both user projects and Rust remain unchanged. See `apple/VERIFICATION.md` and
`apple/verification/cold-previews-20261031.json`. Physical feel, larger image budgets
and full parity stay open. Active follow-up: small cards still decode original PNGs;
`issue_01m6aezd7yn001bzgj6q10bh05` reuses the existing display-sized preview path.
One nice15 compiler job; no extra Darwin I/O policy, long trace or iPhone work.

## Previous installed low-impact continuation — 2026-10-30

Canonical Swift app now matches G2-signed `apple/build/package.EZblNp/VectorCraft Swift.app`.
Executable SHA-256: `04d148fcae97791719c47b42a70160ee6d99007edfd0ffe80969cd6df5be770f`.
Screenshot cards share one actor renderer per editor at utility priority, with existing
cancellation/pixel/export behavior retained. The package script enforces one background
build job at nice15. Twelve focused checks pass; the prior175-test run is the latest
broad suite and was not repeated. Native card load, rotation/refresh and Undo/Save pass
on a two-board synthetic document; Undo/Save restores exact original bytes. The app
was quit after verification. Both saved Smartlist projects and Rust app are unchanged.

Existing21-file native/CLI exports match byte-for-byte. No new trace or batch export
was run while the user's Mac was busy. See `apple/VERIFICATION.md` and
`apple/build/resume-20261030/verification-report.json`. Cold decode/first-zoom stalls
remain in `issue_01m65h65mtcnnhaexbc6qq8nv8`; drag/hardware feel, visual templates,
frame-pose automation, broader SVG/gradient acceptance and full Mac parity remain open.
Mac first. No permission expansion, worktree, commit/push/publication or iPhone work.


## Performance and agent-operation checkpoint — 2026-10-30

Resumed at the owner's request with sequential, low-priority work. Prior checkpoint
release: `apple/build/package.kFG7wX/VectorCraft Swift.app`, executable SHA-256
`368707103f854b828bba24767dfbe1b256ade3077c2911ec23a8f76505460578`.
103 Core + 68 Mac + 4 CLI tests passed before pause. ImageIO preview reuse, clipped
board culling, document warning reuse and affected-only thumbnails are implemented.
Recorded warm overview redraw improved from1.1–1.7s to about31ms; longest recorded
native hang fell3.05→1.17s, with six stalls still detected. Cold decoding remains a gap.
The benchmark retained about23MiB extra peak footprint; exports use original images.

Structured CLI summary/stdin/dry-run/compact/bulk export workflows pass both focused
tests and the actual Smartlist-copy checks. Before the pause, the installed app
cold-reopened all linked frames through the already-approved library scope and exported
21 PNGs. On resume, all21 match CLI output byte-for-byte; both saved user documents
and the performance copy retain their original hashes. Native image/data/unknown-field
preservation holds. Live unsaved-document control remains open. Cortex VectorCraft
Swift v3 now records the owner-approved structured-agent preference; Mac apps remains
the sole direct Dependency.

Read `apple/LOW_IMPACT_WORK_PLAN.md` for the next bounded thumbnail-scheduling change.
No fresh profiling or broad repeated suite is needed while the machine is busy.
`apple/VERIFICATION.md` records exact evidence and limits; no overall parity, iPhone,
commit/publication or physical-trackpad claim follows from this checkpoint.


The owner explicitly started a new ongoing goal: full Adobe Illustrator feature and
interaction parity in Swift, Mac first before iPhone. This supersedes the limited
initial Mac milestone as the current completion target. Earlier milestone records
below are historical; they do not establish completion of this goal.

Completion requires an expanded feature/workflow inventory against public Illustrator
behavior documentation, working native Swift implementations, appropriate focused
tests and installed-app workflow proof, and a final fidelity/accessibility/performance
review. Disabled menus, matched chrome, partial subsystems and build success do not
count as parity. Original Rust/source/data and unsupported native fields stay intact.
No worktree, commit/push/publication or Xcode access expansion is authorized.

Tracking: parent `issue_01m57wfj98mtnk7ae7n5t3hz0j` in Cortex Mac apps. The owner
explicitly approved the independently reviewed VectorCraft Swift Module on October 18;
creation and exact content/Dependency verification passed. See `CORTEX_MODULE_PROPOSAL.md`.

## Visual screenshot cards and placement — 2026-10-29

Installed `build/package.B9N1DM/VectorCraft Swift.app` at the canonical Swift path.
Executable SHA-256: `eb0fc4dae9293852c32fdd296292e2a4c99e962c0a74f48e1df83a2955d4c235`.
Approved G2 signature strictly verifies; original Rust binary and original project are unchanged.

The screenshot inspector now shows rendered composition cards, selected state and
numbered empty slots. Selected-board controls precede the row list; crop fields are
collapsed. Multi-image placement replaces the target then fills following empty slots,
skipping occupied slots, in one native Undo. Move/swap commands retain board IDs,
image/frame resources and unknown fields. Clip to Artboards changes preview only.

100 Core + 67 Mac tests pass. Installed multi-image picker, menu move/swap, exact saved
Undo/Redo, cold launch/reopen and populated-only PNG export pass. Exported slots1/3
are byte-identical to the earlier slots1/8. CUA card/Finder drag delivery remains
inconsistent, so final-build drag acceptance and physical trackpad feel stay open.
A reproduced promised-file Quit delay prompted data-only native card providers;
their exact payload/file-loading path passes tests and normal Quit now works.

Evidence and limits: `VERIFICATION.md` and
`verification/screenshot-flow-20261029/native-flow-report.json`.
Current Cortex issue `issue_01m64crsxh1gx8s7bqaz7pv7xx` remains in progress for native
drag acceptance. Next are that acceptance, frame-pose automation and visual templates;
full Illustrator parity remains open and iPhone remains deferred. No commit/publication.

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

## Installed screenshot workspace and startup resolved — 2026-10-29

Owner requested continuing as needed and the status of ScreenshotMaker integrated into
VectorCraft. Tracking: `issue_01m64724cqmvk02a2dnf7fr03k`. Exclusive shared checkout/build/
install/CUA ownership was coordinated; all screenshot source and prior work are preserved.
The corrected frame-cavity package iFFL8E installed and launched normally, without any
container/ACL/Keychain/trust change. Its original-frame clipping checks were already green.

Installed verification created two screenshot rows and three boards, imported the fictional
PNG through the native picker, selected the local device library/frame, edited the grouped
headline directly on canvas, and inserted an ordinary Rectangle under the board content.
Same-size replacement preserves exact crop/pose. Native Save emits v4 binary resources;
close/reopen and full quit/cold launch retain document and frame bookmarks. Native headline
and rotation Undo/Redo match independently read file snapshots. Rotating the second board
moves the following row from y2782 to1366; Undo restores the entire original document.
Language metadata saves/undoes. PNG2622×1206 RGB, SVG and one-page PDF exports succeed;
Poppler rendering was visually inspected. SVG's external-frame portability limit remains.

A small real panel bug was reproduced: selecting an empty board left another board's crop
values visible. The only source change resets those fields in refresh() when no image exists.
No extra test infrastructure was added for this reversible UI state edit. The final installed
release's exact board-switch interaction now resets to scale1/x0/y0/Fill and restores the
populated board's saved1.15/0.03/-0.02 settings on return.

Final package `build/package.UEYp6W/VectorCraft Swift.app`; installed/package executable
SHA-256 `f09660c868532d338c24047131b8f605cea630e70c38042c09beae8c582c2948`.
Strict signature and Team/identity remain valid; current canonical process62624 is running
the verification document. Earlier installs remain recoverable in Trash. Rust is unchanged.
The current startup blocker is resolved; earlier blocked sections below are historical.
Full Illustrator parity and iPhone work are incomplete. Remaining installed SVG/gradient
workflows and physical trackpad feel stay explicit; current-board/batch UI and local SVG
frame links are screenshot workflow limits. Evidence:
`Verification/screenshot-native-20261029/native-workflow-report.json`, native snapshots
and exports. No new worktree, commit, push, publication or system-permission changes.

## Authorized baseline and native v4 work — 2026-10-29

The owner explicitly authorized preserving all local work, updating the baseline to
v0.18.0, implementing native v4 in Swift and continuing the Mac port. The complete
prior checkout (including Git history, ignored artifacts and screenshot integration)
is preserved in `apple/build/preservation-20261029-c41vl6yl/complete-checkout.tar`,
with the independently verified original under `/private/tmp/vectorcraft-preserve-20261029-c41vl6yl/`.
SHA-256: `64891b9ab4755d0aab912f850129e886b0d0415669eb2852f269ce80f6b4f660`.
All 2,259 nonvolatile files matched; cached build files were captured but excluded
from live comparison. Four root merges retained every local insertion and every
upstream line. Existing `main` fast-forwarded to exact v0.18.0 commit
`68b68a30acad9b3d8a72802b35f43b82e2bd7d3a`; all 322 Swift/verification files remained
byte-identical after that update. No new source commit, branch, worktree or push.

Tracking: `issue_01m6303kmbdqhdwg9vzsg0xges` — completed for this bounded increment. ScreenshotMaker coordination was explicitly
authorized by the human in its coordinator chat and verified from that actual reply.
Its in-progress screenshot additions are preserved and its shared test run was released.
This chat owns source/build/install for the bounded baseline/v4 increment; the other
workstream remains paused until handback. Known screenshot font/insertion/proxy follow-ups
are recorded separately and are not native format regressions.

Acceptance plan: keep v4 binary data with its Drawing snapshot, validate known resource
ranges without allocating each alias, resolve images for rendering and images/profiles for clipboard,
and write valid v4 binary references for large new inline resources. Retain foreign JSON
and opaque binary bytes, existing v1–v3/legacy behavior and native document/Undo ownership.
New documents will use v4; loaded old versions retain their versions. Read compressed and
uncompressed input within the existing 64 MiB/128-level bounds; malformed sizes, offsets,
markers and compressed input fail atomically. No new dependency, Adobe app access, broad
permission or container/Keychain change. Prove focused failures first, then geometry/resource/
clipboard/legacy roundtrips, current Rust interoperability, build/sign and canonical Mac
save/reopen/Undo/export if OS access permits. Full Illustrator parity is not complete.

## Native v4 result — 2026-10-29

Implemented bounded JSON/binary reading and writing, preserved arena bytes/unknown fields,
new-document v4 defaults, legacy v1–v3 behavior, image rendering/export and source-independent
clipboard resources/profiles. The two initial focused regressions failed before the fix.
89 core and 59 native Mac tests now pass; strict Swift format lint and production build pass.
The official checksum-verified Rust 0.18.0 CLI wrote gzip v4/inline v3 fixtures and reopened
Swift's edited v4 output without warnings. Extracted image bytes are identical; Swift image
pixels match the original. Separate Rust filtering/background differences remain qualified.

The coordinated screenshot source pass is preserved: font family/traits, same-size pose,
image-resource reuse, Layers insertion routing and a valid linked-frame proxy. Its focused
command, image, layout, isolation and Undo tests pass. Only the rotation test's numeric
comparison needed a tolerance; the CLI diagnostic places its next row at exactly 2782.
No parallel source/build/install mutation occurred during final verification.

Release `build/package.MnSTIR/VectorCraft Swift.app` is signed with the approved G2
certificate and installed canonically. Installed/package executable SHA-256:
`c6bbaeca142b9cdf6b79897704e1ec8341ba881bbabed08b40eec881ede2a61d`.
The prior app is recoverable in Trash; original Rust executable remains unchanged.
The preserved screenshot integration's existing bookmark entitlement remains alongside
App Sandbox and user-selected file access. No new permission/trust/container change.

Cold launch remains unavailable: fresh PID 19453 waits before application code in
`_libsecinit_appsandbox`/XPC; exact secinitd output again says the Developer ID identity
is not in the existing container ACL and macOS is prompting. Owner action was requested.
Do not relaunch repeatedly or bypass the consent. Installed v4/SVG/gradient workflows,
physical trackpad feel and full parity remain open. Full details: `VERIFICATION.md`.

## Historical blocked audit — 2026-10-28 macOS container-access approval

The same sandbox startup wait has persisted through three consecutive goal turns
since the RC build/install. The preceding continuation made progress by identifying
the exact container ACL/prompt cause. This turn revalidated the specific live process,
its unchanged signed executable and the same startup stack: PID 37111, sleeping at
0% CPU, strict normal-session signature verification passing, all 1,761 final-sample
main-thread samples waiting in AppSandbox/XPC before app code.

No response to the protected data-access prompt has been received. Runtime acceptance
cannot proceed until macOS authorizes the new identity to use the existing container.
The full goal is blocked, not complete or narrowed; signing itself is resolved.
The owner should respond to the VectorCraft macOS data-access prompt, then resume.
No duplicate launch/build/signer, container change, permission bypass or fallback was
performed. Signing/SVG/gradient issues remain in progress for their pending installed
acceptance. See the final audit entry in `VERIFICATION.md`.

## Historical upstream assessment — before the authorized 2026-10-29 update

Tracking: `issue_01m62zdzdtphms3tmk282xz0pb`, under VectorCraft Swift.
The owner asked where the original repo stands and whether this fork needs updating.
Current local base remains v0.4.0, `b64dcc02` (October 7); upstream main `2b36d641`
is 5,497 commits ahead. Latest stable v0.18.0 (October 28), `68b68a30`, is 5,310
commits ahead of our base; main is another 187 ahead of that release.

Recommend preserving the uncommitted port and tracked local edits, then refreshing
the Rust reference baseline at the pinned release and deliberately porting relevant
behaviors to Swift. Native v4 compatibility is the priority new gap: v0.18.0 defaults
to v4 with binary blob sections, while Swift explicitly accepts only v1–v3. The parity
matrix now records that boundary. The original's roadmap still calls itself alpha;
its feature-depth/readiness percentages are estimates, not Swift scores.

Only upstream is configured as `origin`; no separate fork remote is configured.
No matching personal fork was returned by the connected-account repository search.
Upstream has no `apple/` tree. All four dirty tracked files also changed upstream.
No source sync, fetch/ref change, merge, commit, push, branch/worktree, app replacement
or permission change was performed. The full runtime goal remains blocked as above.
See `VERIFICATION.md` for complete snapshot, source links, CI limits and recommendation.

## Resumed build — 2026-10-28

The owner requested the new certificate and continued building. The goal resumed
for the RC build. `/Applications/Xcode.app` reports Xcode 27.2 RC, build `27B48`;
the existing package script now pins that exact path/build. All **73 Core + 55 native
release tests** pass without compiler warnings; log:
`build/release-tests-27B48-20261028.log`.

**The signing blocker is resolved.** `build/package.lrJ2tG/VectorCraft Swift.app`
was signed with the approved G2 identity
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Team `Z5F6B8QVKJ`, secure timestamp and
hardened runtime. Embedded fingerprint and unchanged two sandbox/file entitlements
were checked. Staged and canonical strict signature verification pass. The existing
installer preserved the previous Swift app in Trash and replaced the canonical app;
its executable SHA-256 is
`88014229d3f88402bff6bcbd5badcb623ca92972ad5015abd35974d65c932e40`.
Original Rust hash and source fixtures remain unchanged.

The canonical process started through computer use, but its window cannot yet be
read. Finder's UI remains readable. Two stack samples show all main-thread samples
waiting in `_libsecinit_appsandbox` / XPC before app initialization. No new crash
report appeared. The continuation found the decisive `secinitd` log: the new
`Z5F6B8QVKJ/com.swiftdev.vectorcraft.mac; signer:developer_id` identity is not in the
ACL for the existing `~/Library/Containers/com.swiftdev.vectorcraft.mac/Data`
container (whose old entry has validation category `none`), and macOS is `prompting`.
The owner was asked to respond to that protected VectorCraft data-access prompt.
No container/Keychain/trust/permission workaround was made; no ad-hoc fallback.
The same process remains live and waiting; no duplicate app or signer was started.
Installed SVG/gradient/native file workflows remain pending that OS response.
The older blocked audit below is historical; it no longer describes signing state.

## Historical blocked audit — 2026-10-19

The same private-key signing blocker has recurred across the original certificate
request and two consecutive goal continuations. The preceding turn made source/test/
interop progress; this continuation revalidated external state rather than restarting
terminal jobs. No newer package or successful signature appeared. The current
`build/package.PuivVG/VectorCraft Swift.app` still has only its linker signature:
identifier `VectorCraftMac`, no bound Info.plist/resources, no Team ID; strict bundle
verification fails. The canonical app retains the October 18 hash below. No build
or signing process is live. Handles 73959, 3692 and 61787 remain terminal.

The required next action is owner-side interactive signing. Run the existing
`/Users/naftali/Developer/VectorCraft/apple/Scripts/package-app.sh release` in Terminal,
handle any private-key prompt, and return the resulting app path (or exact error).
The computer-use tool blocks Terminal and SecurityAgent; background signing has
already failed despite a valid certificate chain and unlocked login Keychain. No
permission/ACL/trust change or ad-hoc fallback is authorized or attempted.

The full goal is blocked, not complete or narrowed. Installed SVG/gradient and
persistence/export verification must resume after a valid G2 signature is available;
adding further source-only features would not satisfy those pending end-to-end checks.
All SVG, gradient and signing issues stay in progress.

## In progress: editable SVG, gradients and approved G2 signing

Tracking under VectorCraft Swift:
- SVG: `issue_01m584sax3evbe36z64ra9ekay`.
- Gradients: `issue_01m59a449aqcnfnn62ce7f4sah`.
- Signing: `issue_01m5990mvrgxjwgbrdp432y607`.

**73 core + 55 native release tests** pass without app compiler warnings, including
real AppKit gradient placement, Shift/grid origin/endpoint snapping, preview/cancel,
stop crossing/selection/Delete and Undo. Production packaging compiles successfully.
Native versions 1/3 and SVG fixtures open/render in the original Rust CLI without
warnings. Review caught and fixed incomplete native gradient geometry and unsorted
stops; a failing AppKit check caught the unsnapped new-ramp origin. Transparent-stop
insertion preserves the Swift raster. Opaque radial fixtures differ from the Rust
render by less than 0.4/255 mean channel error on white. Variable-opacity interpolation
still differs from that reference (up to 11 channel values in the ordered-stop case);
keep that fidelity qualification explicit. See the October 19 verification entry.

The owner's replacement Xcode instructions are applied: `/Applications/Xcode-beta.app`,
Xcode 27.2 beta 3, build `27B5038j`, verified live and checked by packaging. The
approved G2 identity is `2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Team `Z5F6B8QVKJ`.
Its trust chain verifies and the login Keychain is unlocked/readable/writable.
Background signing nevertheless fails with `errSecInternalComponent`. Prior signing
sessions **73959**, **3692** and **61787** are terminal; do not poll/restart them as live.
The first RC snapshot had a 248-second signing/TSA discrepancy after an authorization
wait; that does not establish a clean current signature.

The current staged build is `build/package.PuivVG/VectorCraft Swift.app`, built using
27.2; pre-signing executable SHA-256 is
`3dd7265429d43b02c2b2457aed95c867b954fef8f91838503c63ab1bc5c93c13`.
The computer-use tool blocks both SecurityAgent and Terminal. The owner was asked to
run the exact signing command interactively. No Keychain ACL, trust, clock, profile,
entitlement, Xcode service, signing-policy or global permission change was made.
No ad-hoc fallback or new installation occurred. Canonical Swift executable remains
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`.

After successful interactive signing: verify fingerprint/Team/runtime/timestamp and
entitlements, install through the existing recoverable installer, then perform the
canonical SVG/gradient/inline text/Paste/Undo/native Save/relaunch/reopen/export and
existing-document checks. Keep all three issues and the full Mac parity goal open
until their actual acceptance checks pass. No further unverified feature accumulation
should substitute for completing these installed workflows.

## Completed loaded-artboard fitting and native Save scheduling increment

Tracking: `issue_01m582g31eyw1cerjchcx1x37s` and urgent Save follow-up
`issue_01m5830rveszqsbjasthpp2s1y`, under VectorCraft Swift.
The native fit and pending-activity regressions failed before their fixes. Fit mode
now follows loaded/edited artboard geometry while manual navigation stays unchanged.
Installed 612×792 and 1200×300 fitting/paste-center checks, actual-size preservation,
artboard resize/Undo and multi-document reopening pass. Rapid editing/Save originally
froze in NSDocument's serialization semaphore; Save/Save As now schedule the native
operation asynchronously and retain its activity through completion/cancellation.
Runtime logs prove both keyboard and File-menu Save reach the real queue. Rapid
Paste/Save, Undo/Redo/Save, inspector and inline focus, untitled cancellation/retry,
Save As, relaunch/reopen, Open Recent and native/SVG Rust-CLI interoperability pass.
All **47 native release tests** pass without warnings; Core code is unchanged from
its preceding **54-test** pass. Canonical executable SHA-256:
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`.
See `CANVAS_FIT_PLAN.md`, `NATIVE_SAVE_PLAN.md` and the dated verification entry.
Share remains disabled when AppKit provides no available native action; broader
version/recovery/cloud lifecycle stress and physical trackpad feel remain open.
SVG import/external clipboard input remains next. Full Mac parity remains active;
no iPhone, source publication or system-access expansion occurred.

## Completed native artwork clipboard increment

Tracking: `issue_01m581mqmrnh49rncqk914yqc8`, under VectorCraft Swift.
Native Copy/Cut/Paste and Paste in Place/Front/Back now use lossless cross-document
fragments, fresh IDs, referenced-resource merging, legacy path encoding, scoped atomic
commands and Undo. Supported copies also publish SVG/PDF; plain text becomes editable
point text. A failing exact-data regression caught and fixed added empty fields, and
installed QA caught and fixed stale special-paste menu enabling with inspector focus.
All **54 core + 43 native release tests** pass without warnings. Installed shortcuts,
stacking, Cut/Undo/Redo, inline character and inspector clipboard behavior, native
clipboard persistence across process restart, Save/reopen and SVG/native Rust-CLI
interop passed. Final saved roots are `[2,3,6,12,9,15,16,17]`, with fresh copied group
17/children 18–19 and retained foreign fields. Canonical executable SHA-256:
`d6f5a64cc4bd758db6740c55f978527474dc6cf6c91cbea662ce61a94f8d6e4c`.
See `CLIPBOARD_PLAN.md` and the dated `VERIFICATION.md` entry. External graphic import,
all-artboards paste, Remember Layers, anchor copying, complex live kinds, threaded text,
conflict-choice UI and cross-profile conversion remain open. Next address SVG import
and external clipboard input, alongside transform/typography depth and the observed
cold-open artboard-fit inconsistency (`issue_01m582g31eyw1cerjchcx1x37s`).
Full Mac parity remains active; physical haptic
feel, broad accessibility and large-document budgets remain unverified.

## Completed Transform Each, Reflect and Shear increment

Tracking: `issue_01m580vb9cwwqxgnqwgdfnvmbk`, under VectorCraft Swift.
Implemented per-root transforms, numeric reflection/shear, nine reference points,
seeded randomness, nonpersistent preview, Copy/Cancel/OK and repeat integration.
All **45 core + 38 native release tests** pass without warnings, plus a focused
valid-isolation follow-up. Installed shortcut/search/menu dialogs, Cancel, individual
copies and ⌘D repetition, reference-point reflection, horizontal/custom-axis shear,
invalid-value disabling, Undo/Redo, native Save/relaunch/reopen and SVG interoperability
passed. Original IDs/geometry and foreign metadata survived; seven saved paths have
the expected exact bounds. Canonical executable SHA-256:
`e97104aa469f5e10d56cfdbd8acb0eb2524ca9ae807f54d90d8506f66faf98ec`.
See `INDIVIDUAL_TRANSFORMS_PLAN.md` and the dated `VERIFICATION.md` entry. Preview
state/atomicity is proven natively; CUA captures the open sheet, so the canvas behind
an open sheet was not directly captured. Absolute/stroke/effect/corner/pattern options,
canvas tools/arbitrary origins, rotation-aware boxes, frame-reflow repeat and distribution
remain open. Next address vector clipboard and SVG import for cross-document workflows,
alongside continued transform/typography depth. Full Mac parity remains active.

## Completed Transform Again increment

Tracking: `issue_01m580d79brhvac1gxmmndhcqc`, under VectorCraft Swift.
Object → Transform → Transform Again and command search now repeat the last successful
affine move/scale/rotate/copy on the current selection. ⌘D invokes repeat; explicit
Duplicate remains available. CanvasDocument owns transient matrix/copy memory, and
repeated edits use its existing atomic command, isolation and Undo path. All 34 native
tests pass without warnings; the unchanged core retains its preceding 40-test pass.
Native Option-drag copy repetition is covered by AppKit events. Installed ⌘D/search,
100→200→400 width scaling, Undo/Redo, inline-focus disabling, native Save/relaunch/
reopen, transient history reset and SVG interoperability passed. Canonical executable
SHA-256: `e8613282b061f593fd8ae9b201b4f8597c4d11cb0a1c5c04cf6587904464e347`.
Frame reflow clears repeat memory instead of replaying an unrelated affine transform.
Frame-reflow repetition and the wider P05 suite remain open; see `TRANSFORM_AGAIN_PLAN.md`.
Next priority: Transform Each, reflect/shear, rotation-aware boxes/origins and
distribution, followed by typography and interchange. Full Mac parity remains active.

## Completed group selection and group/layer isolation increment

Tracking: `issue_01m57zebk8x68snah3s2y74y6t`, under VectorCraft Swift.
Native click/drag and marquee regressions failed against leaf-only group selection;
Direct Selection's anchor path already passed. The implementation adds group-aware
targets and editor-owned isolation with scoped commands, insertion, selection,
snapping and Layers plus dimmed presentation and nested exit breadcrumbs.
All **40 core + 29 native release tests** pass without compiler warnings. Installed
whole-group movement, nested isolation, scoped Select All/Layers, shape and inline
text insertion, Undo/Redo, breadcrumbs/Escape, layer isolation, native Save/relaunch/
reopen and full-color SVG interoperability passed. New artwork was saved under the
inner group, while original coordinates, IDs and foreign metadata survived. Dimming
is transient presentation only. Canonical executable SHA-256:
`21d8488f759702dd259876a10c12827c14e9af5d6cd45a99b0bdd603815ec7fd`.
See `GROUP_SELECTION_PLAN.md` and the dated `VERIFICATION.md` entry.
Single-object isolation, repeated Group Selection hierarchy clicks, lasso,
multi-anchor/segment selection and clipping-selection depth remain open. Next
priority: deepen P05 with Transform Again/Each and reflect/shear, then rotation-aware
boxes/origins and distribution; continue P18/P19 typography and P27/P29 interchange.
The full Mac parity goal remains active; physical trackpad/haptic feel is unverified.

## Completed transform modifier implementation increment

Tracking: `issue_01m57yr1e935k7szfj4pv8j90j`, under VectorCraft Swift.
Five native regressions reproduced the missing Shift/copy/resize/rotate workflows.
The shared command now supports atomic transformed copies, preserves originals and
metadata, and selects the copy in previews. Shift selection is deferred until click
release; constrained snapping stays on the intended line. Eight visible resize
handles work with opposite/center origins and proportional resizing; rectangular
area text reflows. Rotation supports Shift steps and Option copies. Full release
tests passed 37 core and 23 native checks. Installed Shift-click, side-handle resize,
Duplicate through the shared copy command, Undo/Redo, native save/relaunch/reopen and
SVG interoperability passed. The exact modifier-drag paths are covered by native
AppKit events; CUA cannot hold modifiers across its drag operation, so hands-on
modifier/trackpad verification remains open. Canonical executable SHA-256:
`015308ea9e99fbcfdee9979a33214671e76cfb75d40deb5ab2d2a04714b32d09`.
See `TRANSFORM_MODIFIERS_PLAN.md` and the dated `VERIFICATION.md` entry.
The remaining transform suite and broad P04/P05 parity stay open. Next priority:
group-aware Selection versus direct constituent selection, then rotation-aware
boxes/origins, Transform Again/Each, reflect/shear and distribution.

## Completed native Select All routing increment

Tracking: `issue_01m57yd4s65v9pqcdgv7avkpfw`, under VectorCraft Swift.
Installed ⌘A did nothing because the canvas lacked AppKit's `selectAll:` action and
a custom duplicate item could not replace the disabled standard command. The focused
regression failed against the original canvas, then passed through the native
responder. All 16 native canvas/document tests pass without warnings. Installed ⌘A
selects artwork, inline text or inspector text according to focus; one standard
Select All item remains. Native typing/Save/relaunch/reopen also passed. The installed
executable matches `15d01ac0e9f348cdb6ec5e93fa84f34f51d44d321010e257a2204a4dec3d083e`.
The prior 34 core tests remain valid; this increment only changed Mac responder/menu
routing. Full parity remains active. Next work should deepen P04/P05 selection and
transform modifiers and preserve the text/snapping/document interactions now covered.

## Completed Pathfinder and compound paths increment

Tracking: `issue_01m57xkcrk1y1j5h91c61hy9d1`, under VectorCraft Swift.

- [x] Nine destructive Pathfinder commands, curve-preserving Core Graphics geometry and fill-rule normalization.
- [x] Paint/stacking ownership, foreign metadata and compound Make/Release/anchor editing.
- [x] Focused geometry, native command undo and canvas anchor-event checks.
- [x] Nested final-contour deletion regression and final source review.
- [x] Installed Pathfinder panel/menu/search, save/reopen and export verification.
- [x] Record final evidence and limits; leave full parity active.

See `PATHFINDER_PLAN.md` for acceptance and public behavior references. Final release
tests passed 34 core and 14 native tests, including nine parameterized Pathfinder
cases. Nested final-contour deletion failed before the fix and passed afterward.
Installed Unite/Minus Front/Divide, compound shortcuts, fill rules, direct anchor
dragging, Undo, native save/relaunch/reopen and SVG interoperability passed. The
canonical installed executable matches
`114a53d03714ea5643d182eb477df3f2f46c45bc38982b64f7f73d72c3992e92`.
Outline/Trap, live compound shapes and cross-container operands remain unimplemented.
The installed check exposed an existing Select All shortcut conflict, resolved by
the subsequent native responder increment above.

## Completed snapping increment

Grid snapping and Keynote-like alignment/trackpad feedback, tracked by
`issue_01m57wg3gvzsg7h63b0fecj852`:

- [x] Artwork grid for creation, movement, node placement and resizing; preview and commit agree.
- [x] Edge/center smart guides across zoom levels, excluding selected/hidden geometry.
- [x] Floating toolbar/palette grid, docking, reset and bypass.
- [x] Native haptic filtering on snap transitions, separate from physical feel verification.
- [x] Focused regressions, installed Save/reopen/undo/export, documentation and attribution checks.

Final release and focused follow-up: 27 core + 12 native tests pass. Canonical installed executable matches
`df16eb116195bfbcc774183b40e4be24254302ef3a69beb127b019e220f5425a`.
Installed grid moves, smart edge alignment, Undo/Redo, palette movement/docking,
native save/reopen and SVG interoperability were checked. Physical trackpad feel,
large-document snap performance and broad gesture/accessibility coverage remain
unverified. This milestone does not complete the active full-parity goal.

Next priority: expand the full feature inventory, then deepen
selection/transform workflows, path geometry operations, typography, paint authoring
and file interchange in usable increments. Record actual evidence and remaining gaps
in `ILLUSTRATOR_PARITY.md` and `VERIFICATION.md`.

---

# Swift Mac port progress

The user changed priority from iPhone to Mac first and explicitly started this
goal on 2026-10-12. iPhone UI, device deployment, and cloud account provisioning
are deferred. The original Rust app remains at `/Applications/VectorCraft.app`.

## Completion checks

- [x] Inspect the Rust model, format, commands, renderer, examples and relevant tests.
- [x] Build native SwiftUI/AppKit editor using Xcode 27.1 RC.
- [x] Preserve the native document tree and foreign data across versions 1–3 and legacy DrawCraft names.
- [x] Implement shape, pen, pencil, node, transform, style, layer, group and undo commands.
- [x] Test actual AppKit mouse-event paths and document undo/redo.
- [x] Install a separate sandboxed `/Applications/VectorCraft Swift.app`.
- [x] Finish and verify point text.
- [x] Verify gzip, renderer pixels, export contracts and Rust interoperability.
- [x] Verify installed-app editing, undo/redo, save/reopen, export and resizing.
- [x] Review complete diff, attribution, docs and remaining limitations.

## Evidence so far

- Release build with Xcode 27.1 RC succeeds; the release is installed separately.
- Twenty focused core tests and three native AppKit/document tests pass.
- All four existing upstream example trees and image payloads round-trip.
- The installed app creates and reopens native documents, draws and edits curves,
  moves shapes, supports Undo/Redo, exports all three formats and adapts on resize.
- The initial coordinate-input concern was resolved after activating the document
  window; real installed canvas dragging and text input were verified.
- The preserved Rust CLI reads Swift-written documents and renders the generated SVG.
- Detailed evidence and remaining limits are recorded in `VERIFICATION.md`.

## Permission and preservation notes

The user approved narrowly scoped Xcode access, but canceled the administrator
prompt. The MCP/headless service remains disabled. Builds use the selected RC
command-line tools, with normal compiler-cache access. No global Xcode MCP
configuration has been added. No source commit or upstream Rust source change
has been made. Vectorify was only read; its icon copies are attributed and
redistribution rights remain unverified.

## Appearance follow-up — 2026-10-13

After the initial Mac goal completed, the owner requested the Rust application's
appearance in Swift. This ordinary follow-up matches the palette, existing fonts,
vector icons, workspace chrome, categorized tools, dock and panel rail. Alignment,
polygon, Type/Zoom/Eyedropper tools, command search, rulers/grid and Home presets
connect to real Swift commands and native document creation. Unimplemented tools
and panels remain visibly unavailable. The installed release passes 21 core and
3 native tests, signed-bundle and 380-asset attribution checks. Installed color
editing/save/relaunch, shape/undo, search, alignment, preset/text saving, tool columns,
dock resizing and reference-size canvas fitting were verified. Detailed limits and
evidence are appended to `VERIFICATION.md`; iPhone work remains deferred.

## Text and draggable workspace follow-up — 2026-10-17

The owner reported broken double-click editing and Type dragging, added draggable
toolbars, and set Illustrator parity in Swift as the broader product target. This
ordinary follow-up does not reopen the completed initial goal or defer Mac work to
iPhone. Inline native text input replaces the sheet; Type click/drag creates point
or rectangular area text. Wrapping, overset indication, frame reflow, character
controls, live Save and session undo use the actual document command path. Tools
and Properties/Layers detach, move and dock/reset inside each editor.

Twenty-four core and six native tests pass, including the reported AppKit event
paths and live persistence/undo. The final signed release is installed. Installed
editing, multiline paste, Save while typing, reopen, overflow/reflow, floating
controls, docking/reset and SVG export were checked. The preserved Rust CLI reads
the native file and renders the SVG without warnings. Full parity, external
palettes, custom workspace persistence and broader typography remain tracked in
`ILLUSTRATOR_PARITY.md`; see the dated `VERIFICATION.md` entry for evidence.
