#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
sources = list((ROOT / "MiCoder/Sources").rglob("*.swift"))
app_localization = (ROOT / "MiCoder/Sources/Services/AppLocalization.swift").read_text()
runtime = (ROOT / "MiCoder/Sources/Services/LocalizationRuntime.swift").read_text()

languages = ["en", "ru", "es", "fr", "de", "zh", "ja", "ko", "pt", "ar"]
translation_rows = {}
translation_english = {}
for line in app_localization.splitlines():
    match = re.match(r'^\s*"([^"]+)": \[(.*)\],?\s*$', line)
    if not match:
        continue
    key, body = match.groups()
    translation_rows[key] = {lang: True for lang in re.findall(r'"(en|ru|es|fr|de|zh|ja|ko|pt|ar)"\s*:\s*"', body)}
    english = re.search(r'"en"\s*:\s*"((?:\\\\.|[^"\\])*)"', body)
    if english:
        translation_english[key] = english.group(1)

enum_keys = set(re.findall(r'^\s*case\s+([A-Za-z0-9_]+)\s*$', app_localization, re.MULTILINE))
missing_translation_keys = sorted(enum_keys - set(translation_rows))
print(f"enum_keys={len(enum_keys)}")
print(f"missing_translation_keys={len(missing_translation_keys)}")
for key in missing_translation_keys:
    print(f"MISSING_KEY|{key}")

runtime_keys = set(re.findall(r'^\s*"([^"]+)":\s*"', runtime, re.MULTILINE))
raw_l_keys = []
raw_ui_literals = []
for path in sources:
    text = path.read_text()
    for match in re.finditer(r'\bL\.t\(\s*"([^"]+)"', text):
        raw_l_keys.append((str(path.relative_to(ROOT)), match.group(1)))
    for match in re.finditer(r'\b(?:Text|Button|Label|TextField|SecureField|Toggle|Picker|ProgressView|Link)\(\s*"([^"\n]+)"', text):
        raw_ui_literals.append((str(path.relative_to(ROOT)), match.group(1)))

print(f"translation_rows={len(translation_rows)}")
print("coverage_by_language=" + ",".join(f"{lang}:{sum(lang in row for row in translation_rows.values())}" for lang in languages))
print(f"runtime_russian_keys={len(runtime_keys)}")
print(f"raw_L_t_calls={len(raw_l_keys)}")
for path, key in sorted(set(raw_l_keys)):
    print(f"RAW_L_T|{path}|{key}|runtime={'yes' if key in runtime_keys else 'no'}")
print(f"raw_ui_literals={len(raw_ui_literals)}")
for path, value in sorted(set(raw_ui_literals)):
    matches = [key for key, english in translation_english.items() if english == value]
    suffix = f"|keys={','.join(matches)}" if matches else ""
    print(f"RAW_UI|{path}|{value}{suffix}")
