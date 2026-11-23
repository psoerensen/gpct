"""Audit the two explicitly modified native units; retain the original archive."""
import csv
import hashlib
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
ar = Path('C:/rtools44/x86_64-w64-mingw32.static.posix/bin/ar.exe')
reference = root / 'reference-library/gbayes/lib/libgbayes_core.a'
if not reference.exists():
    reference = root / 'library/gbayes/lib/libgbayes_core.a'
candidate = root / 'cache-library/gbayes/lib/libgbayes_core.a'
def members(path):
    return subprocess.check_output([str(ar), 't', str(path)], text=True).splitlines()
names = members(reference)
assert names == members(candidate) and len(names) == len(set(names))
records = []
for name in names:
    checksums = [hashlib.sha256(subprocess.check_output([str(ar), 'p', str(path), name])).hexdigest()
                 for path in (reference, candidate)]
    records.append(dict(object=name, reference_sha256=checksums[0], candidate_sha256=checksums[1],
                        unchanged=checksums[0] == checksums[1]))
changed = [record['object'] for record in records if not record['unchanged']]
assert set(changed) == {'individual_bed.o', 'mixture.o'}, changed
destination = root / 'qualification/cache-integration/alphabet-native-object-audit.csv'
with destination.open('w', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=list(records[0]))
    writer.writeheader()
    writer.writerows(records)
print(f'Only individual_bed.o and mixture.o changed; {len(records)-2} native objects are byte-identical.')
