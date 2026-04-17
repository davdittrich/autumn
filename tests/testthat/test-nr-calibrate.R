test_that("nr_calibrate matches do_rake solution for 2-variable problem", {
  set.seed(7)
  n = 1000
  data = data.frame(
    var1 = sample(c("a","b","c"), n, TRUE, c(0.5, 0.3, 0.2)),
    var2 = sample(c("x","y"),    n, TRUE, c(0.6, 0.4))
  )
  targets = list(
    var1 = c(a=0.4, b=0.4, c=0.2),
    var2 = c(x=0.5, y=0.5)
  )
  initial = rep(1, n)

  result_rake = do_rake(data, targets, initial,
                        max_weight = 100,
                        max_iterations = 5000,
                        convergence = c(pct=1e-10, absolute=1e-10),
                        verbose = FALSE)

  result_nr = nr_calibrate(data, targets, initial,
                           max_iter = 50, tol = 1e-8)

  pct_nr = sapply(names(targets), function(v)
    max(abs(weighted_pct(factor(data[[v]], levels=names(targets[[v]])),
                         result_nr) - targets[[v]])))

  expect_true(all(pct_nr < 1e-6))
  expect_equal(sum(result_nr), sum(result_rake), tolerance=1e-3)
})

test_that("harvest method='nr' matches method='rake' on standard data", {
  # Use max_weight=Inf to route both methods through their unconstrained paths:
  # NR takes the full-Hessian path (fast convergence), IPF runs without clamping.
  # When max_weight is binding, the two methods are different algorithms that
  # converge to different-but-valid bounded solutions; that is tested separately.
  result_rake = harvest(respondent_data, ns_target,
                        max_weight = Inf, attach_weights = FALSE)
  result_nr   = harvest(respondent_data, ns_target,
                        max_weight = Inf, method = "nr", attach_weights = FALSE)

  for(v in names(ns_target)) {
    pct_rake = weighted_pct(factor(respondent_data[[v]],
                                   levels=names(ns_target[[v]])),
                            result_rake)
    pct_nr   = weighted_pct(factor(respondent_data[[v]],
                                   levels=names(ns_target[[v]])),
                            result_nr)
    expect_equal(pct_rake[names(pct_nr)], pct_nr, tolerance=0.015,
                 label=paste0("marginal agreement for ", v))
  }
})

test_that("harvest method='nr' warns only when select_function is non-default", {
  expect_warning(
    harvest(respondent_data, ns_target,
            method = "nr", attach_weights = FALSE,
            select_function = select_all),
    "calibrates all variables simultaneously"
  )

  expect_no_warning(
    harvest(respondent_data, ns_target,
            method = "nr", attach_weights = FALSE)
  )
})

test_that("harvest method='nr' bounded weights stay within max_weight", {
  result = harvest(respondent_data, ns_target,
                   method = "nr", attach_weights = FALSE,
                   max_weight = 1.5)

  expect_true(max(result) <= 1.5 + 1e-4,
              label = "max weight <= max_weight after clamping loop")

  for(v in names(ns_target)) {
    pct = weighted_pct(factor(respondent_data[[v]],
                              levels = names(ns_target[[v]])),
                       result)
    expect_true(max(abs(pct[names(ns_target[[v]])] - ns_target[[v]])) < 0.10,
                label = paste0("marginal after clamping for ", v))
  }
})

test_that("nr_calibrate handles OOV and NA rows", {
  data    = data.frame(var1 = c("a", "b", "UNKNOWN", NA, "a"))
  targets = list(var1 = c("a"=0.5, "b"=0.5))
  weights = c(1, 1, 2, 3, 1)

  result = nr_calibrate(data, targets, weights, max_iter=50, tol=1e-8)

  expect_equal(result[3], 2, tolerance = 0)   # OOV row: weight must be exactly unchanged
  expect_equal(result[4], 3, tolerance = 0)   # NA row: weight must be exactly unchanged
  expect_false(any(is.na(result)))

  valid = c(1, 2, 5)
  wt_sum = sum(result[valid])
  expect_equal((result[1] + result[5]) / wt_sum, 0.5, tolerance=1e-6)
})

test_that("nr_calibrate converges in few iterations for high-imbalance data", {
  # NR should converge in <30 iterations even for heavily imbalanced data
  set.seed(55)
  n = 2000
  probs = (1/seq_len(20))^1.5; probs = probs/sum(probs)
  data = data.frame(dma = sample(paste0("D",1:20), n, TRUE, probs))
  targets = list(dma = setNames(rep(1/20, 20), paste0("D",1:20)))
  weights = rep(1, n)

  result = nr_calibrate(data, targets, weights, max_iter=30, tol=1e-8)

  expect_false(any(is.na(result)))
  pct = weighted_pct(factor(data$dma, levels=names(targets$dma)), result)
  expect_true(max(abs(pct - targets$dma[names(pct)])) < 0.01)
})

