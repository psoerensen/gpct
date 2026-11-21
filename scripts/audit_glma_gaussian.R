# Controlled model/variance/solve comparisons using owned greml/gsolve fits.
# No outer test outcomes are used to choose a setting or estimate variance.
source('scripts/paths.R');source('environment/preflight.R')
source('scripts/fit_greml.R');source('scripts/evaluate.R')
out<-file.path(output_dir(),'20261121-glma-gaussian-audit')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
past<-if(file.exists(file.path(out,'comparisons.csv')))read.csv(file.path(out,'comparisons.csv'))else NULL
if(!is.null(past))past$restricted_log_likelihood[past$mode=='glma_variances_exact_solve']<-NA_real_
rows<-if(is.null(past))list()else setNames(lapply(seq_len(nrow(past)),function(i)past[i,,drop=FALSE]),
  paste(sub('gpbench_','',past$dataset),past$fold,past$mode))
for(case in c('maize','cattle')) {
  input<-readRDS(file.path(data_dir(),'prepared',paste0(case,'-gpbench.rds')))
  X<-input$X;y<-gpbench_response(input$Y[,if(case=='cattle')'mkg'else'DTT'])$y
  root<-file.path(output_dir(),case)
  folds<-readRDS(file.path(root,'20261121-glma-mkl','folds.rds'))
  old<-read.csv(file.path(root,'20261121-glma-mkl','predictions.csv'))
  old<-old[old$method=='glma_infinitesimal',]
  baseline<-read.csv(file.path(root,'20261121-gsuite-final','predictions.csv'))
  selected<-if(case=='maize')1:10 else 1L
  for(fold in selected) {
    if(all(paste(case,fold,c('glma_variances_exact_solve','standardized_reml'))%in%names(rows))) next
    train<-which(folds$fold!=fold);test<-which(folds$fold==fold)
    cat('BEGIN',case,fold,'\n')
    Xtr<-X[train,,drop=FALSE]
    center<-colMeans(Xtr)
    scale<-sqrt(colMeans(Xtr*Xtr)-center^2)
    stopifnot(all(is.finite(scale)),all(scale>0))
    rm(Xtr);gc()
    scaled<-sweep(X,2L,scale,'/')
    kernel<-tcrossprod(scaled)/ncol(X)
    rm(scaled);gc()
    K<-kernel[train,train,drop=FALSE];Kt<-kernel[test,train,drop=FALSE]
    centered_kernel_mean<-(sum(diag(K))-sum(K)/length(train))/(length(train)-1)
    d<-readRDS(file.path(root,'20261121-glma-mkl',paste0('glma_infinitesimal-fold',fold,'-diagnostics.rds')))
    published<-old$predicted[match(input$ids[test],old$id)]
    raw<-baseline$predicted[match(input$ids[test],baseline$id)]
    for(mode in c('glma_variances_exact_solve','standardized_reml')) {
      key<-paste(case,fold,mode)
      if(key%in%names(rows))next
      started<-proc.time()[['elapsed']]
      fit<-tryCatch(fit_greml(y[train],K,threads=4L,
        initial=if(mode=='standardized_reml')NULL else c(genetic=d$genetic_variance,residual=d$residual_variance),
        optimize=mode=='standardized_reml',tolerance=1e-4),error=function(e){
          write.table(data.frame(dataset=case,fold,mode,message=conditionMessage(e)),
            file.path(out,'optimizer_failures.csv'),sep=',',row.names=FALSE,
            col.names=!file.exists(file.path(out,'optimizer_failures.csv')),append=file.exists(file.path(out,'optimizer_failures.csv')))
          message(conditionMessage(e));NULL
        })
      if(is.null(fit))next
      if(mode=='standardized_reml')stopifnot(isTRUE(fit$converged))
      predicted<-as.numeric(fit$fixed_effects)+as.numeric(fit$parameters['genetic']*Kt%*%fit$Py)
      score<-metrics(y[test],predicted)
      rows[[key]]<-data.frame(dataset=paste0('gpbench_',case),fold,mode,
        native_glma_genetic=d$genetic_variance,native_glma_residual=d$residual_variance,
        reference_genetic=unname(fit$parameters['genetic']),reference_residual=unname(fit$parameters['residual']),
        centered_kernel_mean,
        variance_fraction=unname(fit$parameters['genetic']*centered_kernel_mean/
          (fit$parameters['genetic']*centered_kernel_mean+fit$parameters['residual'])),
        predictive_ability=score['predictive_ability'],rmse=score['rmse'],
        published_glma_correlation=cor(y[test],published),raw_reml_correlation=cor(y[test],raw),
        difference_from_published_max=max(abs(predicted-published)),
        difference_from_published_rms=sqrt(mean((predicted-published)^2)),
        prediction_agreement=cor(predicted,published),
        restricted_log_likelihood=if(mode=='standardized_reml')fit$log_likelihood else NA_real_,
        elapsed_seconds=proc.time()[['elapsed']]-started)
      saveRDS(list(predicted=predicted,fit=fit,train=train,test=test,scale=scale),
        file.path(out,paste0(case,'-',fold,'-',mode,'.rds')))
      write.csv(do.call(rbind,rows),file.path(out,'comparisons.csv'),row.names=FALSE)
      cat('RESULT',case,fold,mode,'cor',score['predictive_ability'],
        'h',tail(rows,1)[[1]]$variance_fraction,
        'max discrepancy',max(abs(predicted-published)),'\n')
      rm(fit);gc()
    }
    rm(kernel,K,Kt);gc()
  }
  rm(input,X);gc()
}
coverage<-do.call(rbind,rows)
stopifnot(nrow(coverage)==22L,
  all(table(coverage$mode[coverage$dataset=='gpbench_maize'])==10L))
capture.output(sessionInfo(),file=file.path(out,'session-info.txt'))
cat('Completed controlled audit:',out,'\n')
