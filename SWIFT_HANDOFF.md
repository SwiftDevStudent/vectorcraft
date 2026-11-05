# VectorCraft Swift / iPhone Handoff

## Current Mac checkpoint — 2026-11-04: v0.21.0 and portable Swift integration

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
No Rust code/Cargo patch is needed. See [INTEGRATION.md](apple/INTEGRATION.md) and
[UPSTREAM_V021_REVIEW.md](apple/UPSTREAM_V021_REVIEW.md). Nothing is committed or published.
Full Mac parity and deeper Picasso-style screenshot composition remain ongoing.

## Previous Mac checkpoint — 2026-10-31

Installed G2-signed `apple/build/package.VesCOA/VectorCraft Swift.app`, SHA-256
`97884f0db019a1dff777562c74cc897538d77a21483ba981d726126e3b3f27d0`.
Selected Xcode27.2/27B52.14 distinct focused layout/state checks pass across initial12
and final8 runs; last broad suite remains184, not repeated. New Slots and selected
Layout use five original vector schematic choices with shared Core geometry, selected
state and stable AX IDs. No bitmap/asset work to open the chooser. Existing command,
native Undo and document ownership remain canonical. Installed read-only dismissal,
future-slot defaults, apply/Undo/Redo/save/reopen and selected gallery checkmark pass.
A reproduced selected-last-slot Undo bug is fixed: valid board/controls/insertion/fit
recover. Native Undo restores exact bytes; resources/blobs remain intact. Export Used
produced exactly one visually inspected1206x2622PNG, skipping nine unused slots.
User projects/Rust hashes unchanged. See `apple/VERIFICATION.md` and
`apple/verification/layout-gallery-20261031.json`. Source checkpoint:
`apple/build/layout-gallery-20261031/source-before.tar`. One nice15 compiler job;
no app/compiler jobs remain. No long trace, broad suite, worktree, permission or
publication/iPhone work. Next screenshot gaps include visual frame browsing, expanded
composition/templates and native drag/hardware acceptance. Full Mac parity stays open.
Previous deferred canvas/card-cache measurements and their cold-load limitations are
retained in the verification record; no fresh runtime performance claim here.

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


## Visual screenshot cards and placement — 2026-10-29

Installed `apple/build/package.B9N1DM/VectorCraft Swift.app` at the canonical Swift path.
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

Evidence and limits: `apple/VERIFICATION.md` and
`apple/verification/screenshot-flow-20261029/native-flow-report.json`.
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

## Previous work — 2026-10-29, screenshot workspace installed and verified

The user requested continuing as needed and a ScreenshotMaker integration status.
The native screenshot workspace is now installed and verified in the canonical Swift
app. The container startup gate is resolved: both initial launch and full quit/cold
launch work without ACL/container/Keychain/trust or permission changes. Existing
approved G2 identity and original Rust app are preserved.

Final package `apple/build/package.UEYp6W/VectorCraft Swift.app` is installed at
`/Applications/VectorCraft Swift.app`; packaged/installed executable SHA-256:
`f09660c868532d338c24047131b8f605cea630e70c38042c09beae8c582c2948`.
The preceding cavity fix package iFFL8E provided the native workflow baseline. This
chat then fixed only ScreenshotWorkspaceControls.refresh()'s empty-board crop defaults,
repackaged and verified that exact switch plus cold launch/reopen in the final release.

Native proof: rows/boards, original local frame-library picker and persistent bookmarks,
PNG import/replacement, inline grouped headline editing, existing Rectangle insertion,
crop, rotation/reflow, native Save/close/reopen and language metadata. Undo/Redo matched
saved document snapshots; multi-row Undo restored all artwork/geometry. Native PNG/SVG/
PDF export passes, including visually inspected Poppler output. Original PNG payload
is byte-identical. The sample remains open in Screenshots/Fit Workspace; no unsaved
user artwork was involved. `apple/Verification/screenshot-native-20261029/` holds the
report, snapshots, document and exports. PID62624 is the last observed canonical process.

