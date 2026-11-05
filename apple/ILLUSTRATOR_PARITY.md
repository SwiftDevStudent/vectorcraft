# Swift Illustrator parity target

The owner's product target is Adobe Illustrator feature and interaction parity,
implemented in Swift. The Mac app is an early implementation. Matching the Rust
workspace does not make it feature complete, and the Rust roadmap's percentages do
not describe the Swift port.

## Current behavior

The v0.21.0 source baseline now passes real writer/Swift save/Rust reopen checks for
v1–v4 and gzip-v4.195 checks pass on27C5020n (115Core/76Mac/4CLI). PNG/TIFF
bitmap Paste uses serial utility preparation and canonical Undo; installed PNG menu
Paste, Save, exact Undo/Redo and export pass. Native cold reopen and both CLI readers also pass. Portable upstream integration keeps private inputs separate.


Both New Slots and selected Layout now use a five-choice visual gallery with original
vector schematics and shared Core geometry. Installed default selection, read-only
dismissal, apply/Undo/Redo/save/reopen, selected checkmark and populated-only export
pass. A selected-last-slot Undo bug discovered in this workflow is fixed.14 distinct
focused checks pass across initial12/final8 runs on27B52. The gallery adds no image
decoding or new assets; live composition previews and visual frame browsing remain gaps.

The October31 continuation adds deferred canvas image decoding, cached zoom fallback,
visible loading status and actor-owned display-sized image reuse for cards.20 focused
checks and installed card refresh, inline edit/Save/Undo and workspace fit pass.
One bitmap pair measured2222.6→114.3ms first draw before image completion; repeated
three-card rendering improved464.2→79.7ms, while its first pass was slower605.1→925.8ms.
These are bounded renderer samples, not native loading-time or hardware smoothness
claims. One nice15 build job; total cold completion and larger budgets remain open.

The previous broad pass contained109 core,71 native Mac and4 CLI tests on Xcode
27.2 build27B52. The current v0.21.0/27C5020n gate above supersedes that count.
The corrected G2-signed release now cold-launches and passes installed screenshot
editing, image/frame access, native Save/reopen, Undo/Redo and PNG/SVG/PDF export.
Canvas clipping, smooth zoom transitions and the ten-slot screenshot workspace now
have installed interaction and populated-only PNG/SVG/PDF batch-export evidence.
Phone-off-top/bottom layouts and combined Duo output controls are implemented.
Rendered cards, multi-image placement, menu move/swap and clipped screenshot previews
now have command and installed workflow proof; card/Finder drag acceptance remains open.
Broader SVG/gradient installed acceptance remains separate; no row establishes full parity.

| Area | Swift implementation | Major remaining gaps |
| --- | --- | --- |
| Text | Inline point text; Type drag creates rectangular area text; wrapping, overflow indication, frame reflow, font/size controls, native text input, save and undo | Styled ranges, paragraph controls, arbitrary area paths, threaded frames, text on paths, vertical/CJK, advanced typography |
| Workspace | Rust palette/icons, tools, Properties/Layers, panel rail, movable floating palettes inside each editor, an 8-point workspace grid, docking/reset | Palettes outside the document window, panel groups/tab docking, persistent custom workspaces |
| Selection and drawing | Group-aware Selection/marquee/Select All, direct leaf/anchor selection, nested group/layer isolation, paths, pen/pencil, basic shapes, move/scale/rotate/align, nine destructive Pathfinder operations, editable compound paths/fill rules, artwork grid and edge/center guides, native snap feedback | Single-object isolation, lasso/multi-anchor selection, persistent guides, spacing/tangent/angle snapping depth, full transform suite, Pathfinder depth/Shape Builder, brushes and symbols |
| Paint and rendering | Solid styles; source-tested linear/radial fill/stroke gradient panel/annotator, stop/geometry editing, vector glyph outlines and PNG/SVG/PDF export | Installed gradient proof, freeform/mesh/focal/midpoint depth, transparent-gradient reference differences, patterns/images/masks/blends/effects, advanced strokes and color management |
| Screenshot composition | Rendered ten-slot composition cards, sparse native boards, multi-image placement, menu move/swap, preview clipping, combined Duo output/display rotation, top/bottom phone edge crops, ordinary editor tools and native Undo/v4 save, populated-only PNG/SVG/PDF batch export | Installed card/Finder drag acceptance, expanded template catalog, visual frame catalog, frame-pose automation, localization depth, self-contained SVG frame portability |
| Documents | Compatible native/legacy v1–v4 file trees and binary resources, coordinated Save/Open, unknown data retention, native vector Copy/Cut/Paste and placement with resource merging, bounded editable SVG File/clipboard import, SVG/PDF clipboard output | Broader SVG/CSS, PDF/AI and image import, link depth, print/package, larger real-file corpus |
| Delivery | Separate installed Mac app with focused source/tests/runtime proof | Performance budgets, broad accessibility, device/iCloud sync; iPhone remains deferred |

