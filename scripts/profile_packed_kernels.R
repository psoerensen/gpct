# Kernel replays against the installed binary. No fitting, RNG or variance updates.
env_root <- Sys.getenv('GPCT_ENV_DIR');stopifnot(nzchar(env_root))
library(Rcpp);library(gbase);library(gbayes)
stopifnot(all(Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))=='1'))
root <- file.path(Sys.getenv('USERPROFILE'),'gpct-results','20261121-mcmc-learning-check')
paired <- identical(Sys.getenv('GPCT_KERNEL_PROFILE_MODE'),'paired')
test_cache <- identical(Sys.getenv('GPCT_PROFILE_CACHE'),'1')
destination <- file.path(root,'performance-audit',Sys.getenv('GPCT_KERNEL_PROFILE_NAME','packed-kernels-avx2'))
dir.create(destination,recursive=TRUE,showWarnings=FALSE)
if(file.exists(file.path(destination,'kernel-timings.csv'))) stop('Preserve the existing kernel profile.')
cache <- file.path(env_root,'qualification','packed-kernel-profile','cache')
dir.create(cache,recursive=TRUE,showWarnings=FALSE)
toolchain <- 'C:/rtools44/x86_64-w64-mingw32.static.posix/bin'
avx_source <- file.path(env_root,'sources/gbits/src/simd_avx2.cpp')
avx_object <- file.path(cache,'existing-gbits-simd-avx2.o')
code <- system2(file.path(toolchain,'g++.exe'),c('-std=gnu++17','-O2','-mavx2',
  paste0('-B',toolchain,'/'),'-c',shQuote(avx_source),'-o',shQuote(avx_object)))
stopifnot(code==0L)
Sys.setenv(PATH=paste(toolchain,'C:/rtools44/usr/bin',Sys.getenv('PATH'),sep=';'),
  BINPREF=paste0(toolchain,'/'),RTOOLS44_HOME='C:/rtools44',
  PKG_CPPFLAGS=paste0('-I"',env_root,'/sources/gbayes/include" -I"',env_root,
    '/library/gbase/include" -DGBAYES_STATIC_DEFINE -DGBITS_STATIC_DEFINE -DGMAT_STATIC_DEFINE -DGSOLVE_STATIC_DEFINE'),
  PKG_LIBS=paste0('"',avx_object,'" "',env_root,'/library/gbayes/libs/x64/gbayes.dll" "',env_root,'/R/bin/x64/Rblas.dll"'))
sourceCpp('scripts/profile_packed_kernels.cpp',cacheDir=cache,verbose=FALSE)
capabilities <- packed_probe_capabilities();stopifnot(capabilities$cpu_os_avx2_supported)
write.csv(as.data.frame(capabilities),file.path(destination,'simd-capabilities.csv'),row.names=FALSE)
print(capabilities)
loaded <- getLoadedDLLs()[['gbayes']][['path']]
stopifnot(normalizePath(loaded)==normalizePath(file.path(env_root,'library/gbayes/libs/x64/gbayes.dll')))

# Missing calls, a partial packed word, and nontrivial row/marker selections.
physical_n <- 19L;physical_p <- 9L
raw <- matrix(rep(0:2,length.out=physical_n*physical_p),physical_n,physical_p)
raw[cbind(c(2,7,18),c(2,4,8))] <- NA
bed <- file.path(destination,'selection-missing-tail-fixture.bed')
bytes <- as.raw(c(108,27,1))
for(j in seq_len(physical_p)) for(first in seq(1,physical_n,by=4)) {
  index <- first:min(first+3,physical_n)
  code <- c(3L,2L,0L)[raw[index,j]+1L];code[is.na(code)] <- 1L
  bytes <- c(bytes,as.raw(sum(code*4^(seq_along(code)-1L))))
}
writeBin(bytes,bed)
rows <- c(19,1,17,3,15,5,13,7,11,9,2,4,6,8,10,12,18)
columns <- c(9,2,5,1,8,3,4,7,6)
frequency <- colMeans(raw[rows,columns],na.rm=TRUE)/2
Z <- sweep(sweep(raw[rows,columns],2,2*frequency,'-'),2,sqrt(2*frequency*(1-frequency)),'/')
Z[is.na(Z)] <- 0
y <- sin(seq_along(rows));y <- y-mean(y)
effects <- seq_along(columns)*.001;delta <- effects*.05;delta[c(TRUE,FALSE)] <- 0
base <- as.numeric(y-Z%*%effects)
fixture <- packed_probe_create(list(physical_n=physical_n,physical_p=physical_p,bed=bed,
  samples=rows-1,markers=columns-1,marker_ids=paste0('fixture_',columns),phenotype=y,
  frequency=frequency,residual=base,effects=effects,delta=delta,order=c(4,1,8,2,6,3,0,7,5)))
