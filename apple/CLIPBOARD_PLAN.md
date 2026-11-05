# Native artwork clipboard — 2026-10-18

Tracking: Cortex `issue_01m581mqmrnh49rncqk914yqc8`. The full Mac parity goal remains active.

Copy selected artwork roots in paint order, retaining descendant and foreign fields and
only referenced resource definitions. Paste allocates fresh IDs and merges resources
without overwriting the destination; conflicting names are renamed and references follow.
Use bounded native decoding for untrusted pasteboard data. Cut and paste enter the atomic
document command/Undo path. Text editors retain normal AppKit clipboard behavior.

Ordinary Paste centers artwork in the canvas viewport; Paste in Place keeps its position
relative to the active artboard. Paste in Front/Back retains coordinates and inserts beside
the selected object in its parent, or at the current container's top/bottom. Isolation,
inherited locks, cancellation/error atomicity and legacy anchor encoding remain enforced.
Supported artwork also publishes SVG and PDF; opaque unsupported artwork stays native,
and placement that cannot be transformed safely is rejected instead of silently altered.

Verify core resource collisions/closure, paint order, fresh IDs, legacy versions, malformed
input and isolation; native responder focus, independent pasteboards and document Undo;
then installed cross-document copy/paste, stacking, Cut/Undo, Save/reopen and SVG export.

This increment excludes external SVG/PDF/image import, anchor-only copying, Paste on All
Artboards, Remember Layers, swatch-conflict choice UI, cross-profile color conversion and
threaded-text clipboard semantics. Track these as remaining P18/P27/P29 gaps. No new
dependencies, assets, Rust changes, iPhone work or system permissions are needed.

Behavior reference: [Adobe's public paste workflows](https://helpx.adobe.com/illustrator/desktop/manage-objects/arrange-objects/move-or-duplicate-an-object-by-pasting.html)
and [relative stacking](https://helpx.adobe.com/illustrator/desktop/manage-objects/arrange-objects/paste-an-object-relative-to-other-objects.html).

## Result

All 54 core and 43 native release tests pass without warnings. Installed cross-document
shortcuts, stacking, Cut/Undo/Redo, inline/inspector focus, clipboard persistence across
process restart, native Save/reopen and SVG/native Rust-CLI interop passed. See the
2026-10-18 clipboard entry in `VERIFICATION.md` and artifacts in ignored `verification/`.
The source/file/resources retain foreign fields; a focused exact-node regression failed
before fixing reference traversal's extra null fields. Installed QA also found and fixed
stale inspector-focus menu enabling. The P29 increment is complete within the boundaries
above; full Mac parity remains active. P02 cold-open fitting is separately tracked as
`issue_01m582g31eyw1cerjchcx1x37s`.