The owner explicitly started the full-parity Codex goal on **2026-10-18**, Mac first.
The goal stays active across completed increments. Snap geometry is tested and
installed interactions are verified; the physical trackpad feel remains unverified.

## Verification policy

Advance rows through observable behavior, not the presence of menu items. Each
implemented interaction needs focused command/layout tests where useful, then
verification in the canonical installed app with synthetic documents and native
save/reopen/export. Use public behavior documentation and original/licensed assets;
preserve the original Rust implementation and data. Missing capabilities remain
explicit rather than being represented by working-looking controls.

Next work should deepen text formatting, selection/drawing interaction, geometry
operations and file interchange against this matrix. This document is a backlog,
not a completed parity claim or a release plan.

## Feature-family inventory — 2026-10-18

This initial inventory is grounded in the current Swift commands/UI and the Rust
roadmap. Each family must be expanded into individual public behavior references,
workflow cases, edge cases and evidence before it can pass. It is a work queue, not
a percentage or an exhaustive feature count. Nothing below is marked fully complete.
Public reference entry point: [Illustrator desktop help](https://helpx.adobe.com/illustrator/desktop.html).

| ID | Family | Current Swift boundary | Next acceptance work |
| --- | --- | --- | --- |
| P01 | Workspace and tool customization | Partial: matching chrome, floating/dockable palettes | External palettes, tabbed groups, tool ordering, saved/restored workspaces |
| P02 | Canvas navigation | Partial: pan, zoom, rulers, fit follows loaded/edited artboard geometry and preserves manual navigation | Gesture hardware audit, canvas rotation, outline/pixel/overprint views |
| P03 | Grid and smart guides | Partial: grid placement, edge/center attraction, native haptic requests | Persistent guides, relative spacing/sizing, angle/tangent snapping, settings persistence and hardware feel |
| P04 | Selection | Partial: whole-group hit/marquee/Select All, direct leaf/anchor selection, nested group/layer isolation, deferred Shift-click toggling and constrained dragging | Single-object isolation, repeated Group Selection hierarchy clicks, lasso/multi-anchor/segment selection, select-same, saved selections and locked/hidden edge cases |
| P05 | Transform | Partial: constrained move/copy, eight axis-aligned handles, proportional/center resize, text-frame reflow, constrained rotate/copy, Transform Again, individual scale/move/rotate/reflect with reference points and seeded randomness, numeric Reflect/Shear dialogs with preview and Copy, numeric values and alignment | Hands-on modifier/trackpad proof, live preview canvas capture, rotation-aware boxes/arbitrary origins, cursor/stationary-modifier feedback, canvas Reflect/Shear tools, absolute/stroke/effect/corner/pattern transform options, frame-reflow repetition and distribution |
| P06 | Basic/live shapes | Partial: rectangle, ellipse, line, star, polygon | Live corners and shape parameters, arcs, spirals, grids and shape conversions |
| P07 | Pen and anchors | Partial: cubic pen, handles, smooth/corner, delete/close | Add/average/join/split anchors, curvature, segment editing, precise modifier behavior |
| P08 | Freehand and erasing | Partial: pencil path creation | Smoothing/reshaping/extension, eraser, scissors and knife |
| P09 | Boolean geometry | Partial: nine destructive Pathfinder operations, curve/fill-rule preservation, command undo | Outline/Trap, live compound shapes, group/cross-container operands, precision/options and larger geometry performance |
| P10 | Shape Builder and Live Paint | Missing | Regions, edge interactions, gap detection, fill/merge/delete, expansion |
| P11 | Groups and layers | Partial: groups, naming, visibility, locks, stacking, nested group/layer isolation with breadcrumbs, scoped insertion/commands/Layers and transient dimming, compound Make/Release | Single-object isolation, nested layer management, clipping groups and deeper object targeting |
| P12 | Solid paint and swatches | Partial: native color picker and style authoring | Named/global/spot swatches, libraries, color groups and reusable palettes |
| P13 | Gradients and meshes | Partial: source-tested linear/radial fill/stroke authoring, ordered editable stops, angle/aspect, canvas endpoints/stop dragging, snapping, preview/Escape/Undo and v1/v3/SVG interop | Installed panel/tool/save/reopen/export proof; mixed values, links/swatches, midpoint/focal/aspect handles, stroke modes, freeform gradients/meshes, transparent-gradient reference differences and broader fidelity |
| P14 | Strokes | Partial: basic authoring and supported imported stroke rendering | Dash/cap/join authoring, variable width, arrows, inside/outside, outline/expand |
| P15 | Brushes | Missing | Art/scatter/pattern/calligraphic brushes, editing, libraries and expansion |
| P16 | Patterns, symbols and repetition | Missing | Tile editing, symbol instances/overrides, repeat/mirror/radial/grid workflows |
| P17 | Appearance and transparency | Partial: basic fill/stroke/opacity | Appearance stacks, blend modes, opacity/clipping masks, style reuse and expansion |
| P18 | Point/area text interaction | Partial: inline single-style text, rectangular wrapping, overset/reflow | Styled ranges, text selection/transform fidelity, advanced area geometry and threading |
| P19 | Typography | Partial: font and size | Paragraph composer, spacing/kerning/leading controls, OpenType, glyphs, text styles and outlines |
| P20 | Text paths and international composition | Missing | Text on paths, vertical/CJK, complex scripts, RTL/multilingual and IME coverage |
| P21 | Images and links | Partial: embedded native image rendering, transforms, clipboard and PNG/SVG/PDF output; screenshot-specific placement/cropping and local linked frames | General Place/Embed/Relink UI, image/link lifecycle, resolution, color fidelity and broader formats; installed image proof |
| P22 | Image tracing | Missing | Raster-to-vector trace settings, preview, expansion and output quality |
| P23 | Blends and envelopes | Missing | Blend steps/spines, envelope creation/editing, warp and expansion |
| P24 | Effects and filters | Missing | Live vector/raster effects, effect ordering, expansion and export fidelity |
| P25 | Perspective and 3D/materials | Missing | Perspective planes/transforms, 3D/extrusion/revolve, lighting/materials and rendering |
| P26 | Artboards and document setup | Partial: presets, imported boards, selected-board resizing | Add/move/duplicate/reorder boards, bleed, multiple-board output, templates and units |
| P27 | Import | Partial: native/legacy v1–v4, bounded binary resources and gzip; editable SVG paths/arcs/shapes/groups/local references, transforms/viewBox, simple CSS, solid/gradient paint, strokes and point text | Broader SVG/CSS, SVGZ, clips/masks/filters/images, rich/path text, nested viewports/symbols, PDF/compatible AI, EPS, CAD and image import with disclosed fidelity boundaries |
| P28 | Export, print and packaging | Partial: current-board PNG/SVG/PDF | Export for screens/assets, board ranges, PNG background/options, print, package, PDF standards and format breadth |
| P29 | Clipboard and interoperability | Partial: native cross-document Copy/Cut/Paste, viewport/in-place/front/back placement, fresh IDs and referenced resource merging, SVG/PDF clipboard output, editable external SVG data/XML, PNG/TIFF bitmap input with serial utility preparation, plain text insertion, focus-aware native editing and Undo | Broader external SVG/PDF/JPEG/other bitmap input, all-artboards paste, Remember Layers, anchor-only and threaded-text copying, cross-profile conversion, conflict-choice UI, complex live kinds, link behavior and wider multi-app fidelity |
| P30 | Color management and production | Missing | Profiles, CMYK/spot/separations, proof/overprint, color conversion and preflight |
| P31 | Data and automation | Partial: saved-document CLI summary, screenshot/native edit batches, stdin/dry-run and populated-only bulk export | Live unsaved-document control, broader command/MCP parity, variables/data merge, graphs and actions |
| P32 | Generative and assisted workflows | Missing | Publicly documented user workflows, service/model requirements, editable outputs and provenance |
| P33 | Document lifecycle and collaboration | Partial: coordinated native Save/Open/undo, queued Save/Save As with cancellation/retry, Open Recent | Native Share, broader recovery/versioning, multi-window conflicts, cloud sync/collaboration behavior and evidence |
| P34 | Accessibility and shortcuts | Partial: labeled controls, basic tool/menu shortcuts, compound shortcuts, focus-aware native Select All | Complete keyboard flow, VoiceOver, contrast, modifier parity and configurable shortcuts |
| P35 | Performance and reliability | Partial: focused input/format checks; measured deferred canvas previews, cached zoom fallback, serial cached card images, offscreen culling and warning reuse | Total cold completion time, broader scene/cache budgets, extreme-zoom proxy fidelity, hardware drag/zoom latency, memory, fuzz/real-file corpora and recovery |

Current priority is completing the remaining installed P27/P29 SVG and P13 gradient
workflows, including the recorded transparency qualification. Signing, cold launch
and installed native v4 screenshot workflows now pass. Next address P04/P05/P09,
P18/P19 and P03 interaction depth plus P12/P13. Reorder when
actual workflows expose a more important gap. Every increment must leave real controls,
native state, undo and affected exports consistent; unsupported data remains intact.

## Upstream compatibility — 2026-10-29

The checkout now uses exact v0.18.0 commit `68b68a30`, with the complete earlier
checkout archived and all overlapping local additions preserved. Swift supports v4
JSON/binary resources and gzip input within its existing 64 MiB/128-level bounds.
New documents use v4; loaded v1–v3 retain inline resources and their original version.
Images/profiles/unknown arena bytes survive native saving. Known ranges are validated
without copying each alias; clipboard images/profiles no longer depend on source offsets.

The official checksum-verified Rust 0.18.0 CLI wrote gzip v4 and inline v3 files.
Swift read, edited, exported and saved the v4 file; Rust reopened and rendered it
without warnings. Extracted PNG bytes and Swift native-image pixels match the original.
Rust's raster image filtering and transparent page background differ, so this is
interoperability/resource proof rather than complete pixel parity. Cached preview/PDF
content is discarded on edit as before; opaque unused arena bytes remain, bounded by
the file limit. V4 cold-launch/Open/edit/Undo/Save/reopen/export acceptance now passes through the
installed screenshot workspace. Wider interchange/fidelity remains open; see the
latest `VERIFICATION.md` entry.

Revision 2026-10-29: added visual cards, batch placement, saved swap/Undo/Redo and export evidence with explicit drag acceptance limits; no overall parity score or completion claim.
