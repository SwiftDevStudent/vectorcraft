# Screenshot card previews — 2026-10-31

The installed Oct30 sample (`build/cold-previews-20261030/ui-loading.sample.txt`)
shows a utility worker decoding full PNGs inside `ScreenshotPreview.png`, alongside
the canvas preview worker. Cards are only128px tall. Serial scheduling limits
concurrency but still repeats original-image decoding for each shared phone frame.

Pass an optional image-preview cache through the existing PNG renderer. Keep nil
as the export default. Give the already-serial per-editor ScreenshotPreview actor
one synchronous cache, using the existing resolution buckets, resource/blob and
linked-file invalidation. No new cache policy, global coordinator or dependency.
Cards can use downsampled image pixels; stored originals and full-resolution exports
must remain unchanged. Geometry, screen clipping, order and cancellation stay intact.

Verify the real raster replacement/Undo path, source-image preservation and current
thumbnail tests. Record one before/after comparison of three representative local
Smartlist-copy cards, plus original-export byte identity. Then verify the installed
signed app with the copy, card loading, zoom and native edit/Undo/Save. A shorter
first canvas draw does not establish complete loading time or hardware smoothness.

Use verified Xcode27.2/27B52, one compiler job at nice15 and sequential measurement.
No long trace, new permission, user-document edit, Rust change, worktree, commit,
publication or iPhone work. Keep the previous signed installation recoverable.
