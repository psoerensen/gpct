# Base-R checks. No synthetic result is a benchmark result.
source("scripts/evaluate.R")
perfect <- metrics(c(1, 2, 4), c(1, 2, 4), 2)
stopifnot(abs(perfect[["predictive_ability"]] - 1) < 1e-12,
          perfect[["rmse"]] == 0, perfect[["predictive_r_squared"]] == 1,
          abs(perfect[["calibration_intercept"]]) < 1e-12,
          abs(perfect[["calibration_slope"]] - 1) < 1e-12)
constant <- metrics(c(1, 2, 4), rep(2, 3), 2)
stopifnot(is.na(constant[["predictive_ability"]]), is.na(constant[["calibration_slope"]]),
          constant[["predictive_r_squared"]] == 0)
poor <- metrics(c(1, 2, 4), c(20, 20, 20), 2)
stopifnot(poor[["predictive_r_squared"]] < 0)
a <- matrix(c(0, 1, 2, NA, 0, 0, 0, 0), 4, 2,
            dimnames = list(letters[1:4], c("variable", "constant")))
b <- matrix(c(NA, 100, 9, 9), 2, 2,
            dimnames = list(letters[5:6], colnames(a)))
prepared <- prepare_fold(a, b)
stopifnot(ncol(prepared$training) == 1L,
          abs(mean(prepared$training)) < 1e-12,
          abs(stats::sd(prepared$training[, 1]) - 1) < 1e-12,
          prepared$centers[[1]] == 1, prepared$target[1, 1] == 0)
changed <- prepare_fold(a, b * 100)
stopifnot(identical(prepared$centers, changed$centers),
          identical(prepared$scales, changed$scales),
          identical(prepared$training, changed$training))
path <- tempfile(fileext = ".rds")
ids <- sprintf("sample-%02d", 1:23)
folds <- saved_folds(ids, path)
stopifnot(identical(saved_folds(ids, path), folds),
          max(tabulate(folds$fold)) - min(tabulate(folds$fold)) <= 1,
          inherits(try(saved_folds(rev(ids), path), silent = TRUE), "try-error"))
unlink(path)
cat("Protocol checks passed.\n")
