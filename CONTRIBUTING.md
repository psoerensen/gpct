# Contributing

Add a row to `datasets/registry.csv` with a stable ID, immutable source version,
citation, species, traits, verified counts, format, processing history, access
conditions and remaining uncertainties. Record evidence and inspection date.
Do not infer licences or original biological identifiers from a dataset label.
For human datasets, describe consent, controlled access and permitted aggregate
release before adding an executable recipe.

Copy a benchmark folder and edit its ordinary R config and README. State the
scientific target, data eligibility rules, method settings, validation population,
commands and outputs. Existing APIs must be checked against actual package help
and examples. Different scientific questions belong in separate benchmark cases.
Do not add statistical solvers or a general workflow engine here.

Use shared saved folds. Fit imputation, scaling, covariate adjustments and tuning
within training folds; any tuning requires inner validation, never outer test
outcomes. Preserve original IDs when supplied; explicitly document positional
surrogates when they are not. Family, environment, temporal or ancestry holdouts
should be new labelled protocols, not silently substituted for random folds.

Mark a case **planned** until execution is verified, **runnable** after its
documented recipe succeeds, and **completed** only with an archived execution
record and reviewed aggregate results. Include failures and convergence limits.
Use `Rscript --vanilla tests/check_protocol.R` to check shared safeguards when R
is available. Review staged files before publishing. Never commit individual
phenotypes, genotypes, fold membership, predictions or a complete local run.
