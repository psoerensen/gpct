# Generate reviewed aggregate website artifacts; individual predictions stay local.
source('scripts/paths.R');source('scripts/evaluate.R');source('benchmarks/methods.R')
batch<-Sys.getenv('GPCT_RUN_ID','20261121-gbayes-glist-1t')
root<-file.path(output_dir(),batch)
asset_version<-format(Sys.time(),'%Y%m%dT%H%M%S',tz='UTC')
asset<-'docs/assets/reports/gbayes-glist-1t';dir.create(asset,recursive=TRUE,showWarnings=FALSE)
labels<-setNames(benchmark_methods$label,benchmark_methods$id)
colors<-setNames(c('#168575','#3267b1','#9863b5','#c7761b','#b84365','#52606d'),benchmark_methods$id)
fmt<-function(x,digits=3)ifelse(is.finite(x),formatC(x,format='f',digits=digits),'not available')
markdown_table<-function(x) {
 x[]<-lapply(x,as.character)
 c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),
 apply(x,1,function(z)paste0('| ',paste(z,collapse=' | '),' |')))
}
completed<-vapply(benchmark_methods$id,function(method)all(vapply(c('cattle','maize'),function(case){
 path<-file.path(root,method,case,'status.csv');file.exists(path)&&read.csv(path)$status=='completed'
},logical(1))),logical(1))
if(!any(completed))stop('No method has completed both datasets; do not publish partial accuracy.')
public_settings<-benchmark_methods;names(public_settings)[names(public_settings)=='id']<-'method_id'
write.csv(public_settings,file.path(asset,'method-settings.csv'),row.names=FALSE)
all_summary<-all_folds<-all_calibration<-list()
for(case in c('cattle','maize')) {
 trait<-if(case=='cattle')'mkg'else'DTT';n<-if(case=='cattle')5024L else 1458L
 report_asset<-file.path(asset,case);dir.create(report_asset,recursive=TRUE,showWarnings=FALSE)
 summaries<-folds<-calibration<-predictions<-list()
 for(method in benchmark_methods$id[completed]) {
  directory<-file.path(root,method,case)
  f<-read.csv(file.path(directory,'fold-results.csv'),stringsAsFactors=FALSE)
  stopifnot(nrow(f)==10L,identical(sort(f$fold),1:10),all(f$status=='completed'),all(f$actual_workers==1L))
  p<-do.call(rbind,lapply(1:10,function(k)read.csv(file.path(directory,paste0('fold',k,'-predictions-local.csv')),stringsAsFactors=FALSE)))
  stopifnot(nrow(p)==n,!anyDuplicated(p$id),all(is.finite(p$observed)),all(is.finite(p$predicted)))
  pooled<-metrics(p$observed,p$predicted);observed_only<-metrics(p$observed[!p$imputed],p$predicted[!p$imputed])
  resource<-file.path(directory,'process-resources.csv')
  peak<-if(file.exists(resource))read.csv(resource)$process_peak_working_set_mib else NA_real_
  s<-data.frame(dataset=paste0('gpbench_',case),trait,method,algorithm=benchmark_methods$algorithm[match(method,benchmark_methods$id)],
   individuals=n,available_markers=f$available_markers[1],markers_used_min=min(f$markers_used),markers_used_max=max(f$markers_used),
   folds=10L,workers=1L,predictive_ability_mean=mean(f$predictive_ability),predictive_ability_fold_sd=sd(f$predictive_ability),
   predictive_ability_pooled=pooled[['predictive_ability']],rmse_mean=mean(f$rmse),rmse_pooled=pooled[['rmse']],
   predictive_r_squared_pooled=pooled[['predictive_r_squared']],calibration_slope_pooled=pooled[['calibration_slope']],
   observed_target_correlation_pooled=observed_only[['predictive_ability']],imputed_targets=sum(p$imputed),
   fit_seconds=sum(f$fit_seconds),prediction_seconds=sum(f$prediction_seconds),
   fit_plus_prediction_seconds=sum(f$fit_seconds+f$prediction_seconds),
   shared_glist_preparation_seconds=sum(f$shared_preparation_seconds),
   actual_glist_load_or_prepare_seconds=sum(f$preparation_seconds),
   process_peak_working_set_mib=peak,warning_count=sum(f$warning_count),
   status=if(any(f$convergence!='converged'))'completed; diagnostics need review'else'completed')
  q<-unique(as.numeric(quantile(p$predicted,seq(0,1,length.out=11))))
  group<-if(length(q)>1L)cut(p$predicted,q,include.lowest=TRUE,labels=FALSE)else rep(1L,n)
  bins<-do.call(rbind,lapply(sort(unique(group)),function(k){z<-p[group==k,];stopifnot(nrow(z)>=5L)
   data.frame(dataset=paste0('gpbench_',case),trait,method,bin=k,n=nrow(z),mean_prediction=mean(z$predicted),mean_observed=mean(z$observed))}))
  summaries[[method]]<-s;folds[[method]]<-f;calibration[[method]]<-bins;predictions[[method]]<-p
 }
 s<-do.call(rbind,summaries);f<-do.call(rbind,folds);b<-do.call(rbind,calibration)
 baseline<-folds[['marker_gaussian']]
 improvement<-vapply(s$method,function(method)mean(folds[[method]]$predictive_ability[
  match(1:10,folds[[method]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]),numeric(1))
 s$correlation_improvement_over_gaussian<-improvement
 for(kind in c('performance','improvement','runtime','calibration')) {
  svg(file.path(report_asset,paste0(kind,'.svg')),width=10,height=5.5,pointsize=13,family='sans')
  par(mar=if(kind%in%c('runtime','calibration'))c(5,5,3,11)else c(5,11,3,2))
  if(kind%in%c('performance','improvement')) {
   y<-rev(seq_len(nrow(s)));values<-if(kind=='performance')s$predictive_ability_mean else improvement
   small<-if(kind=='performance')f$predictive_ability else unlist(lapply(s$method,function(method)
    folds[[method]]$predictive_ability[match(1:10,folds[[method]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]))
   limits<-range(c(values,small,if(kind=='improvement')0));pad<-max(.01,diff(limits)*.1)
   plot(values,y,xlim=limits+c(-pad,pad),ylim=c(.5,nrow(s)+.5),yaxt='n',ylab='',pch=19,cex=1.2,
    col=colors[s$method],xlab=if(kind=='performance')'Predictive correlation: fold mean (large), individual folds (small)'else'Paired fold correlation difference from Gaussian PCG',
    main=paste(tools::toTitleCase(case),trait))
   axis(2,at=y,labels=labels[s$method],las=1)
   for(i in seq_len(nrow(s))) {
    values_i<-if(kind=='performance')folds[[s$method[i]]]$predictive_ability else
     folds[[s$method[i]]]$predictive_ability[match(1:10,folds[[s$method[i]]]$fold)]-baseline$predictive_ability[match(1:10,baseline$fold)]
    points(values_i,rep(y[i],10),col=adjustcolor(colors[s$method[i]],alpha.f=.4),pch=16,cex=.65)
   }
   if(kind=='improvement')abline(v=0,lty=2,col='gray40')
  }else if(kind=='runtime') {
   xr<-range(s$fit_plus_prediction_seconds);yr<-range(s$predictive_ability_mean)
   plot(s$fit_plus_prediction_seconds,s$predictive_ability_mean,pch=19,cex=1.3,col=colors[s$method],
    xlim=xr+c(-1,1)*max(1,diff(xr)*.1),ylim=yr+c(-1,1)*max(.01,diff(yr)*.1),
    xlab='Total fitting + held-out prediction (seconds; ten folds)',ylab='Mean fold predictive correlation',main=paste(tools::toTitleCase(case),trait))
   legend('topright',inset=c(-.6,0),xpd=NA,legend=labels[s$method],col=colors[s$method],pch=19,bty='n',cex=.8)
  }else {
   limits<-range(b$mean_prediction,b$mean_observed)
   plot(limits,limits,type='n',xlab='Binned mean prediction',ylab='Binned mean observed phenotype',main=paste(tools::toTitleCase(case),trait))
   abline(0,1,lty=2,col='gray40')
   for(method in s$method){z<-b[b$method==method,];lines(z$mean_prediction,z$mean_observed,type='b',col=colors[method],pch=19)}
   legend('topright',inset=c(-.6,0),xpd=NA,legend=labels[s$method],col=colors[s$method],pch=19,bty='n',cex=.8)
  }
  dev.off()
 }
 write.csv(s,file.path(report_asset,'benchmark-results.csv'),row.names=FALSE)
 write.csv(f,file.path(report_asset,'fold-results.csv'),row.names=FALSE)
 write.csv(b,file.path(report_asset,'calibration-summary.csv'),row.names=FALSE)
 display<-data.frame(Method=labels[s$method],Correlation=fmt(s$predictive_ability_mean),RMSE=fmt(s$rmse_mean),
  `Pooled predictive R²`=fmt(s$predictive_r_squared_pooled),`Calibration slope`=fmt(s$calibration_slope_pooled),
  `Fit s`=fmt(s$fit_seconds,1),`Predict s`=fmt(s$prediction_seconds,1),`Process peak MiB`=fmt(s$process_peak_working_set_mib,0),check.names=FALSE)
 page<-c('---','layout: default',paste0('title: ',tools::toTitleCase(case),' prediction'),'---',paste0('# ',tools::toTitleCase(case),' / ',trait),'',
  paste('Predict the supplied',trait,'phenotype within this GPBench cohort using existing gbayes methods. All fits and held-out predictions receive Glist.'),'',
  paste(n,'individuals;',s$available_markers[1],'available markers;',s$markers_used_min[1],'QC-retained markers. Synthetic BIM/FAM annotations are bookkeeping, not biological maps.'),'',
  'Saved GPBench ten-fold splits, seed 42; one native worker and one BLAS/OpenMP thread. Native method-specific coding is preserved. See the [protocol](../protocol.html) and [settings](../methods.html).','',
  markdown_table(display),'',
  'Correlation and RMSE in this table are means of ten fold metrics. Predictive R² and calibration slope are calculated from pooled out-of-fold predictions. Fold variation is descriptive; no independent-replicate confidence intervals are claimed.','',
  paste('Shared training-Glist preparation across ten folds:',fmt(s$shared_glist_preparation_seconds[1],2),'seconds. Fitting includes native genotype preparation; prediction is timed separately. Process peak RAM covers package loading, preparation, all folds, saved outputs and prediction; it is not fit-only peak RAM.'),'',
  '[Summary CSV](../assets/reports/gbayes-glist-1t/CASE/benchmark-results.csv) · [Fold metrics](../assets/reports/gbayes-glist-1t/CASE/fold-results.csv) · [Aggregate calibration](../assets/reports/gbayes-glist-1t/CASE/calibration-summary.csv)','',
  '## Predictive performance','','[![Predictive performance](../assets/reports/gbayes-glist-1t/CASE/performance.svg)](../assets/reports/gbayes-glist-1t/CASE/performance.svg)','',
  '## Improvement over Gaussian','','[![Difference from Gaussian PCG](../assets/reports/gbayes-glist-1t/CASE/improvement.svg)](../assets/reports/gbayes-glist-1t/CASE/improvement.svg)','',
  '## Performance and cost','','[![Performance versus runtime](../assets/reports/gbayes-glist-1t/CASE/runtime.svg)](../assets/reports/gbayes-glist-1t/CASE/runtime.svg)','',
  '## Calibration','','[![Aggregate calibration](../assets/reports/gbayes-glist-1t/CASE/calibration.svg)](../assets/reports/gbayes-glist-1t/CASE/calibration.svg)','',
  paste('Mean-imputed evaluation targets:',s$imputed_targets[1],'. Observed-target-only pooled correlations are provided in the summary CSV. No individual prediction plots or records are published.'),'',
  '## Diagnostics and reproduction','',paste('Warnings across published fits:',sum(s$warning_count),'. Convergence status is retained per fold in the downloadable metrics. Native diagnostics and saved fits remain local.'),'',
  '```powershell','./environment/activate.ps1 -BlasThreads 1',paste('Rscript --vanilla scripts/run_gbayes.R marker_gaussian',case),'```','',
  'Replace the method ID with another listed in the [method settings](../methods.html). Individual data and outputs must use the external directories described in the repository. [Back to all results](../results.html).')
 page<-gsub('.svg',paste0('.svg?v=',asset_version),page,fixed=TRUE)
 writeLines(gsub('CASE',case,page,fixed=TRUE),file.path('docs/reports',paste0(case,'.md')))
 all_summary[[case]]<-s;all_folds[[case]]<-f;all_calibration[[case]]<-b
}
s<-do.call(rbind,all_summary)
write.csv(s,file.path(asset,'benchmark-results.csv'),row.names=FALSE)
write.csv(do.call(rbind,all_folds),file.path(asset,'fold-results.csv'),row.names=FALSE)
write.csv(do.call(rbind,all_calibration),file.path(asset,'calibration-summary.csv'),row.names=FALSE)
method_status<-do.call(rbind,lapply(benchmark_methods$id,function(method)do.call(rbind,lapply(c('cattle','maize'),function(case){
 path<-file.path(root,method,case,'status.csv');state<-if(file.exists(path))read.csv(path,stringsAsFactors=FALSE)else data.frame(status='not_started',message='')
 data.frame(dataset=case,method,status=state$status,message=state$message)
}))))
write.csv(method_status,file.path(asset,'method-status.csv'),row.names=FALSE)
states<-data.frame(Method=benchmark_methods$label,Algorithm=benchmark_methods$algorithm,
 Status=vapply(benchmark_methods$id,function(method){
  if(completed[[method]])return('Completed: cattle and maize, ten folds each')
  z<-method_status[method_status$method==method,]
  if(any(z$status=='failed'))return(paste0('Checkpoint failed: ',paste(z$dataset[z$status=='failed'],collapse=', '),'; other runs not launched'))
  if(any(z$status=='running'))return(paste('Running:',paste(z$dataset[z$status=='running'],collapse=', ')))
  if(any(z$status=='partial'))return('First-fold checkpoint passed; full run pending')
  'Queued'
 },character(1)),check.names=FALSE)
main_accuracy<-data.frame(Dataset=ifelse(s$dataset=='gpbench_cattle','[Cattle / mkg](reports/cattle.html)','[Maize / DTT](reports/maize.html)'),
 Method=labels[s$method],Correlation=fmt(s$predictive_ability_mean),RMSE=fmt(s$rmse_mean),
 `Pooled predictive R²`=fmt(s$predictive_r_squared_pooled),`Calibration slope`=fmt(s$calibration_slope_pooled),check.names=FALSE)
main_cost<-data.frame(Dataset=ifelse(s$dataset=='gpbench_cattle','Cattle / mkg','Maize / DTT'),Method=labels[s$method],
 `Fit seconds`=fmt(s$fit_seconds,1),`Predict seconds`=fmt(s$prediction_seconds,1),
 `Fit + predict seconds`=fmt(s$fit_plus_prediction_seconds,1),`Process peak MiB`=fmt(s$process_peak_working_set_mib,0),check.names=FALSE)
writeLines(c('---','layout: default','title: Results and timings','---','# Results and timings','',
 'Existing gbayes methods fitted directly from QC-selected Glist, with **one worker**. Results are added after a method finishes both datasets. The earlier experimental benchmark collection has been retired.','',
 '## Predictive performance','',markdown_table(main_accuracy),'',
 'Correlation and RMSE are means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Compare methods within each dataset and trait.','',
 '## Computational cost','',markdown_table(main_cost),'',
 'Times sum all ten folds. Fitting includes native genotype preparation; shared Glist preparation is reported separately in the detailed reports. Process peak RAM includes loading, preparation, output and prediction, rather than fitting alone.','',
 '## Method progress','',
 markdown_table(states),'','[Cattle / mkg results](reports/cattle.html) · [Maize / DTT results](reports/maize.html)','',
 '[Combined summary CSV](assets/reports/gbayes-glist-1t/benchmark-results.csv) · [Fold metrics](assets/reports/gbayes-glist-1t/fold-results.csv) · [Method settings](assets/reports/gbayes-glist-1t/method-settings.csv) · [Run status and failure messages](assets/reports/gbayes-glist-1t/method-status.csv)','',
 'Compare methods within each dataset and trait. Native model scaling, fixed versus learned variances, iteration settings and diagnostics are documented in the [methods](methods.html) and [protocol](protocol.html). Individual out-of-fold predictions stay local.'),'docs/results.md')
cat('Generated aggregate pages for',sum(completed),'completed methods.\n')
