---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# autumn: Fast, Modern, and Tidy Raking <img src="man/figures/autumn.png" align="right" width="120" />

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**autumn** calibrates survey data via iterative proportional fitting (raking), producing weights that align a sample's marginal distributions with known population targets. This fork extends the original [aaronrudkin/autumn](https://github.com/aaronrudkin/autumn) with Newton-Raphson calibration, SQUAREM acceleration, automatic sparse-cell collapse, bounded water-filling redistribution, and an outcome-aware design-effect estimator.

## Installation


``` r
# Install from GitHub:
remotes::install_github("davdittrich/autumn")
```

## Quick Start

`harvest()` takes a data frame and a target and returns the data frame with a `weights` column. Default parameters enforce a weight cap of 5 and mean 1.


``` r
weighted_data <- harvest(respondent_data, ns_target)
```

Two target formats are supported.

**Named-vector list:**


``` r
list(
  gender = c(Male = 0.4829, Female = 0.5171),
  region = c(Midwest = 0.2086, Northeast = 0.1764,
             South   = 0.3775, West     = 0.2374)
)
```

**Three-column data frame** (columns `variable`, `level`, `proportion`):



```
  variable    level proportion
1   gender     Male     0.4829
2   gender   Female     0.5171
3   region  Midwest     0.2086
4   region Northeast     0.1764
5   region    South     0.3775
6   region     West     0.2374
```

## Key Capabilities

### Auto-collapse of sparse or missing cells

Calibration fails when a target level has zero respondents, and produces extreme weights when a cell is too small to satisfy its target under the weight cap. `auto_collapse = TRUE` detects both conditions and merges each sparse level into its most similar surviving level before calibration begins.

The merge threshold for level $k$ is $\max\!\left(3,\ \lfloor n \cdot 0.002 \rfloor,\ \lceil n p_k / w_{\max} \rceil\right)$. The third term is the minimum count at which the cell's expected weight stays at or below `max_weight`; the second prevents collapsing well-calibrated sparse cells when the cap is loose.


``` r
# One level of 'region' absent from the sample
sparse_data <- respondent_data[respondent_data$region != "Midwest", ]

# Without auto_collapse: stop() with "missing levels" error
# With auto_collapse: Midwest absorbed into nearest neighbour, weights produced
suppressWarnings(
  weighted_sparse <- harvest(sparse_data, ns_target, auto_collapse = TRUE)
)
attr(weighted_sparse, "collapsed_levels")
#>   variable    from  into n_from p_from distance
#>      <chr>   <chr> <chr>  <int>  <dbl>    <dbl>
#> 1   region Midwest  West      0 0.2086        0
```

For ordered factors, merging is restricted to immediately adjacent surviving levels. Custom auxiliary columns for similarity scoring are supplied via `collapse_vars`.

### Newton-Raphson calibration

`method = "nr"` solves the calibration system via Newton-Raphson rather than Gauss-Seidel IPF. The effective path depends on `max_weight`:

- **Unbounded** (`max_weight = Inf`): a single $K \times K$ linear solve per Newton step converges in 10–20 iterations versus 100–500 for IPF. Use this path when data are severely imbalanced and no weight cap is required.
- **Bounded** (`max_weight < Inf`, including the default of 5): SQUAREM-accelerated water-filling IPF (Phase 1) with per-cell bisection fallback (Phase 2). This path is correct where the previous post-hoc hard clamp was not: weights satisfy the cap and the calibration targets simultaneously.


``` r
# Unbounded NR — faster on severely imbalanced problems
harvest(respondent_data, ns_target, method = "nr", max_weight = Inf)

# Bounded NR — correct per-cell water-filling (default max_weight = 5)
harvest(respondent_data, ns_target, method = "nr")
```

### SQUAREM-accelerated IPF

`accelerate = TRUE` applies the Varadhan-Roland (2008) SqS3 acceleration scheme to standard iterative proportional fitting. On problems where IPF converges slowly, SQUAREM reduces iteration count by an order of magnitude.


``` r
harvest(respondent_data, ns_target, accelerate = TRUE)
```

### Outcome-aware design effects

`design_effect()` now supports the Henry and Valliant (2015) estimator when outcome, data, and target are all supplied:

$$\hat{d}_{HV} = (1 - \hat{R}^2_w)\,\hat{d}_K$$

where $\hat{R}^2_w$ is the weighted $R^2$ from regressing the outcome on dummy-coded calibration auxiliaries and $\hat{d}_K$ is the Kish (1992) design effect. When the calibration auxiliaries strongly predict the outcome, the design effect approaches zero — correctly reflecting the variance reduction from calibration.


