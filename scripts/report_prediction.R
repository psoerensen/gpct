# Run from the repository root. Base R only; never copies individual predictions.
source("scripts/evaluate.R")
report_metrics <- c("predictive_ability", "rmse", "predictive_r_squared",
                    "calibration_intercept", "calibration_slope")
report_labels <- c(rrblup = "REML rrBLUP", gbayes_gaussian = "gbayes Gaussian",
                   gbayes_elastic_net = "gbayes elastic net")
report_colors <- c(rrblup = "#3069a6", gbayes_gaussian = "#168575",
                   gbayes_elastic_net = "#8255a8")

case_config <- function(case) {
  env <- new.env(parent = baseenv())
  sys.source(file.path("benchmarks", paste0(case, "_prediction"), "config.R"), env)
  env$config
}

report_tables <- function(config, versions = NULL) {
  registry <- read.csv("datasets/registry.csv", stringsAsFactors = FALSE)
  d <- registry[registry$dataset_id == config$dataset_id, , drop = FALSE]
  stopifnot(nrow(d) == 1L, all(config$methods %in% names(report_labels)))
  catalogue <- data.frame(dataset = config$dataset_id, species = d$species,
    trait = config$trait, phenotype_definition = paste("Supplied GPBench", config$trait,
      "values; biological definition, upstream adjustments and units unverified"),
    individuals_available = d$samples, individuals_eligible = d$selected_trait_finite,
    available_markers = d$markers, planned_markers = config$marker_count,
    markers_used_min = NA_integer_, markers_used_max = NA_integer_,
    marker_usage_status = "planned; actual fitted counts unavailable", source = d$source_url)
  settings <- data.frame(dataset = config$dataset_id, trait = config$trait, method = config$methods,
    package = ifelse(config$methods == "rrblup", "rrBLUP", "gbayes"),
    package_version = "not run", tuning_strategy = "none; fixed predeclared settings",
    model_settings = c(
      "REML ridge; variance ratio fitted on training data; bounds 1e-9 to 1e9",
      sprintf("marker_gaussian/pcg; standardized outcome; ve=%g; prior variance=%g/p; nit=%d",
        1 - config$gaussian_h2, config$gaussian_h2, config$nit),
      sprintf("elastic_net/coordinate_descent; standardized outcome; lambda=%g; alpha=%g; nit=%d",
        config$lambda, config$alpha, config$nit))[match(config$methods, names(report_labels))],
    convergence_criteria = ifelse(config$methods == "rrblup", "REML optimizer; no flag exposed",
      paste("native tolerance", config$tolerance, "and iteration cap; inspect diagnostics")),
    requested_package_threads = ifelse(config$methods == "rrblup", NA_integer_, 1L),
    actual_threads = NA_integer_,
    managed_memory_budget_mib = ifelse(config$methods == "rrblup", NA_real_, config$memory_limit / 1024^2))
  settings$tuning_strategy[settings$method == "rrblup"] <- "training-only REML variance estimation; no CV tuning"
  if (!is.null(versions)) settings$package_version <- versions$version[match(settings$package, versions$package)]
  summary <- data.frame(dataset = config$dataset_id, trait = config$trait,
    method = config$methods, summary_type = "pooled_oof", predictive_ability = NA_real_,
    rmse = NA_real_, predictive_r_squared = NA_real_, calibration_intercept = NA_real_,
    calibration_slope = NA_real_, fit_seconds = NA_real_, prediction_seconds = NA_real_,
    method_elapsed_seconds = NA_real_, case_elapsed_seconds = NA_real_, peak_ram_mb = NA_real_,
    ram_status = "not measured", requested_package_threads = ifelse(config$methods == "rrblup", NA_integer_, 1L),
    actual_threads = NA_integer_,
    available_markers = config$p, planned_markers = config$marker_count,
    markers_used_min = NA_integer_, markers_used_max = NA_integer_,
    completed_folds = 0L, failed_folds = 0L, missing_folds = 5L,
    warning_count = NA_integer_, convergence = "not run", status = "planned",
    baseline_method = "rrblup", delta_predictive_ability = NA_real_,
    relative_rmse_reduction = NA_real_,
    recipe_url = paste0("https://github.com/psoerensen/gpct/tree/main/benchmarks/", config$case, "_prediction"),
    report_url = paste0("https://psoerensen.github.io/gpct/reports/", config$case, ".html"))
  folds <- merge(data.frame(method = config$methods), data.frame(fold = 1:5))
  folds$dataset <- config$dataset_id; folds$trait <- config$trait
  for (field in c(report_metrics, "fit_seconds", "prediction_seconds", "method_elapsed_seconds",
                  "peak_ram_mb", "warning_count", "markers", "n_train", "n_test", "seed",
                  "requested_threads", "actual_threads")) folds[[field]] <- NA_real_
  folds$status <- "planned"; folds$convergence <- "not run"
  calibration <- data.frame(dataset = character(), trait = character(), method = character(),
    bin = integer(), n = integer(), mean_prediction = double(), mean_observed = double())
  metadata <- data.frame(dataset = config$dataset_id, trait = config$trait, run_id = "not run",
    fold_seed = config$fold_seed, method_seed_start = config$method_seed,
    source_revision = d$source_version, prepared_input_md5 = NA_character_,
    validation = "single shared random five-fold run; training-only preparation",
    blas_implementation = "not recorded", blas_runtime_threads = NA_integer_,
    blas_binary_sha256 = NA_character_, cpu_model = "not recorded",
    logical_processors = NA_integer_, installed_ram_gib = NA_real_,
    reporting_R = R.version.string)
  list(dataset_catalogue = catalogue, method_settings = settings, benchmark_results = summary,
       fold_results = folds, calibration_bins = calibration, run_metadata = metadata)
}

