#!/usr/bin/env python3
"""Create native PDF glyphs from the Rust app's already-attributed SVG sources."""
import argparse
import pathlib
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--cli', required=True, help='Existing vectorcraft-cli executable')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[2]
target = root / 'apple/Sources/VectorCraftMac/Resources/Icons'
target.mkdir(parents=True, exist_ok=True)
source = (root / 'apple/Sources/VectorCraftMac/WorkspaceIcon.swift').read_text()
names = sorted(set(re.findall(r'case \w+ = "([\w-]+)"', source)))
registry = root / 'ASSETS.md'
text = registry.read_text()
rows = []
for name in names:
    svg = root / f'assets/icons/{name}.svg'
    if not svg.is_file():
        raise SystemExit(f'Missing owning asset: {svg}')
    pdf = target / f'{name}.pdf'
    # Match icons.rs's 1.6 stroke width; native PDF is a template image at runtime.
    data = svg.read_text().replace('currentColor', 'black').replace('stroke-width="2"', 'stroke-width="1.6"')
    with tempfile.NamedTemporaryFile(suffix='.svg', mode='w', delete=False) as temporary:
        temporary.write(data)
        input_path = pathlib.Path(temporary.name)
    # Keep temporary inputs recoverable; never delete files in this workflow.
    subprocess.run([args.cli, 'convert', str(input_path), str(pdf)], check=True, capture_output=True)
    rel = pdf.relative_to(root).as_posix()
    if f'`{rel}`' not in text:
        original = next((row for row in text.splitlines() if f'`assets/icons/{name}.svg`' in row), None)
        if original is None:
            raise SystemExit(f'Unattributed source: {name}')
        columns = original.split('|')
        rows.append(f'| `{rel}` | {columns[2].strip()} | Derived from `assets/icons/{name}.svg` | {columns[4].strip()} | Native vector PDF; same glyph and stroke as Rust UI |')
if rows:
    registry.write_text(text.rstrip() + '\n' + '\n'.join(rows) + '\n')
license_source = root / 'assets/icons/LICENSE-lucide.txt'
(target / 'LICENSE-lucide.txt').write_bytes(license_source.read_bytes())
print(f'Prepared {len(names)} attributed native vector icons.')
