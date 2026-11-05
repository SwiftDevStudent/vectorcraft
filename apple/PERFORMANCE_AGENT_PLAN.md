# Smartlist performance and agent operation — 2026-10-29

The owner reports severe slowness in the 21-board screenshot document and explicitly
requests better agent operation without computer use. Mac first. Preserve both saved
Smartlist iCloud documents, original Rust app/data, unsupported native fields and dirty
work. No worktree, source commit/publication, dependency, font/entitlement/security
change or iPhone work. Composition changes belong to Smartlist.

## Evidence before implementation

Selected Xcode /Applications/Xcode.app is 27.2 RC/27B48. Canonical installed baseline
is package.B9N1DM, executable eb0fc4...4c235. Copied original file byte-for-byte to
verification/smartlist-performance-20261029-ymvj_0v_/ (source.json records the hash).
Source checkpoint: source-before.tar in that folder.

Time Profiler captured actual copy-only opening, card selection, pan, Fit Workspace
and actual-size navigation. Six hangs, max3.05s; main thread spends substantial time
re-running renderingWarnings. PNG decoding is heavy across app threads. The separate
production-Core benchmark records median overview redraw1094.5ms, fitted redraw162.5ms,
actual-size73.8ms, warning scans31.7ms. Scene has42 image nodes/184MP nominal raster
content, including21 frame uses of only4 original files. Source repeatedly resolves
and decodes images on every redraw; warning scans run twice per EditorView body;
all thumbnails currently refresh after any Drawing change. These measured costs
justify preview reuse; no general scene/glyph cache or renderer rewrite is planned.

## Bounded implementation

- Canvas-owned, resolution-aware image preview reuse with an NSCache cost budget.
  Invalidate embedded resources when their resource table/arena changes and linked
  frames when their path/content identity or file timestamp/size changes. Validate
  original bytes on misses. Do not share mutable caches across documents/workers.
- Exports retain the uncached original-resource path and fresh validation. No image
  embedding, flattening, resource/bookmark rewriting or native file-format changes.
- Skip screenshot layers outside the visible clip only when artboard clipping is on.
- Derive document preview warnings after load/edit/Undo, recheck on app activation;
  avoid rescanning unchanged artwork for selection/zoom changes. Export still validates.
- Refresh a thumbnail after its board/artboard/resources change, or retry a failed
  preview after drawing changes. Keep asynchronous rendering cancellation owned by view.

Agent additions extend existing VectorCraftScreenshots commands:
- compact JSON summary: slots, artboards, IDs, bounds, text frames/editability, requested
  and resolved fonts, resource status; omit image/base64 and bookmark capabilities;
- JSON apply/edit from a file or stdin, optional dry run and compact results;
- populated-only bulk PNG/SVG/PDF export through existing ScreenshotExport;
- document the actual file-based workflow and normal-session font discovery. CLI does
  not represent unsaved GUI state or bypass initial macOS resource permissions.

## Acceptance

Focused checks must catch stale preview pixels after replacement, linked-file changes
and Undo, unsupported-data warning refresh, clipping and opacity/alpha correctness,
thumbnail invalidation, atomic CLI failures and byte-preserving dry runs. Preserve
baseline artwork export pixels and native image bytes. Run the same viewport benchmark
and installed interaction/profile on a separate copy; aim for an order-of-magnitude
warm overview improvement, record cold work and memory tradeoffs. Package/install only
after focused correctness passes and coordinated UI release; preserve previous bundle
in Trash. Verify cold reopen, affected editing/Undo/export and original-file hashes.
No overall Illustrator parity or hardware trackpad claim follows from this increment.

## Installed finding

The first updated-app recording exposed missing linked frames after cold relaunch:
20 of 21 frame nodes in the original CLI-authored document have verified paths but
no per-file bookmark. The existing library bookmark restores only catalog access;
its scope was released immediately. Keep that already-approved scope for the editor
lifetime, shared across dock/floating views, refresh warning/thumbnail state after
restoring or choosing it, then repeat the profile with all resources available.
No new grant, document rewrite or security bypass is required. Native cold-reopen
proof is required because an unsandboxed unit test cannot establish macOS scope lifetime.
