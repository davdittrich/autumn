# Benchmark Results

## Environment
- Date: 2026-04-16
- R version: R version 4.5.3 (2026-03-11)
- n: 1,800,000 rows, 5 variables (gender, education, race, age_group, dma)
- dma: 50-category power-law distribution (worst case: extreme imbalance, uniform target)

## Results

| Function | Before (median) | After (median) | Speedup |
|---|---|---|---|
| `weighted_pct()` 3-cat gender | 68.4 ms | 58.6 ms | 1.17× |
| `weighted_pct()` 50-cat DMA (power-law) | 61.5 ms | 60.8 ms | ~1.00× (noise) |
| `harvest()` end-to-end (5 vars, 3 iterations) | 2.90 min | 2.96 min | ~1.00× (noise) |

## Optimizations Applied
- `rowsum()` replaces `split()+vapply(sum)` in `weighted_pct.R` (commits 3cefabf, f3f67eb)
- NA row index pre-caching in `rake.R` `pre_cache` (commits 729cdbc, 1fac938)

## Analysis

The expected 10–50× speedup did not materialize. Post-hoc diagnosis:

**Why `rowsum` underperformed the prediction:**
`rowsum()` and `split()+vapply(sum)` both require an O(n) scan of the group vector to find
group membership. For a character vector of 1.8M strings, this string-hashing cost dominates
the per-call runtime. The list allocation that `split()` adds (and `rowsum()` avoids) is a
minor fraction of the total. With 3 categories the improvement is ~17%; with 50 categories
it is within measurement noise.

**Why `harvest()` shows no improvement:**
At ~3 minutes for 5 variables, the number of convergence iterations (not `weighted_pct` cost
per call) determines runtime. The extreme imbalance in the 50-category power-law DMA variable
(DMA_001 = 35% of rows, target = 2%) causes slow convergence, requiring hundreds of outer
iterations. The ~17% improvement in 3-category `weighted_pct` saves <10 seconds out of ~180
seconds total.

**True bottleneck:**
Converting data columns to integer factors before the inner raking loop would replace string
hashing with O(1) integer lookup, yielding the 10–50× speedup on `weighted_pct` that was
originally predicted. This is the correct next optimization to pursue.

## Notes
- Baseline measured before optimizations (commit 653c32a)
- Post-optimization measured after commits 3cefabf, f3f67eb, 729cdbc, 1fac938
- `mem_alloc` from `bench::mark()` is cumulative across all iterations (not peak RSS)
- The `rowsum` and NA pre-cache changes are sound and correct; they provide modest wins
  at smaller n where string hashing is not the bottleneck
