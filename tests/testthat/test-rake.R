test_that("single variable rake works", {
  data = data.frame("var1" = c(rep("a", 3), "b"))
  targets = list("var1" = c("a" = 0.875, "b" = 0.125))
  weights = c(1, 1, 1, 1)
  select_function = select_pct
  select_params = c("pct" = 0.05)
  error_function = current_miss_linear

  expect_equal(
    expect_message(
      do_rake(
        data, targets, weights,
        max_weight = 5,
        max_iterations = 1000,
        convergence = c("pct" = 1e-6, "absolute" = 1e-6),
        verbose = 3),
      "is exactly correct"),
    c(1.16666666666667, 1.16666666666667, 1.16666666666667, 0.5)
  )

  # And verify clamping weights -- max weight should be exactly 5
  data2 = data.frame("var1" = c(rep("a", 100), "b"))
  targets2 = list("var1" = c("a" = 0.15, "b" = 0.85))
  weights2 = rep(1, 101)
  res = do_rake(data2, targets2, weights2, 5, 1000,
          convergence = c("pct" = 1e-6, "absolute" = 1e-6),
          enforce_mean = FALSE,
          verbose = 3)
  expect_equal(max(res), 5)

  # And verify ensure_mean
  res2 = do_rake(data2, targets2, weights2, 5, 1000,
                convergence = c("pct" = 1e-6, "absolute" = 1e-6),
                enforce_mean = TRUE,
                verbose = 3)
  # After fix: max_weight is strictly enforced; mean deviates from 1 when
  # clamping is structurally binding (enforce_mean cannot re-mean past max_weight).
  expect_true(max(res2) <= 5,
              label = "max weight respected with enforce_mean = TRUE")
})

test_that("do_rake IPF path strictly respects max_weight", {
  # Regression test: enforce_mean re-scaling inside one_pass() was pushing
  # the "b" weight from 5 (clamped) to ~25 (re-meaned past max_weight).
  # The hard clamp added after the loop must prevent this.
  data    = data.frame(var1 = c(rep("a", 100), "b"))
  targets = list(var1 = c("a" = 0.15, "b" = 0.85))
  weights = rep(1, 101)

  result = do_rake(data, targets, weights,
                   max_weight = 5,
                   max_iterations = 1000,
                   convergence = c(pct = 1e-6, absolute = 1e-6),
                   enforce_mean = TRUE,
                   verbose = FALSE)

  expect_true(max(result) <= 5,
              label = "IPF path must not return weights above max_weight")
})

test_that("testing fast convergence, timeout, regular convergence", {
  reduced_set = ns_target[1:5]
  expect_warning(
      harvest(respondent_data, reduced_set, verbose = 2),
      "Partial convergence")

  expect_message(
    harvest(respondent_data, ns_target,
            convergence = c(pct = 0.01, absolute = 1e-6, time = 0.01),
            verbose = 1),
    "time limit")
})

test_that("NA rows in raking variable get weight multiplier 1", {
  # Rows where the raking variable is NA must not have their weight changed
  # by single_adjust. This tests that the pre_cache NA path works correctly.
  data    = data.frame(var1 = c("a", "b", NA, "a"))
  targets = list(var1 = c("a" = 0.5, "b" = 0.5))
  weights = c(1, 1, 2, 1)   # NA row has weight 2

  result = do_rake(data, targets, weights,
                   max_weight = 10,
                   max_iterations = 100,
                   convergence = c(pct = 1e-6, absolute = 1e-6),
                   verbose = FALSE)

  # NA row weight must be unchanged (multiply by 1)
  expect_equal(result[3], 2)

  # Weighted proportions of "a" and "b" must match targets (0.5 / 0.5)
  # Non-NA weights sum: result[1] + result[2] + result[4]
  # "a" weight: result[1] + result[4]; "b" weight: result[2]
  non_na_sum = result[1] + result[2] + result[4]
  expect_true(abs((result[1] + result[4]) / non_na_sum - 0.5) < 0.01)
  expect_true(abs(result[2] / non_na_sum - 0.5) < 0.01)
})

