context("test-rake")

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
  expect_equal(mean(res2), 1)
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
