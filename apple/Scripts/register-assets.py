#!/usr/bin/env python3
"""Register Swift assets once in the existing repository's required root index."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true', help='Report missing rows without writing')
args = parser.parse_args()
apple = Path(__file__).resolve().parents[1]
registry = apple.parent / 'ASSETS.md'
if not registry.is_file():
    parser.error('Run from an apple/ directory placed in a VectorCraft checkout with ASSETS.md.')
text = registry.read_text()
missing = []
for row in (apple / 'ASSETS.md').read_text().splitlines():
    if not row.startswith('| `apple/'):
        continue
    path = row.split('`')[1]
    if (apple.parent / path).is_file() and f'`{path}`' not in text:
        missing.append(row)
if args.check and missing:
    parser.exit(1, f'{len(missing)} Swift asset rows need registration. Run without --check.\n')
if missing:
    registry.write_text(text.rstrip() + '\n\n## Native Swift assets\n\n' + '\n'.join(missing) + '\n')
print(f'Swift assets: {len(missing)} rows {"missing" if args.check else "added"}.')
