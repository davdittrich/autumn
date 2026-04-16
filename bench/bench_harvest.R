# bench/bench_harvest.R
# Benchmark: autumn harvest() and weighted_pct() performance at n=1.8M
#
# Run with: Rscript bench/bench_harvest.R
#
# Results printed to console; copy paste them to compare against post-optimization run.

suppressPackageStartupMessages({
  library(autumn)
  library(bench)
})

set.seed(2026)
N <- 1800000L

# High-cardinality sparse variable: 50 DMA codes with power-law frequency.
# This represents the "many categories at the margins" worst case.
n_dmas     <- 50L
dma_codes  <- paste0("DMA_", sprintf("%03d", seq_len(n_dmas)))
dma_probs  <- (1 / seq_len(n_dmas))^1.5  # power-law: most codes very rare
dma_probs  <- dma_probs / sum(dma_probs)
# Targets: uniform 1/50 per DMA (forces large adjustments for rare codes)
dma_target <- setNames(rep(1 / n_dmas, n_dmas), dma_codes)

# Synthetic data: 4 standard variables + 1 high-cardinality sparse variable
synth_data <- data.frame(
  gender       = sample(c("Male", "Female", "Nonbinary"), N, replace = TRUE,
                         prob = c(0.48, 0.48, 0.04)),
  education    = sample(c("HS or less", "Some college", "Bachelor", "Postgrad"),
                         N, replace = TRUE),
  race         = sample(c("White", "Black", "Hispanic", "Asian", "Other"),
                         N, replace = TRUE, prob = c(0.60, 0.13, 0.18, 0.06, 0.03)),
  age_group    = sample(c("18-29", "30-44", "45-64", "65+"), N, replace = TRUE),
  dma          = sample(dma_codes, N, replace = TRUE, prob = dma_probs),
  stringsAsFactors = FALSE
)

synth_target <- list(
  gender    = c("Male" = 0.48, "Female" = 0.48, "Nonbinary" = 0.04),
  education = c("HS or less" = 0.36, "Some college" = 0.30,
                "Bachelor" = 0.22, "Postgrad" = 0.12),
  race      = c("White" = 0.60, "Black" = 0.13, "Hispanic" = 0.18,
                "Asian" = 0.06, "Other" = 0.03),
  age_group = c("18-29" = 0.22, "30-44" = 0.26, "45-64" = 0.30, "65+" = 0.22),
  dma       = dma_target
)

w <- rep(1.0, N)

cat("=== BASELINE BENCHMARK ===\n")
cat("n =", N, "| vars =", length(synth_target), "\n\n")

# --- weighted_pct micro-benchmark (inner-loop function) ---
# Use DMA (50 categories, power-law distribution) — the high-cardinality worst case.
cat("--- weighted_pct: 3-category balanced (gender) ---\n")
bm_pct_3 <- bench::mark(
  weighted_pct(synth_data$gender, w),
  iterations = 20L, check = FALSE
)
print(bm_pct_3[, c("expression", "min", "median", "mem_alloc", "n_itr")])

cat("\n--- weighted_pct: 50-category sparse (DMA, power-law) ---\n")
bm_pct <- bench::mark(
  weighted_pct(synth_data$dma, w),
  iterations = 20L,
  check      = FALSE
)
print(bm_pct[, c("expression", "min", "median", "mem_alloc", "n_itr")])

# --- full harvest() end-to-end ---
cat("\n--- harvest() end-to-end (5 vars, n=1.8M) ---\n")
bm_harvest <- bench::mark(
  harvest(synth_data, synth_target, attach_weights = FALSE),
  iterations = 3L,
  check      = FALSE
)
print(bm_harvest[, c("expression", "min", "median", "mem_alloc", "n_itr")])

cat("\n=== Record these numbers before proceeding to optimization tasks. ===\n")