The UI supports selected-board export; batch export UI remains open. Local official
frames remain external, so SVG is not self-contained and some consumers omit the frame.
Language stores metadata, not automatic translations. AI is omitted from screenshot scope.
Full Mac Illustrator parity remains incomplete and iPhone remains deferred. Existing
SVG/gradient installed workflows still need their separate acceptance; source/test proof
must not be relabeled as installed proof. Native startup/signing acceptance can close.
Cortex task: `issue_01m64724cqmvk02a2dnf7fr03k`; screenshot owner issue:
`issue_01m62zd274mwfvtjaz5b1x37k4`. Coordinate before any concurrent source/build/UI work.

## Previous increment — 2026-10-29, v0.18.0 and native v4

The owner authorized preservation, v0.18.0 and native v4. Existing main now points to
`68b68a30acad9b3d8a72802b35f43b82e2bd7d3a`; all four overlapping local root additions
and all 322 prior Swift/verification files survived the update. Complete pre-update
archive: `apple/build/preservation-20261029-c41vl6yl/complete-checkout.tar`, SHA-256
`64891b9ab4755d0aab912f850129e886b0d0415669eb2852f269ce80f6b4f660`.
No new branch/worktree/source commit/push or Rust app replacement.

Swift native v4 JSON/blob resources and gzip input work within the existing 64 MiB
bound; legacy v1–v3 stay compatible. New documents default to v4. Opaque arena bytes
and unknown fields remain; images render/export and clipboard resources become
independent of source offsets. 89 core + 59 native Mac tests pass on Xcode 27.2 RC
27B48. Official Rust 0.18.0 gzip-v4 -> Swift edit/save -> Rust read/render passes;
PNG resource bytes and Swift rendered image pixels match the original. Full pixel
parity is not claimed. V4 source and interop evidence are under
`apple/Verification/native-v4-20261029/` and `apple/build/native-v4-*-20261029.log`.

The screenshot workstream's authorized source-only pass was coordinated and frozen
before builds. Its font/pose/resource reuse/insertion/proxy fixes and focused tests
are preserved; separate CLI-only acceptance uses ScreenshotMaker's own output folder.
Final release CLI: `apple/build/swiftpm/release/VectorCraftScreenshots`.

Approved G2-signed package `apple/build/package.MnSTIR/VectorCraft Swift.app` is
installed at `/Applications/VectorCraft Swift.app`; both executables hash to
`c6bbaeca142b9cdf6b79897704e1ec8341ba881bbabed08b40eec881ede2a61d`.
Fresh PID 19453 waits premain in AppSandbox/XPC; secinitd explicitly says its Developer
ID identity is not in the existing data container ACL and macOS is prompting.
The owner was asked to respond. Do not bypass or modify that container/ACL or launch
duplicate processes. Current installed v4/SVG/gradient interactions remain unverified;
full Illustrator parity remains incomplete and Mac comes first. Existing signing,
SVG and gradient acceptance issues stay open. See `apple/GOAL_PROGRESS.md` and the
latest `apple/VERIFICATION.md` entry before continuing.

## Historical work — 2026-10-28, container-access approval

The owner requested the new certificate and continued building. The resumed RC build
and signing succeeded, but the full goal is now blocked after three consecutive
goal turns waiting for macOS container-access approval. Verified
`/Applications/Xcode.app` as Xcode 27.2 RC, build
`27B48`, and updated the existing package script's exact preflight. All **73 Core +
55 native release tests** pass without compiler warnings; see
`apple/build/release-tests-27B48-20261028.log`. The approved identity remains
`2F726FB7158503B1340F4F88E1CCA27116E23DB0`; its public certificate, G2 issuer, expiry
and local signing trust chain were reverified. Signing succeeded; package
`apple/build/package.lrJ2tG/VectorCraft Swift.app` and the canonical installed app
strictly verify with the approved G2 fingerprint/Team, hardened runtime, timestamp
and unchanged two entitlements. Previous Swift app was preserved in Trash; canonical
executable SHA-256 is
`88014229d3f88402bff6bcbd5badcb623ca92972ad5015abd35974d65c932e40`. Rust is unchanged.

