# External BayesC comparator only; the gsuite fitting route remains Glist.
source('scripts/paths.R'); source('scripts/evaluate.R')
args <- commandArgs(TRUE)
stopifnot(length(args)==1L,args[[1]] %in% c('cattle','maize'))
case <- args[[1]]
.libPaths(c(file.path(Sys.getenv('GPCT_ENV_DIR'),'comparison-library'),.libPaths()))
stopifnot(as.character(packageVersion('BGLR'))=='1.1.4',
  all(Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))=='1'))
root <- file.path(output_dir(),Sys.getenv('GPCT_RUN_ID','20261121-mcmc-learning-check'))
destination <- file.path(root,'bglr_bayesC_masked',case)
dir.create(destination,recursive=TRUE,showWarnings=FALSE)
if(file.exists(file.path(destination,'fold-results.csv'))) stop('Preserve the existing comparison.')
status <- function(value,message='') write.csv(data.frame(status=value,message,
  timestamp_utc=format(Sys.time(),tz='UTC')),file.path(destination,'status.csv'),row.names=FALSE)
status('running')
run <- function() {
  reference <- readRDS(file.path(root,'bayesC_mcmc',case,'fold1-fit.rds'))
  source_dir <- file.path(data_dir(),'glist/20261121-maf001-miss005',case)
  panel <- readRDS(file.path(source_dir,'qc-Glist.rds'))
  input <- readRDS(file.path(source_dir,'phenotype-only.rds'))
  stopifnot(identical(input$ids,panel$ids),length(panel$bedfiles)==1L)
  folds <- saved_folds(input$ids,file.path(data_dir(),'folds',paste0(case,'-gpbench-10fold-seed42.csv')))
  train <- which(folds$fold!=1L); test <- which(folds$fold==1L)
  stopifnot(identical(reference$data$samples,input$ids[train]))
  trait <- if(case=='cattle') 'mkg' else 'DTT'
  response <- gpbench_response(input$Y[,trait]); y <- response$y
  prior <- reference$input$prior
  # BGLR uses S0/chi-square(df); gbayes uses df*scale/chi-square(df).
  # counts=0 gives BGLR Beta(1,1), matching the native Dirichlet(1,1).
  stopifnot(identical(as.numeric(prior$weight_prior),c(1,1)))
  settings <- list(model='BayesC',probIn=prior$inclusion_probability,counts=0,
    effect_df=prior$effect_variance_prior$df,
    effect_S0=prior$effect_variance_prior$df*prior$effect_variance_prior$scale,
    residual_df=prior$residual_variance_prior$df,
    residual_S0=prior$residual_variance_prior$df*prior$residual_variance_prior$scale,
    seeds=c(42002L,42003L),nIter=1500L,burnIn=500L,thin=1L,
    differences=c('BGLR samples an intercept; gbayes fixes the training phenotype mean.',
      'BGLR initializes varB at S0; gbayes initializes at vb. Priors are matched.',
      'Different native samplers and RNGs; equal seeds do not imply equal draws.',
      'BGLR requires a dense matrix; its input is decoded from the shared QC BED and Glist selection.',
      'BGLR uses its standard masked-test-phenotype/yHat route, with latent missing-response augmentation.',
      'BGLR fitting time includes held-out prediction updates; prediction_seconds only measures yHat extraction.'))
  saveRDS(settings,file.path(destination,'settings.rds'))
  write.csv(data.frame(model=settings$model,probIn=settings$probIn,counts=settings$counts,
    effect_df=settings$effect_df,effect_S0=settings$effect_S0,
    residual_df=settings$residual_df,residual_S0=settings$residual_S0,
    chains=2L,burn_in=500L,retained_per_chain=1000L,thin=1L,threads=1L),
    file.path(destination,'method-settings.csv'),row.names=FALSE)
  started <- proc.time()[['elapsed']]
  bed <- BGLR::read_bed(panel$bedfiles,panel$bimfiles,panel$famfiles)
  stopifnot(bed$n==length(input$ids),bed$p==sum(lengths(panel$rsids)),
    all(bed$x %in% c(0L,1L,3L))) # BGLR code 2 denotes missing; these panels have none.
  # Verified on a known four-sample PLINK fixture: raw 3,1,0 -> dosage 0,1,2.
  X <- matrix(c(2,1,NA_real_,0)[bed$x+1L],bed$n,bed$p)
  rm(bed);gc()
  markers <- unlist(panel$rsids,use.names=FALSE)
  stopifnot(max(abs(colMeans(X)/2-unlist(panel$af,use.names=FALSE)))<1e-10)
  selected <- match(reference$data$markers,markers)
  stopifnot(!anyNA(selected),!anyDuplicated(selected))
  coding <- reference$data$coding
  stopifnot(max(abs(colMeans(X[train,selected,drop=FALSE])-coding$centers))<1e-10,
    max(abs(sqrt(2*coding$allele_frequency*(1-coding$allele_frequency))-coding$scales))<1e-10)
  X <- X[,selected,drop=FALSE]
  X <- sweep(sweep(X,2,coding$centers,'-'),2,coding$scales,'/')
  y_masked <- y;y_masked[test] <- NA_real_
  names(y_masked) <- input$ids
  stopifnot(all(is.na(y_masked[test])),identical(unname(y_masked[train]),unname(y[train])))
  preparation_seconds <- proc.time()[['elapsed']]-started
  saveRDS(list(markers=reference$data$markers,training_ids=input$ids[train],test_ids=input$ids[test],
    coding,settings,package=as.character(packageVersion('BGLR')),
    binary_sha256=digest::digest(file=system.file('libs/x64/BGLR.dll',package='BGLR'),algo='sha256'),
    recipe_sha256=digest::digest(file='scripts/run_bglr_comparison.R',algo='sha256'),
    bed_sha256=digest::digest(file=panel$bedfiles,algo='sha256'),
    fold_sha256=digest::digest(file=file.path(data_dir(),'folds',paste0(case,'-gpbench-10fold-seed42.csv')),algo='sha256')),
    file.path(destination,'provenance.rds'))
  predictions <- vector('list',2L);fit_seconds <- prediction_seconds <- 0
  traces <- list()
  for(chain in 1:2) {
    chain_dir <- file.path(destination,paste0('chain',chain))
    if(dir.exists(chain_dir)) stop('Preserve the existing chain directory: ',chain_dir)
    dir.create(chain_dir,showWarnings=FALSE)
    cat('FIT BGLR BayesC',case,'fold 1 chain',chain,'\n');flush.console()
    set.seed(settings$seeds[chain])
    started <- proc.time()[['elapsed']]
    fit <- BGLR::BGLR(y=y_masked,ETA=list(list(X=X,model='BayesC',
      probIn=settings$probIn,counts=settings$counts,df0=settings$effect_df,S0=settings$effect_S0)),
      nIter=settings$nIter,burnIn=settings$burnIn,thin=settings$thin,
      df0=settings$residual_df,S0=settings$residual_S0,R2=.5,
      saveAt=paste0(chain_dir,'/'),verbose=FALSE,rmExistingFiles=FALSE)
    fit_seconds <- fit_seconds+proc.time()[['elapsed']]-started
    stopifnot(all(is.na(fit$y[test])),all(is.finite(fit$yHat)))
    fit$ETA[[1]]$X <- NULL
    fit$ETA[[1]]$x2 <- NULL
    saveRDS(fit,file.path(chain_dir,'fit.rds'))
    started <- proc.time()[['elapsed']]
    predictions[[chain]] <- as.numeric(fit$yHat[test])
    prediction_seconds <- prediction_seconds+proc.time()[['elapsed']]-started
    variance <- scan(file.path(chain_dir,'varE.dat'),quiet=TRUE)
    mixture <- read.table(file.path(chain_dir,'ETA_1_parBayesC.dat'),header=TRUE)
    stopifnot(length(variance)==1500L,nrow(mixture)==1500L)
    retained <- 501:1500
    traces[[chain]] <- data.frame(chain,draw=1:1000,residual_variance=variance[retained],
      effect_variance=mixture$varB[retained],inclusion_probability=mixture$probIn[retained])
    stopifnot(all(traces[[chain]]$residual_variance>0),all(traces[[chain]]$effect_variance>0),
      length(unique(traces[[chain]]$residual_variance))>1L,
      length(unique(traces[[chain]]$effect_variance))>1L)
    rm(fit);gc()
  }
  predicted <- Reduce('+',predictions)/2
  write.csv(do.call(rbind,lapply(1:2,function(chain) data.frame(chain,
    as.list(metrics(y[test],predictions[[chain]]))))),
    file.path(destination,'chain-results.csv'),row.names=FALSE)
  measured <- metrics(y[test],predicted)
  write.csv(data.frame(dataset=paste0('gpbench_',case),trait,method='bglr_bayesC',fold=1L,
    n_train=length(train),n_test=length(test),
    available_markers=if(case=='cattle') 42551L else 75304L,
    markers_used=length(selected),actual_workers=1L,
    preparation_seconds,fit_seconds,prediction_seconds,status='completed',as.list(measured)),
    file.path(destination,'fold-results.csv'),row.names=FALSE)
  write.csv(do.call(rbind,traces),file.path(destination,'retained-parameter-traces.csv'),row.names=FALSE)
  write.csv(data.frame(id=input$ids[test],observed=y[test],predicted,imputed=response$imputed[test]),
    file.path(destination,'fold1-predictions-local.csv'),row.names=FALSE)
  status('partial','Fold 1 complete; no full CV or publication.')
  cat('DONE BGLR BayesC',case,'correlation',measured[['predictive_ability']],
    'fit seconds',fit_seconds,'\n')
}
tryCatch(run(),error=function(e){status('failed',conditionMessage(e));stop(e)})
