# Screenshot documents through the CLI

Use `VectorCraftScreenshots` for saved native documents. These commands use the same
Core editing and export code as the Mac app. They do not inspect or change unsaved
GUI state. Work on a copy while a document is open in the editor; reopen the result
after CLI editing rather than overwriting an open document.

Build with the selected Xcode:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.3.0-Beta.app/Contents/Developer
xcrun swift build --package-path apple --scratch-path apple/build/swiftpm -c release --jobs 1
CLI=apple/build/swiftpm/release/VectorCraftScreenshots
"$CLI" summary '/absolute/path/Project.vectorcraft'
```

Reuse the existing release binary when sources have not changed. On an active Mac,
run builds at reduced CPU priority (`nice -n 15 ...`) and keep heavy
operations sequential. The app packaging script enforces these build limits.

`summary` returns schema-versioned JSON with artboard and object IDs, document-point
bounds, all ten slots per row, populated/included boards, text frames and editability,
requested/resolved fonts, resource availability and rendering warnings. It omits image
payloads and bookmark capabilities. Use `inspect` only when the complete native JSON
envelope is necessary; binary resource bytes are not part of that JSON output.

Discover actual IDs from `summary`; numeric IDs below are examples. JSON command
files and standard input use the same array schema. Trailing flags may be in either
order. `--dry-run` validates the complete batch and returns its resulting summary
without saving. `--summary` replaces the legacy full-envelope response after a save.

```sh
"$CLI" edit '/absolute/path/Copy.vectorcraft' - --dry-run <<'JSON'
[{"action":"editText","id":123,"text":"A clearer headline"}]
JSON

"$CLI" edit '/absolute/path/Copy.vectorcraft' edits.json --summary
"$CLI" apply '/absolute/path/Copy.vectorcraft' layout.json --dry-run
"$CLI" export-used '/absolute/path/Copy.vectorcraft' '/existing/output/folder' png
```

Each edit/apply batch commits one atomic native write only after every command
succeeds. CLI edits preserve unsupported native fields and original image resources;
unsupported text editing and lossy exports remain refused. Standard input is limited
to 4 MiB; use a JSON file for larger batches. Exit status 1 and stderr report failures.
Dry runs do not reserve a file or coordinate concurrent writers.

Native `edit` actions:

| Action | Parameters |
| --- | --- |
| `addText` | `board` or `layer`, `text`, document-space `x`/`y`; optional `font`, `size`, RGB `color` |
| `editText` | text `id`, `text`; optional `font`, `size` |
| `transform` | `ids`, affine `matrix: [a,b,c,d,tx,ty]`; optional `copy` |
| `fill` | `ids`, `color: [r,g,b]` with components from 0 to 1 |

Screenshot `apply` actions are defined by `ScreenshotCommand` in
`Sources/VectorCraftCore/ScreenshotWorkspace.swift`. Examples:

```json
[
  {"action":"setTemplate","board":1,"template":"bottom-crop"},
  {"action":"setExport","board":1,"included":true}
]
```

Command `slot` indices are **zero-based**; summary slot labels are **one-based**.
`moveBoard` stays within its device row; an optional `row` ID must match it. Other actions include `addRow`,
`addBoard`, `rotateBoard`, `crop`, `setDisplay`, `setLanguage`, `setFrame`,
`replaceScreenshot` and `placeScreenshots`. The last two accept base64-encoded `data`
or `images`; for a single file, prefer `import FILE BOARD_ID PNG/JPEG --summary`.
Use `new FILE [PRESET] --summary` to create a project without replacing an existing file.
Presets: `iphone-medium`, `iphone-large`, `iphone-duo`, `ipad-13`.

`export-used FILE DIRECTORY png|svg|pdf` creates a fresh `Screenshots-UUID` folder and
returns its directory and file paths as JSON. It exports only populated/included
slots, using original resources and fresh validation. A failed/canceled export can
leave a partial new folder; success is established by the final response and exit
status. Single-board `export FILE BOARD_ID OUTPUT.png/svg/pdf` remains available.
`extract-image FILE NODE_ID OUTPUT` writes original available image bytes.

Run font-sensitive commands in the normal macOS login session. This machine's Codex
sandbox can hide installed fonts and produce a fallback warning/export refusal;
the same binary and document resolve correctly outside that sandbox. The CLI has no
font-registration flag. Check `resolvedPostScriptName` and `renderingWarnings` before
editing/exporting. Do not change system fonts or flatten text to hide this failure.

Local Apple device frames retain their per-file bookmarks and local-use-only status.
The CLI does not bypass macOS file permission prompts or redistribute frame assets.
SVG currently links original local frame files and is not a self-contained delivery
format. Live unsaved-document control and the full Rust command/MCP surface remain gaps.
