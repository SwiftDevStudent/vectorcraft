# Stable baseline and native Mac follow-up — 2026-11-04

Owner approved updating the baseline to v0.21.0 and deliberately porting relevant
improvements. Starting HEAD was v0.18.0/68b68a30. Target release commit is
11862f61198c8f62c0b22b6c9a331cc5950ac98d; use this stable release, not moving main.

1. Archive all tracked/nonignored local source plus Git metadata, save the dirty
   tracked patch and file hashes, then verify the archive. Keep existing2.6GB of
   ignored build/evidence material in place. Fetch the exact release ref, inspect
   collisions/removals, and preserve any needed local assets before fast-forward.
   Stash only the dirty tracked files, retain that stash after applying, and merge
   local provenance/Swift status with upstream docs if necessary. No source commit,
   publication, branch/worktree or installed Rust replacement.
2. Inspect the new shared format contract and verify native/legacy/gzip/v4 resources
   with focused Swift checks and pinned upstream format evidence. Preserve unknown
   fields, original pixels, existing documents and supported export behavior. A schema
   still numbered4 does not by itself prove interoperability.
3. Review relevant upstream changes. The inspected Swift clipboard accepts native
   artwork/SVG/text but no bitmaps. Implement a bounded native image-paste path with
   decoding outside the UI actor, canonical document commands and Undo, if the
   upstream/core inspection supports that shape. Keep text responder ownership,
   placement and isolation semantics. Progressive Rust GPU upload has no direct
   counterpart in the CoreGraphics canvas; do not invent a renderer rewrite.

Development uses verified Xcode27.3 beta1/27C5020n at
/Applications/Xcode-27.3.0-Beta.app. Keep each build at nice15/--jobs1 and heavy checks
sequential. Run focused checks first; a new-SDK release gate may use the already-built
full Swift suite once. Verify the signed canonical Mac app and copy-only save/reopen/
Undo/export for the affected path. No long trace, global skill/service/permission,
iPhone, cloud or TestFlight work. Historical27.2 proofs retain their real toolchain.
