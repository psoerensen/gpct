plot_prediction_report <- function(tables, directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  s <- tables$benchmark_results; f <- tables$fold_results
  planned <- all(s$status == "planned")
  groups <- unique(paste(s$dataset, s$trait, sep = " / "))
  titles <- c(performance = "Predictive performance", improvement = "Improvement over training mean",
              runtime = "Performance versus workflow time", calibration = "Aggregate calibration")
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
          values <- if (kind == "performance") a$predictive_ability else a$relative_rmse_reduction
          small <- if (kind == "performance") folds$predictive_ability else folds$relative_rmse_reduction
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
            xlab = if (kind == "performance") "Predictive ability (Pearson correlation)" else "Relative RMSE reduction versus training mean",
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
          use <- valid & is.finite(a$workflow_seconds) & is.finite(a$predictive_ability)
          ability_limits <- if (any(use)) range(a$predictive_ability[use]) else c(-1, 1)
          if (any(use)) ability_limits <- pmax(-1, pmin(1, ability_limits +
            c(-1, 1) * max(.02, diff(ability_limits) * .15)))
          graphics::plot(NA, xlim = c(0, if (any(use)) max(a$workflow_seconds[use]) * 1.2 + .01 else 1),
            ylim = ability_limits, xlab = "Workflow time (seconds; 10 folds plus preparation)",
            ylab = "Predictive ability (mean of folds)", main = group, bty = "l")
          if (any(use)) graphics::points(a$workflow_seconds[use], a$predictive_ability[use], pch = 19, cex = 1.2,
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
        "Filled: mean of 10 fold scores. Open: descriptive folds. No confidence intervals." else
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
