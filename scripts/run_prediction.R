# Benchmark orchestration only. Private numerical implementations stay installed externally.
execution_started <- proc.time()[['elapsed']]
source('scripts/paths.R'); source('scripts/evaluate.R'); source('scripts/fit_greml.R')
run_id <- Sys.getenv('GPCT_RUN_ID',paste0(format(Sys.time(),'%Y%m%dT%H%M%S',tz='UTC'),'-gpbench'))
stopifnot(grepl('^[A-Za-z0-9_-]+$',run_id))
destination <- file.path(output_dir(),config$case,run_id)
if(dir.exists(destination)) stop('Run directory exists; choose a new GPCT_RUN_ID.')
dir.create(destination,recursive=TRUE)
write_status <- function(status,message='') write.csv(data.frame(status,message,
  timestamp_utc=format(Sys.time(),tz='UTC')),file.path(destination,'run_status.csv'),row.names=FALSE)
write_status('running'); saveRDS(config,file.path(destination,'settings.rds'))
packages <- c('gsuite','gbase','digest','jsonlite','reticulate')
write.csv(data.frame(package=packages,version=vapply(packages,function(p)
  as.character(utils::packageVersion(p)),character(1))),file.path(destination,'package_versions.csv'),row.names=FALSE)
results <- predictions <- list()
save_tables <- function() {
  for(name in c('results','predictions')) {
    values <- get(name)
    if(length(values)) write.csv(do.call(rbind,values),file.path(destination,
      paste0(switch(name,results='performance',predictions='predictions'),'.csv')),row.names=FALSE)
  }
}
shared_kernel_seconds <- NA_real_
run <- function() {
  input_path <- file.path(data_dir(),'prepared',paste0(config$case,'-gpbench.rds'))
  input <- readRDS(input_path)
  stopifnot(identical(dim(input$X),c(config$n,config$p)),
    identical(input$ids,rownames(input$X)),identical(input$ids,rownames(input$Y)),
    !anyDuplicated(input$ids),all(is.finite(input$X)),
    identical(input$source_columns,seq_len(config$p)),isTRUE(input$metadata$positional_alignment_accepted))
  response <- gpbench_response(input$Y[,config$trait]); y <- response$y
  X <- input$X; ids <- input$ids
  folds <- saved_folds(ids,file.path(data_dir(),'folds',paste0(config$case,'-gpbench-10fold-seed42.csv')))
  saveRDS(folds,file.path(destination,'folds.rds'))
  saveRDS(list(source=input$metadata,input_md5=unname(tools::md5sum(input_path)),
    scripts_md5=tools::md5sum(c('scripts/run_prediction.R','scripts/evaluate.R','scripts/prepare.R',
      'scripts/gpbench_folds.py','scripts/fit_greml.R',paste0('benchmarks/',config$case,'_prediction/config.R'))),
    response_imputed_n=sum(response$imputed),config=config),file.path(destination,'provenance.rds'))
  rm(input); gc()
  # Data-only raw dosage kernel; no marker filtering, allele recoding or SD scaling.
  # Kernel normalization changes only parameter units: vg = markers * marker Vu.
  cat('Building full raw-dosage kernel for greml/gsolve\n')
  started <- proc.time()[['elapsed']]; kernel <- tcrossprod(X)/ncol(X)
  shared_kernel_seconds <<- proc.time()[['elapsed']]-started
  any_failure <- FALSE
  for(fold in seq_len(config$folds)) {
    train <- which(folds$fold!=fold); test <- which(folds$fold==fold)
    ytr <- y[train]; kernel_started <- proc.time()[['elapsed']]
    Ktr <- kernel[train,train,drop=FALSE]; Ktarget <- kernel[test,train,drop=FALSE]
    shared_kernel_seconds <<- shared_kernel_seconds+proc.time()[['elapsed']]-kernel_started
    for(method in config$methods) {
      key <- paste0(method,'-fold',fold)
      row <- data.frame(method,fold,n_train=length(train),n_test=length(test),markers=ncol(X),
        status='failed',convergence='unavailable',message='',fit_seconds=NA_real_,prediction_seconds=NA_real_,
        method_elapsed_seconds=NA_real_,peak_ram_mb=NA_real_,ram_status='not measured',warning_count=0L,
        genetic_variance=NA_real_,residual_variance=NA_real_,
        native_backend='not applicable',native_reported_requested_threads=NA_real_,
        native_reported_resolved_threads=NA_real_,native_reported_support_threads=NA_real_,
        predictive_ability=NA_real_,rmse=NA_real_,mae=NA_real_,mse=NA_real_,predictive_r_squared=NA_real_,
        calibration_intercept=NA_real_,calibration_slope=NA_real_)
      warnings <- character(); begin <- proc.time()[['elapsed']]; stage <- 'fit'
      tryCatch(withCallingHandlers({
        started <- proc.time()[['elapsed']]
        if(method=='gblup_reml') {
          fit <- fit_greml(ytr,Ktr,tolerance=config$tolerance,
            threads=as.integer(Sys.getenv('OMP_NUM_THREADS','4')))
          row$fit_seconds <- proc.time()[['elapsed']]-started
          diagnostics <- list(status=fit$status,converged=fit$converged,parameters=fit$parameters,
            log_likelihood=fit$log_likelihood,diagnostics=fit$diagnostics)
          row$genetic_variance <- fit$parameters[['genetic']];row$residual_variance <- fit$parameters[['residual']]
          row$native_backend <- fit$backend$name
          row$native_reported_requested_threads <- fit$backend$requested_direct_threads
          row$native_reported_resolved_threads <- fit$backend$resolved_direct_threads
          row$native_reported_support_threads <- fit$backend$resolved_support_threads
          row$convergence <- if(isTRUE(fit$converged)) 'converged' else 'not converged'
          if(!isTRUE(fit$status$ok)) stop('greml status: ',fit$status$code)
          if(!isTRUE(fit$converged)) stop('greml REML did not converge')
          stage <- 'prediction'; started <- proc.time()[['elapsed']]
          predicted <- as.numeric(fit$fixed_effects)+
            as.numeric(fit$parameters[['genetic']]*Ktarget %*% fit$Py)
        } else stop('Unknown method')
        row$prediction_seconds <- proc.time()[['elapsed']]-started
        stopifnot(length(predicted)==length(test),all(is.finite(predicted)))
        score <- metrics(y[test],predicted); row[names(score)] <- as.list(score); row$status <- 'completed'
        saveRDS(diagnostics,file.path(destination,paste0(key,'-diagnostics.rds')))
        predictions[[key]] <<- data.frame(id=ids[test],fold,method,observed=y[test],predicted,
          phenotype_was_imputed=response$imputed[test],training_mean=mean(ytr))
      },warning=function(w){warnings <<- c(warnings,conditionMessage(w));invokeRestart('muffleWarning')}),
      error=function(e){row$message <<- conditionMessage(e);any_failure <<- TRUE
        if(stage=='fit') row$fit_seconds <<- proc.time()[['elapsed']]-started
        if(stage=='prediction') row$prediction_seconds <<- proc.time()[['elapsed']]-started})
      row$method_elapsed_seconds <- proc.time()[['elapsed']]-begin; row$warning_count <- length(warnings)
      row$message <- paste(c(row$message[nzchar(row$message)],warnings),collapse='; ')
      results[[key]] <<- row; save_tables(); cat(key,row$status,row$message,'\n'); gc()
    }

  }
  if(any_failure) stop('One or more fits failed; see performance.csv')
}
ok <- tryCatch({run();TRUE},error=function(e){save_tables();write_status('failed',conditionMessage(e));message(conditionMessage(e));FALSE})
blas <- .Call('gpct_blas_info')
checksums <- read.csv(file.path(Sys.getenv('GPCT_ENV_DIR'),'runtime-checksums.csv'))
native_versions <- gsuite::gsuite_versions()
write.csv(data.frame(case_elapsed_seconds=proc.time()[['elapsed']]-execution_started,
  gsolve_version=native_versions$gsolve$version,greml_version=native_versions$greml$version,
  requested_native_threads=as.integer(Sys.getenv('OMP_NUM_THREADS','4')),
  shared_kernel_seconds,blas_implementation=blas$implementation,blas_runtime_threads=blas$threads,
  blas_binary_sha256=checksums$sha256[checksums$component=='Rblas.dll'],cpu_model=Sys.getenv('GPCT_CPU_MODEL'),
  logical_processors=Sys.getenv('GPCT_LOGICAL_PROCESSORS'),installed_ram_gib=Sys.getenv('GPCT_INSTALLED_RAM_GIB'),
  MKL_NUM_THREADS=Sys.getenv('MKL_NUM_THREADS'),peak_ram_mb=NA_real_,ram_status='not measured'),
  file.path(destination,'execution.csv'),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(destination,'sessionInfo.txt'))
if(ok) write_status('completed','Review numerical agreement, convergence and source comparison before publishing.')
cat('Run artifacts:',destination,'\n');if(!ok) quit(status=1L)
