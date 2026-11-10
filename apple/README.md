# VectorCraft Swift for Mac

A native SwiftUI/AppKit editor, installed locally as `/Applications/VectorCraft Swift.app`.
The original Rust app remains at `/Applications/VectorCraft.app`. This is an initial
Mac port; the Rust application's feature scores in the root roadmap do not describe it.
iPhone implementation is deferred until the Mac phase is complete.

The Swift branch uses the stable Rust **v0.23.0** baseline (`5d0e892e`). The
[verification record](VERIFICATION.md) covers native compatibility and the prior
G2-signed installation.
PNG/TIFF clipboard input prepares images off the UI actor; installed PNG Paste,
Save, exact Undo/Redo and PNG export pass. Native cold reopen and both CLI readers also reopen the saved result. Full parity stays open.

The port is a [self-contained upstream addition](INTEGRATION.md). Packaging uses
local license/NOTICE files and optional ignored inputs for signing, fonts and local
branding. The portable source bundle excludes private assets/configuration, fonts,
builds, evidence and Cortex notes, and registers licensed assets once in upstream.

The macOS startup gate is now cleared. The corrected screenshot-enabled release is
installed and passes full quit/cold launch, native v4 save/reopen, image/frame access,
canvas text/vector edits, crop/replacement, rotation/reflow, Undo/Redo and PNG/SVG/PDF
export checks. The native Screenshots panel shares the existing document and tools.
SVG/gradient authoring acceptance beyond these screenshot workflows remains separate.
See `VERIFICATION.md` for exact proof and limits. The complete pre-update checkout
remains preserved under `build/preservation-20261029-c41vl6yl/`.

The workspace now follows the Rust app's medium-dark palette, Source Sans typography,
categorized tool strip, document bar, Properties/Layers dock, panel icon rail,
selection bar and bottom hints/status. The Mac UI is implemented in SwiftUI/AppKit.
Unavailable engine features remain disabled and labeled in help. System document,
export and color-picker dialogs remain native macOS interfaces. Text editing stays
on the artboard.

The October31 continuation moves canvas image decoding to serial utility work and
reuses display-sized image pixels for card redraws.20 focused checks plus installed
card refresh, inline text/Save/Undo and workspace fit pass. Packaging uses one nice15
compiler job. Repeated card rendering improved in the bounded comparison; initial
proxy creation was slower. Total cold loading, larger scenes and hardware feel remain
open. See `VERIFICATION.md` for both measured benefits and limits.

## Screenshot workspace

Choose **Screenshots** beside Properties and Layers, then **Add Row** for iPhone,
iPhone Duo or iPad. Each row shows ten numbered slots in the canvas and inspector;
click an empty slot to activate it. Composition cards show each board and its selected
state. Use **Insert Screenshot…**, **Device Frame**, crop controls and **Rotate Artboard**.
Select multiple image files to replace the target and fill following empty slots in
one Undo; occupied following slots stay intact. Right-click a populated card for
**Move to Slot** or **Swap with Slot**. Selected-board controls stay above the row list;
expand **Image Crop** for crop values. Card/Finder drop support is implemented and
provider-tested; final installed drag acceptance still needs a hands-on check. Duo output display and orientation are per
slot; choose an original frame pose separately. Local frame bookmarks reopen after
an app restart. Same-size replacements retain crop and native pose.

**New Slots** chooses the starting layout; **Layout** changes the selected screenshot.
Both open a visual five-choice gallery with the current choice marked. Its lightweight
schematics show placement without decoding project images. A New Slots choice affects
future slots; choosing Layout applies one native Undo step to the current screenshot.
Headline, Minimal, Split, Phone Off Top and Phone Off Bottom are available. Edge crops
stay within one exported screenshot. Text, paths, layers and colors use the ordinary
editor, native Undo/Redo and `.vectorcraft` saving. Canvas artwork is clipped to its
viewport and zoom transitions are smoothed; panning keeps its previous movement.
**Clip to Artboards** hides outside phone artwork in the preview while preserving the
complete editable geometry.

**Export Used** writes PNG, SVG or PDF for populated/included slots and skips unused
slots. **Include in Export** provides an explicit override for custom artwork. Each
export uses its board's own artwork; neighboring cropped phones cannot bleed into it.
The installed workflow exported slots1 and8 only in all three formats. PNG/PDF include
the original frame; SVG links the local original and is not self-contained. Language
stores metadata rather than translating text. See `VERIFICATION.md` for current proof.

## Agent operation and preview performance

