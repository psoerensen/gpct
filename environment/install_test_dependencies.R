# Focused package tests use a separate tooling library, not the fitting runtime.
root <- Sys.getenv('GPCT_ENV_DIR');stopifnot(nzchar(root))
library <- file.path(root,'comparison-library')
.libPaths(c(library,.libPaths()))
if(!requireNamespace('testthat',quietly=TRUE))
  install.packages('testthat',lib=library,repos='https://cloud.r-project.org',
    type='win.binary',dependencies=NA)
stopifnot(requireNamespace('testthat',quietly=TRUE))
installed <- installed.packages(lib.loc=library)
write.csv(installed[,c('Package','Version','Built'),drop=FALSE],
  file.path(root,'qualification/cache-integration/test-tooling-versions.csv'),row.names=FALSE)
cat('Focused test tooling ready; fitting-library packages were not changed.\n')