calibration_bins <- function(p, dataset, trait, method, bins = 10L, min_n = 5L) {
  breaks <- unique(as.numeric(stats::quantile(p$predicted, seq(0, 1, length.out = bins + 1L))))
  groups <- if (length(breaks) < 2L) rep(1L, nrow(p)) else
    as.integer(cut(p$predicted, breaks, include.lowest = TRUE))
  rows <- lapply(sort(unique(groups)), function(bin) {
    selected <- which(groups == bin)
    if (length(selected) < min_n) return(NULL)
    data.frame(dataset = dataset, trait = trait, method = method, bin = bin,
      n = length(selected), mean_prediction = mean(p$predicted[selected]),
      mean_observed = mean(p$observed[selected]))
  })
  do.call(rbind, rows)
}

summarize_prediction_run <- function(run_dir) {
  config <- readRDS(file.path(run_dir, "settings.rds"))
  saved <- readRDS(file.path(run_dir, "folds.rds"))
  stopifnot(is.character(saved$id), !anyNA(saved$id), !anyDuplicated(saved$id),
            identical(sort(unique(saved$fold)), 1:5), identical(attr(saved, "seed"), 4401L))
  versions <- read.csv(file.path(run_dir, "package_versions.csv"), stringsAsFactors = FALSE)
  tables <- report_tables(config, versions)
  tables$run_metadata$run_id <- basename(run_dir)
  tables$fold_results$status <- "not recorded"
  tables$fold_results$convergence <- "unavailable"
  report_url <- Sys.getenv("GPCT_REPORT_URL", unset = "")
  if (nzchar(report_url)) tables$benchmark_results$report_url <- report_url
  provenance_path <- file.path(run_dir, "provenance.rds")
  if (file.exists(provenance_path)) tables$run_metadata$prepared_input_md5 <- readRDS(provenance_path)$input_md5
  perf <- read.csv(file.path(run_dir, "performance.csv"), stringsAsFactors = FALSE)
  stopifnot(all(c("method", "fold", "status", "convergence", "markers") %in% names(perf)),
    all(perf$method %in% config$methods), all(perf$fold %in% 1:5),
    !anyDuplicated(paste(perf$method, perf$fold)))
  path <- file.path(run_dir, "predictions.csv")
  p <- if (file.exists(path)) read.csv(path, stringsAsFactors = FALSE) else
    data.frame(id = character(), fold = integer(), method = character(), observed = double(),
               predicted = double(), training_mean = double())
  stopifnot(all(c("id", "method", "fold", "observed", "predicted", "training_mean") %in% names(p)),
    all(p$method %in% config$methods), all(p$id %in% saved$id),
    !anyDuplicated(paste(p$method, p$id)), all(p$fold == saved$fold[match(p$id, saved$id)]),
    all(is.finite(p$observed)), all(is.finite(p$predicted)), all(is.finite(p$training_mean)))
  # Check common truth and the fold's training-mean reference across methods.
  for (id in unique(p$id)) stopifnot(length(unique(p$observed[p$id == id])) == 1L)
  for (fold in unique(p$fold)) stopifnot(length(unique(p$training_mean[p$fold == fold])) == 1L)
  for (j in seq_len(nrow(tables$fold_results))) {
    row <- tables$fold_results[j, ]; a <- perf[perf$method == row$method & perf$fold == row$fold, ]
    if (!nrow(a)) next
    common <- intersect(names(tables$fold_results), names(a))
    tables$fold_results[j, common] <- a[1, common]
    q <- p[p$method == row$method & p$fold == row$fold, ]
    expected <- saved$id[saved$fold == row$fold]
    if (a$status %in% c("completed", "completed_provisional") && setequal(q$id, expected)) {
      tables$fold_results[j, report_metrics] <- as.list(metrics(q$observed, q$predicted, q$training_mean))
    } else {
      tables$fold_results[j, report_metrics] <- NA_real_
      if (a$status != "failed") tables$fold_results$status[j] <- "incomplete"
    }
  }
  for (j in seq_len(nrow(tables$benchmark_results))) {
    method <- tables$benchmark_results$method[j]
    a <- tables$fold_results[tables$fold_results$method == method, ]
    raw <- perf[perf$method == method, ]
    q <- p[p$method == method, ]
    completed <- sum(a$status %in% c("completed", "completed_provisional"))
    full <- completed == 5L && setequal(q$id, saved$id)
    tables$benchmark_results$completed_folds[j] <- completed
    tables$benchmark_results$failed_folds[j] <- sum(a$status == "failed")
    tables$benchmark_results$missing_folds[j] <- sum(a$status %in% c("not recorded", "incomplete"))
    tables$benchmark_results$status[j] <- if (!full) {
      if (any(a$status == "failed")) "failed" else "incomplete"
    } else if (any(a$status == "completed_provisional")) "completed_provisional" else "completed"
    tables$benchmark_results$convergence[j] <- paste(sort(unique(a$convergence)), collapse = "; ")
    if (all(is.finite(a$warning_count))) tables$benchmark_results$warning_count[j] <- sum(a$warning_count)
    used <- raw$markers[is.finite(raw$markers)]
    if (length(used)) {
      tables$benchmark_results$markers_used_min[j] <- min(used)
      tables$benchmark_results$markers_used_max[j] <- max(used)
    }
    if (!full) next
    tables$benchmark_results[j, report_metrics] <- as.list(metrics(q$observed, q$predicted, q$training_mean))
    for (field in c("fit_seconds", "prediction_seconds", "method_elapsed_seconds"))
      if (all(is.finite(a[[field]]))) tables$benchmark_results[j, field] <- sum(a[[field]])
    if (all(is.finite(a$peak_ram_mb))) {
      tables$benchmark_results$peak_ram_mb[j] <- max(a$peak_ram_mb)
      tables$benchmark_results$ram_status[j] <- "recorded per-fold measurements; review measurement scope"
    }
    bins <- calibration_bins(q, config$dataset_id, config$trait, method)
    if (!is.null(bins)) tables$calibration_bins <- rbind(tables$calibration_bins, bins)
  }
  used <- perf$markers[is.finite(perf$markers)]
  tables$dataset_catalogue$individuals_eligible <- nrow(saved)
  if (length(used)) {
    tables$dataset_catalogue$markers_used_min <- min(used)
    tables$dataset_catalogue$markers_used_max <- max(used)
    tables$dataset_catalogue$marker_usage_status <- "recorded fitted-marker range across available folds"
  }
  execution <- file.path(run_dir, "execution.csv")
  if (file.exists(execution)) {
    record <- read.csv(execution, stringsAsFactors = FALSE)
    tables$benchmark_results$case_elapsed_seconds <- record$case_elapsed_seconds[1]
    for (field in intersect(c("blas_implementation", "blas_runtime_threads", "blas_binary_sha256",
                              "cpu_model", "logical_processors", "installed_ram_gib"), names(record)))
      tables$run_metadata[[field]] <- record[[field]][1]
  }
  tables
}

