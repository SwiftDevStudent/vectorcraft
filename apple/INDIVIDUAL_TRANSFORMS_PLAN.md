# Transform Each, Reflect and Shear — 2026-10-18

Continue P05 with working numeric transform workflows. Transform Each scales by
horizontal/vertical percentages, moves, rotates counterclockwise, reflects X/Y and
optionally randomizes each selected root about its own nine-point reference. Groups
remain units. Reflect and Shear operate about a nine-point reference in the combined
selection bounds with horizontal, vertical or custom-angle axes. All dialogs support
live, nonpersistent preview, Cancel, Copy and OK, menus and command search.

Use one atomic DrawingCommand path for preview and commit, including copy IDs,
foreign metadata, geometry/text/gradient handling and isolation enforcement. Repeat
Transform Each using its parameters on each new selected object's reference, and
retain affine repeat for Reflect/Shear. Failed, canceled, invalid or stale previews
must not mutate the document, register Undo or change repeat history. A native
document snapshot changed while a dialog is open must be protected at commit.

Verify deterministic geometry with distinct objects and asymmetrical paths, nested
groups/copies, every reference point, angle signs/custom axes, seeded randomness,
atomic invalid/scope failures and native/legacy round trips and SVG/PDF. Native tests
must prove preview versus saved data, cancel/commit/copy/Undo/Redo/repeat and stale
snapshot rejection. Build and install with Xcode 27.1 RC, then check the canonical
Mac dialogs, live canvas, menu/search/shortcut, save/reopen and SVG interoperability.

Preserve existing appearance, document data, original Rust app/source and unrelated
work. No new assets/dependencies, system access, iPhone work or publication. Remaining
depth includes absolute scaling, scale strokes/effects/corners, pattern-only transforms,
canvas Reflect/Shear tools and arbitrary origins, rotation-aware boxes, frame-reflow
repeat, distribution, hardware feel, accessibility and performance.

Public references: [Scale Multiple Objects](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/scale-multiple-objects.html),
[Rotate Individually](https://helpx.adobe.com/illustrator/desktop/manage-objects/arrange-objects/rotate-multiple-objects-individually.html),
[Reflect Along an Axis](https://helpx.adobe.com/illustrator/desktop/manage-objects/arrange-objects/reflect-objects-along-an-axis.html),
[Shear Objects](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/shear-objects.html).
Local behavior: `crates/engine/src/cmd/menucmds.rs`, `cmd/object.rs` and
`crates/ui-egui/src/dialogs/transform_each.rs`. No Adobe bundle or asset is used.

## Outcome

The bounded command/dialog increment is implemented and installed. Final release
tests pass 45 core and 38 native checks, including nine reference-point cases,
custom-axis directions, seeded random consistency, nested copies/legacy native data,
preview/cancel/commit/Undo, repeat on different objects, protected reflected text and
stale-snapshot rejection. A follow-up valid-isolation command case also passes.
The first compile caught a missing MainActor annotation on the new test fixture;
the corrected test also exercises the canvas's reflected-text guard directly.

Installed shortcut/search/menu, Cancel, Copy, Transform Again, left-reference reflection,
custom/horizontal shear, invalid 90° shear disabling, Undo/Redo, native Save/relaunch/
reopen and SVG interoperability passed. Native inspection confirms originals, fresh
IDs, foreign metadata and exact seven-object geometry. CUA captures the sheet itself
while open; preview payload/atomicity is tested natively, but the live canvas behind
the sheet was not directly captured. Committed/restored canvas states were inspected.
Logs, installed hash and local artifacts are in `VERIFICATION.md`.

No assets, dependencies, system access, Rust changes, iPhone work or publication.
The remaining P05 and broad performance/accessibility/hardware boundaries above stay open.
