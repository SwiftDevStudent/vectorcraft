# Screenshot slot workflow — 2026-10-29

Keep native vector editing, ten slots per device row, v4/legacy data, local frame
provenance, existing projects and native Undo. Mac first. No Adobe app use, asset
copying, new dependencies, worktree, commit or publication.

This increment makes slots visual and directly editable:
- Small rendered composition thumbnails, numbered empty cards and selected state.
- Drop PNG/JPEG files onto canvas or inspector slots. Multiple files fill the target
  and subsequent empty slots in order; occupied following slots stay untouched.
  Invalid files/capacity errors roll back the entire command.
- Move a board to an empty slot or swap two occupied slots within its device row.
  Keep IDs, image bytes, frame metadata, inclusion state and document unknowns.
- Put selected-board controls above the row list; disclose crop fields on demand.
- Default to a clipped screenshot preview, with a toggle to reveal outside artwork.
  This changes viewport rendering only; retain complete editable device geometry.

Core adds placeScreenshots and moveBoard commands, reached by UI and JSON CLI.
Native drag payloads identify the source document so cross-document drags cannot
mistake matching numeric IDs for local boards. SwiftUI uses data-only native item providers; canvas
uses AppKit file drops. Both enter the same screenshot command path.
Thumbnails use isolated board artwork and a small background render; UI-owned tasks
are cancelled when inputs change or the card disappears, preventing stale previews.

Prove sparse placement, replacement pose, capacity/invalid-file rollback, slot
swap/move preservation, native Undo and rendered thumbnail bounds. Then package,
install and inspect real file drops, rearrangement, saved reopen and export.
Frame-pose automation, larger template catalogs and localization remain later gaps.

Acceptance update: 100 Core + 67 Mac tests pass. Native visual cards, multi-file
picker, menu move/swap, exact Undo/Redo, cold reopen and unchanged populated-only
PNG export pass. Card/Finder gestures remain inconsistent under CUA, so final-build
native drag acceptance stays open. Details: VERIFICATION.md and native-flow-report.json.