The existing `VectorCraftScreenshots` CLI now provides structured scene summaries,
JSON edits from stdin, dry runs, compact mutation results and populated-only bulk
exports. See [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) for the supported commands,
coordinate/slot conventions, atomic-write behavior and font/resource requirements.
It operates on saved documents; live unsaved-GUI control remains open.

Canvas previews use a per-editor, resolution-aware ImageIO cache, decode off the
main actor with visible loading status and keep an existing image during zoom. They skip offscreen
screenshot layers when artboard clipping is enabled, reuse document warning results
and update thumbnails only when affected. Exports still resolve original resources
and validate freshly. The 21-board Smartlist benchmark and installed-app evidence
are recorded in [VERIFICATION.md](VERIFICATION.md); cold completion time, larger scenes,
hardware gesture feel and broad performance budgets remain separate checks.

## Editing

- Rectangle, ellipse, polygon, star and line tools; freehand pencil and cubic Bézier pen.
- Whole-group Selection/marquee, direct leaf selection, Shift multi-selection, constrained movement, copy dragging and eight resize handles.
- Node and handle dragging, smooth/corner conversion, path closure and anchor deletion.
- Fill, stroke, stroke width, opacity, numeric position/size, rotation and alignment controls.
- Inline point/rectangular area text, wrapping, overflow indication and frame reflow.
- Layer visibility/locking, naming, groups, nested group/layer isolation, duplication and stacking order.
- Native document windows, Undo/Redo, Save/Open, fit, trackpad navigation and a resizable inspector.
- Native artwork Copy/Cut/Paste, Paste in Place/Front/Back, editable external SVG input and SVG/PDF clipboard representations.
- Command search (⌘K), Home artboard presets, rulers/grid, zoom and eyedropper tools.
- Draggable Tools and Properties/Layers palettes, docking, workspace grid and reset.
- Artwork grid snapping, edge/center smart guides and native trackpad snap feedback.
- Nine destructive Pathfinder operations and editable compound paths with fill rules.
- Transform Each, Reflect and Shear dialogs with reference points, preview and copies.
- Linear/radial fill and stroke gradients, editable stops, angle/aspect controls and a canvas annotator.

**Gradient (G)** draws or adjusts a gradient on selected paths/compound paths.
Drag endpoints or stop markers; Shift constrains the ramp, and grid/smart-guide
snapping includes its origin and endpoint. Escape cancels a preview. Double-click
the ramp to add a stop. The Gradient panel targets Fill/Stroke, applies Linear or
Radial, reverses colors, changes angle/radial aspect, and edits stop color, location
and opacity. Delete with Gradient active removes the selected stop; at least two
remain. Native commands preserve other appearance items and foreign fields.
Linked stops/swatches, complex paints and text are refused for gradient authoring.
Freeform/mesh/focal/midpoint/stroke-mode depth, mixed-value UI and installed workflow
proof remain open. Transparent gradients differ from the preserved Rust renderer;
see the measured qualification in `VERIFICATION.md`.

**Edit → Copy/Cut/Paste** uses the macOS clipboard. Ordinary Paste centers copied artwork
in the visible canvas; **Paste in Place** (⇧⌘V) preserves its position relative to the
active artboard. **Paste in Front** (⌘F) and **Paste in Back** (⌘B) insert beside the
selected object, or at the current container's top/bottom. Referenced native resources
travel with the art; conflicts are renamed without replacing destination definitions.
Inline text and inspector fields retain character clipboard behavior. Plain text pasted
onto the canvas becomes editable point text. SVG clipboard data and SVG XML text use
the same editable importer as File → Import SVG. External PDF/image input, all-artboard
paste, Remember Layers, threaded-text clipboard and cross-profile conversion remain open.
Opaque native art can be pasted at its original coordinates when repositioning is unsafe.

Hold Shift while dragging to constrain movement to horizontal, vertical or 45-degree
lines; snapping stays on that line. Hold Option while moving to copy the selection
in one undo step. All eight bounding-box handles resize: Shift preserves proportions
and Option uses the center. Rectangular area text reflows at its existing font size.
The Rotate tool uses Shift for 45-degree steps and Option to rotate a copy. Release
modifiers determine the committed result; Escape cancels a preview. Modifier paths
pass native event tests; hands-on trackpad/modifier feel remains unverified.

**Object → Transform → Transform Again** (⌘D) repeats the last affine move, resize,
rotation or copy drag on the current selection. It also repeats Transform Each
parameters around each selected object's own reference point, and is available in command search.
Duplicate remains an explicit action. Repeat history belongs to the open document
session and resets on reopening; it is disabled during inline text editing. Resizing
an area-text frame clears history until frame-reflow repetition is implemented.

