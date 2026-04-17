test_that("collapse_threshold: zero respondents always collapses", {
  expect_true(autumn:::collapse_threshold(0L, 0.1, 100L, 5))
})

test_that("collapse_threshold: count below adaptive threshold collapses", {
  # n=100, p=0.1, max_weight=5
  # cap_floor = ceiling(100 * 0.1 / 5) = 2
  # min_abs   = max(3, floor(100 * 0.002)) = 3
  # threshold = 3; n_k=2 < 3 → TRUE
  expect_true(autumn:::collapse_threshold(2L, 0.1, 100L, 5))
})

test_that("collapse_threshold: count at threshold does not collapse", {
  # n_k = threshold = 3 → NOT < 3 → FALSE
  expect_false(autumn:::collapse_threshold(3L, 0.1, 100L, 5))
})

test_that("collapse_threshold: max_weight=Inf uses min_abs only", {
  # cap_floor = 0 regardless of p_k; min_abs=3 for n=100
  expect_true(autumn:::collapse_threshold(2L, 0.9, 100L, Inf))
  expect_false(autumn:::collapse_threshold(3L, 0.9, 100L, Inf))
})

test_that("collapse_threshold: min_abs scales with sample size", {
  # n=10000: min_abs = max(3, floor(10000*0.002)) = max(3,20) = 20
  expect_true(autumn:::collapse_threshold(15L, 0.001, 10000L, Inf))
  expect_false(autumn:::collapse_threshold(20L, 0.001, 10000L, Inf))
})

test_that("collapse_threshold: large target proportion raises cap_floor", {
  # n=100, p=0.5, max_weight=5: cap_floor=ceiling(100*0.5/5)=10; min_abs=3; threshold=10
  expect_true(autumn:::collapse_threshold(9L, 0.5, 100L, 5))
  expect_false(autumn:::collapse_threshold(10L, 0.5, 100L, 5))
})

test_that("collapse_threshold: p_k=0 with zero respondents uses min_abs only", {
  # cap_floor = ceiling(n * 0 / max_weight) = 0; threshold = min_abs = 3
  expect_true(autumn:::collapse_threshold(0L, 0.0, 100L, 5))
  expect_true(autumn:::collapse_threshold(2L, 0.0, 100L, 5))
  expect_false(autumn:::collapse_threshold(3L, 0.0, 100L, 5))
})

test_that("collapse_threshold: max_weight=0 produces Inf cap_floor (always collapses)", {
  # ceiling(n * p_k / 0) = Inf; n_k < Inf is always TRUE for finite n_k
  # This documents the behaviour for an invalid caller — collapse_threshold
  # is @keywords internal and relies on harvest() to validate max_weight > 0.
  expect_true(autumn:::collapse_threshold(999L, 0.5, 100L, 0))
})