expected <- numeric(length(columns));working <- base
for(j in c(4,1,8,2,6,3,0,7,5)+1L) {
  expected[j] <- sum(Z[,j]*working)+sum(Z[,j]^2)*effects[j]
  working <- working-Z[,j]*delta[j]
}
checks <- list()
stopifnot(packed_probe_enable_cache(fixture)$allocated)
for(kernel in c('current','decode1_blas','decode64_blas','decode16_avx2','decode64_avx2','decode128_avx2','decode256_avx2','cached_blas')) {
  result <- packed_probe_run(fixture,kernel,'joint',1L)
  stopifnot(max(abs(result$scores-expected))<1e-11,max(abs(result$residual-working))<1e-11)
  checks[[kernel]] <- data.frame(dataset='selection_missing_tail_fixture',kernel,
    max_score_error=max(abs(result$scores-expected)),max_residual_error=max(abs(result$residual-working)))
}
write.csv(do.call(rbind,checks),file.path(destination,'fixture-validation.csv'),row.names=FALSE)
cat('Missing/selection/tail fixture passed for all kernels.\n');flush.console()

timings <- validation <- cache_records <- list()
models <- if(identical(Sys.getenv('GPCT_PROFILE_BOTH_MODELS'),'1')) c('bayesC_mcmc','bayesR_mcmc') else 'bayesC_mcmc'
for(model in models) for(case in c('maize','cattle')) {
  fit <- readRDS(file.path(root,model,case,'fold1-fit.rds'))
  resources <- fit$data$resources;state <- fit$final$states[[1]]
  stopifnot(length(resources$bedfiles)==1L,
    identical(sort(as.numeric(state$marker_order)),seq_along(fit$data$markers)-1))
  panel_dir <- file.path(Sys.getenv('USERPROFILE'),'gpct-data','glist/20261121-maf001-miss005',case)
  input <- readRDS(file.path(panel_dir,'phenotype-only.rds'))
  trait <- fit$data$traits;observed <- input$Y[,trait]
  observed[is.na(observed)] <- mean(observed,na.rm=TRUE)
  phenotype <- observed[match(fit$data$samples,input$ids)]-as.numeric(fit$data$intercept)
  probe <- packed_probe_create(list(physical_n=resources$physicalSampleCount,
    physical_p=resources$physicalMarkerCounts[[1]],bed=resources$bedfiles[[1]],
    samples=resources$sampleIndices,markers=resources$markerIndices[[1]],
    marker_ids=fit$data$markers,phenotype=phenotype,frequency=fit$data$coding$allele_frequency,
    residual=state$working_residual,effects=state$effects,delta=.01*state$effects,order=state$marker_order))
  cache_ok <- FALSE
  if(test_cache) {
    allocation <- packed_probe_enable_cache(probe)
    cache_ok <- allocation$allocated
    cache_records[[length(cache_records)+1L]] <- data.frame(dataset=case,model,as.data.frame(allocation))
  }
  if(paired) {
    reference <- packed_probe_run(probe,'current','joint',1L)
    for(trial in 1:7) {
      candidates <- c('decode64_blas','decode64_avx2',if(cache_ok) 'cached_blas')
      candidates <- candidates[((seq_along(candidates)+trial-2L)%%length(candidates))+1L]
      for(position in seq_len(length(candidates)+2L)) {
        kernel <- c('current',candidates,'current')[position]
        result <- packed_probe_run(probe,kernel,'joint',10L)
        score_error <- max(abs(result$scores-reference$scores))
        residual_error <- max(abs(result$residual-reference$residual))
        stopifnot(score_error<1e-9+1e-11*max(abs(reference$scores)),residual_error<1e-10)
        validation[[length(validation)+1L]] <- data.frame(dataset=case,model,phase='joint',kernel,trial,
          max_score_error=score_error,max_residual_error=residual_error)
        timings[[length(timings)+1L]] <- data.frame(dataset=case,model,phase='joint',kernel,trial,position,
          seconds_per_pass=result$seconds,samples=result$samples,markers=result$markers,
          cpu_seconds_per_pass=result$cpu_seconds,cycles_per_pass=result$cycles,
          active_updates=result$updates,packed_bytes=result$packed_bytes,
          scratch_bytes=result$scratch_bytes,candidate_view_seconds=result$candidate_view_seconds,
          candidate_view_packed_bytes=result$candidate_view_packed_bytes,
          reordered_packed_view=result$reordered_packed_view,threads=1L)
      }
    }
  } else for(phase in c('score','update','joint','decode')) {
    kernels <- if(phase=='decode') c('decode1_blas','decode64_blas') else
      if(phase=='update') c('current','decode1_blas','decode1_avx2') else
        c('current','decode1_blas','decode64_blas','decode16_avx2','decode64_avx2','decode128_avx2','decode256_avx2')
    reference <- if(phase!='decode') packed_probe_run(probe,'current',phase,1L) else NULL
    for(trial in 1:3) for(kernel in kernels[((seq_along(kernels)+trial-2L)%%length(kernels))+1L]) {
      result <- packed_probe_run(probe,kernel,phase,5L)
      if(!is.null(reference)) {
        score_error <- max(abs(result$scores-reference$scores))
        residual_error <- max(abs(result$residual-reference$residual))
        stopifnot(score_error<1e-9+1e-11*max(abs(reference$scores)),residual_error<1e-10)
        validation[[length(validation)+1L]] <- data.frame(dataset=case,model,phase,kernel,trial,
          max_score_error=score_error,max_residual_error=residual_error)
      }
      timings[[length(timings)+1L]] <- data.frame(dataset=case,model,phase,kernel,trial,
        seconds_per_pass=result$seconds,samples=result$samples,markers=result$markers,
        active_updates=result$updates,packed_bytes=result$packed_bytes,
        scratch_bytes=result$scratch_bytes,threads=1L)
    }
  }
  cat('Finished kernel replays:',model,case,'\n');flush.console()
  rm(probe,fit);gc()
}
timings <- do.call(rbind,timings)
write.csv(timings,file.path(destination,'kernel-timings.csv'),row.names=FALSE)
write.csv(do.call(rbind,validation),file.path(destination,'kernel-validation.csv'),row.names=FALSE)
if(length(cache_records)) write.csv(do.call(rbind,cache_records),file.path(destination,'cache-memory.csv'),row.names=FALSE)
summary <- aggregate(seconds_per_pass~dataset+model+phase+kernel,data=timings,FUN=median)
write.csv(summary,file.path(destination,'median-kernel-timings.csv'),row.names=FALSE)
saveRDS(list(binary=loaded,sha256=digest::digest(file=loaded,algo='sha256'),
  harness_sha256=digest::digest(file='scripts/profile_packed_kernels.cpp',algo='sha256'),
  unchanged_existing_simd_source_sha256=digest::digest(file=avx_source,algo='sha256'),
  script_sha256=digest::digest(file='scripts/profile_packed_kernels.R',algo='sha256'),
  affinity_mask=Sys.getenv('GPCT_PROFILE_AFFINITY_MASK','not pinned'),paired=paired,
  semantics='Predetermined event replays; no stochastic fitting or variance learning was run.'),
  file.path(destination,'provenance.rds'))
print(summary,row.names=FALSE)
if(paired) {
  ratios <- do.call(rbind,lapply(split(timings,interaction(timings$dataset,timings$model,timings$trial)),function(rows) {
    baseline <- mean(rows$seconds_per_pass[rows$kernel=='current'])
    cpu_baseline <- mean(rows$cpu_seconds_per_pass[rows$kernel=='current'])
    cycle_baseline <- mean(rows$cycles_per_pass[rows$kernel=='current'])
    candidate <- rows[rows$kernel!='current',]
    data.frame(dataset=candidate$dataset,model=candidate$model,trial=candidate$trial,kernel=candidate$kernel,
      baseline_seconds=baseline,candidate_seconds=candidate$seconds_per_pass,
      speed_ratio=baseline/candidate$seconds_per_pass,
      cpu_speed_ratio=cpu_baseline/candidate$cpu_seconds_per_pass,
      cycle_speed_ratio=cycle_baseline/candidate$cycles_per_pass)
  }))
  write.csv(ratios,file.path(destination,'paired-speed-ratios.csv'),row.names=FALSE)
  print(aggregate(speed_ratio~dataset+model+kernel,ratios,median),row.names=FALSE)
}
