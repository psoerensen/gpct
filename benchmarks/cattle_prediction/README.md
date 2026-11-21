# Cattle / mkg

GPBench supplies 5,024 individuals and 42,551 available markers.
The selected PLINK/QC/Glist panel contains 42,373 markers. Every existing
gbayes method uses the same saved ten folds with seed 42, one native worker,
and native training-specific genotype coding. Original genomic annotations
are absent; synthetic BIM/FAM fields must not be interpreted biologically.

```powershell
./environment/activate.ps1 -BlasThreads 1
Rscript --vanilla scripts/run_gbayes.R marker_gaussian cattle
```

Replace marker_gaussian with a method ID from `benchmarks/methods.R`.
Use `environment/run-method.ps1` to execute both datasets and measure process
peak RAM. See the website protocol, settings and results for interpretation.
Individual out-of-fold predictions and saved fits remain outside this repository.
