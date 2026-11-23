# Tests belong to their private source owner; this file only selects the runtime.
root<-Sys.getenv('GPCT_ENV_DIR');stopifnot(nzchar(root))
.libPaths(c(file.path(root,'cache-library'),file.path(root,'comparison-library'),.libPaths()))
library(testthat);library(gbayes)
stopifnot(normalizePath(find.package('gbayes'))==normalizePath(file.path(root,'cache-library/gbayes')))
owner<-file.path(root,'sources/gsuite/packages/gbayes/tests/testthat')
source(file.path(owner,'helper-summary.R'))
for(name in c('test-decoded-cache.R','test-alphabet-glist.R','test-individual-interface.R','test-individual-continuation.R','test-bed-defaults.R')) {
 path<-file.path(owner,name)
 if(!file.exists(path))stop('Missing required focused test: ',path)
 if(name=='test-individual-continuation.R'&&is.null(gbayes:::.bayes_checkpoint_runtime())) {
   cat('NOT QUALIFIED: high-level exact continuation requires the bundled shared-DLL closure; this local package uses a static closure. No fingerprint bypass.\n')
   next
 }
 testthat::test_file(path,package='gbayes',reporter='summary',stop_on_failure=TRUE)
}
