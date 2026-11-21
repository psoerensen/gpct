# Thin calls to installed private interfaces; no numerical implementation.
fit_greml <- function(y,K,tolerance=1e-4,threads=4L,initial=NULL,optimize=TRUE) {
  ids <- rownames(K)
  if(is.null(ids)) ids <- paste0('row-',seq_along(y))
  # Supplied relationship precision is ordinary input preparation, using R's
  # optimized BLAS/LAPACK. The private engine owns REML and MME solving.
  factor <- chol(K)
  precision <- chol2inv(factor)
  relationship <- gsuite::gs_relationship_matrix(Matrix::Matrix(precision,sparse=TRUE),ids,
    representation='precision',storage='sparse_lower_csc',maximum_dimension=5000L,
    maximum_dense_bytes=2^30,covariance_diagonal=diag(K),
    covariance_log_determinant=2*sum(log(diag(factor))),positive_definite_certified=TRUE,
    provenance='Raw dosage ZZt/p; exact metadata from the same successful Cholesky; no repair')
  records <- gsuite::gs_lmm_records(y,
    matrix(1,length(y),1,dimnames=list(NULL,'intercept')),record_id=ids)
  model <- gsuite::gs_lmm_model(records,list(gsuite::gs_lmm_component(
    'genetic',relationship,list(intercept=gsuite::gs_lmm_channel(ids)),covariance='scalar')))
  if(is.null(initial)) initial <- c(genetic=var(y)/2,residual=var(y)/2)
  start <- list(components=list(matrix(initial[['genetic']],1,1)),residual=initial[['residual']])
  control <- gsuite::gs_lmm_control(score_tolerance=tolerance,maximum_iterations=100L,
    direct_backend='cholmod',direct_threads=threads)
  fit <- if(optimize) gsuite::gs_lmm_fit(model,control,start) else gsuite::gs_lmm_blup(model,start,control)
  if(!isTRUE(fit$status$ok)) stop('greml/gsolve: ',fit$status$message)
  fit$parameters <- c(genetic=as.numeric(fit$components$genetic$covariance),residual=fit$residual_variances[[1]])
  fit$log_likelihood <- fit$restricted_log_likelihood
  fit$diagnostics <- list(optimizer_history=fit$optimizer_history,
    optimizer_parameter_history=fit$optimizer_parameter_history,work=fit$work,
    backend=fit$backend,construction=fit$construction,
    transformed_score=fit$transformed_score,true_mme_residual=fit$true_mme_residual)
  fit
}
