# Inspect existing native grid diagnostics over the saved maize folds.
source('scripts/paths.R')
library(gbase);library(glma)
out<-file.path(output_dir(),'20261121-glma-gaussian-audit')
input<-readRDS(file.path(data_dir(),'prepared/maize-gpbench.rds'))
y<-input$Y[,'DTT'];y[is.na(y)]<-mean(y,na.rm=TRUE)
rm(input);gc()
run<-file.path(output_dir(),'maize/20261121-glma-mkl')
folds<-readRDS(file.path(run,'folds.rds'))
original<-read.csv(file.path(run,'performance.csv'))
original<-original[original$method=='glma_infinitesimal',]
rows<-list()
for(fold in 1:10) {
  train<-which(folds$fold!=fold)
  path<-file.path(out,paste0('maize-fold',fold,'-native-grid-diagnostics.rds'))
  fit<-if(file.exists(path))readRDS(path)else glma::glma_full_marker_prediction(
    file.path(run,'anonymous-dosages.bed'),1458L,75304L,train,y[train],
    'infinitesimal',threads=4L)
  ref<-original[original$fold==fold,]
  stopifnot(abs(fit$genetic_variance-ref$genetic_variance)<1e-7,
    abs(fit$residual_variance-ref$residual_variance)<1e-7)
  center<-fit$initial_genetic_variance/(fit$initial_genetic_variance+fit$initial_residual_variance)
  rows[[fold]]<-data.frame(dataset='gpbench_maize',fold,
    initial_ratio=center,final_ratio=fit$genetic_variance/(fit$genetic_variance+fit$residual_variance),
    used_initial_without_bracket=fit$grid_used_initial,
    grid=paste(signif(center*c(.5,.75,1),8),collapse=';'),
    mc_equations=paste(signif(fit$grid_equations,8),collapse=';'),
    native_refit_accepted=fit$converged,refit_sweeps=fit$sweeps)
  saveRDS(fit,path)
  write.csv(do.call(rbind,rows),file.path(out,'maize-grid-diagnostics.csv'),row.names=FALSE)
  cat('GRID',fold,'fallback',fit$grid_used_initial,'h',center,'\n')
}
