# GPBench regression metrics: test-fold mean is the R2 reference.
metrics <- function(observed, predicted) {
  stopifnot(length(observed)==length(predicted),length(observed)>=2L,
    all(is.finite(observed)),all(is.finite(predicted)))
  error <- observed-predicted; denominator <- sum((observed-mean(observed))^2)
  variable <- sd(predicted)>0
  calibration <- if(variable) coef(lm(observed~predicted)) else c(NA_real_,NA_real_)
  c(predictive_ability=if(variable&&sd(observed)>0) cor(observed,predicted) else NA_real_,
    rmse=sqrt(mean(error^2)),mae=mean(abs(error)),mse=mean(error^2),predictive_r_squared=if(denominator>0)
      1-sum(error^2)/denominator else if(sum(error^2)==0) 1 else 0,
    calibration_intercept=unname(calibration[1]),calibration_slope=unname(calibration[2]))
}
saved_folds <- function(ids,path) {
  if(!file.exists(path)) {
    python <- Sys.getenv('GPCT_PYTHON',Sys.getenv('RETICULATE_PYTHON'))
    if(!nzchar(python)) stop('Set GPCT_PYTHON to the pinned Python environment.')
    if(system2(python,c('scripts/gpbench_folds.py',length(ids),shQuote(path)))!=0L)
      stop('GPBench fold generation failed')
  }
  folds <- read.csv(path,stringsAsFactors=FALSE)
  stopifnot(identical(folds$source_row,seq_along(ids)),
    identical(sort(unique(folds$fold)),1:10),
    max(tabulate(folds$fold))-min(tabulate(folds$fold))<=1L)
  metadata <- jsonlite::fromJSON(sub('\\.csv$','.json',path))
  stopifnot(metadata$n_splits==10L,metadata$random_state==42L,isTRUE(metadata$shuffle),
    metadata$sklearn=='1.6.1',metadata$numpy=='1.26.4',
    metadata$sha256==digest::digest(file=path,algo='sha256'))
  data.frame(id=ids,source_row=folds$source_row,fold=folds$fold)
}
gpbench_response <- function(y) {
  stopifnot(is.numeric(y),any(is.finite(y)),!any(is.infinite(y)))
  imputed <- is.na(y); y[imputed] <- mean(y,na.rm=TRUE)
  list(y=y,imputed=imputed)
}