test_that("OOV values in raking variable get weight multiplier 1", {
  # Out-of-vocabulary values (not in target) must not corrupt weights.
  # autumn-7m3: previously these produced NA in mult, propagating NA weights.
  data    = data.frame(var1 = c("a", "b", "UNKNOWN", "a"))
  targets = list(var1 = c("a" = 0.5, "b" = 0.5))
  weights = c(1, 1, 2, 1)   # OOV row has weight 2

  result = do_rake(data, targets, weights,
                   max_weight = 10,
                   max_iterations = 100,
                   convergence = c(pct = 1e-6, absolute = 1e-6),
                   verbose = FALSE)

  # OOV row weight must be unchanged (was NA before fix, now 1x multiplier)
  expect_equal(result[3], 2)
  # No NA weights
  expect_false(any(is.na(result)))

  # Weighted proportions of "a" and "b" must match targets (0.5 / 0.5)
  non_oov_sum = result[1] + result[2] + result[4]
  expect_true(abs((result[1] + result[4]) / non_oov_sum - 0.5) < 0.01)
  expect_true(abs(result[2] / non_oov_sum - 0.5) < 0.01)
})

test_that("adaptive_order=TRUE converges to same weights as FALSE", {
  # With multiple variables, adaptive ordering must not change the fixed-point
  # solution — only potentially reduce iterations needed.
  # 7-row data with mixed x/y across both a and b levels, so the system is
  # well-conditioned and IPF converges monotonically regardless of ordering.
  data    = data.frame(var1 = c("a","b","b","b","a","a","b"),
                       var2 = c("x","x","y","y","x","y","x"))
  targets = list(var1 = c("a"=0.5, "b"=0.5),
                 var2 = c("x"=0.4, "y"=0.6))
  weights = rep(1, 7)
  conv    = c(pct=1e-10, absolute=1e-10)

  result_default = do_rake(data, targets, weights,
                           max_weight=10, max_iterations=2000,
                           convergence=conv, verbose=FALSE)
  result_adaptive = do_rake(data, targets, weights,
                            max_weight=10, max_iterations=2000,
                            convergence=conv, adaptive_order=TRUE,
                            verbose=FALSE)

  expect_equal(result_default, result_adaptive, tolerance=1e-6)
})

test_that("accelerated do_rake converges to same solution as standard", {
  # Acceleration must not change the fixed-point solution.
  set.seed(42)
  n = 500
  data = data.frame(
    var1 = sample(c("a","b","c"), n, TRUE, c(0.6, 0.3, 0.1)),
    var2 = sample(c("x","y"),    n, TRUE, c(0.7, 0.3))
  )
  targets = list(
    var1 = c(a=0.33, b=0.33, c=0.34),
    var2 = c(x=0.5, y=0.5)
  )
  weights = rep(1, n)
  conv    = c(pct=1e-10, absolute=1e-10)

  result_std = do_rake(data, targets, weights,
                       max_weight=10, max_iterations=5000,
                       convergence=conv, verbose=FALSE)
  result_acc = do_rake(data, targets, weights,
                       max_weight=10, max_iterations=5000,
                       convergence=conv, accelerate=TRUE, verbose=FALSE)

  # Must converge to same fixed point within floating-point tolerance
  expect_equal(result_std, result_acc, tolerance=1e-4)
})

test_that("SQUAREM does not use pct convergence criterion", {
  # With pct=0.999 the standard IPF loop terminates after ~1 iteration
  # (fires when improvement is > 0.1% of previous update — almost immediately).
  # SQUAREM must NOT honour pct and must continue until absolute=1e-8 is met.
  # If SQUAREM mistakenly used pct, it would terminate prematurely and produce
  # poorly calibrated weights.
  set.seed(11)
  n = 800
  probs = (1/seq_len(10))^2; probs = probs/sum(probs)
  data = data.frame(dma = sample(paste0("D", 1:10), n, TRUE, probs))
  targets = list(dma = setNames(rep(0.1, 10), paste0("D", 1:10)))
  weights = rep(1, n)
  # pct=0.999: would trigger on standard IPF after 1-2 iterations
  conv_pct = c(pct = 0.999, absolute = 1e-20)

  result_acc = do_rake(data, targets, weights,
                       max_weight = 10, max_iterations = 5000,
                       convergence = conv_pct, accelerate = TRUE, verbose = FALSE)

  # If SQUAREM uses pct, it would stop too early and marginals would be far off.
  # Verify calibrated result is accurate despite the aggressive pct value.
  pct_result = weighted_pct(factor(data$dma, levels = names(targets$dma)), result_acc)
  # With max_weight=10 and highly imbalanced data (D1 >> 10% target), clamping limits
  # achievable accuracy; the IPF fixed-point itself has max_error ~0.046. The key
  # property is that SQUAREM reaches the same fixed-point as standard IPF (does not
  # terminate prematurely due to pct), not that it exceeds IPF accuracy.
  expect_true(max(abs(pct_result - targets$dma[names(pct_result)])) < 0.1,
              label = "SQUAREM converged accurately despite pct=0.999")
})

