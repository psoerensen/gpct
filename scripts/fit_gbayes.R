# Existing gbayes streamed interface; no estimator is implemented here.
fit_gbayes <- function(y,X,method,settings) {
  variance<-var(y)
  centers<-colMeans(X)
  # Sum of training feature variances in the supplied dosage coordinates.
  denominator<-sum(vapply(seq_len(ncol(X)),function(j)sum((X[,j]-centers[j])^2),numeric(1)))/(nrow(X)-1)
  vb<-settings$h2*variance/denominator;ve<-(1-settings$h2)*variance
  mixture<-method=='gbayes_mixture'
  fit<-gbayes::bayes(data.frame(id=rownames(X),response=y),X=X,trait='response',
    method='normal_mixture',algorithm='vbayes',
    vb=if(mixture)c(0,vb/settings$inclusion_probability)else vb,
    pi=if(mixture)c(1-settings$inclusion_probability,settings$inclusion_probability)else 1,
    ve=ve,nit=settings$maximum_sweeps,ncores=1L,
    control=list(tolerance=settings$tolerance,memoryLimit=settings$memory_limit,
      chunkSize=settings$chunk_size,localIterations=20L,fullSweepInterval=8L,
      skipSettledChunks=TRUE,gramCacheLimit=settings$gram_cache_limit))
  list(fit=fit,diagnostics=gbayes::diagnostics(fit),
    prior=list(average_marker_variance=vb,residual_variance=ve,
      training_sum_marker_variances=denominator,h2=settings$h2,
      inclusion_probability=if(mixture)settings$inclusion_probability else 1))
}
