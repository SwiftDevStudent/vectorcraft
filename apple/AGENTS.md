# Native Swift VectorCraft port

- The user's Swift request explicitly overrides the root Rust-only rule for `apple/`.
- Complete the native Mac editor before starting iPhone-specific UI or deployment.
- The Mac workspace must match the Rust app's appearance: palette, type, categorized tools, dock, icon rail and compact document/context/status bars. The owner's explicit visual requirement overrides generic system-chrome defaults. Use the existing attributed vector icons and legacy UI fonts; preserve native document ownership and real command behavior.
- Use the Xcode version required by the governing Apple instructions and package script. Do not enable headless Xcode or broaden agent access without explicit approval.
- Shared model, format, geometry, rendering and edit commands belong in `Sources/VectorCraftCore`. Mac UI and document integration belong in `Sources/VectorCraftMac`.
- Document edits enter through `Drawing.perform` and `CanvasDocument.execute`. Register native undo actions for every persistent edit so macOS 27 document autosave works.
- Preserve imported native data that the UI cannot render. Show the preview limitation and block artwork export when it would silently omit supported source content. Do not flatten rich text implicitly.
- Keep the original Rust app at `/Applications/VectorCraft.app`. The canonical local Swift app is `/Applications/VectorCraft Swift.app`.
- Build/package with `Scripts/package-app.sh`, then install with `Scripts/install-app.sh`. Preserve previous installs in Trash; do not permanently remove bundles, caches or user files.
- Verify focused tests using the selected Xcode and `xcrun swift test --package-path apple`. Inspect the installed app for actual GUI, save/reopen and export proof.
- Do not commit, push, publish or provision cloud accounts without the user's request. Vectorify icon redistribution rights remain unverified; its source project must remain unchanged.

- For saved screenshot documents, prefer the existing `VectorCraftScreenshots` CLI over computer use where its supported commands suffice. Read `AGENT_WORKFLOW.md` for inspection, stdin/dry-run edits, bulk export and resource/font limits. Coordinate ownership before editing an open document.
