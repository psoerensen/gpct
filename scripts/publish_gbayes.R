# Generate reviewed aggregate website artifacts; individual predictions stay local.
source('scripts/paths.R');source('scripts/evaluate.R');source('benchmarks/methods.R')
fitting_library<-Sys.getenv('GPCT_GBAYES_LIBRARY')
if(nzchar(fitting_library)).libPaths(c(fitting_library,.libPaths()))
batch<-Sys.getenv('GPCT_RUN_ID','20261122-gbayes-glist-4t')
root<-file.path(output_dir(),batch)
asset_version<-format(Sys.time(),'%Y%m%dT%H%M%S',tz='UTC')
asset<-'docs/assets/reports/gbayes-glist';dir.create(asset,recursive=TRUE,showWarnings=FALSE)
rhe_root<-file.path(output_dir(),'20261122-rhe-blup-evaluation/4t')
rhe_ready<-all(vapply(c('cattle','maize'),function(case){
 path<-file.path(rhe_root,case,'status.csv')
 file.exists(path)&&read.csv(path)$status%in%c('completed','completed_with_failures')
},logical(1)))
if(rhe_ready)benchmark_methods<-rbind(benchmark_methods,data.frame(id='rhe_blup',
 label='RHE + BLUP',method='rhe_blup',algorithm='rhe_blup',
 settings='Ordinary native greml RHE: 128 probes, batches of 8, seed 62000+fold; native BLUP block PCG tolerance 1e-10, cap 1000; final residual gate 1e-8; native PSD/residual-floor policy unchanged; Glist training-AF HWE coding; K=ZZt/markers; RAM-budgeted oneMKL products',stringsAsFactors=FALSE))
directory_for<-function(method,case) {
 if(method=='rhe_blup')return(file.path(rhe_root,case))
 current<-file.path(root,method,case)
 if(method=='marker_gaussian'&&!file.exists(file.path(current,'status.csv')))
  return(file.path(output_dir(),'20261121-gbayes-glist-1t',method,case))
 current
}
labels<-setNames(benchmark_methods$label,benchmark_methods$id)
colors<-setNames(c('#168575','#3267b1','#9863b5','#c7761b','#b84365','#52606d',if(rhe_ready)'#111111'),benchmark_methods$id)
fmt<-function(x,digits=3)ifelse(is.finite(x),formatC(x,format='f',digits=digits),'not available')
legend_right<-function(methods) {
 area<-par('usr')
 legend(x=area[2]+.03*diff(area[1:2]),y=area[4],xjust=0,yjust=1,xpd=NA,
  legend=labels[methods],col=colors[methods],pch=ifelse(methods=='rhe_blup',17,19),bty='n',cex=.8)
}
display_status<-function(status)ifelse(grepl('^failed',status),sub('^failed; ','Failed: ',status),
 ifelse(grepl('provisional',status),'Provisional (mixing)','Completed'))
