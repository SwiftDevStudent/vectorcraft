# Transform modifier increment — 2026-10-18

Continue the active full Mac parity goal (P04/P05). The existing eight visible
bounding-box handles should all resize; Shift-drag must retain selected artwork,
constrain movement to horizontal/vertical/45-degree lines and preserve that line
when grid/smart snapping attracts the artwork. Shift-click without a drag still
toggles selection. Option-move creates a transformed copy as one command/undo step.
Preview must show both original and selected copy, with release modifiers deciding
the final command. Escape leaves document data intact.

Resize uses the opposite handle by default, the selection center with Option and
proportional dimensions with Shift. Rectangular area text continues reflowing at its
original font size. The Rotate tool uses 45-degree increments with Shift and copies
with Option. All operations preserve source data, stacking, IDs and native format;
new copies receive distinct IDs. Validate focused native event regressions before
and after, geometry/copy boundaries, installed modifier workflows, Undo/Redo,
save/reopen and SVG interoperability. No new assets or dependencies are needed.

Public behavior references: [duplication](https://helpx.adobe.com/illustrator/desktop/manage-objects/edit-objects/duplicate-objects.html),
[scale](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/scale-objects.html),
[rotation](https://helpx.adobe.com/illustrator/desktop/manage-objects/arrange-objects/rotate-objects.html),
[movement](https://helpx.adobe.com/illustrator/using/moving-aligning-distributing-objects.html).
The owning local Rust selection/bounding-box code is another clean-room project
reference. Xcode remains pinned to 27.1 RC; no Xcode service access changes.

Remaining work includes rotation-aware bounding boxes, custom origins, cursor and
stationary-modifier feedback, Transform Again/Each, reflect/shear, distributions,
and complete selection/isolation behavior. This increment does not complete P05.

Outcome: all 37 core and 23 native release tests pass. Five native tests failed
against the prior behavior before the fix. Installed Shift-click, side-handle resize,
Duplicate through the shared copy command, Undo/Redo, native save/relaunch/reopen and
SVG interoperability passed. CUA cannot hold a modifier through a drag; exact
modifier-drag workflows are covered by real AppKit event tests, with hands-on
verification still open. See `VERIFICATION.md` for artifacts and the installed hash.
