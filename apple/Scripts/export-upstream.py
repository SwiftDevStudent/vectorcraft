#!/usr/bin/env python3
"""Export the self-contained Swift addition, excluding machine-local and unlicensed inputs."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('output', type=Path, help='New .tar file; existing files are never replaced')
args = parser.parse_args()
if args.output.exists():
    parser.error('The destination already exists; choose a new archive path.')
apple = Path(__file__).resolve().parents[1]
paths = [apple / name for name in [
    'Package.swift', '.gitignore', 'AGENTS.md', 'LICENSE-MIT', 'LICENSE-APACHE', 'NOTICE',
    'INTEGRATION.md', 'AGENT_WORKFLOW.md', 'ILLUSTRATOR_PARITY.md',
    'local-build.env.example', 'Resources/Info.plist', 'Resources/VectorCraft.entitlements',
    'Scripts/package-app.sh', 'Scripts/install-app.sh', 'Scripts/register-assets.py',
    'Scripts/export-upstream.py',
]]
for directory in ['Sources', 'Tests']:
    paths.extend(p for p in (apple / directory).rglob('*') if p.is_file() and p.name != '.DS_Store')
files = {f'apple/{p.relative_to(apple).as_posix()}': p.read_bytes() for p in sorted(paths)}
if any(Path(name).suffix.lower() in {'.ttf', '.otf', '.woff', '.woff2'} for name in files):
    parser.error('Font binaries are external inputs and cannot enter the source bundle.')
files['apple/README.md'] = ("# Native Swift VectorCraft for Mac\n\n"
    "A SwiftUI/AppKit vector editor and screenshot workspace using native VectorCraft v1–v4 documents. "
    "This is an incomplete Mac port; iPhone work follows Mac acceptance.\n\n"
    "See [integration and build instructions](INTEGRATION.md), "
    "[structured saved-document commands](AGENT_WORKFLOW.md), and "
    "[feature gaps](ILLUSTRATOR_PARITY.md).\n\n"
    "Core owns model/format/rendering/commands; Mac owns native documents and UI; "
    "VectorCraftScreenshots exposes the same Core to agents. No Rust crate is linked. "
    "Project code is MIT OR Apache-2.0; see LICENSE-MIT, LICENSE-APACHE, NOTICE and ASSETS.md.\n").encode()
rows = [row for row in (apple / 'ASSETS.md').read_text().splitlines()
        if row.startswith('| `apple/') and row.split('`')[1] in files]
asset_text = ('# Swift asset attribution\n\nPaths are relative to the repository root.\n\n'
              '| Asset | Author | Source | Licence | Notes |\n|---|---|---|---|---|\n'
              + '\n'.join(rows) + '\n')
asset_extensions = {'.png', '.jpg', '.jpeg', '.svg', '.pdf', '.icns', '.ttf', '.otf', '.icc'}
missing = [name for name in files if Path(name).suffix.lower() in asset_extensions
           and f'`{name}`' not in asset_text]
if missing:
    parser.error('Unattributed portable assets: ' + ', '.join(missing))
files['apple/ASSETS.md'] = asset_text.encode()
head = subprocess.run(['git', '-C', str(apple), 'rev-parse', 'HEAD'], capture_output=True, text=True)
manifest = {'schemaVersion': 1, 'sourceBaseline': head.stdout.strip() if head.returncode == 0 else None,
            'files': {name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())}}
files['apple/INTEGRATION-MANIFEST.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
with tarfile.open(args.output, 'x') as archive:
    for name, data in sorted(files.items()):
        info = tarfile.TarInfo(name)
        info.size = len(data)
        info.mode = 0o755 if name.startswith('apple/Scripts/') else 0o644
        archive.addfile(info, io.BytesIO(data))
print(json.dumps({'archive': str(args.output.resolve()), 'files': len(files),
                  'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest()}))
