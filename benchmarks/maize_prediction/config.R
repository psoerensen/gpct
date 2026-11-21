config <- list(case = "maize", dataset_id = "gpbench_maize",
  species_folder = "Maize", n = 1458L, p = 75304L,
  traits = c("DTT", "PH", "EW"), trait = "DTT", marker_count = 75304L,
  methods = c("gblup_reml","gbayes_gaussian","gbayes_mixture","glma_infinitesimal","glma_prior_selected"),
  gbayes = list(h2=.5,inclusion_probability=.1,maximum_sweeps=100L,tolerance=1e-6,
    memory_limit=1024^3,chunk_size=128L,gram_cache_limit=256*1024^2),
  folds = 10L, fold_seed = 42L, tolerance = 1e-4,
  gpbench_revision = "2c92073fb8c67e6d6c5c1cda8bd410f191c7ef02")
