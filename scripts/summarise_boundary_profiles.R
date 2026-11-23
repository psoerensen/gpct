# Re-read saved profiles only; this script never runs a fit.
root <- file.path(Sys.getenv('USERPROFILE'),'gpct-results',
  '20261121-mcmc-learning-check','performance-audit')
timing <- read.csv(file.path(root,'boundary-timing.csv'))
timing <- timing[,c('package','dataset','transitions','chains','threads','elapsed_seconds','profiled_seconds')]
timing$native_entry_self_seconds <- timing$native_entry_self_percent <- NA_real_
for(i in seq_len(nrow(timing))) {
  profile <- summaryRprof(file.path(root,paste0(timing$package[i],'-boundary.Rprof')))
  labels <- gsub('"','',rownames(profile$by.self),fixed=TRUE)
  selected <- startsWith(labels,'cpp_')
  if(any(selected)) {
    timing$native_entry_self_seconds[i] <- sum(profile$by.self[selected,'self.time'])
    timing$native_entry_self_percent[i] <- 100*timing$native_entry_self_seconds[i]/profile$sampling.time
  }
}
write.csv(timing,file.path(root,'boundary-timing.csv'),row.names=FALSE)
print(timing,row.names=FALSE)
cat('NA for BGLR: Rprof cannot split its mixed R/C loop into native and R self time.\n')
