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

# ── calibrate_weights() unit tests ──────────────────────────────────────────

# Helper: compute marginal error for a single variable
marginal_error <- function(data_col, levels, weights, target_prop) {
  f   <- factor(data_col, levels = levels)
  pct <- weighted_pct(f, weights)
  pct <- pct[names(target_prop)]
  pct[is.na(pct)] <- 0
  max(abs(pct - target_prop))
}

# Build X and targets_adj from respondent_data / ns_target for reuse.
# vars: subset of names(target) to calibrate on. Defaults to all variables.
# targets_adj = targets_prop (no OOV scaling) — unit-tests algorithm only.
make_calibrate_inputs <- function(data   = respondent_data,
                                  target = ns_target,
                                  vars   = names(target),
                                  d      = NULL) {
  target <- target[vars]
  in_scope <- Reduce("&", lapply(names(target), function(v) {
    !is.na(factor(data[[v]], levels = names(target[[v]])))
  }))
  n_inscope <- sum(in_scope)

  target_vars  <- names(target)
  data_factors <- data[in_scope, target_vars, drop = FALSE]
  for (v in target_vars)
    data_factors[[v]] <- factor(data_factors[[v]], levels = names(target[[v]]))

  carg <- lapply(target_vars, function(v)
    contrasts(data_factors[[v]], contrasts = FALSE))
  names(carg) <- target_vars
  X <- model.matrix(~ . - 1, data = data_factors, contrasts.arg = carg)

  targets_prop <- unlist(lapply(target_vars, function(v)
    setNames(target[[v]], paste0(v, names(target[[v]])))))
  targets_adj  <- targets_prop   # no OOV scaling: unit-tests algorithm only
  names(targets_adj) <- colnames(X)

  list(
    X           = X,
    d           = if (is.null(d)) rep(1, n_inscope) else d,
    targets_adj = targets_adj,
    in_scope    = in_scope,
    vars        = target_vars
  )
}

test_that("calibrate_weights raking (unbounded) achieves < 1e-4 marginal error on ns_target", {
  inp <- make_calibrate_inputs()
  w   <- calibrate_weights(inp$X, inp$d, inp$targets_adj,
                           min_weight = 0, max_weight = Inf)
  expect_true(all(is.finite(w)), label = "finite weights")
  expect_equal(mean(w), 1, tolerance = 1e-9, label = "mean = 1")

  data_is <- respondent_data[inp$in_scope, ]
  for (v in names(ns_target)) {
    err <- marginal_error(data_is[[v]], names(ns_target[[v]]),
                          w, ns_target[[v]])
    expect_true(err < 1e-4, label = paste0("marginal error for ", v))
  }
})

# Logit tests use gender+age only: raking weights in [0.66, 1.86], so
# max_weight=5 and min_weight=0.5 are both feasible for this subset.
test_that("calibrate_weights logit (max_weight=5) achieves < 1e-4 marginal error, respects bounds", {
  inp <- make_calibrate_inputs(vars = c("gender", "age"))
  w   <- calibrate_weights(inp$X, inp$d, inp$targets_adj,
                           min_weight = 0, max_weight = 5)
  expect_true(all(is.finite(w)), label = "finite weights")
  expect_equal(mean(w), 1, tolerance = 1e-9, label = "mean = 1")
  expect_true(max(w) <= 5 + 1e-9, label = "max weight <= 5")
  expect_true(min(w) >= 0 - 1e-9, label = "min weight >= 0")

  data_is <- respondent_data[inp$in_scope, ]
  for (v in inp$vars) {
    err <- marginal_error(data_is[[v]], names(ns_target[[v]]),
                          w, ns_target[[v]])
    expect_true(err < 1e-4, label = paste0("marginal error for ", v))
  }
})

test_that("calibrate_weights logit respects min_weight = 0.5", {
  inp <- make_calibrate_inputs(vars = c("gender", "age"))
  w   <- calibrate_weights(inp$X, inp$d, inp$targets_adj,
                           min_weight = 0.5, max_weight = 5)
  expect_true(min(w) >= 0.5 - 1e-9, label = "min weight >= 0.5")
  expect_true(max(w) <= 5 + 1e-9,   label = "max weight <= 5")
})

test_that("calibrate_weights pathological (max_weight=1.5): no error, bounds respected, error < 0.10", {
  # gender+age raking max ~ 1.86: mildly infeasible with max_weight=1.5
  inp <- make_calibrate_inputs(vars = c("gender", "age"))
  w   <- expect_no_error(
    calibrate_weights(inp$X, inp$d, inp$targets_adj,
                      min_weight = 0, max_weight = 1.5)
  )
  expect_true(all(is.finite(w)), label = "finite weights")
  expect_true(max(w) <= 1.5 + 1e-9, label = "max weight <= 1.5")

  data_is <- respondent_data[inp$in_scope, ]
  for (v in inp$vars) {
    err <- marginal_error(data_is[[v]], names(ns_target[[v]]),
                          w, ns_target[[v]])
    expect_true(err < 0.10, label = paste0("marginal error < 0.10 for ", v))
  }
})

test_that("calibrate_weights ridge solve handles rank-deficient X (one column = linear combo)", {
  inp <- make_calibrate_inputs()
  X2  <- cbind(inp$X, redundant = inp$X[, 1] + inp$X[, 2])
  t2  <- c(inp$targets_adj, redundant = 0)
  w <- expect_no_error(
    calibrate_weights(X2, inp$d, t2, min_weight = 0, max_weight = Inf)
  )
  expect_true(all(is.finite(w)), label = "finite weights despite rank deficiency")
  expect_equal(mean(w), 1, tolerance = 1e-6, label = "mean approx 1")
})

test_that("calibrate_weights emits non-convergence warning when max_iter=1", {
  inp <- make_calibrate_inputs()
  expect_warning(
    w <- calibrate_weights(inp$X, inp$d, inp$targets_adj,
                           min_weight = 0, max_weight = Inf, max_iter = 1),
    regexp = "did not converge",
    ignore.case = TRUE
  )
  expect_true(all(is.finite(w)), label = "returned weights are finite despite non-convergence")
  expect_true(mean(w) > 0,       label = "returned weights are positive")
})
