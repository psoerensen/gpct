# GPBench arrays -> PLINK -> gprep -> gfilter -> QC-selected Glist.
source('scripts/paths.R')
library(gbase)
library(jsonlite)
root<-Sys.getenv('GPCT_ENV_DIR')
stopifnot(nzchar(root))
python<-file.path(root,'python/Scripts/python.exe')
revision<-'f0204d8372fb5ec8fa29eb3f00c9a9d0a7656517'
destination<-file.path(data_dir(),'glist','20261121-maf001-miss005')
summaries<-list()
for(case in c('cattle','maize')) {
  species<-if(case=='cattle')'Cattle'else'Maize'
  directory<-file.path(destination,case)
  dir.create(directory,recursive=TRUE,showWarnings=FALSE)
  prefix<-file.path(directory,'source-synthetic')
  source<-file.path(data_dir(),'raw',revision,'Benchmarkdata/Benchmarkdata',species,'genotype.npz')
  arguments<-c('scripts/npz_to_plink.py',case,shQuote(source),shQuote(prefix))
  if(file.exists(paste0(prefix,'.json'))) arguments<-c(arguments,'--verify-existing')
  status<-system2(python,arguments)
  if(status!=0L)stop('NPZ/PLINK conversion or verification failed for ',case)
  manifest<-jsonlite::fromJSON(paste0(prefix,'.json'))
  stopifnot(isTRUE(manifest$synthetic_annotations),isTRUE(manifest$all_dosages_roundtrip_equal))
  Glist<-gbase::gprep(bedfiles=paste0(prefix,'.bed'),nthreads=4L,companion=NULL)
  Glist$provenance$synthetic_annotations<-TRUE
  Glist$provenance$synthetic_metadata<-manifest
  gbase::validate_Glist(Glist)
  # Use the existing public selector; allele/map-dependent rules are disabled.
  keep<-gbase::gfilter(Glist,maf=.01,missing=.05,hwe=NULL,
    info=NULL,ambiguous=FALSE,indels=FALSE,mhc=FALSE)
  # Existing owner audit supplies the same per-marker HWE statistics for reporting.
  audit<-gbase:::.gfilter_audit(Glist,maf=.01,missing=.05,hwe=NULL,
    info=NULL,ambiguous=FALSE,indels=FALSE,mhc=FALSE)
  stopifnot(identical(keep,audit$marker_id[!audit$excluded]),
    !any(abs(audit$maf-.01)<1e-14))
  write.csv(audit,file.path(directory,'marker-qc-local.csv'),row.names=FALSE)
  qc_prefix<-file.path(directory,'qc')
  if(!file.exists(paste0(qc_prefix,'.bed'))) {
    selected<-gbase::gprep(Glist=Glist,task='subset',rsids=keep,
      out_prefix=qc_prefix,nthreads=4L,companion=NULL)
  } else selected<-gbase::gprep(bedfiles=paste0(qc_prefix,'.bed'),nthreads=4L,companion=NULL)
  selected$provenance$synthetic_annotations<-TRUE
  selected$provenance$synthetic_metadata<-manifest
  selected$provenance$qc<-list(maf_cutoff=.01,missingness_max=.05,hwe_filter=FALSE,
    summary_samples='whole supplied cohort; no phenotypes used',
    original_markers=manifest$markers,selected_markers=length(keep),
    boundary_rule='gfilter excludes MAF <= .01; no exact-boundary markers in these cohorts')
  stopifnot(identical(unlist(selected$rsids,use.names=FALSE),keep),
    identical(selected$ids,Glist$ids),selected$n==manifest$individuals,
    selected$m==length(keep))
  gbase::validate_Glist(selected)
  saveRDS(Glist,file.path(directory,'source-Glist.rds'))
  saveRDS(selected,file.path(directory,'qc-Glist.rds'))
  counts<-data.frame(dataset=manifest$dataset,individuals=selected$n,
    available_markers=manifest$markers,qc_retained_markers=selected$m,
    maf_excluded=sum(audit$exclude_maf),missingness_excluded=sum(audit$exclude_missing),
    hwe_filter_applied=FALSE,hwe_p_below_1e12=sum(audit$hwe_p<1e-12),
    mean_missing_rate=mean(audit$missing_rate),
    synthetic_annotations=TRUE,dosage_roundtrip_equal=TRUE)
  summaries[[case]]<-counts
  write.csv(counts,file.path(directory,'qc-summary.csv'),row.names=FALSE)
  cat('Prepared QC Glist:',case,selected$n,'individuals;',selected$m,'of',manifest$markers,'markers\n')
  rm(Glist,selected,audit);gc()
}
write.csv(do.call(rbind,summaries),file.path(destination,'qc-summary.csv'),row.names=FALSE)
