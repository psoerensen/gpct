# Native gbayes methods only; every method receives Glist directly.
benchmark_methods <- data.frame(
 id=c('marker_gaussian','bayesN_mcmc','bayesA_mcmc','bayesB_mcmc','bayesC_mcmc','bayesR_mcmc'),
 label=c('Gaussian PCG','BayesN / Bayesian ridge','BayesA MCMC','BayesB MCMC','BayesC MCMC','BayesR MCMC'),
 method=c('marker_gaussian','bayesN','bayesA','bayesB','bayesC','bayesR'),
 algorithm=c('pcg',rep('mcmc',5)),
 settings=c('Fixed equal marker variances and residual variance; working h2=0.5; tolerance 1e-8; 1000 iteration cap; no REML',
 'All markers Gaussian; learned shared marker and residual variances; proper inverse-chi-square priors df=4',
 'All markers; learned marker-specific and residual variances; fixed common inverse-chi-square hyperprior df=4',
 'Spike and marker-specific variances; learned active probability, marker and residual variances; fixed variance hyperprior df=4',
 'Full CV: four concurrent chains; 500 burn-in plus 1000 post-burn transitions each; thin=1; native variance/probability learning; first seed=42000+fold*2',
 'Full CV: four concurrent chains; 500 burn-in plus 1000 post-burn transitions each; thin=1; native variance/probability learning; first seed=42000+fold*2'),stringsAsFactors=FALSE)

gbayes_arguments <- function(id,Glist,y,trait,fold) {
 spec<-benchmark_methods[match(id,benchmark_methods$id),]
 p<-sum(lengths(Glist$rsids));v<-var(y);n<-length(y)
 af<-unlist(Glist$af,use.names=FALSE)
 n1<-unlist(Glist$n1,use.names=FALSE);n2<-unlist(Glist$n2,use.names=FALSE)
 # Training empirical variance in native HWE-coded coordinates.
 total_feature_variance<-sum((n1+4*n2-n*(2*af)^2)/(n-1)/(2*af*(1-af)))
 stopifnot(all(af>0 & af<1),is.finite(total_feature_variance),total_feature_variance>0)
 vb<-.5*v/total_feature_variance;ve<-.5*v
 workers<-as.integer(Sys.getenv('GPCT_WORKERS','1'))
 draws<-as.integer(Sys.getenv('GPCT_MCMC_NIT','1000'))
 burnin<-as.integer(Sys.getenv('GPCT_MCMC_BURNIN','500'))
 chains<-as.integer(Sys.getenv('GPCT_MCMC_CHAINS','2'))
 stopifnot(workers%in%c(1L,4L),chains>=workers,draws>0,burnin>=0)
 args<-list(Glist=Glist,trait=trait,method=spec$method,algorithm=spec$algorithm,ncores=workers,nit=if(spec$algorithm=='mcmc')draws else 1000L)
 if(id=='marker_gaussian')args<-c(args,list(ve=ve,prior=list(markerVariance=setNames(rep(vb,p),unlist(Glist$rsids,use.names=FALSE)))))
 if(spec$algorithm=='mcmc')args<-c(args,list(updateB=TRUE,updateE=TRUE,
  nburn=burnin,nthin=1L,nchains=chains,seed=42000L+fold*2L))
 args
}
