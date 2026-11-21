root <- Sys.getenv("GPCT_ENV_DIR")
if (!nzchar(root)) stop("Activate the pinned environment first: ./environment/activate.ps1")
pin <- read.csv("environment/runtime.csv", stringsAsFactors = FALSE)
expected <- stats::setNames(pin$value, pin$key)
stopifnot(as.character(getRversion()) == expected[["r_version"]])
stopifnot(tolower(normalizePath(R.home(), winslash = "/")) ==
          tolower(normalizePath(file.path(root, "R"), winslash = "/")))
for (p in c("gbase", "gbayes", "rrBLUP", "digest", "reticulate")) {
  if (!requireNamespace(p, quietly = TRUE)) stop("Missing required package: ", p)
  path <- tolower(normalizePath(find.package(p), winslash = "/"))
  if (!startsWith(path, paste0(tolower(normalizePath(root, winslash = "/")), "/")))
    stop("Package is outside the isolated environment: ", p)
  cat(p, as.character(utils::packageVersion(p)), "\n")
}
stopifnot(as.character(utils::packageVersion("gbayes")) == expected[["gbayes_version"]],
          all(c("bayes", "diagnostics", "fit_contract") %in% getNamespaceExports("gbayes")))
if (!"blas_probe" %in% names(getLoadedDLLs())) dyn.load(file.path(root, "probe", "blas_probe.dll"))
gpct_blas <- .Call("gpct_blas_info")
checksums <- read.csv(file.path(root, "runtime-checksums.csv"), stringsAsFactors = FALSE)
expected_hash <- checksums$sha256[checksums$component == "Rblas.dll"]
stopifnot(length(expected_hash) == 1L,
          identical(digest::digest(file = gpct_blas$library_path, algo = "sha256"), expected_hash))
stopifnot(grepl(paste0("OpenBLAS ", expected[["openblas_version"]]), gpct_blas$implementation),
          gpct_blas$threads == as.integer(Sys.getenv("OMP_NUM_THREADS")))
print(gpct_blas[c("implementation", "core", "threads")])
cat("Pinned environment and optimized BLAS preflight passed.\n")
