from pathlib import Path

root = Path('/home/ubuntu/MiCoder')
paths = list((root / 'MiCoder' / 'Sources').rglob('*.swift')) + list((root / 'MiCoder' / 'Tests').rglob('*.swift'))
replacements = [
    ('MiMoAutoProviderStore', 'MiCoderAutoFreeStore'),
    ('MiMoAutoProvider', 'MiCoderAutoFreeProvider'),
    ('MiMoAutoClient', 'MiCoderAutoFreeClient'),
    ('MiMoAutoError', 'MiCoderAutoFreeError'),
    ('MiMoAuto', 'MiCoderAutoFree'),
    ('mimoAuto', 'autoFree'),
    ('mimo-auto', 'micoder-auto-free'),
    ('MiMo Auto', 'MiCoder Auto Free'),
]
for path in paths:
    text = path.read_text()
    updated = text
    for old, new in replacements:
        updated = updated.replace(old, new)
    if updated != text:
        path.write_text(updated)

# The two implementation filenames are part of the public source map.
for old, new in [
    ('MiMoAutoClient.swift', 'MiCoderAutoFreeClient.swift'),
    ('MiMoAutoProvider.swift', 'MiCoderAutoFreeProvider.swift'),
    ('MiMoAutoProviderTests.swift', 'MiCoderAutoFreeProviderTests.swift'),
]:
    old_path = root / 'MiCoder' / ('Tests' if 'Tests' in old else 'Sources/Services') / old
    new_path = old_path.with_name(new)
    if old_path.exists() and not new_path.exists():
        old_path.rename(new_path)
