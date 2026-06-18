#!/usr/bin/env python3
"""Check that all ${VAR} references in compose files exist in .env.example."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
refs = set()
for f in ROOT.rglob('*.yml'):
    for m in re.finditer(r'\$\{(\w+)[:-]', f.read_text(encoding='utf-8', errors='ignore')):
        refs.add(m.group(1))

example = ROOT / '.env.example'
if not example.exists():
    print('SKIP: no .env.example found')
    sys.exit(0)

defined = {
    line.split('=')[0].strip()
    for line in example.read_text().splitlines()
    if '=' in line and not line.startswith('#')
}

missing = refs - defined - {'HOME'}
if missing:
    print(f'{len(missing)} env vars referenced but not in .env.example:')
    for v in sorted(missing):
        print(f'  - {v}')
    sys.exit(1)

print(f'All {len(refs)} referenced env vars have defaults')