``` r
weighted_data <- harvest(respondent_data, ns_target)
# Kish estimator (weights only)
design_effect(weighted_data$weights)

# Henry-Valliant estimator (outcome-aware).
# respondent_data has no continuous outcome; use a binary indicator.
male_indicator <- as.integer(respondent_data$gender == "Male")
design_effect(weighted_data$weights,
              outcome = male_indicator,
              data    = respondent_data,
              target  = ns_target)
```

`design_effect()` with only weights now emits a warning and falls back to Kish when the Spencer (2000) estimator would otherwise be invoked; Spencer assumes design weights (inverse inclusion probabilities), which calibration weights are not.

### Additional controls

- `add_na_proportion`: inject an `___NA` category at the observed missingness rate, preventing listwise deletion from distorting calibration
- `adaptive_order`: reorder calibration variables each iteration by current error magnitude
- `convergence`: named vector controlling `"pct"`, `"absolute"`, `"single_weight"`, and `"time"` stopping rules
- `diagnose_weights()`: per-variable calibration summary with marginal deviations

## Performance



### Comparison with anesrake

On the included 6,691-respondent dataset raked on 10 variables, autumn's median runtime is 9.1× faster than anesrake and allocates 91% less memory:


```
#> # A data frame: 2 × 3
#>   expression   median mem_alloc
#>   <chr>      <bch:tm> <bch:byt>
#> 1 autumn        1.28s    1.13GB
#> 2 anesrake     11.63s   13.01GB
```

On a harder problem — the same dataset raked on 17 variables — autumn is 9.1× faster and allocates substantially less memory:


```
#> # A data frame: 2 × 3
#>   expression   median mem_alloc
#>   <chr>      <bch:tm> <bch:byt>
#> 1 autumn        1.29s    1.13GB
#> 2 anesrake     11.69s   13.03GB
```

`survey::rake` does not complete the 17-variable rake under default parameters and is excluded from that benchmark.

### Calibration method comparison

The six parameter combinations cover two axes: bounding (`max_weight` finite vs. `Inf`) and algorithm (`method = "rake"` vs. `"nr"`, and `accelerate`):


```
#> # A data frame: 6 × 4
#>   expression               median mem_alloc n_itr
#>   <chr>                  <bch:tm> <bch:byt> <int>
#> 1 rake_bounded              1.26s    1.13GB    10
#> 2 rake_bounded_squarem      1.88s    1.67GB    10
#> 3 rake_unbounded          51.48ms    49.3MB    10
#> 4 rake_unbounded_squarem 155.03ms  142.74MB    10
#> 5 nr_bounded               10.88s   17.89GB    10
#> 6 nr_unbounded              3.49s    5.08GB    10
```

Key guidance from the results above:

- **Unbounded rake** (`max_weight = Inf`) is 24.5× faster than bounded rake on this dataset and uses 98% less memory — the weight cap forces additional constraint-satisfaction work per cell per iteration. Use it when no cap is needed.
- **SQUAREM** (`accelerate = TRUE`) is 1.5× *slower* on this well-conditioned bounded dataset. Both plain IPF and SQUAREM exit via the `pct` convergence criterion within 3–5 passes on this problem, so SQUAREM's iteration savings are minimal; its per-super-step overhead (two IPF passes plus a projected CBB step) determines the net result. Use SQUAREM on poorly-conditioned problems where plain IPF requires thousands of iterations.
- **Unbounded NR** (`method = "nr", max_weight = Inf`) is 67.8× slower than unbounded rake on this 10-variable problem. NR's advantage emerges on severely imbalanced data where IPF requires hundreds of iterations; a single K×K Newton step costs more but converges in 10–20 steps versus 500+. Note that `accelerate` has no effect on `method = "nr"` — the bounded path hard-codes SQUAREM internally and the unbounded path is a direct K×K solve.
- **Bounded NR** (`method = "nr"`) is a correctness tool: it satisfies the weight cap and calibration targets simultaneously. The previous post-hoc hard clamp broke calibration; bounded NR does not.

Tightening convergence criteria (`convergence["pct"]` and `convergence["absolute"]`) yields further gains at the cost of additional iterations.

## Why "autumn"?

<p align="center">
  <img src="man/figures/raking_leaves.jpg" align="center" width="480" />
</p>

## Authorship

**autumn** is maintained by [Dennis A. V. Dittrich](https://github.com/davdittrich/). This package is a fork of the original **autumn** by [Aaron Rudkin](https://github.com/aaronrudkin/); the core IPF implementation and the `ns_target` dataset originate from that work. Target proportions in `ns_target` were developed by [Alex Rossell-Hayes](https://github.com/rossellhayes).

Bug reports and contributions are welcome at the [GitHub issue tracker](https://github.com/davdittrich/autumn/issues).

Package hex logo adapted from art by [Freepik](https://www.flaticon.com/authors/Freepik) from [flaticon.com](https://www.flaticon.com/).
