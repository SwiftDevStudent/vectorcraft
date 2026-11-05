# Rust workspace appearance — 2026-10-13

The user wants VectorCraft's Swift Mac implementation to look the same as the Rust
application. The installed Rust 0.4.0 app and its owning source are the reference.

## Acceptance

- Match the medium-dark palette, compact density, categorized left tools, application
  and document bars, right Properties/Layers dock and panel icon rail, and bottom
  hint/status bars using SwiftUI/AppKit.
- Use the existing attributed VectorCraft/Lucide vector glyphs, retaining licenses.
- Verify empty/selected artwork, switching tools/panels, actual editing, native
  undo/save/reopen and resizing in the installed Swift app with synthetic documents.
- Preserve coordinated document ownership, the Swift model/commands, existing files,
  licenses, the original Rust app and its working tree. Keep unavailable commands
  visibly disabled; this appearance pass does not imply the missing Rust engine
  features have been implemented.

The source `plan/` directory is absent in this checkout. Direct owning references:
`crates/ui-egui/src/{theme,toolbar,dock,chrome}.rs` and `assets/icons/`.
Reference captures used `apple/verification/mac-runtime.vectorcraft` in both apps.
The Rust window was approximately 1470 × 923 points. Medium Dark uses panel #535353,
tab strips #424242, input #454545 and pasteboard #606060. Reference chrome sizes are
44-point application bar, 35-point document tabs, 76/48-point tool columns,
300-point expanded dock, 38-point panel rail, and 24-point status/hint bars.

No new worktree, branch, commit, publication, iPhone work or Xcode permission change
is authorized. Outcome and measured installed evidence will be appended here.

## Outcome

Installed `/Applications/VectorCraft Swift.app` uses SwiftUI/AppKit with matching
source tokens, 65 existing vector glyphs converted to PDF templates, and the Rust
app's existing Source Sans regular/semibold fonts. The release matches the reference
44/35/76/300/38-point chrome metrics and 91.25% fit at approximately 1470 × 923 points.
Selection handles and the floating bar follow selected geometry; the dock can resize,
collapse and switch between Properties/Layers, and tools can use one or two columns.

Actual controls reach Swift commands for styles, position/size, rotation, alignment,
layers, drawing and text. Command search filters/activates tools. Home presets create
native documents with their requested artboard dimensions. Native picker activation
was explicitly implemented for the custom square color well and verified by applying
`FF8000`, saving and reopening the artwork.

The final release passes 21 core plus 3 native tests, Swift-format lint, shell/plist
checks, strict signature verification and a 380-asset attribution scan. See
`VERIFICATION.md` for exact installed evidence and the executable hash.

This matches the editor's product layout and styling, not every Rust interaction
or pixel. Native startup/Open/Save/export/color/text dialogs differ. Missing engine
features remain disabled, the Vectorify app icon remains the owner's requested icon,
and import, rich text, wider command/MCP coverage and iCloud sync remain as previously
documented. Tiny-window behavior was not comprehensively exercised; native zoom and
dock/toolbar layout changes were checked. Rust source, the original app and history
remain preserved. No commit, push, publication or Xcode permission change occurred.
