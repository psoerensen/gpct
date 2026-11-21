packages <- c("rrBLUP", "gbayes", "digest", "reticulate", "glma", "gcorr", "gsuite")
cat(R.version.string, "\n")
for (p in packages) {
  available <- requireNamespace(p, quietly = TRUE)
  cat(p, if (available) as.character(utils::packageVersion(p)) else "MISSING", "\n")
}
cat("\nPrediction requires rrBLUP and compatible gbayes; preparation requires digest, reticulate and NumPy.\n")
cat("glma/gcorr/gsuite are recorded for future cases, not required for these pilots.\n")
if (requireNamespace("gbayes", quietly = TRUE)) {
  cat("\ngbayes::bayes formals:\n")
  if ("bayes" %in% getNamespaceExports("gbayes")) print(formals(gbayes::bayes))
  else cat("MISSING exported bayes interface\n")
}
if (requireNamespace("reticulate", quietly = TRUE)) {
  Sys.setenv(RETICULATE_USE_MANAGED_VENV = "no")
  tryCatch({
    print(reticulate::py_config())
    cat("NumPy available:", reticulate::py_module_available("numpy"), "\n")
  }, error = function(e) cat("Python check failed:", conditionMessage(e), "\n"))
}
