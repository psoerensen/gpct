# Separate fixed-variance numerical check. This does not refit variance components.
source('environment/preflight.R')
source('scripts/evaluate.R')
args <- commandArgs(trailingOnly=TRUE);stopifnot(length(args)==1L)
source('scripts/paths.R')
run <- normalizePath(args[1],winslash='/',mustWork=TRUE)
config <- readRDS(file.path(run,'settings.rds'))
folds <- readRDS(file.path(run,'folds.rds'))
provenance <- readRDS(file.path(run,'provenance.rds'))
path <- file.path(data_dir(),'prepared',paste0(config$case,'-gpbench.rds'))
stopifnot(unname(tools::md5sum(path))==provenance$input_md5)
input <- readRDS(path);X<-input$X;y<-gpbench_response(input$Y[,config$trait])$y
stopifnot(identical(input$ids,folds$id),config$folds==10L,config$marker_count==config$p)
p <- read.csv(file.path(run,'predictions.csv'))
kernel <- tcrossprod(X)/ncol(X)
rm(input,X);gc()
selected_folds <- if(config$case=='cattle') c(1L,9L) else 1L
rows <- list()
for(fold in selected_folds) {
  train<-which(folds$fold!=fold);test<-which(folds$fold==fold)
  fitted<-readRDS(file.path(run,paste0('gblup_reml-fold',fold,'-diagnostics.rds')))
  # The intercept is retained in the predictions; recover its fitted value
  # from the GLS equation using the same fixed-variance gsolve operation.
  Ktr<-kernel[train,train,drop=FALSE];cross<-kernel[test,train,drop=FALSE]
  V<-fitted$parameters[['genetic']]*Ktr+fitted$parameters[['residual']]*diag(length(train))
  started<-proc.time()[['elapsed']]
  solve<-gsuite::gsuite_solve(V,cbind(response=y[train],intercept=1),
    control=list(relative_tolerance=1e-10,maximum_iterations=length(train),threads=1L))
  stopifnot(length(solve$converged)>0L,all(solve$converged))
  beta<-sum(solve$solution[,1])/sum(solve$solution[,2])
  Py<-solve$solution[,1]-solve$solution[,2]*beta
  predicted<-beta+drop(fitted$parameters[['genetic']]*cross%*%Py)
  original<-p[p$method=='gblup_reml'&p$fold==fold,]
  original<-original[match(folds$id[test],original$id),]
  difference<-max(abs(predicted-original$predicted))
  rows[[as.character(fold)]]<-data.frame(fold,status='converged',max_prediction_difference=difference,
    prediction_correlation=cor(predicted,original$predicted),elapsed_seconds=proc.time()[['elapsed']]-started,
    requested_workers=1L,stage='representative-fold fixed-variance GLS/BLUP; two RHS; REML excluded')
  saveRDS(solve,file.path(run,paste0('gsolve-supported1-fold',fold,'-diagnostics.rds')))
  write.csv(do.call(rbind,rows),file.path(run,'solver_checks-supported1.csv'),row.names=FALSE)
  stopifnot(is.finite(difference),difference<1e-5)
  cat('Supported one-worker solver check: fold',fold,'max difference',difference,'\n')
}
original<-file.path(run,'solver_checks.csv');archive<-file.path(run,'solver_checks-original.csv')
if(file.exists(original)&&!file.exists(archive)) file.copy(original,archive)
file.copy(file.path(run,'solver_checks-supported1.csv'),original,overwrite=TRUE)
write.csv(data.frame(source_file='scripts/check_solvers.R',
  md5=unname(tools::md5sum('scripts/check_solvers.R')),
  fit_implementation='gsuite ecosystem: greml/gsolve',selected_folds=paste(selected_folds,collapse=';')),
  file.path(run,'solver_check_provenance.csv'),row.names=FALSE)