Cold launch is not yet verified: canonical process 37111 started, but computer use
times out reading its window while Finder remains readable. A three-second sample
(`apple/build/signed-launch-sample-20261028.txt`) shows the main thread waiting in
`_libsecinit_appsandbox` / XPC before application initialization. No new app crash
report appeared. A continuation's exact-PID `secinitd` log establishes that the new
Developer ID identity is not in the existing VectorCraft data container's ACL and
macOS is `prompting`. The owner was asked to respond to that protected data-access
prompt. The same process is still live and waiting; do not restart it merely because
AX reads time out. A final two-second sample has all 1,761 main-thread samples in
the same AppSandbox/XPC wait; normal-session strict signature/hash checks still pass.
The owner needs to respond to the VectorCraft macOS data-access prompt, then resume
the goal. Do not change container data, ACLs,
trust, signing policy or permissions, and do not weaken the valid G2 signature.
Signing issue remains in progress for cold launch/native access; SVG and gradient
issues remain in progress for installed acceptance. The old signing-blocker audit
below is historical, not the current state.

## Historical work — 2026-10-19, goal blocked on interactive signing

The third consecutive signing-blocker audit confirmed no successful new signature
or active signer. The full goal is marked blocked pending owner-side interactive
signing; do not start duplicate signer jobs or replace the canonical app with the
linker-only staged bundle.

The owner authorized the new certificate and continued Mac-first development. The
source implements editable SVG File/clipboard import and linear/radial gradient
panel/canvas authoring. **73 core + 55 native release tests** pass without app compiler
warnings. The production package builds with the owner's new Xcode 27.2 beta 3,
`/Applications/Xcode-beta.app`, exact build `27B5038j`, verified live and pinned with a
packaging preflight. Gradient native v1/v3 and SVG interoperability are checked; see
`apple/VERIFICATION.md` for the transparent-gradient reference discrepancy and limits.

Current staged bundle: `apple/build/package.PuivVG/VectorCraft Swift.app`.
Approved G2 Developer ID: `2F726FB7158503B1340F4F88E1CCA27116E23DB0`, Team `Z5F6B8QVKJ`.
The certificate chain verifies and the login Keychain is unlocked/readable/writable,
but background `codesign` fails with `errSecInternalComponent`. All prior signing
handles (73959, 3692, 61787) are terminal. The computer-use tool blocks SecurityAgent
and Terminal; the owner has been asked to run the exact codesign command interactively.
Do not restart an old handle, weaken signing, alter Keychain ACLs/trust/clock, or install
an unverified staged bundle. The original Rust app and canonical October 18 Swift app
are unchanged. No worktree, commit, push, publication, iPhone work or access expansion.

After the owner signs, verify the embedded fingerprint/Team/runtime/timestamp and
unchanged entitlements, then use the recoverable installer. Finish canonical import,
gradient panel/annotator/stop/color/alpha, inline text, Clipboard/Undo, native Save,
relaunch/reopen and export checks before closing the SVG/gradient/signing issues.
`apple/GOAL_PROGRESS.md` names their IDs and current evidence. The full parity goal
remains active; no source-only increment establishes completion. Temporary browser
verification tab and loopback server were closed after the gradient audit.

## Installed baseline — 2026-10-18

The user subsequently requested a Swift **Mac port before iPhone**, authorized best
judgment while asleep, and explicitly started a Codex goal. The initial native Mac
editor is now implemented in `apple/` and installed separately at
`/Applications/VectorCraft Swift.app`. The Rust app and source remain preserved.

The current release passes 47 native tests; unchanged Core retains its preceding 54-test pass. Installed editing, Undo/Redo, save/reopen,
SVG/PNG/PDF export and resizing checks. Native documents retain unsupported/unknown
data. Preview/export limitations and cross-device iCloud uncertainty are documented
in [`apple/README.md`](apple/README.md) and [`apple/VERIFICATION.md`](apple/VERIFICATION.md).
The Vectorify icon variants were inspected and copied unchanged with attribution;
redistribution rights remain unverified. iPhone UI/deployment and account provisioning
are deferred. No commit, push or publication occurred. The canceled Xcode headless
enable prompt left that service disabled.

