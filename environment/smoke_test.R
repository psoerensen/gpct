# Run only with the newly built isolated R/library.
stopifnot(as.character(getRversion()) == "4.4.3")
for (p in c("gbase", "gbayes", "rrBLUP", "digest", "reticulate"))
  if (!requireNamespace(p, quietly = TRUE)) stop("Missing required package: ", p)
stopifnot(as.character(utils::packageVersion("gbayes")) == "0.1.16",
          all(c("bayes", "blr", "diagnostics", "fit_contract") %in% getNamespaceExports("gbayes")))
root <- Sys.getenv("GPCT_ENV_DIR")
if (!nzchar(root)) stop("GPCT_ENV_DIR must identify the isolated environment")
dyn.load(file.path(root, "probe", "blas_probe.dll"))
blas <- .Call("gpct_blas_info")
stopifnot(grepl("OpenBLAS", blas$implementation), blas$threads >= 1L)
print(blas)
# Exact example from the public workflow guide, independently checked expectations.
X <- cbind(u = c(-1, -1, 1, 1), v = c(-1, 1, -1, 1))
rownames(X) <- paste0("i", 1:4)
training <- data.frame(id = rownames(X), height = c(-1, 1, -2, 2))
fit <- gbayes::bayes(training, X = X, trait = "height",
  method = "marker_gaussian", algorithm = "pcg", ve = 1,
  prior = list(markerVariance = c(u = .2, v = .2)))
weighted <- gbayes::bayes(training, X = X, trait = "height",
  method = "elastic_net", algorithm = "coordinate_descent",
  control = list(lambda = .1, alpha = .6, l1Weights = c(u = 1, v = 2)))
stopifnot(max(abs(as.numeric(coef(fit)) - c(0, 2/3))) < 1e-6,
          max(abs(as.numeric(coef(weighted)) - c(0, 1.326923076923))) < 1e-6,
          max(abs(as.numeric(predict(fit, X)) - as.numeric(X %*% coef(fit)))) < 1e-10)
set.seed(4401)
A <- matrix(rnorm(400), 40, 10)
stopifnot(max(abs(crossprod(A) - t(A) %*% A)) < 1e-10,
          max(abs(svd(A)$d^2 - eigen(crossprod(A), symmetric = TRUE)$values)) < 1e-8)
cat("Optimized BLAS and documented Gaussian/elastic-net interface smoke checks passed.\n")
