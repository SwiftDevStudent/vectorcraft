# Pathfinder and compound paths — 2026-10-18

This is an increment of the active full Swift Mac parity goal (P09/P11), following
the verified snapping work. It does not complete those feature families.

Acceptance: real Unite, Minus Front/Back, Intersect, Exclude, Divide, Trim, Merge and
Crop commands operate on selected sibling paths/compound paths in paint order.
Region geometry retains editable curves and honors each source fill rule. A new
result occupies the frontmost selected position while unrelated siblings stay put.
Unite/Intersect/Exclude take front styling; subtraction keeps its surviving source.
Divide creates disjoint editable faces with the frontmost area owner's styling.
Trim/Merge/Crop remove strokes; matching fills merge after hidden areas are removed.
Empty-area results report an error atomically. Bounds, sampled regions/paint, holes,
styles, locks, native format, Undo and export provide the acceptance evidence.

Compound Make preserves original constituent data and takes backmost appearance.
Nonzero/Even-Odd fill rules are explicit. Constituents remain editable through the
Nodes tool; Release produces individual paths using the compound's current style.
Menus, command search and the existing Pathfinder rail/panel reach the same commands.
No proprietary artwork/icons or additional package is required: Core Graphics ships
curve Boolean operations in the selected SDK. Test output complexity is bounded;
large-document performance is a separate remaining verification gate.

References: [Pathfinder panel behavior](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/pathfinder-panel-overview.html),
[compound paths](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/create-compound-paths.html),
Core Graphics `CGPath` Boolean/normalization APIs and the owning Rust commands/tests.
The source `plan/` directory remains absent. Outline/Trap, live compound shapes,
group/cross-container operands and richer precision/settings behavior remain open.

Outcome: release tests passed 34 core and 14 native tests. Installed panel/menu/search,
compound shortcuts, even-odd holes, constituent anchor dragging, Undo, native
save/relaunch/reopen and SVG rendering through the preserved Rust CLI passed.
Detailed artifacts, executable hash and boundaries are in `VERIFICATION.md`.
