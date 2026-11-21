# Bounded synthetic interface qualification; these are not GPBench results.
root <- Sys.getenv("GPCT_ENV_DIR")
stopifnot(nzchar(root))
library(gbase)
library(glma)
source(file.path(root, "sources/gsuite/packages/glma/tests/testthat/helper-plink.R"))
set.seed(1910)
n <- 128L
m <- 96L
genotype <- matrix(rbinom(n * m, 2L, 0.35), n, m)
paths <- write_glma_plink(genotype, paste0("synthetic", seq_len(m)),
  chromosome = rep(c("1", "2"), each = m / 2L))
Glist <- gbase::gprep(bedfiles = paths[["bed"]])
covariate <- matrix(rnorm(n), ncol = 1L)
phenotype <- 0.25 * covariate[, 1L] + 0.4 * genotype[, 2L] +
  0.3 * genotype[, 65L] + rnorm(n)
out <- file.path(root, "qualification/glma-mkl")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
results <- list()
rows <- list()
for (method in c("infinitesimal_loco", "prior_selected_loco")) {
  fun <- getExportedValue("glma", paste0("glma_", method))
  for (threads in c(1L, 4L)) {
    key <- paste(method, threads, sep = "-")
    cat("BEGIN_GLMA", key, "\n")
    elapsed <- system.time(fit <- fun(phenotype, Glist, covariate,
      threads = threads, block_size = 32L,
      controls = list(scaling_factor = 1)))[["elapsed"]]
    stopifnot(inherits(fit, "glma_fit"), nrow(fit$associations) == m,
      nrow(fit$fit$loco) == 2L, all(is.finite(fit$associations$p)),
      all(fit$associations$p >= 0 & fit$associations$p <= 1))
    results[[key]] <- fit
    rows[[key]] <- data.frame(method, threads, individuals = n, markers = m,
      elapsed_seconds = elapsed, selected_prior = fit$fit$selected_prior,
      candidates = fit$diagnostics$candidate_model_count,
      fit_seconds = fit$diagnostics$fit_seconds,
      scan_seconds = fit$diagnostics$scan_seconds,
      variance_estimator = fit$diagnostics$variance_estimator)
    cat("END_GLMA", key, "elapsed", elapsed, "prior", fit$fit$selected_prior, "\n")
  }
  a <- results[[paste(method, 1L, sep = "-")]]
  b <- results[[paste(method, 4L, sep = "-")]]
  stopifnot(isTRUE(all.equal(a$associations$p, b$associations$p, tolerance = 1e-7)),
    identical(a$fit$selected_prior, b$fit$selected_prior))
}
write.csv(do.call(rbind, rows), file.path(out, "timings.csv"), row.names = FALSE)
saveRDS(results, file.path(out, "synthetic-fits.rds"))
capture.output(sessionInfo(), file = file.path(out, "session-info.txt"))
unlink(paths)
cat("PASS: both interfaces; finite results; one/four-worker agreement.\n")
