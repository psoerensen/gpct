metrics <- function(observed, predicted, training_mean) {
  stopifnot(length(observed) == length(predicted), length(observed) >= 2L,
            all(is.finite(observed)), all(is.finite(predicted)),
            length(training_mean) %in% c(1L, length(observed)), all(is.finite(training_mean)))
  error <- observed - predicted
  denominator <- sum((observed - training_mean)^2)
  variable <- stats::sd(predicted) > 0
  calibration <- if (variable) stats::coef(stats::lm(observed ~ predicted)) else c(NA_real_, NA_real_)
  c(predictive_ability = if (variable && stats::sd(observed) > 0)
      stats::cor(observed, predicted) else NA_real_,
    rmse = sqrt(mean(error^2)),
    predictive_r_squared = if (denominator > 0) 1 - sum(error^2) / denominator else NA_real_,
    calibration_intercept = unname(calibration[1]),
    calibration_slope = unname(calibration[2]))
}

prepare_fold <- function(training, target) {
  stopifnot(is.matrix(training), is.matrix(target),
            identical(colnames(training), colnames(target)))
  # Impute with training means, then scale by training sample SD.
  means <- colMeans(replace(training, !is.finite(training), NA_real_), na.rm = TRUE)
  keep <- is.finite(means)
  training <- training[, keep, drop = FALSE]
  target <- target[, keep, drop = FALSE]
  means <- means[keep]
  for (j in seq_along(means)) {
    training[!is.finite(training[, j]), j] <- means[j]
    target[!is.finite(target[, j]), j] <- means[j]
  }
  scales <- apply(training, 2L, stats::sd)
  keep2 <- is.finite(scales) & scales > 0
  if (!any(keep2)) stop("No varying training markers.")
  means <- means[keep2]; scales <- scales[keep2]
  transform <- function(x) sweep(sweep(x[, keep2, drop = FALSE], 2, means, "-"), 2, scales, "/")
  list(training = transform(training), target = transform(target),
       centers = means, scales = scales, markers = names(means))
}

saved_folds <- function(ids, path) {
  stopifnot(length(ids) >= 10, !anyDuplicated(ids), !anyNA(ids))
  if (file.exists(path)) {
    folds <- readRDS(path)
    if (!identical(folds$id, ids) || !identical(attr(folds, "seed"), 4401L) ||
        !identical(sort(unique(folds$fold)), 1:5) ||
        max(tabulate(folds$fold)) - min(tabulate(folds$fold)) > 1L)
      stop("Saved folds disagree with eligible sample IDs or protocol; choose a new fold file.")
  } else {
    RNGkind("Mersenne-Twister", "Inversion", "Rejection")
    set.seed(4401L)
    folds <- data.frame(id = ids, fold = sample(rep(1:5, length.out = length(ids))))
    attr(folds, "seed") <- 4401L
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(folds, path)
  }
  folds
}
