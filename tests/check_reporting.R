# Synthetic checks only; these values never become website benchmark results.
source("scripts/report_prediction.R")
fixture <- tempfile("gpct-report-")
dir.create(fixture)
config <- case_config("cattle")
saveRDS(config, file.path(fixture, "settings.rds"))
ids <- sprintf("test-%03d", 1:50)
fold <- rep(1:5, 10)
saved <- data.frame(id = ids, fold = fold)
attr(saved, "seed") <- 4401L
saveRDS(saved, file.path(fixture, "folds.rds"))
versions <- data.frame(package = c("rrBLUP", "gbayes"), version = c("test", "test"))
write.csv(versions, file.path(fixture, "package_versions.csv"), row.names = FALSE)
y <- sin(seq_along(ids)) + seq_along(ids)/10
predictions <- lapply(config$methods, function(method) {
  prediction <- switch(method, rrblup = .6*y + cos(seq_along(ids)),
    gbayes_gaussian = y + .1*sin(seq_along(ids)), gbayes_elastic_net = rep(mean(y), length(y)))
  data.frame(id = ids, fold = fold, method = method, observed = y, predicted = prediction,
    training_mean = vapply(fold, function(k) mean(y[fold != k]), numeric(1)))
})
p <- do.call(rbind, predictions)
perf <- do.call(rbind, lapply(config$methods, function(method) do.call(rbind, lapply(1:5, function(k) {
  data.frame(method = method, fold = k, status = "completed", convergence = "converged",
    markers = 512L - k, fit_seconds = k, prediction_seconds = .1, method_elapsed_seconds = k + .2,
    warning_count = 0L)
}))))
write_inputs <- function(p, perf) {
  write.csv(p, file.path(fixture, "predictions.csv"), row.names = FALSE)
  write.csv(perf, file.path(fixture, "performance.csv"), row.names = FALSE)
}
write_inputs(p, perf)
tables <- finish_report_tables(summarize_prediction_run(fixture))
s <- tables$benchmark_results
baseline <- s[s$method == "rrblup", ]
gaussian <- s[s$method == "gbayes_gaussian", ]
q <- p[p$method == "rrblup", ]
expected_r2 <- 1 - sum((q$observed-q$predicted)^2)/sum((q$observed-q$training_mean)^2)
stopifnot(abs(baseline$predictive_r_squared - expected_r2) < 1e-12,
          baseline$fit_seconds == 15, baseline$prediction_seconds == .5,
          baseline$markers_used_min == 507, baseline$markers_used_max == 511,
          baseline$available_markers == 42551, baseline$planned_markers == 512,
          is.na(baseline$peak_ram_mb), baseline$ram_status == "not measured",
          is.na(baseline$actual_threads), baseline$delta_predictive_ability == 0,
          all(tables$calibration_bins$n >= 5), !"id" %in% names(tables$calibration_bins))
stopifnot(abs(gaussian$delta_predictive_ability -
  (gaussian$predictive_ability-baseline$predictive_ability)) < 1e-12,
  abs(gaussian$relative_rmse_reduction - (1-gaussian$rmse/baseline$rmse)) < 1e-12)
fold_mean <- tables$fold_metric_means$predictive_r_squared[tables$fold_metric_means$method == "rrblup"]
stopifnot(abs(fold_mean-baseline$predictive_r_squared) > 1e-5,
          is.na(s$predictive_ability[s$method == "gbayes_elastic_net"]))
out <- tempfile("report-output-")
write_prediction_report(tables, out)
stopifnot(all(file.exists(file.path(out, paste0(c("performance", "improvement", "runtime", "calibration"), ".svg")))),
          file.exists(file.path(out, "benchmark_results.csv")),
          !file.exists(file.path(out, "predictions.csv")),
          !file.exists(file.path(out, "folds.rds")))
