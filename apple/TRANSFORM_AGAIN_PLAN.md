# Transform Again — 2026-10-18

Continue P05 with a bounded repeat-transform increment. After a successful affine
move/scale/rotate/copy, Object → Transform → Transform Again (⌘D) repeats its matrix
and copy intent on the current selection. Repetition must preserve original artwork,
fresh IDs/metadata for copies, atomic isolation boundaries and one-step native Undo.
Keep explicit Duplicate available without the conflicting shortcut.

CanvasDocument owns transient transform memory, shared by its editors and separate
from native document data. Successful affine transforms replace it; unrelated style
or selection changes retain it. Failed and identity transforms do not overwrite it.
Fresh documents and applied/opened snapshots start without history. A rectangular
text-frame reflow clears affine repeat memory until its distinct frame operation
can be repeated faithfully; affine text transforms remain repeatable.

Acceptance: focused document tests for repeated move/copy and matrix replacement,
Undo/Redo, no-op/failure history retention, isolation rejection, snapshot reset and
native data/export preservation. Add a native canvas Option-drag-to-repeat workflow.
Verify the canonical installed menu/shortcut/search, text-focus disabled state,
native save/relaunch/reopen and SVG output. No new dependencies/assets or core/Rust
changes. Transform Each, reflect/shear, frame-reflow repetition, rotation-aware boxes,
custom origins and distribution remain separate P05 work.

Reference: [Adobe transform behavior](https://helpx.adobe.com/illustrator/desktop/manage-objects/reshape-transform-objects/transform-objects.html)
and the project's `object.transformAgain` command in `crates/engine/src/cmd/object.rs`.

## Outcome

Completed the bounded affine repeat increment. Five new document tests and an
extended native Option-drag test prove move/copy repetition, current-selection
targeting, paint/foreign data preservation, scale/rotation replacement, failed/no-op
history retention, isolation rejection, native Undo/Redo and snapshot reset. The
final release run passed all 34 native tests without warnings. The core is unchanged
after the preceding 40-test pass. One initial fixture used an invalid one-object
Group command; correcting it to a valid two-object group resolved that test failure.

The canonical installed app passed repeated movement via ⌘D/search, numeric width
scaling from 100 to 200 to 400, Undo/Redo, disabled repeat during inline text editing,
Save while typing, quit/relaunch/reopen and history reset. SVG/native interoperability
passed through the preserved Rust CLI, with visual output inspection. Native file
inspection confirms one rectangle (no unintended copies), final coordinates/ID and
foreign metadata, plus the inline text. See `VERIFICATION.md` for logs and package hash.

Copy-drag repetition is proven by native AppKit events; CUA's drag API does not hold
modifiers, so installed hands-on copy dragging and physical trackpad feel remain
unverified. The separate P05 work listed above remains open. No new assets,
dependencies, Core/Rust edits, system permissions, iPhone work or publication.