finish_report_tables <- function(tables) {
  s <- tables$benchmark_results
  for (group in unique(paste(s$dataset, s$trait))) {
    rows <- which(paste(s$dataset, s$trait) == group)
    baseline <- rows[s$method[rows] == "rrblup"]
    if (length(baseline) != 1L) next
    s$delta_predictive_ability[rows] <- s$predictive_ability[rows] - s$predictive_ability[baseline]
    if (is.finite(s$rmse[baseline]) && s$rmse[baseline] > 0)
      s$relative_rmse_reduction[rows] <- 1 - s$rmse[rows] / s$rmse[baseline]
  }
  tables$benchmark_results <- s
  means <- s[, c("dataset", "trait", "method", "summary_type", report_metrics, "status")]
  means$summary_type <- "mean_of_fold_metrics"
  for (j in seq_len(nrow(means))) {
    a <- tables$fold_results
    a <- a[a$dataset == means$dataset[j] & a$trait == means$trait[j] & a$method == means$method[j], ]
    for (field in report_metrics) means[j, field] <-
      if (nrow(a) == 5L && all(is.finite(a[[field]]))) mean(a[[field]]) else NA_real_
  }
  tables$fold_metric_means <- means
  tables
}

plot_prediction_report <- function(tables, directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  s <- tables$benchmark_results; f <- tables$fold_results
  planned <- all(s$status == "planned")
  groups <- unique(paste(s$dataset, s$trait, sep = " / "))
  titles <- c(performance = "Predictive performance", improvement = "Improvement over rrBLUP",
              runtime = "Performance versus fitting time", calibration = "Aggregate calibration")
  for (kind in names(titles)) {
    grDevices::svg(file.path(directory, paste0(kind, ".svg")), width = 11,
                   height = max(5, 4.5 * length(groups)), pointsize = 13, family = "sans")
    tryCatch({
      graphics::par(mfrow = c(length(groups), 1), mar = c(4.5, 10, 3.2, 2), oma = c(2, 0, 3, 0))
      for (group in groups) {
        a <- s[paste(s$dataset, s$trait, sep = " / ") == group, ]
        folds <- f[paste(f$dataset, f$trait, sep = " / ") == group, ]
        y <- rev(seq_len(nrow(a))); labels <- unname(report_labels[a$method])
        valid <- a$status %in% c("completed", "completed_provisional")
        if (kind %in% c("performance", "improvement")) {
          values <- if (kind == "performance") a$predictive_ability else a$delta_predictive_ability
          small <- folds$predictive_ability
          if (kind == "improvement") {
            base <- folds[folds$method == "rrblup", ]
            small <- small - base$predictive_ability[match(folds$fold, base$fold)]
            if (!any(a$method == "rrblup" & valid)) small[] <- NA_real_
          }
          small[!folds$method %in% a$method[valid]] <- NA_real_
          measured <- c(values, small); measured <- measured[is.finite(measured)]
          bounds <- if (length(measured)) range(c(0, measured)) else
            if (kind == "performance") c(-1, 1) else c(-.1, .1)
          if (length(measured)) {
            padding <- max(.01, diff(bounds) * .08)
            bounds <- bounds + c(-padding, padding)
            if (kind == "performance") bounds <- pmax(-1, pmin(1, bounds))
          }
          graphics::plot(NA, xlim = bounds, ylim = c(.5, nrow(a) + .5), yaxt = "n", ylab = "",
            xlab = if (kind == "performance") "Predictive ability (Pearson correlation)" else "Difference in predictive ability from rrBLUP",
            main = group, bty = "l")
          graphics::axis(2, at = y, labels = labels, las = 1, tick = FALSE)
          graphics::abline(v = 0, col = "#c9ced5", lty = 2)
          for (i in seq_len(nrow(a))) {
            rows <- which(folds$method == a$method[i] & is.finite(small))
            if (length(rows)) graphics::points(small[rows], y[i] + seq(-.12, .12, length.out = length(rows)),
                                               pch = 1, cex = .75, col = report_colors[a$method[i]])
            if (valid[i] && is.finite(values[i])) graphics::points(values[i], y[i], pch = 19,
                                                                  cex = 1.2, col = report_colors[a$method[i]])
          }
          if (!any(is.finite(values))) graphics::text(mean(bounds), mean(y),
            if (planned) "Template: no measured benchmark results" else "No complete defined scores available", col = "#586069")
        } else if (kind == "runtime") {
          use <- valid & is.finite(a$fit_seconds) & is.finite(a$predictive_ability)
          ability_limits <- if (any(use)) range(a$predictive_ability[use]) else c(-1, 1)
          if (any(use)) ability_limits <- pmax(-1, pmin(1, ability_limits +
            c(-1, 1) * max(.02, diff(ability_limits) * .15)))
          graphics::plot(NA, xlim = c(0, if (any(use)) max(a$fit_seconds[use]) * 1.2 + .01 else 1),
            ylim = ability_limits, xlab = "Fitting time (seconds; sum of five folds)",
            ylab = "Predictive ability (pooled OOF)", main = group, bty = "l")
          if (any(use)) graphics::points(a$fit_seconds[use], a$predictive_ability[use], pch = 19, cex = 1.2,
                                         col = report_colors[a$method[use]])
          else graphics::text(.5, 0, if (planned) "Template: no measured benchmark results" else
            "Complete performance/timing pairs unavailable", col = "#586069")
          graphics::legend("bottomright", legend = labels, col = report_colors[a$method], pch = 19, bty = "n", cex = .8)
        } else {
          bins <- tables$calibration_bins
          bins <- bins[paste(bins$dataset, bins$trait, sep = " / ") == group, ]
          limits <- if (nrow(bins)) range(c(bins$mean_prediction, bins$mean_observed)) else c(0, 1)
          if (diff(limits) == 0) limits <- limits + c(-.5, .5)
          graphics::plot(NA, xlim = limits, ylim = limits, xlab = "Binned mean prediction (source trait units)",
            ylab = "Mean observed phenotype", main = group, bty = "l")
          graphics::abline(0, 1, lty = 2, col = "#697582")
          for (method in a$method) {
            rows <- bins[bins$method == method, ]; rows <- rows[order(rows$mean_prediction), ]
            if (nrow(rows)) graphics::lines(rows$mean_prediction, rows$mean_observed,
                                           type = "b", pch = 19, col = report_colors[method])
          }
          if (!nrow(bins)) graphics::text(.5, .75, if (planned) "Template: awaiting aggregate calibration bins" else
            "No aggregate calibration bins available", col = "#586069")
          graphics::legend("bottomright", legend = labels, col = report_colors[a$method], pch = 19, bty = "n", cex = .8)
        }
      }
      graphics::mtext(titles[kind], outer = TRUE, side = 3, line = 1, font = 2, cex = 1.2)
      note <- if (kind %in% c("performance", "improvement"))
        "Filled: pooled OOF score. Open: descriptive fold values. No confidence intervals." else
        if (kind == "runtime") "Compare within dataset/trait. Missing timing and RAM remain explicit in CSV tables." else
          "Pooled OOF quantile bins; at least 5 samples/bin. Dashed line: identity. No individual predictions."
      graphics::mtext(note, outer = TRUE, side = 1, cex = .75)
    }, finally = grDevices::dev.off())
  }
}

