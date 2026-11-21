source('environment/preflight.R');source('scripts/fit_gbayes.R')
stopifnot(packageVersion('gbayes')=='0.1.16')
set.seed(71);X<-matrix(sample(0:2,80*120,TRUE),80,120,dimnames=list(paste0('s',1:80),paste0('m',1:120)))
y<-drop(X[,1:10]%*%seq(.1,1,.1))+rnorm(80)
settings<-list(h2=.5,inclusion_probability=.1,maximum_sweeps=500L,tolerance=1e-8,
 memory_limit=1024^3,chunk_size=128L,gram_cache_limit=256*1024^2)
for(method in c('gbayes_gaussian','gbayes_mixture')) {
 result<-fit_gbayes(y,X,method,settings);print(result$diagnostics$convergence);print(result$diagnostics$execution)
 prediction<-drop(predict(result$fit,X,type='phenotype'))
 stopifnot(all(is.finite(prediction)),result$diagnostics$convergence$status=='converged')
 if(method=='gbayes_gaussian') {
  centered<-sweep(X,2,colMeans(X));centered_y<-y-mean(y)
  b<-solve(crossprod(centered)+diag(result$prior$residual_variance/result$prior$average_marker_variance,ncol(X)),crossprod(centered,centered_y))
  reference<-mean(y)+drop(centered%*%b)
  stopifnot(max(abs(prediction-reference))<1e-3)
  cat('Gaussian prediction numerical reference max difference:',max(abs(prediction-reference)),'\n')
  target<-X[1:7,,drop=FALSE]+.1
  heldout<-drop(predict(result$fit,target,type='phenotype'))
  expected<-mean(y)+drop(sweep(target,2,colMeans(X))%*%b)
  stopifnot(max(abs(heldout-expected))<1e-3)
 }
}
