# Tests for method="calibrate" (K-dim dual Newton) and harvest() API changes.
# calibrate_weights() unit tests are added in subsequent tasks.

test_that("method='nr' removed: harvest throws informative error", {
  expect_error(
    harvest(respondent_data, ns_target, method = "nr", attach_weights = FALSE),
    regexp = "method.*nr.*removed",
    ignore.case = TRUE
  )
})

test_that("min_weight > 0 with method='rake' warns", {
  expect_warning(
    harvest(respondent_data, ns_target, min_weight = 0.5, attach_weights = FALSE),
    regexp = "min_weight.*ignored",
    ignore.case = TRUE
  )
})
