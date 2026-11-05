# Loaded-artboard fitting — 2026-10-18

Tracking: `issue_01m582g31eyw1cerjchcx1x37s`. Full Mac parity remains active.

Native document reading is asynchronous. The canvas can lay out its default 800×800
drawing before receiving the opened document. Its update path previously fitted only
on selected-index changes, so a 612×792 document could keep the initial viewport.

Refit when the active artboard's geometry changes while Fit mode is active. Preserve
manual pan/zoom across document edits; changing the selected artboard still fits that
board. Configure the SwiftUI bridge through the same canvas update path. Do not add
stored geometry mirrors, global state or another navigation implementation.

The focused native regression reproduces the wrong center and scale after initial
layout and a geometry update. Check geometry edits, window resizing, actual-size mode,
translated secondary artboards and independent views. Then package/install and verify
cold-open and multiple native document windows with clipboard placement, undo and
save/reopen. Wider navigation, rotation, view modes and hardware feel remain P02 gaps.

No new APIs, dependencies, assets, document-format changes or system access are needed.
