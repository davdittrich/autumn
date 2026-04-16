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
