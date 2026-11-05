# v0.21.0 integration review — 2026-11-04

The owner approved the stable release, not moving main. The local checkout now points
to `11862f61198c8f62c0b22b6c9a331cc5950ac98d` after a fast-forward from v0.18.0.
No source commit was made. The four dirty tracked files reapplied without conflicts;
276 existing Apple/handoff files matched their pre-update hashes immediately afterward.

## Selected changes

| Upstream change | Swift decision |
| --- | --- |
| [Shared native format, PR5146](https://github.com/storytold/vectorcraft/pull/5146) | Verified the pinned craft-libs contract and real writer/reader round-trips. No speculative codec migration. |
| [Bitmap paste preparation, PR4277](https://github.com/storytold/vectorcraft/pull/4277), [Mac menu paste, PR5230](https://github.com/storytold/vectorcraft/pull/5230) | Add PNG/TIFF clipboard input to the real canvas responder. Prepare pixels on a serial utility actor, then use existing fragment/paste commands and native Undo. |
| [Progressive rendering, PR4961](https://github.com/storytold/vectorcraft/pull/4961) | Rust GPU texture upload is not the CoreGraphics path. Keep the existing deferred canvas/card proxies; no renderer rewrite or new performance claim. |
| [Custom toolbars, PR5038](https://github.com/storytold/vectorcraft/pull/5038), [Tiled windows, PR5216](https://github.com/storytold/vectorcraft/pull/5216) | Separate remaining Mac workspace work. Existing draggable palettes stay intact. |

The [pinned shared crate](https://github.com/storytold/craft-libs/blob/14d5dbb50c317b8747a9cf9eb35ab8a22515f137/crates/vectorcraft-format/src/lib.rs)
still defines versions1–4, the `0a005643424c4f425300` binary marker and8192-byte
inline threshold. The shared reader additionally accepts ordered array envelopes;
Swift accepts the object envelopes the writer emits. Swift's64MB document limit is
smaller than upstream's1GiB resource limit. These remain explicit boundaries.

The official [v0.21.0 release](https://github.com/storytold/vectorcraft/releases/tag/v0.21.0)
Mac CLI archive was checked against its published SHA-256:
`1c645c749759654223136f9a4c0c6ea73867e79a3969b17844e3cdabaec07429`.
Five original synthetic files (legacy v1/v2, v3, v4, gzip v4) pass upstream writer →
Swift reader/writer → upstream reopen, with exact document and decoded image bytes.

Clipboard scope: native artwork/SVG and meaningful text retain priority; blank text
beside a bitmap yields the picture. PNG bytes are preserved. TIFF becomes PNG and
uses its physical resolution. Inputs are bounded to16MB/32MP/16384px per side.
One pending preparation belongs to each canvas; another Paste supersedes it, teardown
cancels it, and document/target changes refuse the stale completion with an error.
No URLs are fetched. Broader image/PDF clipboard formats and cross-profile conversion
remain gaps. Installed proof and exact tests are recorded in `VERIFICATION.md`.

Recovery: `build/current-v021-evidence.txt` points to the verified source/Git archive,
dirty patch, preflight and interoperability records. The recovery stash
`dbd27f407cacd016e9d68ea574d736e1e52937c7` remains retained. Ignored build/evidence
directories stayed in place. Only the stable tag was fetched, so `origin/main` is an
older tracking snapshot; its ahead count does not represent newly authored commits.
