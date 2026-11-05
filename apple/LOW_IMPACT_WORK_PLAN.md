# Low-impact Mac continuation — 2026-10-30

The owner resumed work after pausing because it slowed the computer. Keep work
sequential, compile with one low-priority job, reuse the existing incremental cache,
and avoid new profiling recordings or broad repeated suites while the Mac is busy.
Do not alter unrelated system/update/indexing processes or global settings.

First reconcile the completed October 29 checkpoint. Native Export Used finished
before the pause: its 21 PNGs match the CLI's 21 files byte-for-byte. Both saved
Smartlist documents and the performance copy still match their recorded hashes.
Installed package kFG7wX matches executable 368707...60578. Tests and recorded
measurements remain historical evidence; no new benchmark is implied.

The remaining bounded change is thumbnail scheduling. Each visible card currently
starts independent @concurrent full-image raster work. The measured 21-board scene
contains 42 images/184 nominal megapixels; the prior trace showed substantial PNG
decoding on background threads. Use one actor renderer per editor, shared by its
cards, with synchronous raster work inside that actor so jobs cannot interleave.
Use utility-priority card tasks and preserve cancellation before/after rendering.
No global queue/cache, parallel edit engine, resource or export changes are needed.

Success: existing thumbnail pixels/clipping and document/Undo checks pass through
the production actor path; canceled queued work does not render; native cards load
and refresh after an affected edit/Undo in the installed app. Exports retain their
original-resolution path. Do not claim measured latency/memory improvements from
scheduling alone. Wider Mac/Illustrator parity and physical trackpad proof stay open.

Preserve the original Rust app, both user documents, unsupported fields, signing and
entitlements. No worktree, commit/push/publication, permission expansion or iPhone work.

## Outcome

G2-signed package EZblNp is installed (executable04d148...770f). Twelve focused
checks and native two-board load/rotation/thumbnail refresh/Undo/Save passed.
Undo/Save restores the exact fixture bytes. Both user documents and Rust executable
remain unchanged. No new trace, full-suite repetition or batch export was needed.
The test app is quit and no heavy task remains running. Cold-decode work is a separate
follow-up, issue_01m65h65mtcnnhaexbc6qq8nv8. Full parity is still incomplete.
