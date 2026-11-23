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
active=root/'docs/assets/reports/gbayes-glist'
for path in active.rglob('*.csv'):
    with path.open(encoding='utf-8-sig',newline='') as stream:
        reader=csv.DictReader(stream)
        assert not {'id','sample_id','observed','predicted','allele1','allele2'}&set(reader.fieldnames),path
        rows=list(reader)
        if path.name=='fold-results.csv':
            keys=[(r['dataset'],r['method'],r['fold']) for r in rows]
            assert len(keys)==len(set(keys)),path
            assert all(r['actual_workers'] in {'1','4'} and r['status'] in {'completed','failed'} for r in rows),path
            for row in rows:
                if row['status']=='failed':
                    assert row['method']=='rhe_blup' and row['failure_message'],path
                    assert all(row[k] in {'NA',''} for k in ('predictive_ability','rmse','predictive_r_squared')),path
                elif row['method']=='rhe_blup':
                    assert float(row['true_relative_residual'])<=1e-8,path
        if path.name=='benchmark-results.csv':
            for row in rows:
                if row['status'].startswith('failed'):
                    assert int(row['accepted_folds'])<10,path
                    assert all(row[k] in {'NA',''} for k in ('predictive_ability_mean','rmse_mean','predictive_r_squared_pooled')),path
# Published dataset tables must keep peak memory and combined time in separate cells.
for case in ("cattle", "maize"):
    report = (root / "docs/reports" / (case + ".md")).read_text(encoding="utf-8-sig")
    cost = report.split("## Computational cost", 1)[1].split("\n| ", 1)[1]
    lines = ("| " + cost).split("\n\n", 1)[0].splitlines()
    header = [cell.strip() for cell in lines[0].strip("|").split("|")]
    width = len(header)
    assert "Process peak MiB" in header, case
    assert all(len(line.strip("|").split("|")) == width for line in lines), case
    with (active / case / "benchmark-results.csv").open(encoding="utf-8-sig", newline="") as stream:
        summaries = list(csv.DictReader(stream))
    rhe = next((row for row in summaries if row["method"] == "rhe_blup"), None)
    if rhe:
        from statistics import mean
        from math import isclose
        with (active / case / "fold-results.csv").open(encoding="utf-8-sig", newline="") as stream:
            folds = [row for row in csv.DictReader(stream) if row["method"] == "rhe_blup"]
        accepted = [row for row in folds if row["status"] == "completed"]
        assert len(folds) == int(rhe["folds"]) == 10, case
        assert len(accepted) == int(rhe["accepted_folds"]), case
        for metric in ("predictive_ability", "rmse"):
            if len(accepted) == len(folds):
                assert isclose(mean(float(row[metric]) for row in accepted),
                               float(rhe[metric + "_mean"]), rel_tol=1e-10), (case, metric)
            else:
                assert rhe[metric + "_mean"] in {"NA", ""}, (case, metric)
        assert "Fit + predict s" in header, case
        row = next(line for line in lines if line.startswith("| RHE + BLUP |"))
        cells = dict(zip(header, (cell.strip() for cell in row.strip("|").split("|"))))
        assert cells["Process peak MiB"] == format(float(rhe["process_peak_working_set_mib"]), ".0f"), case
        total = rhe["fit_plus_prediction_seconds"]
        assert cells["Fit + predict s"] == ("not available" if total == "NA" else format(float(total), ".1f")), case
for name in ['20261121-glma-mkl','20261121-glma-gaussian-audit','20261121-gsuite-models']:
    assert not (root/'docs/assets/reports'/name).exists()
assert not errors,'\n'.join(errors)
print('Passed: website links, SVG XML, aggregate-only result headers, unique folds and declared worker records.')
