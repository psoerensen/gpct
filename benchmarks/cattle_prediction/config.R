config <- list(case = "cattle", dataset_id = "gpbench_cattle",
  species_folder = "Cattle", n = 5024L, p = 42551L,
  traits = c("mkg", "fpro", "scs"), trait = "mkg", marker_count = 42551L,
  methods = c("gblup_reml"),
  folds = 10L, fold_seed = 42L, tolerance = 1e-4,
  gpbench_revision = "2c92073fb8c67e6d6c5c1cda8bd410f191c7ef02")
