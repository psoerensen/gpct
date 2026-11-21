# Thin case recipe: package fits, shared folds, metrics and provenance only.
source("scripts/paths.R")
source("scripts/evaluate.R")
run_id <- Sys.getenv("GPCT_RUN_ID", paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "-", Sys.getpid()))
if (!grepl("^[A-Za-z0-9_-]+$", run_id)) stop("Invalid GPCT_RUN_ID")
destination <- file.path(output_dir(), config$case, run_id)
if (dir.exists(destination)) stop("Run directory exists; use a new GPCT_RUN_ID.")
dir.create(destination, recursive = TRUE)
write_status <- function(status, message = "") {
  write.csv(data.frame(status = status, message = message,
                      timestamp_utc = format(Sys.time(), tz = "UTC")),
            file.path(destination, "run_status.csv"), row.names = FALSE)
}
write_status("running")
saveRDS(config, file.path(destination, "settings.rds"))
capture.output(sessionInfo(), file = file.path(destination, "sessionInfo-start.txt"))
packages <- c("rrBLUP", "gbayes", "gbase", "glma", "gcorr", "gsuite", "digest", "reticulate")
versions <- vapply(packages, function(p) {
  if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else "MISSING"
}, character(1))
write.csv(data.frame(package = packages, version = versions),
          file.path(destination, "package_versions.csv"), row.names = FALSE)
results <- list(); predictions <- list()
save_tables <- function() {
  if (length(results)) write.csv(do.call(rbind, results), file.path(destination, "performance.csv"), row.names = FALSE)
  if (length(predictions)) write.csv(do.call(rbind, predictions), file.path(destination, "predictions.csv"), row.names = FALSE)
}

