# Combine reviewed aggregate history with the completed GLMA prediction batch.
# Run from gpct; output stays external until reviewed and copied to docs/assets.
source('scripts/paths.R')
source('scripts/report_prediction.R')
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L)
destination <- normalizePath(args[1],winslash='/',mustWork=FALSE)
repo <- normalizePath('.',winslash='/')
stopifnot(!startsWith(tolower(destination),paste0(tolower(repo),'/')),
  tolower(destination)!=tolower(repo),!dir.exists(destination))
dir.create(destination,recursive=TRUE)
bind <- function(...) {
  x <- list(...); columns <- unique(unlist(lapply(x,names)))
  do.call(rbind,lapply(x,function(a){
    for(n in setdiff(columns,names(a))) a[[n]]<-rep(NA,nrow(a))
    a[,columns,drop=FALSE]
  }))
}
read_tables <- function(path) setNames(lapply(list.files(path,'[.]csv$',full.names=TRUE),
  function(p)read.csv(p,stringsAsFactors=FALSE)),sub('[.]csv$','',list.files(path,'[.]csv$')))
old_root <- 'docs/assets/reports/20261121-gsuite-models'
source_commit <- 'ccfd296' # Resolved to the full immutable commit below.
source_commit <- system2('git',c('rev-parse',source_commit),stdout=TRUE)
stopifnot(length(source_commit)==1L,nchar(source_commit)==40L)
cases <- list()
for(case in c('cattle','maize')) {
  run <- file.path(output_dir(),case,'20261121-glma-mkl')
  baseline <- file.path(output_dir(),case,'20261121-gsuite-final')
  stopifnot(read.csv(file.path(run,'run_status.csv'))$status=='completed')
  b <- read.csv(file.path(baseline,'predictions.csv'))
  p <- read.csv(file.path(run,'predictions.csv'))
  bp <- readRDS(file.path(baseline,'provenance.rds'))
  np <- readRDS(file.path(run,'provenance.rds'))
  be <- read.csv(file.path(baseline,'execution.csv'))
  ne <- read.csv(file.path(run,'execution.csv'))
  same_folds <- identical(readRDS(file.path(baseline,'folds.rds')),
    readRDS(file.path(run,'folds.rds')))
  stopifnot(same_folds,identical(bp$input_md5,np$input_md5))
  for(method in unique(p$method)) {
    q <- p[p$method==method,]; q <- q[match(b$id,q$id),]
    for(field in c('id','fold','observed','phenotype_was_imputed','training_mean'))
      stopifnot(identical(b[[field]],q[[field]]))
  }
  hardware <- c('cpu_model','logical_processors','installed_ram_gib','blas_binary_sha256')
  for(field in hardware) stopifnot(identical(be[[field]],ne[[field]]))
  t <- summarize_prediction_run(run)
  stopifnot(all(t$benchmark_results$status=='completed'),nrow(t$fold_results)==20L)
  fold_hash <- digest::digest(file=file.path(data_dir(),'folds',paste0(case,'-gpbench-10fold-seed42.csv')),algo='sha256')
  t$run_metadata$source_commit<-source_commit
  t$run_metadata$fold_assignment_sha256<-fold_hash
  t$recipe_checksums$source_commit<-source_commit
  t$recipe_checksums$run_id<-basename(run)
  for(field in c('recipe_url')) t$benchmark_results[[field]] <-
    sub('/main/',paste0('/',source_commit,'/'),t$benchmark_results[[field]],fixed=TRUE)
  t$software_sources$run_id<-basename(run)
  old <- read_tables(file.path(old_root,case))
  old$software_sources$run_id<-'earlier reviewed executions'
  portable <- old$software_sources[old$software_sources$repository=='gsolve',][1,,drop=FALSE]
  portable$revision<-'8aa261a6b92b0cfed2adf3bad83983e54c698ed0'
  portable$version<-'portable copy embedded in gbase for earlier gbayes runs'
  portable$run_id<-'20261121-gbayes'
  old$software_sources<-bind(old$software_sources,portable)
  tables <- old
  for(name in intersect(names(t),names(old))) {
    if(name=='dataset_catalogue') next
    tables[[name]] <- bind(old[[name]],t[[name]])
  }
  identity <- data.frame(dataset=paste0('gpbench_',case),baseline_run=basename(baseline),
    added_run=basename(run),added_methods=paste(unique(p$method),collapse=';'),
    same_input_md5=TRUE,same_saved_fold_ids=same_folds,same_outcomes=TRUE,
    same_imputed_target_flags=TRUE,same_training_mean_reference=TRUE,
    same_blas_binary=TRUE,same_hardware=TRUE,fold_assignment_sha256=fold_hash)
  tables$identity_checks<-bind(old$identity_checks,identity)
  details <- do.call(rbind,lapply(seq_len(nrow(t$fold_results)),function(i){
    row<-t$fold_results[i,]
    d<-readRDS(file.path(run,paste0(row$method,'-fold',row$fold,'-diagnostics.rds')))
    stopifnot(!any(d$outer_training_source_rows %in%
      readRDS(file.path(run,'folds.rds'))$source_row[readRDS(file.path(run,'folds.rds'))$fold==row$fold]))
    data.frame(dataset=row$dataset,method=row$method,fold=row$fold,
      selected_prior=d$selected_prior,candidate_count=nrow(d$candidates),
      inner_validation_n=length(d$inner_validation_rows_0based),
      outer_test_outcomes_used=FALSE,markers_used=row$markers,sweeps=d$sweeps,
      native_refit_accepted=d$converged,prediction_stopped=d$prediction_stopped,
      native_seconds=d$native_seconds,initial_variance_seconds=d$initial_variance_seconds,
      candidate_seconds=d$candidate_seconds,refit_seconds=d$refit_seconds)
  }))
  tables$glma_fit_diagnostics<-details
  interface<-read.csv(file.path(Sys.getenv('GPCT_ENV_DIR'),'qualification/glma-mkl/interface-cost.csv'))
  tables$glma_interface_cost<-interface[interface$dataset==paste0('gpbench_',case),]
  hashes<-read.csv(file.path(Sys.getenv('GPCT_ENV_DIR'),'qualification/glma-mkl/prediction-runtime-checksums.csv'))
  hashes$run_id<-basename(run)
  tables$native_runtime_checksums<-bind(old$native_runtime_checksums,hashes)
  attr(tables,'fit_session')<-c(readLines(file.path(old_root,case,'fit-sessionInfo.txt')),
    '',paste('GLMA batch:',basename(run)),readLines(file.path(run,'sessionInfo.txt')))
  cases[[case]]<-tables
  write_prediction_report(tables,file.path(destination,case))
}
combined <- setNames(lapply(names(cases[[1]]),function(name)
  bind(cases[[1]][[name]],cases[[2]][[name]])),names(cases[[1]]))
attr(combined,'fit_session')<-c(attr(cases[[1]],'fit_session'),'',attr(cases[[2]],'fit_session'))
write_prediction_report(combined,file.path(destination,'combined'))
cat('Reviewed identities and aggregate reports written externally:',destination,'\n')
