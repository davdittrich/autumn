context("test-weighted_pct")

test_that("unweighted case", {
  x = c(rep("x", 5), rep("y", 15))
  weights = rep(1, 20)
  result = weighted_pct(x, weights)
  expect_true(all.equal(unname(result), c(0.25, 0.75)))
  expect_equal(names(result), c("x", "y"))
})

test_that("weighted case", {
  x = c(rep("x", 5), rep("y", 15))
  weights = c(rep(3, 5), rep(1, 15))
  result = weighted_pct(x, weights)
  expect_true(all.equal(unname(result), c(0.5, 0.5)))
  expect_equal(names(result), c("x", "y"))
})

test_that("NA values in x are excluded from all groups", {
  x       = c("a", "b", NA, "a", "b")
  weights = c(1,   1,   1,  1,   1 )
  result  = weighted_pct(x, weights)
  # NA row's weight does NOT contribute to any named group's sum.
  # Groups: "a" = 2, "b" = 2. Denominator = sum(all weights) = 5.
  # Proportions: a = 2/5 = 0.4, b = 2/5 = 0.4 (matches split() behavior)
  expect_equal(unname(result), c(0.4, 0.4))
  expect_equal(names(result), c("a", "b"))
  # NA group must not appear in output (rownames from rowsum() can be
  # NA_character_, so use is.na() not string comparison)
  expect_false(any(is.na(names(result))))
})

test_that("NA weights are excluded from sums when na.rm=TRUE", {
  x       = c("a", "b", "a")
  weights = c(2,   1,   NA)
  result  = weighted_pct(x, weights)
  # Only non-NA weights count: "a" = 2, "b" = 1, total = 3
  expect_equal(unname(result), c(2/3, 1/3))
  expect_equal(names(result), c("a", "b"))
})

test_that("factor x produces same result as character x", {
  x_char   = c("a", "b", "a", "b", "b")
  x_factor = factor(x_char)
  weights  = c(1, 2, 3, 4, 5)
  expect_equal(weighted_pct(x_char, weights),
               weighted_pct(x_factor, weights))
})

test_that("factor x with non-alphabetical levels returns correct proportions by name", {
  # Factor levels in reverse alpha order — rowsum may order differently than
  # character input, but downstream code always subscripts by name, so values
  # must match regardless of order.
  x_char   = c("b", "a", "b", "a", "a")
  x_factor = factor(x_char, levels = c("b", "a"))  # non-alphabetical
  weights  = c(1, 2, 3, 4, 5)
  res_char   = weighted_pct(x_char, weights)
  res_factor = weighted_pct(x_factor, weights)
  # Values must match by name, regardless of output order
  expect_equal(res_char[["a"]], res_factor[["a"]])
  expect_equal(res_char[["b"]], res_factor[["b"]])
})
