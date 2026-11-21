"""Static link, SVG and public-aggregate boundary checks."""
from pathlib import Path
import csv,re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
errors=[]
for path in (root/'docs').rglob('*.md'):
    for dest in re.findall(r'\]\(([^\s)]+)(?:\s+"[^"]*")?\)',path.read_text(encoding='utf-8-sig')):
        if dest.startswith(('http:','https:','#','{{','mailto:')):continue
        dest=dest.split('#')[0].split('?')[0]
        target=path.parent/dest
        if not target.exists() and not (target.suffix=='.html' and target.with_suffix('.md').exists()):errors.append(f'{path.relative_to(root)}: {dest}')
for path in (root/'docs/assets').rglob('*.svg'):ET.parse(path)
active=root/'docs/assets/reports/gbayes-glist-1t'
for path in active.rglob('*.csv'):
    with path.open(encoding='utf-8-sig',newline='') as stream:
        reader=csv.DictReader(stream)
        assert not {'id','sample_id','observed','predicted','allele1','allele2'}&set(reader.fieldnames),path
        rows=list(reader)
        if path.name=='fold-results.csv':
            keys=[(r['dataset'],r['method'],r['fold']) for r in rows]
            assert len(keys)==len(set(keys)),path
            assert all(r['actual_workers']=='1' and r['status']=='completed' for r in rows),path
for name in ['20261121-glma-mkl','20261121-glma-gaussian-audit','20261121-gsuite-models']:
    assert not (root/'docs/assets/reports'/name).exists()
assert not errors,'\n'.join(errors)
print('Passed: website links, SVG XML, aggregate-only result headers, unique folds and one-worker records.')
