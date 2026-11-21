args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args %in% c("cattle", "maize"))
  stop("Run from repo root: Rscript --vanilla scripts/prepare.R cattle|maize")
source("scripts/paths.R")
source(file.path("benchmarks", paste0(args, "_prediction"), "config.R"))
for (p in c("digest", "reticulate"))
  if (!requireNamespace(p, quietly = TRUE)) stop("Missing package: ", p)
if (Sys.getenv("GPCT_ACCEPT_POSITIONAL_IDS") != "yes")
  stop("Read datasets/README.md; acknowledge source row-order assumption with GPCT_ACCEPT_POSITIONAL_IDS=yes")
Sys.setenv(RETICULATE_USE_MANAGED_VENV = "no")
np <- reticulate::import("numpy", convert = FALSE)
root <- data_dir()
revision <- "f0204d8372fb5ec8fa29eb3f00c9a9d0a7656517"
checksum <- "fa02416336dd99d521a1533d2035b48fa02b723a7458236bd33b2c11b248ab67"
archive <- Sys.getenv("GPCT_ARCHIVE", file.path(root, "raw", "Benchmarkdata.zip"))
if (!file.exists(archive)) {
  dir.create(dirname(archive), recursive = TRUE, showWarnings = FALSE)
  url <- paste0("https://huggingface.co/datasets/xw97/GPBench/resolve/", revision,
                "/Benchmarkdata.zip?download=true")
  options(timeout = max(600, getOption("timeout")))
  utils::download.file(url, archive, mode = "wb")
}
if (!identical(digest::digest(file = archive, algo = "sha256"), checksum))
  stop("Archive SHA-256 mismatch; do not use unverified input.")
members <- paste0("Benchmarkdata/Benchmarkdata/", config$species_folder,
                  c("/genotype.npz", "/phenotype.npz"))
listing <- utils::unzip(archive, list = TRUE)$Name
if (!all(members %in% listing)) stop("Expected archive members missing.")
raw <- file.path(root, "raw", revision)
dir.create(raw, recursive = TRUE, showWarnings = FALSE)
utils::unzip(archive, files = members, exdir = raw, overwrite = TRUE)
g <- np$load(file.path(raw, members[1]), allow_pickle = FALSE)
ph <- np$load(file.path(raw, members[2]), allow_pickle = FALSE)
genotype <- reticulate::py_get_item(g, "arr_0")
shape <- as.integer(unlist(reticulate::py_to_r(genotype$shape)))
if (!identical(shape, as.integer(c(config$n, config$p)))) stop("Genotype shape differs from registry.")
columns <- unique(as.integer(round(seq(1, shape[2], length.out = config$marker_count))))
X <- reticulate::py_to_r(np$take(genotype, columns - 1L, axis = 1L))
Y <- reticulate::py_to_r(reticulate::py_get_item(ph, "arr_0"))
traits <- as.character(reticulate::py_to_r(reticulate::py_get_item(ph, "arr_1")))
if (!is.matrix(X) || any(!is.finite(X)) || any(!X %in% 0:2)) stop("Unexpected selected genotype coding.")
if (!is.matrix(Y) || nrow(Y) != nrow(X) || !identical(traits, config$traits) || ncol(Y) != length(traits))
  stop("Phenotype dimensions or trait names differ from registry.")
ids <- sprintf(paste0(config$dataset_id, ":row:%06d"), seq_len(nrow(X)))
rownames(X) <- rownames(Y) <- ids
colnames(X) <- paste0(config$dataset_id, ":column:", columns)
colnames(Y) <- traits
prepared <- list(X = X, Y = Y, ids = ids, source_columns = columns,
  metadata = list(dataset_id = config$dataset_id, source_revision = revision,
    archive_sha256 = checksum, positional_alignment_accepted = TRUE,
    marker_scope = "512 evenly spaced source columns; no outcome selection",
    upstream_processing = "unknown", prepared_utc = format(Sys.time(), tz = "UTC"),
    numpy_version = reticulate::py_to_r(np$`__version__`)))
destination <- file.path(root, "prepared", paste0(args, ".rds"))
dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
saveRDS(prepared, destination)
g$close(); ph$close()
cat("Prepared:", destination, "\n")
