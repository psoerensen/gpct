"""Exact upstream splitter; write only to the explicitly supplied external path."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import numpy as np
import sklearn
from sklearn.model_selection import KFold

parser = argparse.ArgumentParser()
parser.add_argument('samples', type=int)
parser.add_argument('destination', type=Path)
args = parser.parse_args()
checkout = Path(__file__).resolve().parents[1]
dest = args.destination.resolve()
if dest == checkout or checkout in dest.parents:
    raise SystemExit('Fold assignments must remain outside the repository')
if dest.exists():
    raise SystemExit('Fold file already exists')
assignments = np.zeros(args.samples, dtype=np.int64)
for fold, (train, test) in enumerate(KFold(n_splits=10, shuffle=True, random_state=42).split(assignments)):
    assignments[test] = fold + 1
    assert len(np.intersect1d(train, test)) == 0
dest.parent.mkdir(parents=True, exist_ok=True)
with dest.open('w', newline='', encoding='utf-8') as stream:
    writer = csv.writer(stream)
    writer.writerow(['source_row', 'fold'])
    writer.writerows(enumerate(assignments.tolist(), start=1))
metadata = dict(splitter='sklearn.model_selection.KFold', n_splits=10, shuffle=True,
                random_state=42, numpy=np.__version__, sklearn=sklearn.__version__,
                sha256=hashlib.sha256(dest.read_bytes()).hexdigest())
dest.with_suffix('.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
print(json.dumps(metadata))
