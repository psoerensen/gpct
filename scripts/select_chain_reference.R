# Reuse only clean two-chain runs made with the exact current native binary.
source('scripts/paths.R')
args<-commandArgs(TRUE);stopifnot(length(args)==2L)
method<-args[1];case<-args[2]
expected<-digest::digest(file=file.path(Sys.getenv('GPCT_GBAYES_LIBRARY'),'gbayes/libs/x64/gbayes.dll'),algo='sha256')
old<-if(method%in%c('bayesC_mcmc','bayesR_mcmc'))'20261121-cache-comparison'else'20261121-alphabet-check-1t'
choice<-list(ready=FALSE,path='',reason='No clean matched-binary reference; run two sequential chains')
for(batch in c('20261122-chain-comparison-1t',old)) {
 path<-file.path(output_dir(),batch,method,case)
 required<-file.path(path,c('fold1-fit.rds','fold1-source-provenance.rds','fold-results.csv','process-resources.json'))
 if(!all(file.exists(required)))next
 process<-jsonlite::fromJSON(required[4]);if(process$exit_code!=0L)next
 provenance<-readRDS(required[2])$installed_source_manifests
 source<-Filter(function(x)x$package=='gbayes',provenance)
 if(length(source)!=1L||!identical(tolower(source[[1]]$binary_sha256),tolower(expected)))next
 fit<-readRDS(required[1]);plan<-fit$input$execution
 if(plan$nchains!=2L||plan$ncores!=1L||plan$nburn!=500L||plan$nit!=1000L)next
 choice<-list(ready=TRUE,path=path,reason='Clean matched-binary two-chain qualification run',binary_sha256=expected)
 break
}
dest<-file.path(output_dir(),'20261122-chain-comparison-summary/references')
dir.create(dest,recursive=TRUE,showWarnings=FALSE)
jsonlite::write_json(choice,file.path(dest,paste0(method,'-',case,'.json')),auto_unbox=TRUE,pretty=TRUE)
