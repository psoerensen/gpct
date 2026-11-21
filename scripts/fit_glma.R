# Thin calls to the existing private native joint prediction workflows.
# No chromosome map is required or invented; these are full-marker predictions.
fit_glma <- function(y,bed,n,p,training,method,threads=4L) {
  glma::glma_full_marker_prediction(bed,n,p,training,y,
    method=if(method=='glma_infinitesimal') 'infinitesimal' else 'prior_selected',
    threads=threads,block_size=256L,memory_limit_bytes=1024^3)
}
