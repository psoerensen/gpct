config <- list(case = "cattle", dataset_id = "gpbench_cattle",
  species_folder = "Cattle", n = 5024L, p = 42551L,
  traits = c("mkg", "fpro", "scs"), trait = "mkg", marker_count = 42551L,
  methods = c("gblup_reml","gbayes_gaussian","gbayes_mixture"),
  gbayes = list(h2=.5,inclusion_probability=.1,maximum_sweeps=100L,tolerance=1e-6,
    memory_limit=1024^3,chunk_size=128L,gram_cache_limit=256*1024^2),
  folds = 10L, fold_seed = 42L, tolerance = 1e-4,
  gpbench_revision = "2c92073fb8c67e6d6c5c1cda8bd410f191c7ef02")
