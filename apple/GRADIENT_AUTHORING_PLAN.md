# Editable gradients — 2026-10-19

Tracking: `issue_01m59a449aqcnfnn62ce7f4sah`, under VectorCraft Swift.

P13 currently previews/imports gradients but cannot author them. Add working fill and
stroke gradient controls in the existing panel rail and Gradient tool. Use native
linear/radial paint data, targeted atomic commands and the existing canvas
preview/commit/Undo path. Preserve other appearance items, stroke settings, node
opacity, foreign data, document compatibility and the Rust workspace appearance.

Acceptance: apply linear/radial gradients to supported paths/compound paths and group
members; edit stop colors, opacity and position, add/remove stops, reverse colors,
change angle and radial aspect. Draw/reposition the annotator on canvas, use snapping
and Shift constraints, and commit one undo step per gesture; Escape discards preview.
Panel edits and canvas geometry share the command implementation. Validate malformed,
locked, outside-isolation and unsupported-content requests atomically. Existing complex
paint/text must not be flattened into a simpler gradient.

Verify command geometry/pixels, preservation, limits and native/legacy roundtrips;
AppKit events and native Undo/Redo; affected SVG/PNG/PDF exports; then the canonical
installed app, save/relaunch/reopen and current/source appearance comparison. G2 signing
is independently waiting for the owner's Keychain prompt; keep that process alive.
Installed proof is pending until signing access becomes available. Freeform gradients,
meshes, midpoint/focal/stroke modes, linked swatches and broad accessibility/performance
remain part of full parity and must not be described as complete.

Public behavior reference (viewed October 19):
https://helpx.adobe.com/illustrator/desktop/paint-and-fill/create-and-edit-gradients/gradients-overview.html
SVG geometry: https://www.w3.org/TR/SVG2/pservers.html

Current evidence: all 73 Core and 55 native tests pass on Xcode 27.2 build 27B5038j.
Native v1/v3 and SVG fixtures render in the preserved Rust CLI. Native geometry
completeness, ordered stops/selection tracking and both grid-snapped ramp endpoints
are covered mechanically. Variable-opacity reference differences are qualified in
VERIFICATION.md. The current production package is staged at build/package.PuivVG;
interactive G2 signing and the installed workflow checks remain required before this
increment can close. Freeform/mesh/advanced gradient scope is unchanged.
