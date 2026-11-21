# Existing gbayes methods only; every method receives Glist directly.
benchmark_methods <- data.frame(
 id=c('marker_gaussian','elastic_net','laplace_gaussian','bayesC_vb','bayesC_mcmc','bayesR_mcmc'),
 label=c('Gaussian PCG','Elastic net','Laplace–Gaussian VB','BayesC VB','BayesC MCMC','BayesR MCMC'),
 method=c('marker_gaussian','elastic_net','laplace_gaussian','bayesC','bayesC','bayesR'),
 algorithm=c('pcg','coordinate_descent','vbayes','vbayes','mcmc','mcmc'),
 settings=c('Fixed equal marker variances and residual variance; working h2=0.5; tolerance 1e-8; 1000 iteration cap; no REML',
 'Fixed candidate: alpha=0.5; lambda=0.01*training phenotype SD; native tolerance; 1000 sweep cap; no tuning',
 'Fixed average marker and residual variances; working h2=0.5; Laplace probability=0.1; Gaussian variance fraction=0.3; 1000 sweep cap',
 'Fixed active probability=0.1, slab and residual variances; working h2=0.5; native tolerance; 1000 sweep cap',
 'Two sequential chains; 500 burn-in plus 1000 post-burn transitions each; thin=1; native variance/probability learning; first seed=42000+fold*2',
 'Two sequential chains; 500 burn-in plus 1000 post-burn transitions each; thin=1; native variance/probability learning; first seed=42000+fold*2'),stringsAsFactors=FALSE)

gbayes_arguments <- function(id,Glist,y,trait,fold) {
 spec<-benchmark_methods[match(id,benchmark_methods$id),]
 p<-sum(lengths(Glist$rsids));v<-var(y);n<-length(y)
 af<-unlist(Glist$af,use.names=FALSE)
 n1<-unlist(Glist$n1,use.names=FALSE);n2<-unlist(Glist$n2,use.names=FALSE)
 # Training empirical variance in native HWE-coded coordinates.
 total_feature_variance<-sum((n1+4*n2-n*(2*af)^2)/(n-1)/(2*af*(1-af)))
 stopifnot(all(af>0 & af<1),is.finite(total_feature_variance),total_feature_variance>0)
 vb<-.5*v/total_feature_variance;ve<-.5*v
 args<-list(Glist=Glist,trait=trait,method=spec$method,algorithm=spec$algorithm,ncores=1L,nit=1000L)
 if(id=='marker_gaussian')args<-c(args,list(ve=ve,prior=list(markerVariance=setNames(rep(vb,p),unlist(Glist$rsids,use.names=FALSE)))))
 if(id=='elastic_net')args<-c(args,list(control=list(lambda=.01*sd(y),alpha=.5)))
 if(id=='laplace_gaussian')args<-c(args,list(vb=vb,ve=ve,prior=list(laplaceProbability=.1,normalVarianceFraction=.3)))
 if(id=='bayesC_vb')args<-c(args,list(vb=vb/.1,ve=ve,pi=.1))
 if(id%in%c('bayesC_mcmc','bayesR_mcmc'))args<-c(args,list(nburn=500L,nthin=1L,nchains=2L,seed=42000L+fold*2L))
 args
}
