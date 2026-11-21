args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
library <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
cache <- normalizePath(args[2], winslash = "/", mustWork = TRUE)
lock <- read.csv(args[3], stringsAsFactors = FALSE)
.libPaths(c(library, .Library))
for (i in seq_len(nrow(lock))) {
  package <- lock$package[i]
  present <- tryCatch(utils::packageVersion(package, lib.loc = library),
                      error = function(e) NULL)
  if (is.null(present) || present != package_version(lock$version[i])) {
    archive <- file.path(cache, paste0(package, "_", lock$version[i], ".zip"))
    utils::install.packages(archive, repos = NULL, type = "win.binary", lib = library)
  }
  stopifnot(utils::packageVersion(package, lib.loc = library) == package_version(lock$version[i]))
}
cat("All pinned CRAN dependency versions match.\n")
