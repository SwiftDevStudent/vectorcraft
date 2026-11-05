# Snapping and trackpad interaction — 2026-10-18

Acceptance: artwork uses a 10-point document grid when Snap to Grid is enabled.
Movement snaps the selected bounds' origin (including artwork starting off-grid),
preserves multi-object relationships, previews live and commits the same position.
Shape/text-frame creation, pen anchors, node movement and corner resize use the
same coordinate policy. Freehand pencil strokes remain continuous. Smart Guides
show nearby edge/center alignment to visible artwork and artboards with a six-screen-
point tolerance. Selected descendants and hidden ancestor content do not attract
the moving selection. Control bypasses snapping; toggles keep grid display, grid
snapping, smart guides, palette snapping and haptics independent.

Floating Tools/Properties positions use an 8-point workspace grid, with window
bounds taking precedence at the edges. Controls, docking and reset remain usable.
Use the existing native scroll/pinch paths for trackpad pan and zoom. AppKit's
alignment feedback filter receives drag events and previous/default/snapped view
positions, and filters haptic requests. Grid quantization itself remains deterministic
for mouse, trackpad and automation; hardware haptic suppression cannot change the
saved geometry. No synthetic-event check proves the physical feel of a trackpad.

References: [Keynote alignment guides](https://support.apple.com/en-mt/guide/keynote/tan738df74cb/mac),
[AppKit alignment feedback](https://developer.apple.com/documentation/appkit/nsalignmentfeedbackfilter),
and the selected RC SDK headers. Apple documents transient center/edge guides and
native feedback when an object reaches alignment. This increment implements these
interactions; relative spacing, persistent document guides, advanced snapping and
all other parity gaps remain in the ongoing product checklist.
