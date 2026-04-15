context("test-design_effect")

test_that("basic code runthroughs of Kish effect and ESS", {
  weights = rep(1, 100)
  expect_equal(design_effect(weights), 1)
  expect_equal(effective_sample_size(weights), 100)

  df_w = data.frame(id = 1:100, weights = rep(1, 100))
  expect_equal(effective_sample_size(df_w), 100)

  df_w2 = data.frame(id = 1:100, w2 = rep(1, 100))
  expect_error(design_effect(df_w2), "Please specify weights directly")

  expect_error(
    design_effect(weights, outcome = rep(1, 50)),
    "not equal in length"
  )

  expect_error(
    design_effect(weights, outcome = rep("a", 100)),
    "must be numeric"
  )
})

test_that("design_effect finds .weights_autumn when data has pre-existing weights column", {
  skip_on_cran()

  data_preweight = respondent_data
  data_preweight$weights = 1
  result_w = harvest(data_preweight, ns_target)
  expect_true(".weights_autumn" %in% colnames(result_w))

  # design_effect() must find .weights_autumn and return a numeric result
  deff = design_effect(result_w)
  expect_true(is.numeric(deff))
  expect_false(is.na(deff))
})

test_that("Henry & Valliant (2015) design effect: correct behavior", {
  skip_on_cran()

  weights = harvest(respondent_data, ns_target, attach_weights = FALSE)
  n = length(weights)

  # --- Test 1: Henry ≈ Kish when outcome uncorrelated with calibration vars ---
  set.seed(42)
  y_rand = rnorm(n)
  henry_deff = design_effect(weights, y_rand, respondent_data, ns_target)
  kish_deff  = design_effect(weights)
  expect_true(abs(henry_deff - kish_deff) < 0.1)

  # --- Test 2: Henry < Kish when outcome correlated with calibration vars ---
  # gender is a raking variable; use female dummy as outcome (high R^2)
  y_corr = as.numeric(respondent_data$gender == "Female") + rnorm(n, sd = 0.1)
  henry_deff_corr = design_effect(weights, y_corr, respondent_data, ns_target)
  expect_true(henry_deff_corr < kish_deff - 0.05)
  expect_true(henry_deff_corr > 0)

  # --- Test 3: Warning + Kish fallback when outcome given, data/target NULL ---
  expect_warning(
    deff_fallback <- design_effect(weights, y_rand),
    regexp = "Falling back to Kish|requires both"
  )
  expect_equal(deff_fallback, kish_deff)

  # --- Test 4: stop() when outcome given, data given, target NULL ---
  expect_error(
    design_effect(weights, y_rand, data = respondent_data),
    regexp = "supplied together"
  )

  # --- Test 5: stop() when outcome given, target given, data NULL ---
  expect_error(
    design_effect(weights, y_rand, target = ns_target),
    regexp = "supplied together"
  )

  # --- Test 6: stop() on NA in outcome ---
  y_na = y_rand
  y_na[1] = NA
  expect_error(
    design_effect(weights, y_na, respondent_data, ns_target),
    regexp = "NA"
  )

  # --- Test 7: stop() on constant outcome ---
  expect_error(
    design_effect(weights, rep(1, n), respondent_data, ns_target),
    regexp = "constant|var\\(outcome\\)"
  )

  # --- Test 8: Warning + Kish when outcome NULL but data/target given ---
  expect_warning(
    deff_no_outcome <- design_effect(weights, data = respondent_data,
                                     target = ns_target),
    regexp = "ignored when.*outcome.*NULL|requires.*outcome"
  )
  expect_equal(deff_no_outcome, kish_deff)

  # --- Test 9 (ESS): Henry ESS is meaningfully higher than Kish ESS ---
  # Use correlated outcome from test 2. When outcome has high R^2 against
  # calibration vars, deff_H = (1 - R^2) * deff_K shrinks toward 0, so
  # ESS_henry = n / deff_H >> ESS_kish = n / deff_K.
  ess_henry = effective_sample_size(weights, y_corr, respondent_data, ns_target)
  ess_kish  = effective_sample_size(weights)
  expect_true(ess_henry > ess_kish * 1.05)
  expect_true(ess_henry > 0)
})
