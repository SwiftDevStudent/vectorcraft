# Visual screenshot layouts — 2026-10-31

The current inspector exposes five compositions only through text menus: New Slots
and the selected board's Layout. Make their spatial differences visible in one
reusable compact popover, preserving the existing names and command IDs.

Draw five original vector schematics with the current artboard/device aspect ratio.
Share the existing Core positioning calculation with the real template command,
including phone-off-top/bottom cropping. This avoids raster decoding, filesystem
access or expensive live rendering merely to open a chooser. A selected tile is
visible and accessible; choosing a tile closes the popover. Escape/outside dismissal
must leave the document unchanged. No hover-driven mutations or extra helper copy.

New Slots changes the local default for future Add Row/slot commands. Selected Layout
executes the existing setTemplate command once, preserving native Undo/autosave and
ordinary vector/text editing. Keep resources, blob bytes, unknown native data,
ten-slot population/export semantics and existing frame/crop controls intact.

Acceptance: Core geometry agrees with actual fitted/cropped placement for portrait
and landscape boards; native layout edits/Undo retain resources and unknown data.
Check both installed chooser entry points, read-only dismissal, selection, one-step
Undo, save/reopen and original-resolution export on a synthetic local fixture.
Use existing focused tests and only small targeted regressions. No broad suite or
profiling. Package with verified Xcode27.2/27B52, one nice15 job, install separately
from Rust and retain the previous signed app in Trash. Do not modify either user
Smartlist document or other apps. No worktree, commit/publication, permission or
iPhone work. A visual device-frame catalog remains separate follow-up work.

Installed acceptance exposed an existing selection gap: after activating slot2,
Undo removes its artboard but leaves selectedArtboard at an invalid index, hiding
the selected-board controls. Repair only invalid indices at the editor state owner
when the drawing changes, retaining a valid selection and active content layer.
Cover that exact native Undo transition and repeat it in the installed app.
