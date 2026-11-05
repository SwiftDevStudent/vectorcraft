# Editable SVG import — 2026-10-18

Tracking: `issue_01m584sax3evbe36z64ra9ekay`. Full Mac Illustrator parity remains active.

Use one bounded Swift parser for File → Import SVG and external SVG clipboard data.
Convert supported art into the existing native Drawing tree; keep its groups, editable
paths/text, appearance and native Undo. Imported files become new native documents,
so Save cannot overwrite the original XML. Keep current native Open/Save ownership,
unsupported native fields, Rust app, workspace appearance and iPhone deferral intact.

Acceptance: SVG M/L/H/V/C/S/Q/T/A/Z paths, shapes, transforms and viewBox mapping,
presentation/inline/simple stylesheet cascade, solid paint, gradients, stroke settings,
group opacity and simple point text. Unsupported visible semantics must cause an
actionable error, not partial/silent artwork. XML never resolves external resources.
Bound bytes, nodes, nesting, expansion, numeric ranges and path work; malformed input
must leave destination artwork and Undo untouched. No new package or raster fallback.

Verify a failing native SVG-only clipboard regression first, then focused parser
geometry/style/render/input tests and native clipboard/isolation/Undo tests. Verify
the installed Import menu, editable results, failed import, Paste placement, Undo,
native Save/reopen and SVG export/Rust CLI rendering. Record exact supported and
remaining SVG semantics in the parity matrix and verification log. Full SVG, CSS,
filters/masks/images and advanced text remain part of the ongoing goal.

Primary references:
- https://www.w3.org/TR/SVG2/paths.html
- https://www.w3.org/TR/SVG2/coords.html
- https://www.w3.org/TR/SVG2/painting.html
- https://developer.apple.com/documentation/swiftui/newdocumentaction
- https://helpx.adobe.com/illustrator/desktop/get-started/learn-the-basics/supported-file-formats.html
