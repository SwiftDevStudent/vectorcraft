# Cold canvas previews — 2026-10-30

Existing evidence: final-ui.trace/exported text attributes about620ms of a recorded
stall to synchronous VectorImagePreviewCache.resolve inside VectorCanvasView.draw.
Warm overview is about31ms, but cold ImageIO work remains on the main thread.
The owner requests continued Mac work with low computer impact. Use the existing
trace, one background compiler job and focused checks; do not start another capture.

Make the canvas request missing preview images without decoding them in draw().
Keep the cache synchronous by default for existing Core consumers. The canvas opts
into deferred loading, collecting deduplicated immutable requests for visible images.
One utility-priority actor per canvas decodes those requests sequentially. The UI
keeps a cached resolution while a better one loads, coalesces pending work to the
latest viewport, and redraws as images arrive. No mutable cache crosses actors.

Publish only if the request still matches current embedded resources/blob bytes and
linked-file identity. Undo back to identical resources can reuse identical pixels.
Cancel work on teardown; remember failed requests until source/access changes so a
failed decode cannot create a redraw/retry loop. Reuse the existing device-library
revision to retry after its approved grant is restored. No new permission is needed.

Deferred preview proxies are capped at4096pixels per side to bound decoded memory;
the existing128MiB cache budget remains. Loading/unavailable status is visible in the
status bar. Stored images and original-resolution exports remain unchanged. Full
resolution inspection beyond the proxy limit remains a fidelity limitation.

Acceptance: cold lookup returns immediately without decoding; background completion
produces correct pixels; stale embedded/linked completions are refused; zoom keeps a
cached image until replacement arrives; offscreen images create no requests; loader
coalescing/cancellation does not publish stale pixels. Verify focused Core/Mac checks,
one bounded bitmap measurement and installed cold-open/zoom/edit/Undo using copies.
Preserve user documents, native unknown data, Rust app, signing and entitlements.
No full suite repetition, worktree, commit/publication, global service or iPhone work.

Toolchain update: the owner changed the required default during this increment.
Stop the27B48 build; use verified Xcode27.2/27B52 at /Applications/Xcode-27.2.0.app.
Historical27B48 evidence remains labeled with its actual toolchain. Personal skills
are maintained separately; no global skill/service/configuration edit is needed here.

After the owner-mandated SDK change, all24 focused checks passed on27B52. Run the
already-built complete suite once with --skip-build as the toolchain migration
release gate; this does not repeat compilation. Keep the test process at nice15.

Packaging startup investigation: the one-second launcher sample shows dyld fixups
before Swift main, about416KiB resident, after several minutes under Darwin
background policy. Retry with nice15 and --jobs1, removing only that extra I/O
policy. No other process, permission, signing or global setting is changed.