The owner then requested the **same appearance as the Rust app, implemented in
Swift**. The editor now uses the source palette, Source Sans fonts and licensed
vector glyphs, with matching tool groups, document chrome, Properties/Layers dock,
panel rail and selection bar. The installed release's executable SHA-256 is
`aea9bc6faeb5209f4003e8885838f880e1ac44649f19eed9f71bd2ad7d2c63d7`.
See `apple/RUST_WORKSPACE_MATCH.md` for the appearance scope. Missing Rust features
stay visibly disabled; system dialogs and startup document handling remain native.
This follow-up did not create another goal or change the iPhone deferral.

The October 17 interaction follow-up replaces text-entry sheets with native input
on the artboard. Double-click edits text; Type click/drag creates point/rectangular
area text. Frames wrap, show overflow and reflow when resized. Tools and Properties
can float within the document window, dock again, and reset through Essentials.
Installed typing/save/reopen, undo/redo, frame reflow, floating controls and SVG
interoperability were verified. Full Illustrator parity remains the target, with
substantial gaps in `apple/ILLUSTRATOR_PARITY.md`. Palettes outside windows and
persistent custom workspaces remain unimplemented.

On October 18 the owner explicitly started the full Illustrator-parity goal in Swift,
Mac first. It remains active after the initial snapping increment: artwork grid,
edge/center smart guides, palette grid, Control bypass and native snap feedback.
Installed snapped geometry, undo/save/reopen, palettes and SVG export were verified.
Physical haptic feel and full parity remain open. Parent goal tracking is
`issue_01m57wfj98mtnk7ae7n5t3hz0j`; snapping tracking is
`issue_01m57wg3gvzsg7h63b0fecj852`.

The next increment adds nine destructive Pathfinder operations, compound Make/Release,
explicit fill rules and constituent anchor editing. The installed panel/menu/search,
compound shortcuts, native save/relaunch/reopen, Undo and SVG interoperability passed.
Its tracking is `issue_01m57xkcrk1y1j5h91c61hy9d1`. Outline/Trap, live compound shapes,
group operands and precision/performance depth remain open. The installed check found
an existing ⌘A conflict. The subsequent native responder fix removed the duplicate
menu item and verified selection of artwork, inline characters and inspector text
according to focus, including Save/relaunch/reopen. All 16 native tests pass without
warnings; the core was unchanged after its 34-test run. Selection tracking is
`issue_01m57yd4s65v9pqcdgv7avkpfw`. Continue P04/P05 interaction and transform gaps.

The next increment implements Shift-constrained movement/selection, Option copy
dragging, eight axis-aligned resize handles with proportional/center modifiers,
area-text reflow and constrained rotation/copy through atomic commands. Tracking:
`issue_01m57yr1e935k7szfj4pv8j90j`. All 60 release tests pass. Installed Shift-click,
side-handle resize, Duplicate/copy command, Undo/Redo, native save/relaunch/reopen and
SVG interoperability passed. Exact modifier-drag geometry is proven by native
AppKit event tests; CUA cannot hold modifiers across drag, and hands-on verification
remains open. Continue group-aware Selection/direct selection, then rotation-aware
boxes, custom origins and the remaining transform suite. A read-only strict signature
check found an error in the untouched original Rust bundle; its CLI remains usable.

The group/layer increment adds whole-group Selection/marquee/Select All while Nodes
still targets leaf paths. Nested isolation scopes commands, insertion, snapping and
Layers; breadcrumbs/Escape restore the parent, with transient dimming outside the
scope. All 69 release tests pass. Installed whole-group dragging, nested and layer
isolation, inline text/shape creation, Undo/Redo, Save/relaunch/reopen and full-color
SVG interoperability passed. Original IDs, coordinates and foreign fields survived;
new artwork was saved under the inner group. Tracking: `issue_01m57zebk8x68snah3s2y74y6t`.
Single-object isolation, repeated hierarchy selection, lasso/multi-anchor/segment
selection and clipping depth remain open. Continue P05 Transform Again/Each,
reflect/shear, rotation-aware boxes/origins and distribution; full parity stays active.