bind_rows<-function(rows) {
 columns<-unique(unlist(lapply(rows,names)))
 do.call(rbind,lapply(rows,function(x){for(key in setdiff(columns,names(x)))x[[key]]<-NA;x[columns]}))
}
markdown_table<-function(x) {
 x[]<-lapply(x,as.character)
 c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),
 apply(x,1,function(z)paste0('| ',paste(z,collapse=' | '),' |')))
}
completed<-vapply(benchmark_methods$id,function(method)all(vapply(c('cattle','maize'),function(case){
 path<-file.path(directory_for(method,case),'status.csv');file.exists(path)&&
  read.csv(path)$status%in%if(method=='rhe_blup')c('completed','completed_with_failures')else'completed'
},logical(1))),logical(1))
if(!any(completed))stop('No method has completed both datasets; do not publish partial accuracy.')
public_settings<-benchmark_methods;names(public_settings)[names(public_settings)=='id']<-'method_id'
public_settings$full_cv_workers<-ifelse(public_settings$algorithm%in%c('mcmc','rhe_blup'),4L,1L)
public_settings$full_cv_chains<-ifelse(public_settings$algorithm=='mcmc',4L,NA_integer_)
public_settings$burnin_per_chain<-ifelse(public_settings$algorithm=='mcmc',500L,NA_integer_)
public_settings$postburn_per_chain<-ifelse(public_settings$algorithm=='mcmc',1000L,NA_integer_)
public_settings$blas_threads<-ifelse(public_settings$algorithm=='rhe_blup',4L,1L)
public_settings$software<-ifelse(public_settings$algorithm=='rhe_blup','greml + gsolve + gbits; private Glist adapter','gbayes')
write.csv(public_settings,file.path(asset,'method-settings.csv'),row.names=FALSE)
native_sources<-do.call(rbind,lapply(c('gbase','gbayes'),function(package){
 manifest<-file.path(find.package(package),'source-manifest.txt')
 if(!file.exists(manifest))return(data.frame(package,component='installed native source manifest',revision='not present in installed R package'))
 all_lines<-readLines(manifest)
 lines<-all_lines[grepl('^Source-',all_lines)]
 rows<-data.frame(package,component=sub('^Source-([^:]+):.*','\\1',lines),
  revision=sub('^Source-[^:]+: *','',lines))
 local<-all_lines[grepl('^Local-source-SHA256: ',all_lines)]
 if(length(local))rows<-rbind(rows,data.frame(package,
  component=paste('local development SHA256',sub('^Local-source-SHA256: (.*) [[:xdigit:]]{64}$','\\1',local)),
  revision=tolower(sub('^.* ([[:xdigit:]]{64})$','\\1',local))))
 unique(rows)
}))
if(rhe_ready) {
 pins<-read.csv('environment/sources.csv',stringsAsFactors=FALSE)
 pins<-pins[pins$repository%in%c('greml','gsolve','gbits'),]
 native_sources<-rbind(native_sources,data.frame(package=pins$repository,
  component='RHE native prefix source pin',revision=pins$revision))
 cfg<-readRDS(file.path(rhe_root,'maize/configuration.rds'))
 native_sources<-rbind(native_sources,data.frame(package='RHE Glist adapter',
  component='private adapter source SHA256; implementation not published',revision=cfg$adapter_sha256))
}
write.csv(native_sources,file.path(asset,'native-source-revisions.csv'),row.names=FALSE)
runtime<-do.call(rbind,lapply(c('gbase','gbayes'),function(package){
 paths<-file.path(find.package(package),c(paste0('libs/x64/',package,'.dll'),paste0('R/',package,'.rdb'),paste0('R/',package,'.rdx')))
 paths<-paths[file.exists(paths)]
 data.frame(package,version=as.character(packageVersion(package)),artifact=basename(paths),
  sha256=vapply(paths,function(path)digest::digest(file=path,algo='sha256'),character(1)))
}))
if(rhe_ready)runtime<-rbind(runtime,data.frame(package='RHE native libraries',
 version='local native build; source pins recorded separately',artifact=names(cfg$native_sha256),sha256=unname(cfg$native_sha256)))
