# Source from the repository root. All individual artifacts stay outside git.
external_dir <- function(variable, default) {
  path <- normalizePath(path.expand(Sys.getenv(variable, default)),
                        winslash = "/", mustWork = FALSE)
  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  # Windows paths are case insensitive; normalize comparisons on all platforms.
  if (tolower(path) == tolower(root) ||
      startsWith(tolower(path), paste0(tolower(root), "/")))
    stop(variable, " must point outside the repository.", call. = FALSE)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  # Resolve existing symlinks/junctions before any artifacts are written.
  if (tolower(path) == tolower(root) ||
      startsWith(tolower(path), paste0(tolower(root), "/")))
    stop(variable, " resolves inside the repository.", call. = FALSE)
  path
}
data_dir <- function() external_dir("GPCT_DATA_DIR", "~/gpct-data")
output_dir <- function() external_dir("GPCT_OUTPUT_DIR", "~/gpct-results")