Transform Again now repeats successful affine moves/scales/rotations/copy drags on
the current selection through the same atomic command path. ⌘D belongs to repeat;
Duplicate remains available explicitly. Tracking: `issue_01m580d79brhvac1gxmmndhcqc`.
All 34 native tests pass, including Option-drag-to-repeat and isolation/Undo/reset;
the unchanged core retains its 40-test pass. Installed shortcut/search, numeric
100→200→400 scaling, Undo/Redo, inline-focus disabling, Save/relaunch/reopen/history
reset and SVG interoperability passed. Frame-reflow repetition is still absent and
clears repeat memory; Transform Each and the wider transform suite remain open.

Transform Each and numeric Reflect/Shear now provide individual/reference-point
transforms, seeded randomness, nonpersistent previews, Cancel/Copy/OK and menu/search
integration. Tracking: `issue_01m580vb9cwwqxgnqwgdfnvmbk`. All 83 release tests pass,
plus a focused valid-isolation follow-up. Installed dialogs, individual copy/repeat,
reflection/shear, invalid-value disabling, Undo/Redo, Save/relaunch/reopen and SVG
interoperability passed. Preview payload/atomicity is tested natively; CUA captures
the open sheet rather than the canvas behind it. Remaining transform options/tools,
arbitrary origins/boxes, distribution, typography, clipboard/import, accessibility,
performance and physical trackpad feel remain open. Continue vector clipboard and
SVG import for cross-document workflows while the full Mac parity goal stays active.

The loaded-artboard fitting and queued native Save increment now passes focused native
tests and installed rapid-edit/Save, cancellation/retry, Save As, inline/inspector focus,
Open Recent, native reopening and Rust-CLI SVG/native interoperability. Tracking:
`issue_01m582g31eyw1cerjchcx1x37s` and `issue_01m5830rveszqsbjasthpp2s1y`.
The final build avoids initializing NSDocumentController during Commands construction.
Native Share is unavailable/disabled; broad recovery/versioning/cloud stress remains
open. Continue SVG import/external clipboard input while the full Mac goal stays active.

Text/workspace tracking: `issue_01m56cxmnamv2rambvbn2cz7f9`.
Implementation tracking: `issue_01m4q9zv9s4yqxh1q8zw0t2she` in Cortex `Mac apps`.
Appearance tracking: `issue_01m4v227pznv2k1j017yxk71af` in the same Module.
The owner approved the exact independently reviewed project Module on October 18.
It was saved as **VectorCraft Swift** with **Mac apps** as its sole direct Dependency,
then flashed to verify exact content. The local record is `apple/CORTEX_MODULE_PROPOSAL.md`. The sections below preserve the earlier relocation
handoff and its then-current state.

## User Request

Move the downloaded VectorCraft repository to `/Users/naftali/Developer/VectorCraft`. The user will create the Codex project pointing at that existing folder; continue implementation there after handoff.

Build a native Swift port that works on the user's iPhone. Sync documents through iCloud. Research how Vectornator, now Linearity Curve, adapts vector editing to iPhone. Reuse the icon from the user's old Vectorify app.

## Existing Source and Build

- Upstream: https://github.com/storytold/vectorcraft
- Downloaded revision: `b64dcc02df4c656255142c0b611711d2717314db` (version 0.4.0).
- The checkout was clean before relocation. It contains the original Rust implementation and Git history.
- Main desktop application: `apps/vectorcraft/`; shared implementation: `crates/`; examples: `examples/`.
- Existing upstream instructions are in `AGENTS.md`, with product status in `ROADMAP.md`. The user's explicit Swift request overrides the upstream Rust-only rule for this port. Preserve upstream licensing and asset provenance.
- The Rust macOS app was successfully built, installed at `/Applications/VectorCraft.app`, and checked with a rendered example and PNG export. This is evidence for the original desktop app, not the future Swift port.
- Previous deliverable: `/Users/naftali/Documents/Codex/2026-10-07/https-github-com-storytold-vectorcraft-https/outputs/VectorCraft-0.4.0-arm64.zip`.