write.csv(runtime,file.path(asset,'runtime-checksums.csv'),row.names=FALSE)
all_summary<-all_folds<-all_calibration<-list();resource_rows<-list();fit_runtime<-list()
for(case in c('cattle','maize')) {
 trait<-if(case=='cattle')'mkg'else'DTT';n<-if(case=='cattle')5024L else 1458L
 report_asset<-file.path(asset,case);dir.create(report_asset,recursive=TRUE,showWarnings=FALSE)
 summaries<-folds<-calibration<-predictions<-list()
 for(method in benchmark_methods$id[completed]) {
  directory<-directory_for(method,case)
  f<-read.csv(file.path(directory,'fold-results.csv'),stringsAsFactors=FALSE)
  algorithm<-benchmark_methods$algorithm[match(method,benchmark_methods$id)]
  expected_workers<-if(algorithm%in%c('mcmc','rhe_blup'))4L else 1L
  stopifnot(nrow(f)==10L,identical(sort(f$fold),1:10),all(f$actual_workers==expected_workers),
    all(f$status%in%if(method=='rhe_blup')c('completed','failed')else'completed'))
  fully_accepted<-all(f$status=='completed')
  if(algorithm=='mcmc')stopifnot(all(f$logical_chains==4L),all(f$burnin_per_chain==500L),
   all(f$postburn_per_chain==1000L),all(f$blas_threads==1L))
  p<-if(fully_accepted)do.call(rbind,lapply(1:10,function(k)read.csv(file.path(directory,paste0('fold',k,'-predictions-local.csv')),stringsAsFactors=FALSE)))else
   data.frame(id=character(),observed=numeric(),predicted=numeric(),imputed=logical())
  if(fully_accepted)stopifnot(nrow(p)==n,!anyDuplicated(p$id),all(is.finite(p$observed)),all(is.finite(p$predicted)))
  stopifnot(length(unique(f$actual_workers))==1L)
  for(fold in 1:10) {
   provenance_file<-file.path(directory,paste0('fold',fold,'-source-provenance.rds'))
   entries<-if(file.exists(provenance_file))readRDS(provenance_file)$installed_source_manifests else
    lapply(c('gbase','gbayes'),function(package)list(package=package,version=NA_character_,binary_sha256=NA_character_))
   fit_runtime[[paste(case,method,fold)]]<-do.call(rbind,lapply(entries,function(x)
    data.frame(dataset=case,method,fold,package=x$package,version=x$version,
     binary_sha256=x$binary_sha256,recorded_at_fit=file.exists(provenance_file))))
  }
  pooled<-if(fully_accepted)metrics(p$observed,p$predicted)else
   setNames(rep(NA_real_,7),c('predictive_ability','rmse','mae','mse','predictive_r_squared','calibration_intercept','calibration_slope'))
  observed_only<-if(fully_accepted)metrics(p$observed[!p$imputed],p$predicted[!p$imputed])else pooled
  resource<-file.path(directory,'process-resources.csv')
  json_resources<-list.files(directory,pattern='^process-resources.*[.]json$',full.names=TRUE)
  if(length(json_resources)) {
   measured<-lapply(json_resources,jsonlite::fromJSON)
   # A preserved copy of one process report must not count as a second process.
   identities<-vapply(measured,function(x)paste(x$elapsed_seconds,x$user_cpu_seconds,
    x$kernel_cpu_seconds,x$peak_working_set_bytes,x$exit_code,sep='|'),character(1))
   measured<-measured[!duplicated(identities)]
   failed_processes<-sum(vapply(measured,function(x)x$exit_code!=0L,logical(1)))
   write.csv(data.frame(process_peak_working_set_mib=max(vapply(measured,`[[`,numeric(1),'peak_working_set_bytes'))/1024^2,
    process_elapsed_seconds=sum(vapply(measured,`[[`,numeric(1),'elapsed_seconds')),
    measured_processes=length(measured),unsuccessful_process_exits=failed_processes,
    scope=paste('Peak across',length(measured),'measured R processes; loading, preparation, fitting, saving and prediction;',failed_processes,'unsuccessful process exits included. Per-fold fitting failures are reported separately.'),
    completed_folds_at_start=paste(vapply(measured,function(x)if(is.null(x$completed_folds_at_start))'not recorded'else as.character(x$completed_folds_at_start),character(1)),collapse='; ')),resource,row.names=FALSE)
  }
  peak<-if(file.exists(resource))read.csv(resource)$process_peak_working_set_mib else NA_real_
  if(file.exists(resource)) {
   r<-read.csv(resource,stringsAsFactors=FALSE)
   value<-function(name)if(name%in%names(r))as.character(r[[name]][1])else'not recorded'
   resource_rows[[paste(case,method)]]<-data.frame(dataset=case,method,process_peak_working_set_mib=peak,
    scope=value('scope'),completed_folds_at_start=value('completed_folds_at_start'),
    phenotype_cache_preexisting=value('phenotype_cache_preexisting'),training_glists_cached_at_start=value('training_glists_cached_at_start'))
  }
  s<-data.frame(dataset=paste0('gpbench_',case),trait,method,algorithm=benchmark_methods$algorithm[match(method,benchmark_methods$id)],
   individuals=n,available_markers=f$available_markers[1],markers_used_min=min(f$markers_used),markers_used_max=max(f$markers_used),
   folds=10L,accepted_folds=sum(f$status=='completed'),workers=unique(f$actual_workers),
   predictive_ability_mean=if(fully_accepted)mean(f$predictive_ability)else NA_real_,
   predictive_ability_fold_sd=if(fully_accepted)sd(f$predictive_ability)else NA_real_,
   predictive_ability_pooled=pooled[['predictive_ability']],rmse_mean=if(fully_accepted)mean(f$rmse)else NA_real_,rmse_pooled=pooled[['rmse']],
   predictive_r_squared_pooled=pooled[['predictive_r_squared']],calibration_slope_pooled=pooled[['calibration_slope']],
   observed_target_correlation_pooled=observed_only[['predictive_ability']],imputed_targets=sum(p$imputed),
   fit_seconds=sum(f$fit_seconds),prediction_seconds=if(any(is.finite(f$prediction_seconds)))sum(f$prediction_seconds,na.rm=TRUE)else NA_real_,
   process_elapsed_seconds=if(file.exists(resource)&&'process_elapsed_seconds'%in%names(read.csv(resource)))read.csv(resource)$process_elapsed_seconds[1]else NA_real_,
   fit_plus_prediction_seconds=sum(f$fit_seconds+f$prediction_seconds),
   shared_glist_preparation_seconds=sum(f$shared_preparation_seconds),
   actual_glist_load_or_prepare_seconds=sum(f$preparation_seconds),
   process_peak_working_set_mib=peak,warning_count=sum(f$warning_count),
   mcmc_rhat_max=if('mcmc_rhat_max'%in%names(f)&&any(is.finite(f$mcmc_rhat_max)))max(f$mcmc_rhat_max,na.rm=TRUE)else NA_real_,
   mcmc_ess_min=if('mcmc_ess_min'%in%names(f)&&any(is.finite(f$mcmc_ess_min)))min(f$mcmc_ess_min,na.rm=TRUE)else NA_real_,
   status=if(!fully_accepted)paste0('failed; ',sum(f$status=='completed'),'/10 folds accepted')else
    if(algorithm=='mcmc'&&any(f$convergence!='mcmc_parameter_checks_passed'))'provisional; MCMC diagnostics need review'else'completed')
  if(fully_accepted) {
  q<-unique(as.numeric(quantile(p$predicted,seq(0,1,length.out=11))))
  group<-if(length(q)>1L)cut(p$predicted,q,include.lowest=TRUE,labels=FALSE)else rep(1L,n)
  bins<-do.call(rbind,lapply(sort(unique(group)),function(k){z<-p[group==k,];stopifnot(nrow(z)>=5L)
   data.frame(dataset=paste0('gpbench_',case),trait,method,bin=k,n=nrow(z),mean_prediction=mean(z$predicted),mean_observed=mean(z$observed))}))
  }else bins<-data.frame(dataset=character(),trait=character(),method=character(),bin=integer(),n=integer(),mean_prediction=numeric(),mean_observed=numeric())
  summaries[[method]]<-s;folds[[method]]<-f;calibration[[method]]<-bins;predictions[[method]]<-p
 }
 s<-do.call(rbind,summaries);f<-bind_rows(folds);b<-do.call(rbind,calibration)
 baseline<-folds[['marker_gaussian']]
 improvement<-vapply(s$method,function(method)mean(folds[[method]]$predictive_ability[
  match(1:10,folds[[method]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]),numeric(1))
 s$correlation_improvement_over_gaussian<-improvement
 for(kind in c('performance','improvement','runtime','calibration')) {
  svg(file.path(report_asset,paste0(kind,'.svg')),width=10,height=5.5,pointsize=13,family='sans')
  dev.control(displaylist='enable')
  par(mar=if(kind%in%c('runtime','calibration'))c(5,5,3,11)else c(5,11,3,2))
  if(kind%in%c('performance','improvement')) {
   y<-rev(seq_len(nrow(s)));values<-if(kind=='performance')s$predictive_ability_mean else improvement
   small<-if(kind=='performance')f$predictive_ability else unlist(lapply(s$method,function(method)
    folds[[method]]$predictive_ability[match(1:10,folds[[method]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]))
   limits<-range(c(values,small,if(kind=='improvement')0),na.rm=TRUE);pad<-max(.01,diff(limits)*.1)
   plot(values,y,xlim=limits+c(-pad,pad),ylim=c(.5,nrow(s)+.5),yaxt='n',ylab='',pch=ifelse(s$method=='rhe_blup',17,19),cex=1.2,
    col=colors[s$method],xlab=if(kind=='performance')'Predictive correlation: fold mean (large), individual folds (small)'else'Paired fold correlation difference from Gaussian PCG',
    main=paste(tools::toTitleCase(case),trait))
   axis(2,at=y,labels=labels[s$method],las=1)
   if(any(!is.finite(values)))text(limits[1],y[!is.finite(values)],'no accepted ten-fold score',adj=0,cex=.8)
   for(i in seq_len(nrow(s))) {
    values_i<-if(kind=='performance')folds[[s$method[i]]]$predictive_ability else
     folds[[s$method[i]]]$predictive_ability[match(1:10,folds[[s$method[i]]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]
    points(values_i,rep(y[i],10),col=adjustcolor(colors[s$method[i]],alpha.f=.4),pch=16,cex=.65)
   }
   if(kind=='improvement')abline(v=0,lty=2,col='gray40')
  }else if(kind=='runtime') {
   xr<-range(s$fit_plus_prediction_seconds,na.rm=TRUE);yr<-range(s$predictive_ability_mean,na.rm=TRUE)
   plot(s$fit_plus_prediction_seconds,s$predictive_ability_mean,pch=ifelse(s$method=='rhe_blup',17,19),cex=1.3,col=colors[s$method],
    xlim=xr+c(-1,1)*max(1,diff(xr)*.1),ylim=yr+c(-1,1)*max(.01,diff(yr)*.1),
    xlab='Total fitting + held-out prediction (seconds; ten folds)',ylab='Mean fold predictive correlation',main=paste(tools::toTitleCase(case),trait))
   legend_right(s$method[is.finite(s$predictive_ability_mean)])
  }else {
   limits<-range(b$mean_prediction,b$mean_observed)
   plot(limits,limits,type='n',xlab='Binned mean prediction',ylab='Binned mean observed phenotype',main=paste(tools::toTitleCase(case),trait))
   abline(0,1,lty=2,col='gray40')
   for(method in s$method){z<-b[b$method==method,];if(nrow(z))lines(z$mean_prediction,z$mean_observed,type='b',col=colors[method],pch=if(method=='rhe_blup')17 else 19)}
   legend_right(unique(b$method))
  }
  recorded_plot<-recordPlot()
  dev.off()
  # Private raster mirror supports visual QA; only the SVG enters the website.
  preview_dir<-file.path(output_dir(),'website-preview',batch,case)
  dir.create(preview_dir,recursive=TRUE,showWarnings=FALSE)
  png(file.path(preview_dir,paste0(kind,'.png')),width=960,height=528,res=96,pointsize=13,type='cairo')
  replayPlot(recorded_plot)
  dev.off()
 }
 write.csv(s,file.path(report_asset,'benchmark-results.csv'),row.names=FALSE)
 write.csv(f,file.path(report_asset,'fold-results.csv'),row.names=FALSE)
 write.csv(b,file.path(report_asset,'calibration-summary.csv'),row.names=FALSE)
 display<-data.frame(Method=labels[s$method],Correlation=fmt(s$predictive_ability_mean),RMSE=fmt(s$rmse_mean),
  `Pooled predictive R²`=fmt(s$predictive_r_squared_pooled),`Calibration slope`=fmt(s$calibration_slope_pooled),
  Status=display_status(s$status),check.names=FALSE)
 cost_display<-data.frame(Method=labels[s$method],Workers=s$workers,
  `Fit s`=fmt(s$fit_seconds,1),`Predict s`=fmt(s$prediction_seconds,1),
  `Total process s`=fmt(s$process_elapsed_seconds,1),
  `Process peak MiB`=fmt(s$process_peak_working_set_mib,0),
  `Fit + predict s`=fmt(s$fit_plus_prediction_seconds,1),check.names=FALSE)
 page<-c('---','layout: default',paste0('title: ',tools::toTitleCase(case),' prediction'),'---',paste0('# ',tools::toTitleCase(case),' / ',trait),'',
  paste('Predict the supplied',trait,'phenotype within this GPBench cohort using native gsuite methods. All fits and held-out predictions receive Glist.'),'',
  paste(n,'individuals;',s$available_markers[1],'available markers;',s$markers_used_min[1],'QC-retained markers. Synthetic BIM/FAM annotations are bookkeeping, not biological maps.'),'',
  'Saved GPBench ten-fold splits, seed 42. The MCMC collection uses four concurrent chains with one BLAS thread; the fixed Gaussian PCG reference used one worker. Actual workers are reported per method. Native model coding is preserved. See the [protocol](../protocol.html) and [settings](../methods.html).','',
  markdown_table(display),'',
  'Correlation and RMSE in this table are means of ten fold metrics. Predictive R² and calibration slope are calculated from pooled out-of-fold predictions. Fold variation is descriptive; no independent-replicate confidence intervals are claimed.','',
  '## Computational cost','',markdown_table(cost_display),'',
  paste('Shared training-Glist preparation across ten folds:',fmt(s$shared_glist_preparation_seconds[1],2),'seconds. Fitting includes native genotype preparation; prediction is timed separately. Process peak RAM covers package loading, preparation, the folds executed in that process, saved outputs and prediction; it is not fit-only peak RAM. Cache state and resumed work may differ; see [process resource context](../assets/reports/gbayes-glist/process-resources.csv).'),'',
  '[Summary CSV](../assets/reports/gbayes-glist/CASE/benchmark-results.csv) · [Fold metrics](../assets/reports/gbayes-glist/CASE/fold-results.csv) · [Aggregate calibration](../assets/reports/gbayes-glist/CASE/calibration-summary.csv)','',
  '## Predictive performance','','[![Predictive performance](../assets/reports/gbayes-glist/CASE/performance.svg)](../assets/reports/gbayes-glist/CASE/performance.svg)','',
  '## Improvement over Gaussian','','[![Difference from Gaussian PCG](../assets/reports/gbayes-glist/CASE/improvement.svg)](../assets/reports/gbayes-glist/CASE/improvement.svg)','',
  '## Performance and cost','','[![Performance versus runtime](../assets/reports/gbayes-glist/CASE/runtime.svg)](../assets/reports/gbayes-glist/CASE/runtime.svg)','',
  '## Calibration','','[![Aggregate calibration](../assets/reports/gbayes-glist/CASE/calibration.svg)](../assets/reports/gbayes-glist/CASE/calibration.svg)','',
  paste('Mean-imputed evaluation targets:',s$imputed_targets[1],'. Observed-target-only pooled correlations are provided in the summary CSV. No individual prediction plots or records are published.'),'',
  '## Diagnostics and reproduction','',paste('R fitting warnings:',sum(s$warning_count),'. Separately,',sum(f$method%in%benchmark_methods$id[benchmark_methods$algorithm=='mcmc'] & f$convergence!='mcmc_parameter_checks_passed'),'MCMC fold fits have diagnostic flags. MCMC scores remain provisional if any fold has retained-parameter R-hat above 1.05, bulk ESS below 100, or unavailable diagnostics. Per-fold maxima/minima and status are in the downloadable metrics; these checks do not establish all-marker convergence. Native diagnostics and saved fits remain local.'),'',
  if(rhe_ready)'RHE + BLUP uses up to four native MKL threads for one fit, rather than four chains. Any failed fold suppresses its ten-fold accuracy and calibration summaries. Timings retain failed fitting attempts. See the [RHE evaluation and variance diagnostics](rhe-blup.html).','',
  'Reproduction entry point for the retained local development checkout: this requires the identified unreleased native build and local benchmark controller. These implementation changes are not released by this aggregate website update.','',
  '```powershell','./environment/run-glist-benchmark-plan.ps1','```','',
  'This runs the matched threading/chain checks and the four-chain ten-fold collection on both panels. Use `-Methods bayesC_mcmc` to select one MCMC method. The fixed Gaussian reference is rebuilt if missing. Individual data and outputs use the external directories described in the repository. See the [method settings](../methods.html). [Back to all results](../results.html).')
 page<-gsub('.svg',paste0('.svg?v=',asset_version),page,fixed=TRUE)
 writeLines(gsub('CASE',case,page,fixed=TRUE),file.path('docs/reports',paste0(case,'.md')))
 all_summary[[case]]<-s;all_folds[[case]]<-f;all_calibration[[case]]<-b
}
s<-do.call(rbind,all_summary)
write.csv(s,file.path(asset,'benchmark-results.csv'),row.names=FALSE)
write.csv(do.call(rbind,fit_runtime),file.path(asset,'fit-runtime-checksums.csv'),row.names=FALSE)
write.csv(bind_rows(all_folds),file.path(asset,'fold-results.csv'),row.names=FALSE)
write.csv(do.call(rbind,all_calibration),file.path(asset,'calibration-summary.csv'),row.names=FALSE)
if(length(resource_rows))write.csv(do.call(rbind,resource_rows),file.path(asset,'process-resources.csv'),row.names=FALSE)
method_status<-do.call(rbind,lapply(benchmark_methods$id,function(method)do.call(rbind,lapply(c('cattle','maize'),function(case){
 path<-file.path(directory_for(method,case),'status.csv');state<-if(file.exists(path))read.csv(path,stringsAsFactors=FALSE)else data.frame(status='not_started',message='')
 message<-if('message'%in%names(state))state$message else''
 if(method=='rhe_blup') {
  records<-read.csv(file.path(directory_for(method,case),'fold-results.csv'),stringsAsFactors=FALSE)
  message<-paste(unique(records$failure_message[records$status=='failed']),collapse=' | ')
 }
 data.frame(dataset=case,method,status=state$status,message)
}))))
write.csv(method_status,file.path(asset,'method-status.csv'),row.names=FALSE)
states<-data.frame(Method=benchmark_methods$label,Algorithm=benchmark_methods$algorithm,
 Status=vapply(benchmark_methods$id,function(method){
  if(completed[[method]])return(if(method=='rhe_blup')'Evaluation finished: ten attempts per dataset; acceptance shown above'else'Completed: cattle and maize, ten folds each')
  z<-method_status[method_status$method==method,]
  if(any(z$status=='failed'))return(paste0('Checkpoint failed: ',paste(z$dataset[z$status=='failed'],collapse=', '),'; other runs not launched'))
  if(any(z$status=='running'))return(paste('Running:',paste(z$dataset[z$status=='running'],collapse=', ')))
  if(any(z$status=='partial'))return('First-fold checkpoint passed; full run pending')
  'Queued'
 },character(1)),check.names=FALSE)
main_accuracy<-data.frame(Dataset=ifelse(s$dataset=='gpbench_cattle','[Cattle / mkg](reports/cattle.html)','[Maize / DTT](reports/maize.html)'),
 Method=labels[s$method],Correlation=fmt(s$predictive_ability_mean),RMSE=fmt(s$rmse_mean),
 `Pooled predictive R²`=fmt(s$predictive_r_squared_pooled),`Calibration slope`=fmt(s$calibration_slope_pooled),
 Status=display_status(s$status),check.names=FALSE)
main_cost<-data.frame(Dataset=ifelse(s$dataset=='gpbench_cattle','Cattle / mkg','Maize / DTT'),Method=labels[s$method],Workers=s$workers,
 `Fit seconds`=fmt(s$fit_seconds,1),`Predict seconds`=fmt(s$prediction_seconds,1),
 `Total process seconds`=fmt(s$process_elapsed_seconds,1),
 `Fit + predict seconds`=fmt(s$fit_plus_prediction_seconds,1),`Process peak MiB`=fmt(s$process_peak_working_set_mib,0),check.names=FALSE)
writeLines(c('---','layout: default','title: Results and timings','---','# Results and timings','',
 'Native gsuite methods fitted directly from QC-selected Glist. MCMC runs use four concurrent chains and one BLAS thread; the fixed Gaussian PCG reference used one worker. RHE + BLUP uses one fit with up to four native MKL threads. Results follow evaluation of both datasets.','',
 '## Predictive performance','',markdown_table(main_accuracy),'',
 'Correlation and RMSE are means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Compare methods within each dataset and trait. MCMC rows are provisional when retained parameter R-hat exceeds 1.05 or bulk ESS is below 100; completing iterations does not establish convergence. Failed RHE fits remain visible; a missing fold suppresses the aggregate accuracy rather than averaging only successful fits.','',
 '## Computational cost','',markdown_table(main_cost),'',
 'Fit and prediction times sum all ten folds. Total process time includes loading, preparation, fitting, saving and prediction across recorded process segments; unsuccessful attempts, if any, are included and recorded in the resource context. Unavailable measurements remain explicit. Fitting includes native genotype/cache preparation; shared Glist preparation is reported separately. Peak RAM spans the recorded R processes. Cache state and resumed work can differ; [process resource context](assets/reports/gbayes-glist/process-resources.csv) preserves available details.','',
 '## Method progress','',
 markdown_table(states),'','[Cattle / mkg results](reports/cattle.html) · [Maize / DTT results](reports/maize.html)','',
 '[Combined summary CSV](assets/reports/gbayes-glist/benchmark-results.csv) · [Fold metrics](assets/reports/gbayes-glist/fold-results.csv) · [Method settings](assets/reports/gbayes-glist/method-settings.csv) · [Run status and failure messages](assets/reports/gbayes-glist/method-status.csv)','',
 'Compare methods within each dataset and trait. Native model scaling, fixed versus learned variances, iteration settings and diagnostics are documented in the [methods](methods.html) and [protocol](protocol.html). Individual out-of-fold predictions stay local.'),'docs/results.md')
cat('Generated aggregate pages for',sum(completed),'completed methods.\n')
thread_files<-list.files(file.path(output_dir(),'20261122-thread-probe-summary'),pattern='[.]csv$',full.names=TRUE)
if(length(thread_files)) {
 threads<-do.call(rbind,lapply(thread_files,read.csv,stringsAsFactors=FALSE))
 stopifnot(all(threads$identical_seeded_outputs))
 write.csv(threads,file.path(asset,'thread-comparison.csv'),row.names=FALSE)
 view<-data.frame(Dataset=threads$dataset,Method=labels[threads$method],
  `1-worker fit s`=fmt(threads$one_worker_fit_seconds,1),`4-worker fit s`=fmt(threads$four_worker_fit_seconds,1),
  `Fit speedup`=fmt(threads$fitting_speedup,2),`Sampler speedup`=fmt(threads$sampler_speedup,2),check.names=FALSE)
 writeLines(c('---','layout: default','title: One versus four workers','---','# One versus four workers','',
  'Matched short probes on saved fold 1: four identical seeded chains, each with 100 burn-in and 200 post-burn transitions. Only the maximum concurrent chain count changes. BLAS stays at one thread. These probes measure threading, and are separate from the ten-fold accuracy results.','',
  markdown_table(view),'','Speedup is one-worker time divided by four-worker time. Fitting includes genotype/cache preparation; the sampler column isolates native sampling. Seeded effects and parameter traces must be identical. A changed cache admission state makes the speedup unavailable. Process peak RAM and all timings are in the [summary CSV](../assets/reports/gbayes-glist/thread-comparison.csv).','',
  'Four workers run independent chains concurrently; marker updates within each chain retain their existing order. These short probes do not establish convergence. The separate [chain-efficiency comparison](chain-efficiency.html) measures the effect of adding chains.','',
  '[Back to results](../results.html)'), 'docs/reports/threading.md')
 cat('Generated matched-workload threading report.\n')
}
chain_files<-list.files(file.path(output_dir(),'20261122-chain-comparison-summary'),pattern='[.]csv$',full.names=TRUE)
if(length(chain_files)) {
 chains<-do.call(rbind,lapply(chain_files,read.csv,stringsAsFactors=FALSE))
 stopifnot(all(chains$first_two_chain_trajectories_match))
 write.csv(chains,file.path(asset,'chain-efficiency.csv'),row.names=FALSE)
 view<-data.frame(Dataset=chains$dataset,Method=labels[chains$method],Parameter=chains$parameter,
  Chains=chains$chains,Workers=chains$workers,`R-hat`=fmt(chains$rhat,2),
  `Bulk ESS`=fmt(chains$bulk_ess,1),`ESS / fit second`=fmt(chains$bulk_ess_per_fit_second,3),check.names=FALSE)
 writeLines(c('---','layout: default','title: Chain efficiency','---','# Two versus four chains','',
  'Saved fold 1, unchanged 500 burn-in and 1000 post-burn transitions per chain: two sequential chains versus four concurrent chains. The first two seeded parameter trajectories must match. More chains add draws; scheduling the same chains differently changes runtime without changing their draws.','',
  markdown_table(view),'','Compare ESS per second within the same method, dataset and parameter. ESS estimates remain provisional when chains have not mixed; more chains do not guarantee proportionally more effective samples. Fitting includes genotype/cache preparation. This is distinct from the short matched four-chain [threading probe](threading.html).','',
  '[Summary CSV](../assets/reports/gbayes-glist/chain-efficiency.csv) · [Ten-fold results](../results.html)'), 'docs/reports/chain-efficiency.md')
 cat('Generated practical chain-efficiency report.\n')
}
if(length(thread_files)||length(chain_files))cat('\n[One versus four workers](reports/threading.html) · [Two versus four chains and ESS per second](reports/chain-efficiency.html)\n',file='docs/results.md',append=TRUE)
if(rhe_ready)source('scripts/publish_rhe_report.R')