markdown_table <- function(table) {
  format_value <- function(x) {
    if (is.numeric(x)) x <- format(signif(x, 5), trim = TRUE)
    x <- as.character(x); x[is.na(x) | x == "NA"] <- "not available"
    gsub("|", "\\|", gsub("[\r\n]+", " ", x), fixed = TRUE)
  }
  if (!nrow(table)) return("No measured rows available.")
  values <- as.data.frame(lapply(table, format_value), stringsAsFactors = FALSE)
  titles <- c(predictive_ability = "Predictive ability", rmse = "RMSE", predictive_r_squared = "Predictive R²",
    fit_seconds = "Fit (s)", prediction_seconds = "Predict (s)", method_elapsed_seconds = "Method elapsed (s)",
    peak_ram_mb = "Peak RAM (MB)", markers_used_min = "Markers fitted, min", markers_used_max = "Markers fitted, max",
    available_markers = "Available markers", planned_markers = "Planned markers",
    individuals_available = "Individuals available", individuals_eligible = "Eligible individuals")
  headers <- tools::toTitleCase(gsub("_", " ", names(values)))
  selected <- names(values) %in% names(titles)
  headers[selected] <- titles[names(values)[selected]]
  c(paste0("| ", paste(headers, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(values)), collapse = " | "), " |"),
    apply(values, 1L, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
}

write_report_page <- function(tables, path) {
  s <- tables$benchmark_results; catalogue <- tables$dataset_catalogue
  planned <- all(s$status == "planned")
  heading <- if (nrow(catalogue) == 1L) paste(catalogue$dataset, catalogue$trait) else "Prediction benchmark collection"
  page <- c("---", "layout: default", paste0("title: ", heading), "---", paste0("# ", heading), "",
    if (planned) "**Planned report template. No measured benchmark results.**" else
      "**Generated run summary. Review failures, diagnostics and publication rights before release.**", "",
    "## Scientific question and dataset", "",
    "How well do the declared methods predict the supplied trait within this dataset under shared random five-fold validation? Source trait definitions, upstream adjustments and units remain unverified.", "",
    paste0("Recipe: [", unique(s$dataset), "](", unique(s$recipe_url), ")"), "",
    markdown_table(catalogue[, c("species", "dataset", "trait", "individuals_available", "individuals_eligible", "available_markers", "planned_markers", "markers_used_min", "markers_used_max")]), "",
    "[Dataset catalogue CSV](dataset_catalogue.csv)", "",
    "## Methods and validation design", "",
    "Single shared five-fold partition, seed 4401. All methods use the same eligible samples and frozen training-only transformations. Fixed pilot settings; no tuning on test folds. REML rrBLUP is the baseline.", "",
    markdown_table(tables$method_settings), "",
    "[Method settings CSV](method_settings.csv) · [Run metadata CSV](run_metadata.csv)", "",
    "## Main results", "",
    "Main metrics are calculated from pooled out-of-fold predictions. Fold means are a separate descriptive summary. NA means not run, not measured or undefined; consult status. Available markers and actually fitted markers are separate.", "",
    markdown_table(s[, c("dataset", "trait", "method", report_metrics, "fit_seconds", "prediction_seconds", "method_elapsed_seconds", "peak_ram_mb", "ram_status", "status")]), "",
    "[Download summary CSV](benchmark_results.csv) · [Per-fold metrics](fold_results.csv) · [Fold means](fold_metric_means.csv)", "",
    "## Performance and computational cost", "",
    "Filled dots show pooled OOF scores; open dots show descriptive fold values. No confidence intervals are implied. Baseline changes use matched dataset/trait and folds. Raw RMSE is never combined across traits.", "",
    '<figure class="report-figure"><img src="performance.svg" alt="Predictive ability by method, with pooled and fold values distinguished."></figure>', "",
    "[Full-size performance SVG](performance.svg)", "",
    '<figure class="report-figure"><img src="improvement.svg" alt="Change in predictive ability from rrBLUP with a zero reference line."></figure>', "",
    "[Full-size baseline-improvement SVG](improvement.svg)", "",
    '<figure class="report-figure"><img src="runtime.svg" alt="Pooled predictive ability versus fitting seconds, coloured by method."></figure>', "",
    "[Full-size performance/runtime SVG](runtime.svg)", "",
    "Fitting and prediction seconds are summed over five folds. Method elapsed includes loading, diagnostics and scoring but excludes shared input/fold preparation and CSV writes. Case elapsed includes all methods and shared work and is not a per-method cost. Peak RAM and observed per-fit thread utilization remain unmeasured. gbayes requests one package worker. Run metadata records the loaded BLAS implementation, its runtime thread setting, binary checksum and hardware; a thread setting does not measure CPU utilization.", "",
    "## Calibration, convergence, warnings and failed fits", "",
    "Calibration uses pooled OOF quantile bins (up to ten, at least five individuals per published bin) and an identity line. Only aggregate bin means and counts leave the local run; review them before publication. These plots do not recalibrate predictions.", "",
    '<figure class="report-figure"><img src="calibration.svg" alt="Binned mean observed phenotype versus mean prediction, with an identity line."></figure>', "",
    "[Full-size calibration SVG](calibration.svg)", "",
    "[Aggregate calibration CSV](calibration_bins.csv)", "",
    markdown_table(tables$fold_results[, c("method", "fold", "status", "convergence", "warning_count")]), "",
    "Failed or incomplete methods keep their fold statuses; pooled scores and comparison plots are withheld. Raw warning/error text and full diagnostic objects remain local because they can contain identifiers or paths. Unknown convergence and missing resource measurements are explicit. Completion does not certify scientific validity.", "",
    "## Reproduce and inspect", "", "From the repository root, first build and activate the pinned environment described in the repository's environment/README.md:", "", "```text",
    "Rscript --vanilla environment/preflight.R",
    "Rscript --vanilla scripts/check_dependencies.R", "Rscript --vanilla tests/check_protocol.R",
    "Rscript --vanilla tests/check_reporting.R")
  for (case in unique(sub("gpbench_", "", catalogue$dataset))) page <- c(page,
    paste("Rscript --vanilla scripts/prepare.R", case),
    paste0("Rscript --vanilla benchmarks/", case, "_prediction/run.R"))
  page <- c(page, "Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY", "```", "",
    "Set external GPCT_DATA_DIR/GPCT_OUTPUT_DIR and acknowledge the positional-ID contract before preparation. Do not publish individual predictions, folds or raw diagnostic files. Preserve the run's original settings, versions and input checksum.", "",
    "[Settings and versions](method_settings.csv) · [Reporting sessionInfo](report-sessionInfo.txt) · [Run metadata](run_metadata.csv)", "",
    "Repeated validation with identical method splits can be added later. Five folds are descriptive partitions, not independent experimental replicates. Association and genetic-correlation cases need separate outcomes and reporting schemas.")
  writeLines(page, path)
}

write_prediction_report <- function(tables, directory) {
  if (dir.exists(directory)) stop("Report destination already exists; use a new directory.")
  dir.create(directory, recursive = TRUE)
  tables <- finish_report_tables(tables)
  for (name in names(tables)) utils::write.csv(tables[[name]], file.path(directory, paste0(name, ".csv")),
                                            row.names = FALSE, na = "NA")
  plot_prediction_report(tables, directory)
  write_report_page(tables, file.path(directory, "report.md"))
  capture.output(sessionInfo(), file = file.path(directory, "report-sessionInfo.txt"))
  invisible(tables)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1L || length(args) > 2L)
    stop("Rscript --vanilla scripts/report_prediction.R --templates [NEW_DIRECTORY] OR RUN_DIRECTORY [NEW_DIRECTORY]")
  if (args[1] == "--templates") {
    cases <- lapply(c("cattle", "maize"), function(case) report_tables(case_config(case)))
    tables <- lapply(names(cases[[1]]), function(name) do.call(rbind, lapply(cases, `[[`, name)))
    names(tables) <- names(cases[[1]])
    directory <- if (length(args) == 2L) args[2] else "docs/assets/reports/templates"
  } else {
    source("scripts/paths.R")
    run_dir <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
    tables <- summarize_prediction_run(run_dir)
    directory <- if (length(args) == 2L) args[2] else file.path(run_dir, "report")
    checkout <- tolower(normalizePath(".", winslash = "/"))
    destination <- tolower(normalizePath(directory, winslash = "/", mustWork = FALSE))
    if (destination == checkout || startsWith(destination, paste0(checkout, "/")))
      stop("Measured reports must be generated outside the checkout, then reviewed before publication.")
  }
  write_prediction_report(tables, directory)
  if (args[1] == "--templates") for (case in c("cattle", "maize"))
    write_prediction_report(report_tables(case_config(case)), file.path(directory, case))
  cat("Report written to", directory, "\n")
}