**Object → Transform → Transform Each…** (⌥⇧⌘D) scales, moves, rotates and reflects
each selected object or group about its own reference point. Random uses a stable
seed so preview and commit agree. **Reflect…** and **Shear…** use the combined
selection's reference point with horizontal, vertical or custom-angle axes. Positive
Transform Each rotations are counterclockwise. Choose **Copy** to retain originals,
**OK** to apply, or **Cancel** to discard preview. Stroke weights stay unchanged;
absolute scaling and stroke/effect/corner/pattern options remain unimplemented.

**Select** targets whole groups; **Nodes** reaches their individual paths and anchors.
Double-click a group to isolate it, then double-click a nested group to go deeper.
**Object → Enter Isolation** and the Layers context menu also isolate a selected
group or layer. The breadcrumb buttons, **Exit Isolation**, or Escape on the canvas
return through the hierarchy. Outside artwork dims; selection, new artwork, commands,
snapping and Layers stay within the active container. Native saving and export retain
the full document at normal opacity. Isolation belongs to the current editor and
is not saved in the document. Single-object isolation remains unimplemented.

Use **Type (T)**: click for point text or drag a wrapping text frame. Double-click
existing supported text to edit directly on the artboard. Return inserts a line;
Escape or ⌘Return finishes. Save includes current typing without dismissing the editor.
Font/size controls are in Properties and Character. Resize an axis-aligned area frame
using its corner handles or Properties to reflow text without scaling the letters.

Drag the grip above Tools or Properties to float the palette inside the editor.
Use its Dock button or double-click the grip to dock again; **Essentials → Reset
Workspace** restores both. Positions belong to the current window and are not saved
as custom workspaces. Palettes cannot move outside the document window.

**Essentials** also provides independent **Grid**, **Snap to Grid** (10 document
points), **Smart Guides**, **Snap Palettes to Grid** (8 window points) and **Snap
Haptics** toggles. Smart Guides and palette snapping start enabled; artwork grid
snapping starts disabled. Hold Control during a drag to place freely. Smart Guides
use a six-screen-point radius; grid spacing stays fixed in document coordinates.
Nearby smart-guide alignment takes priority over the grid on each matching axis.
Snap feedback uses AppKit’s alignment filter and respects the current device and
system preferences. Physical trackpad feel still needs hands-on verification.

Use the **Pathfinder** panel, **Object → Pathfinder**, or command search to Unite,
Minus Front/Back, Intersect, Exclude, Divide, Trim, Merge or Crop selected sibling
paths. Curves remain editable; Divide/Trim/Merge/Crop create groups. Empty-area
results leave the document unchanged and show an error. Outline/Trap, live compound
shapes and group/cross-container operands remain open.

**Object → Compound Path → Make** (⌘8) uses the backmost path's appearance.
Choose Nonzero Winding or Even-Odd in Pathfinder; **Nodes** edits constituent anchors.
**Release** (⌥⇧⌘8) produces paths with the compound's current appearance. Native Save
retains constituent metadata. **Edit → Select All** (⌘A) follows native focus: artwork
on the canvas, characters in inline text, or contents of an inspector text field.

**Insert → Text…** and **Object → Edit Text…** also open in-canvas editing.
Click to place pen anchors, drag to create handles, then press Return to finish or
click the first anchor to close. Escape cancels an unfinished path. Space temporarily
pans; Option-scroll and trackpad pinch zoom. The Tools menu lists keyboard shortcuts.

## Documents and export

Open `.vectorcraft` and legacy `.drawcraft` documents, including versions 1–4 and
gzip-compressed documents. New documents use v4; native saves preserve a loaded older
format/version. V4 saves write JSON followed by its binary resource section for new
images/profiles of at least 8 KiB. Existing resource offsets, opaque binary bytes,
document trees and unknown fields remain intact. Clipboard resources become independent
of the source arena. Saves are uncompressed, update the generator and discard stale
cached preview/PDF data. Unused arena bytes are retained to preserve foreign references;
resource compaction and choosing a different save version are not implemented. Files and decompressed input
are limited to 64 MiB, with bounded nesting, node counts and geometry.

