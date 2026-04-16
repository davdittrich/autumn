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

---

## Factor Pre-Conversion Results (2026-04-16)

**Baseline for this comparison:** post-rowsum numbers above (58.6 ms / 60.8 ms / 2.96 min)

### Measured speedups

| Function | Pre-factor (median) | Post-factor (median) | Speedup |
|---|---|---|---|
| `weighted_pct()` 3-cat, char input (standalone) | 58.6 ms | 54.4 ms | 1.08× (noise) |
| `weighted_pct()` 3-cat, **factor vs char direct** | 42.8 ms (char) | 26.4 ms (factor) | **1.62×** |
| `weighted_pct()` 50-cat, char input (standalone) | 60.8 ms | 43.6 ms | 1.39× (better measurement) |
| `weighted_pct()` 50-cat, **factor vs char direct** | 43.4 ms (char) | 24.7 ms (factor) | **1.76×** |
| `harvest()` end-to-end (5 vars, n=1.8M) | 2.96 min | 1.05 min | **2.82×** |

### Optimization applied

Factor pre-conversion in `pre_cache`: `factor(data[[variable]], levels=target_names)` once
per variable in `do_rake()`. `cache[[var]]$x` (factor INTSXP) replaces per-call character
vector argument to `weighted_pct()`. Commits: 58722fd, 2adf284.

### Why harvest() speedup (2.82×) exceeds per-call weighted_pct speedup (1.65×)

The 10–50× prediction assumed string hashing was O(n) naive comparison. In practice,
R's `rowsum()` uses an efficient string hash table, so the per-call improvement is ~1.65×
(integer codes vs hashed character pointers). However:

1. **Memory**: factor INTSXP = 4 bytes × n, character STRSXP = 8 bytes × n. Each
   `weighted_pct` call allocates ~7 MB (factor) vs ~15 MB (char) for n=1.8M.
2. **GC amplification**: At 500+ iterations of `do_rake()`, cumulative allocation drops
   from 229 GB to 97.9 GB (2.34×). Less allocation → fewer GC pauses → 2.82× end-to-end
   speedup on `harvest()`.

### Notes

- Standalone `weighted_pct` benchmarks call with raw character vectors (no factor);
  direct factor vs char comparison requires constructing `factor(x, levels=target_names)`
  before the bench::mark call (see source above).
- The 10–50× prediction in the plan was a theoretical upper bound under the assumption
  that string comparison dominated. The actual bottleneck is string pointer dereferencing +
  hash lookup, which R handles efficiently. Factor integers are cheaper but not 10–50× so.
- Side-effect fix (autumn-7m3): OOV values now correctly get weight multiplier 1 instead
  of NA (factor codes make OOV → NA_integer_, caught by `which(is.na(codes))`).
- Commits: 58722fd (factor pre-conversion + OOV fix), 2adf284 (comment correction)
