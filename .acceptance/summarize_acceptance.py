import csv
from pathlib import Path

path = Path(__file__).with_name("ACCEPTANCE_MATRIX.csv")
with path.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))

status_counts = {}
for row in rows:
    status_counts[row["implementation_status"]] = status_counts.get(row["implementation_status"], 0) + 1

implementation = [int(row["implementation_quality_0_5"]) for row in rows]
task_fit = [int(row["task_fit_quality_0_5"]) for row in rows]

print(f"rows={len(rows)}")
print("status_counts=" + ",".join(f"{key}:{status_counts[key]}" for key in sorted(status_counts)))
print(f"implementation_average={sum(implementation)/len(implementation):.2f}/5")
print(f"task_fit_average={sum(task_fit)/len(task_fit):.2f}/5")
print("zero_task_fit=" + ",".join(row["id"] for row in rows if row["task_fit_quality_0_5"] == "0"))
print("runtime_failures=" + ",".join(row["id"] for row in rows if row["target_runtime_status"] == "FAIL"))
