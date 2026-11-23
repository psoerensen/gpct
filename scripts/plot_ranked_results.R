# Ranked summaries from the reviewed, aggregate-only comparison CSVs.
# Rscript scripts/plot_ranked_results.R [input-directory] [output-directory]
plot_ranked_results <- function(input, output = input) {
  labels <- c(
    old_marker_gaussian = 'Gaussian PCG (fixed h2=0.5)',
    old_bayesN_mcmc = 'BayesN (4 chains)',
    old_bayesA_mcmc = 'BayesA (4 chains)',
    old_bayesB_mcmc = 'BayesB (4 chains)',
    old_bayesC_mcmc = 'BayesC (4 chains)',
    old_bayesR_mcmc = 'BayesR (4 chains)',
    new_Gaussian = 'Gaussian PCG (training variance)',
    new_D = 'D-weighted PCG (training variance)',
    new_B = 'Adaptive B (initial training variance)',
    new_BayesA = 'BayesA (2 chains, 1 worker)',
    new_GLMA_Gaussian = 'GLMA Gaussian / infinitesimal',
    new_GLMA_prior = 'GLMA prior-selected'
  )
  for (case in c('cattle', 'maize')) {
    d <- read.csv(file.path(input, case, 'combined-summary.csv'))
    stopifnot(!anyDuplicated(d$method), all(d$folds == 10))
    d$display <- unname(labels[d$method])
    d$display[is.na(d$display)] <- d$label[is.na(d$display)]
    provisional <- grepl('provisional', d$status, ignore.case = TRUE)
    d$display[provisional] <- paste0(d$display[provisional], ' *')
    dir.create(file.path(output, case), showWarnings = FALSE, recursive = TRUE)
    svg(file.path(output, case, 'ranked-overview.svg'), width = 14, height = 6.8,
        bg = 'white', family = 'sans', pointsize = 14)
    par(mfrow = c(1, 2), mar = c(4.4, 13.5, 3.5, 2.8), oma = c(1, 0, 2.2, 0),
        fg = '#243444', col.axis = '#475569', col.lab = '#243444', las = 1)
    for (metric in c('PCC_mean', 'peak_process_MiB')) {
      x <- d[is.finite(d[[metric]]), ]
      # Accuracy requires every fold to be accepted; failed fits are not ranked.
      if (metric == 'PCC_mean') x <- x[!grepl('failed|pending', x$status, ignore.case = TRUE), ]
      x <- x[order(if (metric == 'PCC_mean') -x[[metric]] else x[[metric]], x$method), ]
      n <- nrow(x)
      values <- x[[metric]]
      spread <- max(diff(range(values)), if (metric == 'PCC_mean') .02 else 100)
      limits <- range(values) + c(-.12, .42) * spread
      if (metric != 'PCC_mean') limits[1] <- max(0, limits[1])
      plot(NA, xlim = limits, ylim = c(.4, n + .6), yaxt = 'n', ylab = '',
           xlab = if (metric == 'PCC_mean') 'Mean held-out correlation' else 'Peak process RAM (MiB)',
           main = if (metric == 'PCC_mean') 'A   Correlation: highest first' else 'B   Memory: lowest first',
           bty = 'n', cex.main = 1.05)
      y <- rev(seq_len(n))
      abline(h = y, col = '#edf1f5', lwd = 1)
      axis(2, at = y, labels = x$display, tick = FALSE, cex.axis = .82)
      color <- ifelse(x$method %in% c('new_D', 'new_Gaussian'), '#007f7b', '#41658b')
      points(values, y, pch = 19, cex = 1.15, col = color)
      text(values + .035 * spread, y,
           labels = if (metric == 'PCC_mean') sprintf('%.4f', values) else format(round(values), trim = TRUE, big.mark = ','),
           adj = 0, cex = .8, col = '#243444')
    }
    mtext(if (case == 'cattle') 'Cattle / mkg' else 'Maize / DTT', outer = TRUE,
          side = 3, line = .4, adj = 0, font = 2, cex = 1.2)
    mtext('* Provisional MCMC mixing diagnostics', outer = TRUE, side = 1,
          line = 0, adj = 0, cex = .8, col = '#475569')
    dev.off()
  }
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  input <- if (length(args)) args[1] else 'docs/assets/reports/training-variance'
  output <- if (length(args) > 1) args[2] else input
  plot_ranked_results(input, output)
}