The macOS document system coordinates file reads/writes and provides native Save/Open
locations, including iCloud Drive. No private iCloud container or account provisioning
is required for saving there. Cross-device synchronization has not been verified.
Save and Save As wait asynchronously for pending native document activity; canceling
a save dialog permits another attempt. Open Recent uses AppKit's recent-file history.
Fit follows the loaded artboard and geometry edits while manual pan/zoom is preserved.
Native Share and broader recovery/version/cloud workflows remain unverified or unavailable.

**File → Import SVG…** creates a new native document with editable supported paths,
shapes, groups, local references, transforms, simple CSS, solid/gradient paint,
strokes and simple point text. SVG arcs become cubic segments; nonuniformly transformed
strokes become editable outlines. Physical SVG units map to document points. Import
and external SVG Paste share the same parser and fail atomically on detected unsupported
content, including images, filters, masks, clipping, nested viewports, styled text
spans and text paths. Sources stay unchanged, and Save uses a new native destination.
DTD/custom entities and external resources are refused. Input is limited to 8 MiB,
with bounded nesting, nodes, expanded geometry and style work. SVGZ, broader SVG/CSS,
PDF/AI and image import remain open.

**File → Export** provides PNG, SVG and PDF for the current artboard. Supported artwork includes paths,
compound paths, embedded bitmap images, solid paint, basic linear/radial gradients and outlined point/rectangular area text.
PNG uses a white artboard; SVG retains transparency. SVG/PDF text is exported as glyph
outlines. Large PNG output is bounded to 32 megapixels and 16,384 pixels per side.

Imported artwork may contain features this port cannot faithfully display: unsupported image data,
placed documents, meshes, effects, masks, blends, special strokes, advanced gradients, color profiles,
or advanced typography (including paragraph formatting and character strokes).
A **Limited Preview** notice lists detected limitations and
blocks artwork export. Native saving retains the source data. Editing unsupported
rich/path/vertical text and unsupported area frames is refused rather than flattening
them. Skewed/reflected text remains protected from inline editing.

Remaining major gaps include broader SVG/CSS and PDF import, deeper clipboard interoperability, advanced path
operations, image editing, advanced gradients/meshes, advanced typography and the wider
Rust command/MCP surface. Large-document performance and broad accessibility testing
remain open. This build requires macOS 27. The current toolchain is Xcode 27.3 beta 1, build `27C5020n`, at `/Applications/Xcode-27.3.0-Beta.app`.

## Build and verify

Open `Package.swift` in the selected Xcode, or run from the repository root:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.3.0-Beta.app/Contents/Developer
xcrun swift test --package-path apple -c release --jobs 1
apple/Scripts/package-app.sh release
apple/Scripts/install-app.sh '/absolute/path/from/package-output/VectorCraft Swift.app'
```

Packaging creates a fresh bundle under `apple/build/` and signs it with the owner's
approved Developer ID Application G2 certificate for Bizit LLC (Apps), Team `Z5F6B8QVKJ`,
SHA-1 `2F726FB7158503B1340F4F88E1CCA27116E23DB0`. It enables hardened runtime and
requests a secure timestamp, retaining App Sandbox and user-selected file access.
This does not notarize or publish the app. Installation requires the Swift app to be
quit, preserves the previous bundle in a unique Trash location, and registers the
canonical `/Applications/VectorCraft Swift.app`. It preserves the Rust application.
Set `VECTORCRAFT_BUILD_ROOT` to use a different SwiftPM build cache.
Compilation uses one job at nice15 so the Mac can favor
interactive work. Run only the affected tests while continuing on a busy machine;
avoid overlapping a build, an export batch and a profiling capture.

The shared core uses Foundation, CoreGraphics, CoreText and the system zlib; no new
third-party dependency or repository font file was added. Packaging reuses the Rust
app's existing licensed Source Sans fonts and process-scoped registration. The vector
PDF workspace glyphs derive from the existing attributed SVG icons; regenerate them
with `Scripts/prepare-workspace-icons.py --cli /absolute/path/to/vectorcraft-cli`.
The Mac target owns UI state and native
document/undo integration. Persistent edits enter through `DrawingCommand` and commit
atomically through `Drawing.perform` and `CanvasDocument.execute`.

See [VERIFICATION.md](VERIFICATION.md) for the installed-app checks and their limits,
and [ILLUSTRATOR_PARITY.md](ILLUSTRATOR_PARITY.md) for the broader Swift product target
and remaining gaps.
The [Vectorify provenance record](Resources/VectorifyIcons/PROVENANCE.md) covers the
reused icon; redistribution rights must be resolved before publication. This task has
not changed Xcode service access or added global MCP configuration.
The full Mac Illustrator-parity goal is active; iPhone work follows the Mac phase.
