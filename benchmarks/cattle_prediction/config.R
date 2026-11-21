config <- list(case = "cattle", dataset_id = "gpbench_cattle",
  species_folder = "Cattle", n = 5024L, p = 42551L,
  traits = c("mkg", "fpro", "scs"), trait = "mkg", marker_count = 512L,
  methods = c("rrblup", "gbayes_gaussian", "gbayes_elastic_net"),
  fold_seed = 4401L, method_seed = 4401L,
  gaussian_h2 = 0.5, lambda = 0.1, alpha = 0.5, nit = 2000L,
  tolerance = 1e-8, memory_limit = 512 * 1024^2)
