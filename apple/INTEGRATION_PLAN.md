# Portable upstream integration — 2026-11-04

Owner: “make our code easily placed into the existing main repo so we don't have
to do this every time we update.”

Success: the shared Swift source lives in one `apple/` directory, its package has
no Rust-crate dependency, and packaging no longer reads mandatory files from a
parent checkout. An export produces only reviewed source/tests/docs/licensed
resources. A one-time idempotent command registers its assets in upstream's required
root registry. After upstream accepts that addition, future pulls keep the Swift
directory through normal Git history rather than reapplying a port patch.

Keep local G2 signing, Vectorify branding and Source Sans workspace appearance in
an ignored local build-input file. Shared packaging defaults to ad-hoc signing and
system fallback typography when optional inputs are absent. Font binaries must not
be added here; local-use-only icon/frame resources cannot enter the portable bundle.
Copy project license texts and a Swift-specific NOTICE into apple/. Preserve the
existing local assets, root provenance and historical evidence.

Validate shell/Python syntax, exported paths/hashes and complete asset registration.
Parse the package from an extracted source bundle without parent Rust files. Exercise
the existing packager/install path with the local inputs, verify its G2 signature,
and complete installed bitmap/save/Undo/reopen checks. Do not run another full source
build from the extracted bundle merely to repeat already-passing Swift checks.

No source commit, upstream PR/push, branch/worktree, CI rewrite or publication. Actual
upstream acceptance remains separate. Native schema changes still need compatibility
checks; a portable directory cannot guarantee that future upstream behavior never changes.