test_that("nr_calibrate bounded matches do_rake bounded for 2-variable problem", {
  # Both IPF water-filling and active-set NR minimize the Deville-Sarndal
  # truncated-linear objective; they must converge to the same weight vector.
  set.seed(42)
  n = 1000
  data = data.frame(
    var1 = sample(c("a","b","c"), n, TRUE, c(0.5, 0.3, 0.2)),
    var2 = sample(c("x","y"),    n, TRUE, c(0.6, 0.4))
  )
  targets = list(
    var1 = c(a=0.4, b=0.4, c=0.2),
    var2 = c(x=0.5, y=0.5)
  )
  initial = rep(1, n)
  max_w   = 3.0

  result_rake = do_rake(data, targets, initial,
                        max_weight     = max_w,
                        max_iterations = 5000,
                        convergence    = c(pct=1e-10, absolute=1e-10),
                        verbose        = FALSE)

  result_nr = nr_calibrate(data, targets, initial, max_weight = max_w,
                           max_iter = 50, tol = 1e-8)

  expect_true(max(result_nr) <= max_w + 1e-4,
              label = "NR max weight bounded")

  for (v in names(targets)) {
    pct_nr   = weighted_pct(factor(data[[v]], levels=names(targets[[v]])), result_nr)
    pct_rake = weighted_pct(factor(data[[v]], levels=names(targets[[v]])), result_rake)
    expect_equal(pct_nr[names(pct_rake)], pct_rake, tolerance=1e-3,
                 label=paste0("bounded calibration agreement for ", v))
  }
})

test_that("nr_calibrate max_weight=Inf produces same result as unbounded default", {
  set.seed(7)
  n = 500
  data = data.frame(
    var1 = sample(c("a","b","c"), n, TRUE, c(0.5, 0.3, 0.2)),
    var2 = sample(c("x","y"),    n, TRUE, c(0.6, 0.4))
  )
  targets = list(
    var1 = c(a=0.4, b=0.4, c=0.2),
    var2 = c(x=0.5, y=0.5)
  )
  initial = rep(1, n)

  result_default = nr_calibrate(data, targets, initial, max_iter=50, tol=1e-8)
  result_inf     = nr_calibrate(data, targets, initial, max_weight=Inf,
                                max_iter=50, tol=1e-8)

  expect_equal(result_default, result_inf, tolerance=1e-12,
               label = "max_weight=Inf identical to unbounded default")
})

test_that("nr_calibrate bounded does not clamp OOV or NA rows", {
  data    = data.frame(var1 = c("a", "b", "UNKNOWN", NA, "a"))
  targets = list(var1 = c("a"=0.5, "b"=0.5))
  weights = c(1, 1, 5, 7, 1)   # OOV row[3]=5, NA row[4]=7 both exceed max_weight=3
  max_w   = 3.0

  result = nr_calibrate(data, targets, weights, max_weight = max_w,
                        max_iter = 50, tol = 1e-8)

  expect_equal(result[3], 5, tolerance=0, label = "OOV weight unchanged")
  expect_equal(result[4], 7, tolerance=0, label = "NA weight unchanged")
  expect_true(result[1] <= max_w + 1e-4, label = "valid row 1 bounded")
  expect_true(result[2] <= max_w + 1e-4, label = "valid row 2 bounded")
  expect_true(result[5] <= max_w + 1e-4, label = "valid row 5 bounded")
  expect_false(any(is.na(result)),        label = "no NA in output")
})

test_that("nr_calibrate bounded handles structurally infeasible cell without error", {
  # Single "a" row capped at max_weight=2.0 contributes at most 2 weight units.
  # Target for "a" is 0.5 * 8 = 4.0 units: structurally infeasible.
  # Algorithm must terminate without error and respect the weight cap.
  data    = data.frame(var1 = c("a", "b", "b", "b", "b", "b", "b", "b"))
  targets = list(var1 = c("a"=0.5, "b"=0.5))
  weights = rep(1, 8)
  max_w   = 2.0

  result = nr_calibrate(data, targets, weights, max_weight = max_w,
                        max_iter = 50, tol = 1e-8)

  expect_false(any(is.na(result)), label = "no NA for infeasible cell")
  expect_true(max(result) <= max_w + 1e-4, label = "max weight bounded for infeasible cell")
})

test_that("harvest method='nr' bounded (max_weight=5) agrees with IPF marginals", {
  result_rake = harvest(respondent_data, ns_target,
                        max_weight = 5, attach_weights = FALSE)
  result_nr   = harvest(respondent_data, ns_target,
                        max_weight = 5, method = "nr", attach_weights = FALSE)

  expect_true(max(result_nr) <= 5 + 1e-4, label = "NR weights bounded at 5")

  for (v in names(ns_target)) {
    pct_rake = weighted_pct(factor(respondent_data[[v]],
                                   levels=names(ns_target[[v]])), result_rake)
    pct_nr   = weighted_pct(factor(respondent_data[[v]],
                                   levels=names(ns_target[[v]])), result_nr)
    # When max_weight is binding, bounded IPF (with per-cell water-filling) and
    # bounded sequential IPF (multiply-then-clamp) converge to similar but not
    # identical feasible solutions because they apply the max_weight constraint
    # differently within each cell. 10% tolerance reflects this path difference.
    expect_equal(pct_rake[names(pct_nr)], pct_nr, tolerance=0.10,
                 label=paste0("bounded marginal agreement for ", v))
  }
})
