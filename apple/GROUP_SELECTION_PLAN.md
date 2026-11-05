# Group selection and isolation — 2026-10-18

Continue P04/P11 of the active full Mac parity goal. Selection clicks and marquees
target whole groups; Nodes reaches leaf paths/compound anchors. Keep Shift toggling,
constrained copy/resize behavior and double-click inline editing for accessible text.
Double-click groups or use Object/Layers commands to isolate groups/layers. Nested
breadcrumbs, Escape and explicit exit controls recover the surrounding workspace.

Isolation is presentation state belonging to the editor window. Dim outside artwork
without altering export or native data. Scope hit tests, Select All, marquees,
snapping, Layers and insertion to the active container. Enforce the same scope at
the document command boundary so stale selection or an outside command cannot edit
unrelated artwork. Drawn paths and point/area text must become real children of the
isolated group; edits retain IDs, unknown fields and world coordinates. Reconcile
deleted, moved, hidden or locked scopes after document changes and Undo.

Acceptance: reproduce group hit/marquee failures before changing code; verify core
selection and command-scope policy, dimmed presentation versus normal export,
native events/insertion/undo and inline text. Verify the canonical installed app's
group movement, nested isolation/exit, creation, save/reopen and SVG interoperability.
No new asset, dependency, system permission, Rust edit or iPhone work is required.

Public references: [selection tools](https://helpx.adobe.com/illustrator/desktop/manage-objects/select-objects/select-transform-objects-selection-tools.html),
[groups](https://helpx.adobe.com/illustrator/desktop/manage-objects/select-objects/select-object-groups-and-nested-object-groups.html),
[isolation](https://helpx.adobe.com/illustrator/desktop/manage-objects/select-objects/isolate-objects.html).
Local Rust selection/hit/isolation commands are another project behavior reference.
Single-object isolation, Group Selection's repeated hierarchy clicks, lasso,
multi-anchor/segment selection and clipping-selection depth remain open.

## Outcome

Completed the bounded group/layer increment. Before implementation, native whole-group
click/drag and marquee checks failed; direct anchor editing already passed. Final
release tests passed 40 core and 29 native checks without warnings, covering scoped
commands/atomic failure, selection, insertion, native Undo/Redo, invalid scope
reconciliation, round trip and pixel-level presentation dimming.

The canonical installed app passed whole-group movement, nested double-click
isolation, scoped Select All, shape/inline text creation, Undo/Redo, scoped Layers,
parent breadcrumb/Escape exits and menu-based layer isolation. Native Save while
typing retained both new objects as children of the inner group, original IDs,
coordinates and foreign fields. After quitting and reopening, all colors and content
remained, with no persisted isolation. SVG exported during isolation retained the
whole document at normal opacity and rendered with the preserved Rust CLI without
warnings. See `VERIFICATION.md` for artifact paths, logs and the installed hash.

No Rust source, assets, dependencies, system permissions or iPhone code changed.
The remaining P04/P11 scope above and broad keyboard/VoiceOver coverage remain open.