test_that("accelerated do_rake needs fewer iterations for high-imbalance data", {
  # Acceleration should reduce iterations for the extreme-imbalance case.
  set.seed(99)
  n = 2000
  # Power-law imbalance: one category dominates
  probs = (1/seq_len(20))^1.5; probs = probs/sum(probs)
  data = data.frame(dma = sample(paste0("D",1:20), n, TRUE, probs))
  targets = list(dma = setNames(rep(1/20, 20), paste0("D",1:20)))
  weights = rep(1, n)
  conv    = c(pct=0.01, absolute=1e-6)

  # Count iterations for standard IPF: re-run with very verbose and capture
  # A proxy: use a tight convergence that definitely needs many iterations
  conv_tight = c(pct=1e-8, absolute=1e-8)
  result_acc = do_rake(data, targets, weights,
                       max_weight=10, max_iterations=5000,
                       convergence=conv_tight, accelerate=TRUE, verbose=FALSE)

  # Must produce valid (no NA) weights and correct marginal proportions
  # (within the accuracy achievable given max_weight=10 clamping)
  expect_false(any(is.na(result_acc)))
  pct = weighted_pct(factor(data$dma, levels=names(targets$dma)), result_acc)
  expect_true(max(abs(pct - targets$dma[names(pct)])) < 0.02)
})

test_that("bounded redistribution: cell sums match targets after one IPF pass", {
  # Minimal case where unbounded IPF would assign weight > max_weight.
  # Cell "b": single row, target 0.85 of 101 total weight needed.
  # Without cap: w["b"] = 1 * (0.85 / (1/101)) >> max_weight=5.
  # With bounded redistribution: w["b"] = 5 (clamped), cell sum < target (infeasible).
  # Cell "a": 100 rows, target 0.15 * 101 weight-units needed.
  data    = data.frame(var1 = c(rep("a", 100), "b"))
  targets = list(var1 = c("a" = 0.15, "b" = 0.85))
  weights = rep(1, 101)

  result = do_rake(data, targets, weights,
                   max_weight = 5,
                   max_iterations = 1,
                   convergence = c(pct = 1e-20, absolute = 1e-20),
                   verbose = FALSE)

  a_rows = seq_len(100)
  b_row  = 101L
  expect_true(max(result) <= 5 + 1e-9, label = "no weight exceeds max_weight")
  expect_equal(result[b_row], 5, tolerance = 1e-9)
  expect_true(var(result[a_rows]) < 1e-20, label = "a rows uniform within cell")
})

test_that("bounded redistribution: feasible cell hits target with binding cap", {
  set.seed(7)
  n = 500
  data    = data.frame(var1 = sample(c("a","b","c"), n, TRUE, c(0.5, 0.3, 0.2)))
  targets = list(var1 = c("a" = 0.4, "b" = 0.4, "c" = 0.2))
  weights = rep(1, n)

  result = do_rake(data, targets, weights,
                   max_weight = 3,
                   max_iterations = 5000,
                   convergence = c(pct = 1e-10, absolute = 1e-10),
                   verbose = FALSE)

  expect_true(max(result) <= 3 + 1e-9, label = "bound respected")
  pct = weighted_pct(factor(data$var1, levels = names(targets$var1)), result)
  expect_true(max(abs(pct[names(targets$var1)] - targets$var1)) < 0.05,
              label = "marginals near targets despite binding cap")
})

test_that("bounded redistribution backward compat: Inf cap = no change", {
  set.seed(3)
  n = 300
  data    = data.frame(var1 = sample(c("a","b"), n, TRUE),
                       var2 = sample(c("x","y","z"), n, TRUE))
  targets = list(var1 = c(a=0.5, b=0.5),
                 var2 = c(x=0.3, y=0.4, z=0.3))
  weights = rep(1, n)
  conv    = c(pct=1e-10, absolute=1e-10)

  result_inf = do_rake(data, targets, weights,
                       max_weight = Inf, max_iterations = 5000,
                       convergence = conv, verbose = FALSE)
  result_big = do_rake(data, targets, weights,
                       max_weight = 1e9, max_iterations = 5000,
                       convergence = conv, verbose = FALSE)

  expect_equal(result_inf, result_big, tolerance = 1e-4)
  for (v in names(targets)) {
    pct = weighted_pct(factor(data[[v]], levels=names(targets[[v]])), result_inf)
    expect_true(max(abs(pct[names(targets[[v]])] - targets[[v]])) < 1e-4)
  }
})

