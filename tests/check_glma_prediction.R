# Check the thin full-marker adapter against an independent fixed-V ridge solve.
library(gbase)
library(glma)
set.seed(481)
X <- matrix(rbinom(160L * 96L, 2L, .35), 160L, 96L)
X[, 96L] <- 0
y <- .4 * X[, 2L] + .3 * X[, 65L] + rnorm(160L)
path <- tempfile(fileext = '.bed')
glma::glma_prediction_cache(X, path)
train <- 1:128
fits <- lapply(c('infinitesimal','prior_selected'), function(method) {
  fit <- glma::glma_full_marker_prediction(path, nrow(X), ncol(X), train,
    y[train], method, threads=4L, block_size=32L)
  stopifnot(isTRUE(fit$converged), fit$markers_used==95L,
    fit$effects[96L]==0, all(is.finite(fit$effects)),
    all(fit$inner_validation_rows_0based %in% 0:127))
  fit
})
fit <- fits[[1]]
Z <- scale(X[train,1:95], center=TRUE,
  scale=sqrt(colSums(scale(X[train,1:95],scale=FALSE)^2)/length(train)))
K <- tcrossprod(Z)/95
V <- fit$genetic_variance*K + diag(fit$residual_variance,length(train))
one <- rep(1,length(train)); Vinvy <- solve(V,y[train]); Vinvone <- solve(V,one)
intercept <- sum(Vinvy)/sum(Vinvone)
reference <- intercept + fit$genetic_variance*K %*% solve(V,y[train]-intercept)
actual <- fit$intercept + X[train,,drop=FALSE] %*% fit$effects
stopifnot(max(abs(reference-actual))<.02, cor(as.numeric(reference),as.numeric(actual))>.999)
target <- fit$intercept + X[-train,,drop=FALSE] %*% fit$effects
stopifnot(length(target)==32L,all(is.finite(target)))
unlink(path)
cat('PASS: native full-marker fits, constant-marker accounting, and fixed-V ridge reference; max difference',
  max(abs(reference-actual)), '\n')
