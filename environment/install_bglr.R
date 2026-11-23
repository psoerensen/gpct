# Optional external comparator, isolated from the gsuite runtime library.
root <- Sys.getenv('GPCT_ENV_DIR')
stopifnot(nzchar(root))
library <- file.path(root,'comparison-library')
cache <- file.path(root,'downloads','bglr-comparator')
dir.create(library,recursive=TRUE,showWarnings=FALSE)
dir.create(cache,recursive=TRUE,showWarnings=FALSE)
repository <- 'https://cloud.r-project.org'
available <- available.packages(repos=repository,type='win.binary')
packages <- c('truncnorm','BGLR')
stopifnot(all(packages %in% rownames(available)))
records <- list()
for(package in packages) {
  version <- available[package,'Version']
  url <- paste0(available[package,'Repository'],'/',package,'_',version,'.zip')
  destination <- file.path(cache,basename(url))
  if(!file.exists(destination)) download.file(url,destination,mode='wb',quiet=TRUE)
  .libPaths(c(library,.libPaths()))
  if(!dir.exists(file.path(library,package)))
    install.packages(destination,lib=library,repos=NULL,type='win.binary')
  stopifnot(packageVersion(package,lib.loc=library)==package_version(version))
  records[[package]] <- data.frame(package,version,url,
    archive_sha256=digest::digest(file=destination,algo='sha256'))
}
write.csv(do.call(rbind,records),file.path(cache,'installed-binaries.csv'),row.names=FALSE)
.libPaths(c(library,.libPaths()))
if(!requireNamespace('posterior',quietly=TRUE))
  install.packages('posterior',lib=library,repos=repository,type='win.binary',dependencies=NA)
stopifnot(requireNamespace('posterior',quietly=TRUE))
installed <- installed.packages(lib.loc=library)
write.csv(installed[,c('Package','Version','Built'),drop=FALSE],
  file.path(cache,'comparison-library-versions.csv'),row.names=FALSE)
cat('BGLR comparator installed in',library,'without changing gsuite packages.\n')