## Vectorify Icon

Existing project: `/Users/naftali/Developer/Vectorify`.

Icon asset catalog: `/Users/naftali/Developer/Vectorify/Vectorify/Assets.xcassets/AppIcon.appiconset/`.

Its `Contents.json` references these iOS 1024x1024 variants:

- Default: `AppIcon1024x1024.png`
- Dark: `AppIcon1024x1024 1.png`
- Tinted: `AppIcon1024x1024 2.png`

The icon files were located and their catalog read. They have not yet been visually inspected, copied, or applied. Preserve the old Vectorify project.

## Implementation and Verification to Continue

1. Inspect the real document format, model, commands, renderer, and current feature scope before deciding the Swift architecture. Define reviewable acceptance criteria for the port rather than treating a blank canvas as a completed port.
2. Research current public Linearity Curve iPhone documentation and interaction examples. Derive interaction principles without copying proprietary assets.
3. Use the personal Apple workflow skill and pin `DEVELOPER_DIR=/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer`. The Cortex Mac apps Module currently lists an older beta path; the user's explicit RC selection takes precedence.
4. Implement native phone editing and document persistence, using platform document APIs and iCloud capabilities. Inspect signing/team/container configuration before provisioning; verify real document synchronization rather than claiming entitlements alone prove it.
5. Apply the user's existing Vectorify icon and record its asset provenance.
6. Build and run using the selected Xcode workflow and the user's actual phone when available. Distinguish build, simulator, device, editing, persistence, and cross-device iCloud sync proof. Ask for required device or account access only when a concrete missing requirement blocks it.

## Build History and Preservation

Prior macOS builds encountered iCloud-offloaded source and Cargo cache files. Source files were restored byte-for-byte from local Git objects; offloaded originals were retained at `/Users/naftali/Documents/Codex/2026-10-07/https-github-com-storytold-vectorcraft-https/work/offloaded-source-backups/`.

The successful Rust build used temporary caches under `/private/tmp/vectorcraft-build-eu4sfijv`. Verify availability before reuse. Historical build scripts in the original chat's `work/` refer to the old checkout path and must be updated before reuse. Do not blindly rerun the upstream bundle task: it removes an existing generated app bundle. Preserve existing bundles recoverably first if rebuilding.

No Swift implementation, Linearity research, phone installation, iCloud provisioning, sync verification, or icon replacement has been performed in this relocation task. No commit, push, new branch, worktree, or Codex task was created.

Relocation tracking issue: `issue_01m4q8ktqxatg00m8pphwrmwfj` in Cortex `Mac apps`.

## Relocation Verified

The checkout was successfully moved on 2026-10-12. `git rev-parse HEAD` still reports the original revision and `git status --short` was empty before this handoff note was added. The original chat no longer contains the source checkout. The old ignored Rust `target/` cache was preserved at `/Users/naftali/Documents/Codex/2026-10-07/https-github-com-storytold-vectorcraft-https/work/relocated-rust-target/` to avoid dragging cloud-offloaded build caches into the new project. This handoff note is the only added repository file.

The native clipboard increment implements focus-aware Copy/Cut/Paste, Paste in
Place/Front/Back, plain-text insertion, referenced resource closure and collision-safe
merging with fresh IDs. Supported copies offer SVG/PDF. Tracking:
`issue_01m581mqmrnh49rncqk914yqc8`. All 97 release tests pass; installed cross-document
shortcuts, Cut/Undo/Redo, inline character/inspector focus, clipboard persistence across
relaunch, native Save/reopen and SVG/native Rust-CLI interoperability passed. The saved
fixture has eight roots, fresh group 17/children 18–19, and retained object/document
metadata. See `apple/CLIPBOARD_PLAN.md` and the dated verification entry. External graphic
clipboard input/SVG import, all-artboards paste, Remember Layers, threaded text and
cross-profile conversion remain open. Cold-open artboard fitting is inconsistent and
needs a separate P02 fix. The full Mac goal remains active; iPhone stays deferred.
