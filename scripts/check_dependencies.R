# Run from the repository root after activating the pinned environment.
source('environment/preflight.R')
Sys.setenv(RETICULATE_USE_MANAGED_VENV='no')
np <- reticulate::import('numpy',convert=FALSE)
sk <- reticulate::import('sklearn',convert=FALSE)
stopifnot(reticulate::py_to_r(np$`__version__`)=='1.26.4',
          reticulate::py_to_r(sk$`__version__`)=='1.6.1')
cat('Pinned R, native integration and Python dependencies passed.\n')
