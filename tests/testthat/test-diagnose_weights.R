context("test-diagnose_weights")

test_that("initial error handling", {
  # Need a target variable
  rd2 = respondent_data
  expect_error(diagnose_weights(rd2))

  # Given a target attribute that doesn't resolve, this should error.
  attr(rd2, "target_symbol") = "invalid_symbol"
  expect_error(diagnose_weights(rd2))

  # Given a target variable, this should error because you also need a weight
  # variable
  attr(rd2, "target_symbol") = "ns_target"
  expect_error(diagnose_weights(rd2))

  # Bake weights into the DF
  rd2$weights = 1
  diagnostic_table = diagnose_weights(rd2)

  # Does it work with a df set of proportions?
  expect_equal(
    dim(diagnose_weights(respondent_data, list_targets_to_df(ns_target),
                         rd2$weights)),
    c(132, 7))

  # Produced a valid diagnostic table
  expect_equal(dim(diagnostic_table), c(132, 7))

  # Because we gave weights = 1, the error original and error_weighted should
  # be the same
  expect_equal(diagnostic_table$error_original,
               diagnostic_table$error_weighted)

  # The variables should be in the original order:
  expect_equal(unique(diagnostic_table$variable),
               names(ns_target))

  # The levels should be in the the correct order and equal
  expect_equal(diagnostic_table$target,
               unname(unlist(ns_target)))

  # Regression: when data has pre-existing 'weights' column, harvest() attaches
  # '.weights_autumn' (no number). diagnose_weights() must find it.
  data_preweight = respondent_data
  data_preweight$weights = 1  # pre-existing weights column
  result_w = harvest(data_preweight, ns_target)
  expect_true(".weights_autumn" %in% colnames(result_w))
  expect_no_error(diagnose_weights(result_w, ns_target))

})