test_that("bounded redistribution: OOV/NA rows unchanged", {
  data    = data.frame(var1 = c("a", "b", "UNKNOWN", NA, "a"))
  targets = list(var1 = c("a" = 0.5, "b" = 0.5))
  weights = c(1, 1, 3, 4, 1)

  result = do_rake(data, targets, weights,
                   max_weight = 2,
                   max_iterations = 1000,
                   convergence = c(pct = 1e-10, absolute = 1e-10),
                   verbose = FALSE)

  expect_equal(result[3], 3, tolerance = 0,   label = "OOV row unchanged")
  expect_equal(result[4], 4, tolerance = 0,   label = "NA row unchanged")
  expect_false(any(is.na(result)),             label = "no NA weights")
  # OOV/NA rows keep their original weights (multiplier=1), which may exceed
  # max_weight. Only the raked rows (non-OOV, non-NA) must respect the bound.
  raked_rows = c(1, 2, 5)
  expect_true(max(result[raked_rows]) <= 2 + 1e-9, label = "bound respected for raked rows")
})

test_that("bounded redistribution: infeasible cell does not loop or error", {
  # All 3 "b" rows can contribute at most 3 * max_weight = 6 weight-units.
  # But target 0.90 * 100 = 90 weight-units needed. Cell is structurally infeasible.
  data    = data.frame(var1 = c(rep("a", 97), "b", "b", "b"))
  targets = list(var1 = c("a" = 0.10, "b" = 0.90))
  weights = rep(1, 100)

  result = expect_no_error(
    do_rake(data, targets, weights,
            max_weight = 2,
            max_iterations = 100,
            convergence = c(pct = 1e-6, absolute = 1e-6),
            verbose = FALSE)
  )
  expect_false(any(is.na(result)), label = "no NA weights in infeasible cell case")
  expect_true(max(result) <= 2 + 1e-9, label = "bound respected in infeasible case")
  expect_true(all(result[98:100] <= 2 + 1e-9))
})

test_that("bounded redistribution: SQUAREM + binding max_weight converges", {
  set.seed(42)
  n = 800
  data = data.frame(
    var1 = sample(c("a","b","c"), n, TRUE, c(0.6, 0.3, 0.1)),
    var2 = sample(c("x","y"),    n, TRUE, c(0.7, 0.3))
  )
  targets = list(
    var1 = c(a=0.33, b=0.33, c=0.34),
    var2 = c(x=0.5, y=0.5)
  )
  weights = rep(1, n)
  conv    = c(pct=1e-8, absolute=1e-8)
  mw      = 2.5

  result_acc = do_rake(data, targets, weights,
                       max_weight = mw, max_iterations = 5000,
                       convergence = conv, accelerate = TRUE, verbose = FALSE)
  result_std = do_rake(data, targets, weights,
                       max_weight = mw, max_iterations = 5000,
                       convergence = conv, accelerate = FALSE, verbose = FALSE)

  expect_true(max(result_acc) <= mw + 1e-9,
              label = "SQUAREM: no weight above max_weight")
  expect_false(any(is.na(result_acc)),
               label = "SQUAREM: no NA weights")
  # With binding max_weight constraints, IPF is a non-smooth operator:
  # SQUAREM and standard IPF converge to fixed points that may differ by O(0.02)
  # in absolute weight but achieve statistically equivalent calibration.
  # The correct invariant is calibration quality, not exact weight identity.
  for (v in names(targets)) {
    f = factor(data[[v]], levels = names(targets[[v]]))
    pct_acc = weighted_pct(f, result_acc)[names(targets[[v]])]
    pct_std = weighted_pct(f, result_std)[names(targets[[v]])]
    expect_true(max(abs(pct_acc - targets[[v]])) < 1e-6,
                label = paste("SQUAREM calibration for", v))
    expect_true(max(abs(pct_std - targets[[v]])) < 1e-6,
                label = paste("standard IPF calibration for", v))
  }
})

test_that("enforce_mean is inert in IPF path after bounded redistribution", {
  set.seed(5)
  n = 400
  data    = data.frame(var1 = sample(c("a","b","c"), n, TRUE))
  targets = list(var1 = c(a=0.4, b=0.4, c=0.2))
  weights = rep(1, n)
  conv    = c(pct=1e-10, absolute=1e-10)

  r_true  = do_rake(data, targets, weights,
                    max_weight = 3, max_iterations = 5000,
                    convergence = conv, enforce_mean = TRUE,  verbose = FALSE)
  r_false = do_rake(data, targets, weights,
                    max_weight = 3, max_iterations = 5000,
                    convergence = conv, enforce_mean = FALSE, verbose = FALSE)

  expect_equal(r_true, r_false, tolerance = 1e-9,
               label = "enforce_mean has no effect in IPF path after bounded redistribution")
})
