# tools/benchmark_readme.R
# Regenerates benchmark objects for README.Rmd.
# Output: tools/benchmark_results.rds

suppressPackageStartupMessages({
  library(autumn)
  library(bench)
  library(anesrake)
})

# ------------------------------------------------------------------
# Prepare anesrake input (requires integer case IDs and factor variables)
# ------------------------------------------------------------------
df_anesrake        <- respondent_data
df_anesrake$caseid <- seq_len(nrow(df_anesrake))
# anesrake requires factor variables with levels matching target names exactly
for (nm in names(ns_target)) {
  df_anesrake[[nm]] <- factor(df_anesrake[[nm]], levels = names(ns_target[[nm]]))
}

# ------------------------------------------------------------------
# Small benchmark: 6,691 obs, 10 variables
# ------------------------------------------------------------------
bm_small <- suppressWarnings(bench::mark(
  "autumn (unbounded)"   = harvest(respondent_data, ns_target, max_weight = Inf),
  "autumn (cap = 5)"     = harvest(respondent_data, ns_target),
  "anesrake (unbounded)" = anesrake::anesrake(ns_target, df_anesrake, df_anesrake$caseid),
  "anesrake (cap = 5)"   = anesrake::anesrake(ns_target, df_anesrake, df_anesrake$caseid,
                                               cap = 5),
  iterations = 20,
  check      = FALSE
))
bm_small$expression <- c("autumn (unbounded)", "autumn (cap = 5)",
                          "anesrake (unbounded)", "anesrake (cap = 5)")

# ------------------------------------------------------------------
# Medium benchmark: 6,691 obs, 17 variables (7 synthetic binary vars added)
# survey::rake does not converge on 17-variable rake; excluded.
# Uses local copies so package dataset is not mutated.
# ------------------------------------------------------------------
set.seed(42)
n          <- nrow(respondent_data)
rdata_17   <- respondent_data
anesrake_17 <- df_anesrake
target_17   <- ns_target
for (i in seq_len(7)) {
  vname            <- paste0("aux_", i)
  vals             <- sample(c("A", "B"), n, replace = TRUE, prob = c(0.4, 0.6))
  rdata_17[[vname]]        <- vals
  anesrake_17[[vname]]     <- factor(vals, levels = c("A", "B"))
  target_17[[vname]]       <- c(A = 0.4, B = 0.6)
}

bm_medium <- suppressWarnings(bench::mark(
  "autumn (unbounded)"   = harvest(rdata_17, target_17, max_weight = Inf),
  "autumn (cap = 5)"     = harvest(rdata_17, target_17),
  "anesrake (unbounded)" = anesrake::anesrake(target_17, anesrake_17, anesrake_17$caseid),
  "anesrake (cap = 5)"   = anesrake::anesrake(target_17, anesrake_17, anesrake_17$caseid,
                                               cap = 5),
  iterations = 10,
  check      = FALSE
))
bm_medium$expression <- c("autumn (unbounded)", "autumn (cap = 5)",
                           "anesrake (unbounded)", "anesrake (cap = 5)")

# ------------------------------------------------------------------
# Methods benchmark: all 6 autumn parameter combinations
# Uses 10-variable problem (respondent_data / ns_target).
# ------------------------------------------------------------------
bm_methods <- suppressWarnings(bench::mark(
  rake_bounded           = harvest(respondent_data, ns_target),
  rake_bounded_squarem   = harvest(respondent_data, ns_target, accelerate = TRUE),
  rake_unbounded         = harvest(respondent_data, ns_target, max_weight = Inf),
  rake_unbounded_squarem = harvest(respondent_data, ns_target,
                                   max_weight = Inf, accelerate = TRUE),
  calibrate_bounded      = harvest(respondent_data, ns_target,
                                   method = "calibrate", max_weight = 5,
                                   auto_collapse = TRUE),
  calibrate_unbounded    = harvest(respondent_data, ns_target,
                                   method = "calibrate", max_weight = Inf),
  iterations = 20,
  check      = FALSE
))
bm_methods$expression <- c(
  "rake_bounded", "rake_bounded_squarem",
  "rake_unbounded", "rake_unbounded_squarem",
  "calibrate_bounded", "calibrate_unbounded"
)

# ------------------------------------------------------------------
# Save results
# ------------------------------------------------------------------
dir.create("tools", showWarnings = FALSE)
saveRDS(
  list(small = bm_small, medium = bm_medium, methods = bm_methods),
  file = "tools/benchmark_results.rds"
)

message("Benchmarks complete. Results saved to tools/benchmark_results.rds")
print(bm_small[,   c("expression", "median", "mem_alloc")])
print(bm_medium[,  c("expression", "median", "mem_alloc")])
print(bm_methods[, c("expression", "median", "mem_alloc", "n_itr")])
