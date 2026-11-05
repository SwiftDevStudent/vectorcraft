# Text and workspace interactions — 2026-10-17

The owner's target is Illustrator feature parity implemented in Swift. This change
repairs the reported text interactions and adds draggable workspace tools; matching
chrome alone does not establish feature parity.

Acceptance: double-click existing supported text to edit on the artboard; Type click
creates point text and Type drag creates a wrapping rectangular text frame. No text
entry sheet. Selection, caret, Return, Escape, native clipboard/undo, Save while
editing and reopen must retain actual text. Unsupported imported formatting remains
protected. The Tools strip and Properties/Layers dock can detach by dragging their
grips, move over the workspace, and dock/reset without losing editing state.

Implementation: AppKit text input stays inside the existing canvas; persistent edits
use Swift commands and the document's undo/snapshot path. Core Text lays out area
text for the canvas and all exports. Floating positions belong to each editor's UI
state. No new dependency, iPhone work, commit, publication or Xcode access changes.

Reference: [public Adobe Type-tool documentation](https://helpx.adobe.com/illustrator/using/tool-techniques/type-tool.html) describes click for point text and
drag for paragraph text. Existing Rust document serialization remains authoritative
for native compatibility. Advanced typography, arbitrary text paths and the other
unported Illustrator subsystems remain tracked gaps, not completed features.

Outcome: acceptance checks passed in focused tests and the installed app. The
October 17 entry in `VERIFICATION.md` records the executable hash, actual UI checks
and remaining limits. `ILLUSTRATOR_PARITY.md` tracks the broader product target.