bad <- perf; bad$status[bad$method == "gbayes_gaussian" & bad$fold == 3] <- "failed"
partial <- p[!(p$method == "gbayes_gaussian" & p$fold == 3), ]
write_inputs(partial, bad)
failed <- finish_report_tables(summarize_prediction_run(fixture))
a <- failed$benchmark_results[failed$benchmark_results$method == "gbayes_gaussian", ]
stopifnot(a$status == "failed", a$failed_folds == 1L, a$completed_folds == 4L,
          is.na(a$predictive_ability), is.na(a$delta_predictive_ability),
          !any(failed$calibration_bins$method == "gbayes_gaussian"))
bad <- perf; bad$status[bad$method == "rrblup" & bad$fold == 3] <- "failed"
partial <- p[!(p$method == "rrblup" & p$fold == 3), ]
write_inputs(partial, bad)
no_baseline <- finish_report_tables(summarize_prediction_run(fixture))$benchmark_results
stopifnot(all(is.na(no_baseline$delta_predictive_ability)),
          all(is.na(no_baseline$relative_rmse_reduction)))
write_inputs(p, perf[-1, ])
incomplete <- summarize_prediction_run(fixture)$benchmark_results
stopifnot(incomplete$status[incomplete$method == perf$method[1]] == "incomplete")
write_inputs(rbind(p, p[1, ]), perf)
stopifnot(inherits(try(summarize_prediction_run(fixture), silent = TRUE), "try-error"))
bad <- p; bad$fold[1] <- 5
write_inputs(bad, perf)
stopifnot(inherits(try(summarize_prediction_run(fixture), silent = TRUE), "try-error"))
bad <- p; bad$observed[1] <- bad$observed[1]+1
write_inputs(bad, perf)
stopifnot(inherits(try(summarize_prediction_run(fixture), silent = TRUE), "try-error"))
unlink(c(fixture, out), recursive = TRUE)

# Exercise runner failure recording and timing without fitting a package model.
check_failed_runner <- function() {
  root <- tempfile("gpct-runner-"); dir.create(root)
  old <- Sys.getenv(c("GPCT_DATA_DIR", "GPCT_OUTPUT_DIR", "GPCT_RUN_ID"), unset = NA_character_)
  on.exit({
    for (key in names(old)) if (is.na(old[[key]])) Sys.unsetenv(key) else
      do.call(Sys.setenv, stats::setNames(list(old[[key]]), key))
    unlink(root, recursive = TRUE)
  })
  Sys.setenv(GPCT_DATA_DIR = file.path(root, "data"), GPCT_OUTPUT_DIR = file.path(root, "out"), GPCT_RUN_ID = "failure-check")
  dir.create(file.path(root, "data", "prepared"), recursive = TRUE)
  cfg <- case_config("cattle"); cfg$n <- 50L
  # Unknown method exercises explicit failure after preprocessing; no fit executes.
  cfg$methods <- "deliberately_unavailable_test_method"
  X <- outer(1:50, 1:512, function(i, j) sin(i+j))
  dimnames(X) <- list(ids, paste0("marker-", 1:512))
  Y <- matrix(y, ncol = 1, dimnames = list(ids, "mkg"))
  saveRDS(list(X = X, Y = Y, ids = ids,
    metadata = list(dataset_id = cfg$dataset_id, positional_alignment_accepted = TRUE)),
    file.path(root, "data", "prepared", "cattle.rds"))
  env <- new.env(parent = globalenv()); env$config <- cfg; env$exit_status <- NULL
  env$quit <- function(status) env$exit_status <- status
  sys.source("scripts/run_prediction.R", env)
  destination <- file.path(root, "out", "cattle", "failure-check")
  rows <- read.csv(file.path(destination, "performance.csv"))
  execution <- read.csv(file.path(destination, "execution.csv"))
  stopifnot(env$exit_status == 1L, nrow(rows) == 5L, all(rows$status == "failed"),
    all(is.finite(rows$method_elapsed_seconds)), all(is.na(rows$peak_ram_mb)),
    is.finite(execution$case_elapsed_seconds), execution$ram_status == "not measured")
}
check_failed_runner()
cat("Reporting checks passed; synthetic outputs removed.\n")
