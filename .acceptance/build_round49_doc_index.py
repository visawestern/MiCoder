from pathlib import Path
import re

root = Path('/home/ubuntu/MiCoder')
paths = []
for pattern in ('*.md', '*.csv'):
    paths.extend(root.glob(pattern))
paths.extend((root / 'docs').rglob('*.md'))
paths.extend((root / 'docs').rglob('*.csv'))
paths.extend((root / 'plans').glob('*.md'))
paths = sorted({p for p in paths if '.git' not in p.parts and p.is_file()})

out = []
for path in paths:
    text = path.read_text(errors='replace')
    lines = text.splitlines()
    headings = [line.strip() for line in lines if re.match(r'^#{1,4} ', line)][:12]
    markers = [line.strip() for line in lines if re.search(r'(?i)pending|unverified|partial|missing|fail|todo|not implemented|requires macos|requires manual', line)]
    out.append(f'## {path.relative_to(root)}\n')
    out.append(f'- lines: {len(lines)}\n')
    out.append('- headings:\n')
    out.extend(f'  - {h}\n' for h in headings)
    out.append(f'- unresolved_marker_count: {len(markers)}\n')
    out.extend(f'  - {m[:280].rstrip()}\n' for m in markers[:10])
    out.append('\n')
(root / '.acceptance/ROUND49_DOC_INDEX.md').write_text(''.join(out).rstrip() + '\n')
print(f'indexed {len(paths)} documents')
