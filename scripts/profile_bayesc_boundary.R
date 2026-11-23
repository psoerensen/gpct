# Short diagnostic runs: locate time across the R/native boundary, not accuracy fits.
source('scripts/evaluate.R')
env_root <- Sys.getenv('GPCT_ENV_DIR')
.libPaths(c(file.path(env_root,'comparison-library'),.libPaths()))
library(gbase);library(gbayes);library(BGLR)
stopifnot(all(Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))=='1'))
root <- file.path(Sys.getenv('USERPROFILE'),'gpct-results','20261121-mcmc-learning-check')
destination <- file.path(root,'performance-audit')
dir.create(destination,showWarnings=FALSE)
if(file.exists(file.path(destination,'boundary-timing.csv'))) stop('Preserve the existing profile.')
case <- 'maize';trait <- 'DTT'
panel_dir <- file.path(Sys.getenv('USERPROFILE'),'gpct-data','glist/20261121-maf001-miss005',case)
panel <- readRDS(file.path(panel_dir,'qc-Glist.rds'))
input <- readRDS(file.path(panel_dir,'phenotype-only.rds'))
reference <- readRDS(file.path(root,'bayesC_mcmc',case,'fold1-fit.rds'))
training <- readRDS(file.path(root,'glist-cache',case,'fold1.rds'))$Glist
train <- match(reference$data$samples,input$ids);test <- setdiff(seq_along(input$ids),train)
y <- gpbench_response(input$Y[,trait])$y
outcomes <- data.frame(id=input$ids[train],DTT=y[train])
bed <- BGLR::read_bed(panel$bedfiles,panel$bimfiles,panel$famfiles)
X <- matrix(c(2,1,NA_real_,0)[bed$x+1L],bed$n,bed$p);rm(bed);gc()
X <- X[,match(reference$data$markers,unlist(panel$rsids,use.names=FALSE)),drop=FALSE]
X <- sweep(sweep(X,2,reference$data$coding$centers,'-'),2,reference$data$coding$scales,'/')
y_masked <- y;y_masked[test] <- NA_real_
settings <- readRDS(file.path(root,'bglr_bayesC_masked',case,'settings.rds'))
measure <- function(package,expression) {
  path <- file.path(destination,paste0(package,'-boundary.Rprof'))
  Rprof(path,interval=.01)
  start <- proc.time()[['elapsed']]
  fit <- tryCatch(force(expression),finally=Rprof(NULL))
  elapsed <- proc.time()[['elapsed']]-start
  profile <- summaryRprof(path)
  self <- profile$by.self
  write.csv(data.frame(function_name=rownames(self),self,row.names=NULL),
    file.path(destination,paste0(package,'-profile-self.csv')),row.names=FALSE)
  # Rprof attributes .Call work to its R caller. Rcpp's leaf wrappers identify
  # that boundary for gbayes; the mixed R/C BGLR loop cannot be split this way.
  labels <- gsub('"','',rownames(self),fixed=TRUE)
  native <- which(startsWith(labels,'cpp_'))
  data.frame(package,dataset=case,transitions=100L,chains=1L,threads=1L,
    elapsed_seconds=elapsed,profiled_seconds=profile$sampling.time,
    native_entry_self_seconds=if(length(native)) sum(self[native,'self.time']) else NA_real_,
    native_entry_self_percent=if(length(native))
      100*sum(self[native,'self.time'])/profile$sampling.time else NA_real_)
}
native <- measure('gbayes',gbayes::bayes(Glist=training,data=outcomes,trait=trait,
  method='bayesC',algorithm='mcmc',ncores=1L,nchains=1L,nburn=20L,nit=80L,nthin=1L,
  updateB=TRUE,updateE=TRUE,seed=42002L))
chain_dir <- file.path(destination,'bglr-short-chain')
if(dir.exists(chain_dir)) stop('Preserve existing BGLR profile files.')
dir.create(chain_dir)
set.seed(42002L)
external <- measure('BGLR',BGLR::BGLR(y=y_masked,
  ETA=list(list(X=X,model='BayesC',probIn=settings$probIn,counts=settings$counts,
    df0=settings$effect_df,S0=settings$effect_S0)),
  df0=settings$residual_df,S0=settings$residual_S0,R2=.5,nIter=100L,burnIn=20L,
  thin=1L,saveAt=paste0(chain_dir,'/'),verbose=FALSE,rmExistingFiles=FALSE))
result <- rbind(native,external)
write.csv(result,file.path(destination,'boundary-timing.csv'),row.names=FALSE)
print(result,row.names=FALSE)
cat('R boundary sampling cannot attribute native time to individual C++ kernels.\n')
