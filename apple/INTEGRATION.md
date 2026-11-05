# Add the Swift port to upstream

The port is a self-contained Swift package under `apple/`. It does not link Rust
crates, change the Cargo workspace or require a generated Xcode project. Keep it
in the same repository so ordinary Git updates retain it after upstream accepts
the addition. Native format compatibility remains a shared contract to verify when
upstream changes it.

Prepare the source bundle from this checkout:

```sh
python3 apple/Scripts/export-upstream.py /absolute/path/VectorCraft-Swift-source.tar
```

The archive contains `apple/` source, tests, required resources, license texts and
documentation. `INTEGRATION-MANIFEST.json` records every included file's hash and
the source baseline. It excludes build products, verification files, Cortex notes,
machine-local configuration, font binaries, local Vectorify branding and external
device frames. It is a review artifact; preparing it does not publish anything.

Place that `apple/` directory in the existing upstream checkout, then register its
licensed assets once:

```sh
python3 apple/Scripts/register-assets.py
python3 apple/Scripts/register-assets.py --check
```

The registration appends only missing rows to upstream's required `ASSETS.md`.
Running it again makes no change. Include that one-time registry addition with
`apple/` in the eventual upstream change. A README link is optional; the Swift code
does not require a root README/ROADMAP/NOTICE patch or modifications to Rust internals.

Use the required development Xcode27.3 beta1/27C5020n and macOS27:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.3.0-Beta.app/Contents/Developer
nice -n 15 xcrun swift build --package-path apple -c release --jobs 1
nice -n 15 xcrun swift test --package-path apple -c release --jobs 1
bash apple/Scripts/package-app.sh release
```

The shared packager uses only files inside `apple/` and defaults to ad-hoc signing,
system font fallback and no custom app icon. For this Mac's established G2 signature,
Source Sans typography and local icon, copy `local-build.env.example` to the ignored
`local-build.env` and set the available local inputs. Source Sans3 fonts remain
external files with their OFL notice; do not add font binaries to this repository.
Local branding requires its provenance file and redistribution permission before
publication. Neither private signing identity nor local assets belong in upstream.
Keep local font inputs in an ignored build-input cache or separate font checkout,
rather than an upstream-owned asset path that a later update could remove.

Install only through `Scripts/install-app.sh`, which preserves previous bundles in
Trash. The canonical local app stays `/Applications/VectorCraft Swift.app`; the Rust
app remains separate. No commit, PR, push or release is created by these scripts.