run <- function() {
  input_path <- file.path(data_dir(), "prepared", paste0(config$case, ".rds"))
  if (!file.exists(input_path)) stop("Missing prepared input; run scripts/prepare.R ", config$case)
  input <- readRDS(input_path)
  if (!identical(input$metadata$dataset_id, config$dataset_id) ||
      !isTRUE(input$metadata$positional_alignment_accepted) ||
      !identical(input$ids, rownames(input$X)) || !identical(input$ids, rownames(input$Y)) ||
      anyNA(input$ids) || anyDuplicated(input$ids) || any(!nzchar(input$ids)) ||
      !is.matrix(input$X) || !is.numeric(input$X) ||
      nrow(input$X) != config$n || ncol(input$X) != config$marker_count ||
      is.null(colnames(input$X)) || anyNA(colnames(input$X)) ||
      any(!nzchar(colnames(input$X))) || anyDuplicated(colnames(input$X)) ||
      !config$trait %in% colnames(input$Y)) stop("Prepared input contract failed.")
  eligible <- is.finite(input$Y[, config$trait])
  X <- input$X[eligible, , drop = FALSE]
  y <- input$Y[eligible, config$trait]
  ids <- input$ids[eligible]
  folds <- saved_folds(ids, file.path(data_dir(), "folds", paste0(config$case, "-", config$trait, "-seed4401.rds")))
  saveRDS(folds, file.path(destination, "folds.rds"))
  saveRDS(list(source = input$metadata, input_md5 = unname(tools::md5sum(input_path)),
               scripts_md5 = tools::md5sum(c("scripts/run_prediction.R", "scripts/evaluate.R",
                 "scripts/prepare.R", "scripts/paths.R", paste0("benchmarks/", config$case, "_prediction/config.R"))),
               config = config, eligible_n = length(ids), excluded_n = sum(!eligible),
               R = R.version.string, RNG = c("Mersenne-Twister", "Inversion", "Rejection")),
          file.path(destination, "provenance.rds"))
  any_failure <- FALSE
  for (fold in 1:5) {
    train <- which(folds$fold != fold); test <- which(folds$fold == fold)
    # No test outcomes are passed to preparation, fitting or prediction.
    prep <- prepare_fold(X[train, , drop = FALSE], X[test, , drop = FALSE])
    train_mean <- mean(y[train]); train_sd <- stats::sd(y[train])
    if (!is.finite(train_sd) || train_sd <= 0) stop("Degenerate training response.")
    training <- data.frame(id = ids[train], response = (y[train] - train_mean) / train_sd)
    saveRDS(list(centers = prep$centers, scales = prep$scales, markers = prep$markers,
                 response_mean = train_mean, response_sd = train_sd),
            file.path(destination, paste0("preprocessing-fold", fold, ".rds")))
    for (method in config$methods) {
      key <- paste0(method, "-fold", fold)
      seed <- config$method_seed + fold - 1L
      set.seed(seed)
      warnings <- character(); fit_seconds <- prediction_seconds <- NA_real_
      stage <- "package_check"
      row <- data.frame(method = method, fold = fold, seed = seed,
        n_train = length(train), n_test = length(test), markers = ncol(prep$training),
        status = "failed", convergence = "unavailable", message = "",
        fit_seconds = NA_real_, prediction_seconds = NA_real_,
        predictive_ability = NA_real_, rmse = NA_real_, predictive_r_squared = NA_real_,
        calibration_intercept = NA_real_, calibration_slope = NA_real_)
      tryCatch(withCallingHandlers({
        package <- if (method == "rrblup") "rrBLUP" else "gbayes"
        if (!requireNamespace(package, quietly = TRUE)) stop("Missing package: ", package)
        stage <- "fitting"
        started <- proc.time()[["elapsed"]]
        if (method == "rrblup") {
          fit <- rrBLUP::mixed.solve(y = training$response, Z = prep$training,
                                    method = "REML", bounds = c(1e-9, 1e9))
          diagnostics <- list(Vu = fit$Vu, Ve = fit$Ve, LL = fit$LL,
                              convergence = "not exposed by mixed.solve")
        } else if (method == "gbayes_gaussian") {
          fit <- gbayes::bayes(data = training, X = prep$training, trait = "response",
            method = "marker_gaussian", algorithm = "pcg", nit = config$nit,
            ve = 1 - config$gaussian_h2,
            prior = list(markerVariance = stats::setNames(
              rep(config$gaussian_h2 / ncol(prep$training), ncol(prep$training)), colnames(prep$training))),
            control = list(tolerance = config$tolerance, memoryLimit = config$memory_limit))
        } else if (method == "gbayes_elastic_net") {
          fit <- gbayes::bayes(data = training, X = prep$training, trait = "response",
            method = "elastic_net", algorithm = "coordinate_descent", nit = config$nit,
            control = list(lambda = config$lambda, alpha = config$alpha,
              tolerance = config$tolerance, memoryLimit = config$memory_limit))
        } else stop("Unknown configured method: ", method)
        fit_seconds <- proc.time()[["elapsed"]] - started
        stage <- "diagnostics"
        if (method != "rrblup") diagnostics <- gbayes::diagnostics(fit)
        saveRDS(diagnostics, file.path(destination, paste0(key, "-diagnostics.rds")))
        stage <- "prediction"
        started <- proc.time()[["elapsed"]]
        standardized_prediction <- if (method == "rrblup") {
          as.numeric(fit$beta) + as.numeric(prep$target %*% fit$u)
        } else as.numeric(stats::predict(fit, newdata = prep$target, type = "phenotype"))
        prediction_seconds <- proc.time()[["elapsed"]] - started
        stage <- "evaluation"
        predicted <- train_mean + train_sd * standardized_prediction
        stopifnot(length(predicted) == length(test), all(is.finite(predicted)))
        # Held-out responses become available only for scoring here.
        score <- metrics(y[test], predicted, train_mean)
        row[names(score)] <- as.list(score)
        row$convergence <- if (method == "rrblup") "not exposed" else {
          value <- diagnostics$convergence$status
          if (is.null(value)) "unavailable" else paste(value, collapse = ";")
        }
        row$status <- if (method == "rrblup" || row$convergence == "converged") "completed" else "completed_provisional"
        predictions[[key]] <<- data.frame(id = ids[test], fold = fold, method = method,
          observed = y[test], predicted = predicted, training_mean = train_mean)
      }, warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
      }), error = function(e) {
        if (stage == "fitting") fit_seconds <<- proc.time()[["elapsed"]] - started
        if (stage == "prediction") prediction_seconds <<- proc.time()[["elapsed"]] - started
        row$message <<- conditionMessage(e); any_failure <<- TRUE
      })
      row$fit_seconds <- fit_seconds; row$prediction_seconds <- prediction_seconds
      row$message <- paste(c(row$message[nzchar(row$message)], warnings), collapse = "; ")
      results[[key]] <<- row
      save_tables()
      cat(key, row$status, row$message, "\n")
    }
  }
  if (any_failure) stop("One or more fold/method runs failed; see performance.csv.")
}

ok <- tryCatch({run(); TRUE}, error = function(e) {
  save_tables(); write_status("failed", conditionMessage(e));
  message(conditionMessage(e)); FALSE
})
capture.output(sessionInfo(), file = file.path(destination, "sessionInfo.txt"))
if (ok) write_status("completed", "Review per-method convergence; completion does not certify scientific validity.")
cat("Run artifacts:", destination, "\n")
if (!ok) quit(status = 1L)
