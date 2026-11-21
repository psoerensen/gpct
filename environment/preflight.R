root <- Sys.getenv("GPCT_ENV_DIR")
if (!nzchar(root)) stop("Activate the pinned environment first: ./environment/activate.ps1")
pin <- read.csv("environment/runtime.csv", stringsAsFactors = FALSE)
expected <- stats::setNames(pin$value, pin$key)
stopifnot(as.character(getRversion()) == expected[["r_version"]])
stopifnot(tolower(normalizePath(R.home(), winslash = "/")) ==
          tolower(normalizePath(file.path(root, "R"), winslash = "/")))
for (p in c("gbase", "gsuite", "gbayes", "digest", "jsonlite", "reticulate")) {
  if (!requireNamespace(p, quietly = TRUE)) stop("Missing required package: ", p)
  path <- tolower(normalizePath(find.package(p), winslash = "/"))
  if (!startsWith(path, paste0(tolower(normalizePath(root, winslash = "/")), "/")))
    stop("Package is outside the isolated environment: ", p)
  cat(p, as.character(utils::packageVersion(p)), "\n")
}
stopifnot(all(c("gs_lmm_fit", "gs_lmm_blup", "gs_lmm_control", "gs_relationship_matrix",
                "gs_lmm_model", "gs_lmm_records", "gs_lmm_channel", "gs_lmm_component",
                "gsuite_solve", "gsuite_versions") %in% getNamespaceExports("gsuite")))
stopifnot(as.character(utils::packageVersion('gbase'))==expected[['gbase_version']],
          as.character(utils::packageVersion('gsuite'))==expected[['gsuite_version']])
native_versions <- gsuite::gsuite_versions()
stopifnot(as.character(utils::packageVersion('gbayes'))==expected[['gbayes_version']],
          all(c('bayes','diagnostics')%in%getNamespaceExports('gbayes')))
stopifnot(all(c('covariance_diagonal','covariance_log_determinant','positive_definite_certified') %in%
              names(formals(gsuite::gs_relationship_matrix))))
stopifnot(native_versions$gsolve$version == '0.28.0', native_versions$greml$version == '0.92.0')
print(native_versions[c('gsolve','greml')])
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
