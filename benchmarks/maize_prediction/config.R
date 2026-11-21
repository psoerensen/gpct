config <- list(case = "maize", dataset_id = "gpbench_maize",
  species_folder = "Maize", n = 1458L, p = 75304L,
  traits = c("DTT", "PH", "EW"), trait = "DTT", marker_count = 512L,
  methods = c("rrblup", "gbayes_gaussian", "gbayes_elastic_net"),
  fold_seed = 4401L, method_seed = 4401L,
  gaussian_h2 = 0.5, lambda = 0.1, alpha = 0.5, nit = 2000L,
  tolerance = 1e-8, memory_limit = 512 * 1024^2)
