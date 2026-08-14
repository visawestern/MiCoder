import csv
from pathlib import Path

path = Path('/home/ubuntu/MiCoder/docs/FEATURE_SPREADSHEET.csv')
raw = path.read_text()
rows = list(csv.DictReader(raw.splitlines(), restkey='__extra__'))
fields = ['area','id','name','user_story','expected_behavior','test_coverage','status','notes']
clean = []
for row in rows:
    extras = row.pop('__extra__', None)
    if extras:
        # Preserve malformed trailing text in notes rather than discarding it.
        row['notes'] = (row.get('notes') or '') + ' | CSV legacy extra: ' + ' | '.join(extras)
    clean.append({field: row.get(field, '') for field in fields})
with path.open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(clean)
print(f'normalized_rows={len(clean)}')
