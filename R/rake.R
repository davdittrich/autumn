#' Adjust weights based on current imbalance of a single variable.
#'
#' This function internally rakes the weights provided according to the
#' current imbalance in a single variable. The mathematical process here is
#' simple: for each level of the variable, multiply the weight by the target
#' proportion divided by the current weighted proportion. For instance, if a
#' \code{party} variable should be 0.4 Independent, 0.35 Democratic, and 0.25
#' Republican, and the current weighted proportion is 0.4 Democratic, then the
#' weights of every Democrat will be multiplied by 0.35 / 0.4. This is an
#' internal function and not intended for end-users.
#'
#' @param weights The current weights
#' @param target The target proportions, specified as in \code{\link{harvest}}
#' @param var A quoted character vector containing the variable we are currently
#'   raking on.
#' @param cache The pre_cache list from \code{do_rake}: each entry is a list
#'   with \code{x} (factor column), \code{idx} (integer level indices), and
#'   \code{na_rows} (NA + OOV row positions).
#' @return A list with: \code{weights} (adjusted weight vector) and
#'   \code{max_dev} (max relative deviation of current from target before
#'   adjustment — used by \code{do_rake} for adaptive variable ordering).
#' @keywords internal
single_adjust = function(weights, target, var, cache) {
  # Get the current weight balance in the population.
  # cache[[var]]$x is a pre-converted factor — rowsum() uses integer codes
  # instead of per-call string hashing (see bench/results.md for measured speedup).
  current = weighted_pct(cache[[var]]$x, weights)[names(target[[var]])]

  # max_dev: scalar imbalance measure before this adjustment.
  # Used by do_rake() for adaptive variable ordering.
  # max(|target/current - 1|) = max relative deviation from target.
  max_dev = max(abs(target[[var]] / current - 1), na.rm = TRUE)

  # Multiply each row's weight by target / current for its category.
  # cache[[var]]$idx: integer level index for each row (from as.integer(factor)).
  # NA and OOV rows have idx = NA_integer_, so mult[NA] = NA.
  mult = unname(target[[var]] / current)[cache[[var]]$idx]

  # NA and OOV rows get multiplier 1 (weight unchanged).
  # Covers: actual NA in data AND out-of-vocabulary values absent from target.
  mult[cache[[var]]$na_rows] = 1

  # max_dev is pre-adjustment: reflects the imbalance that *caused* the ordering
  # decision for this variable, not the post-correction state. Zero-count levels
  # produce Inf (non-zero target / 0 current) — Inf is correct (variable maximally
  # off-target) and safe (those categories have no rows so no weight becomes Inf).
  # 0/0 levels produce NaN (dropped by na.rm=TRUE, equivalent to a 0 contribution
  # since they are at target). Both cases handled correctly.
  list(weights = weights * mult, max_dev = max_dev)
}

#' Clamp weights to a maximum weight
#'
#' @param weights Current vector of weights
#' @param clamp A scalar maximum weight
#' @return A vector of clamped weights
#' @keywords internal
clamp_weights_top = function(weights, clamp) {
  # Parallel minimum: if a weight is above the maximum, clamp it down.
  # pmin is faster than other options; copying the vector and overwriting
  # using a subset is somewhat faster but allocates much more memory.
  pmin(weights, clamp)
}

#' Performs iterative raking on data
#'
#' This function performs iterative raking as described in DeBell and Krosnick
#' (2009). It is a private function and not intended for end-users. End-users
#' should call \code{\link{harvest}} to add weights.
#'
#' @param data The data frame (tibble) or matrix containing the original data
#' @param target The target proportions, specified as in \code{\link{harvest}}
#' @param weights A numeric vector of current weights
#' @param max_weight The maximum weight to clamp weights to after raking each
#'   variable
#' @param max_iterations The maximum number of iterations of raking to perform
#'   before giving up. Please note that depending on the variable selection
#'   method, \code{\link{harvest}} may continue iterative raking on new
#'   variables after completing the iterations of this function call.
#' @param convergence Convergence parameters as described in
#'   \code{\link{harvest}}.
#' @param verbose Level of verbosity, defaults to FALSE. At TRUE or 1, the
#'   function begins emitting progress information during major events. At 2,
#'   each iteration provides progress information.
#' @inheritParams harvest
#' @return A numeric vector of adjusted, raked weights.
#' @keywords internal
do_rake = function(data, target, weights,
                   max_weight, max_iterations, convergence,
                   enforce_mean = TRUE,
                   adaptive_order = FALSE,
                   accelerate = FALSE,
                   verbose) {
  # Get current time
  base_time = Sys.time()

  # Pocket algorithm: we want to start this with a very high value
  weight_update_sum = 1e9

  # weight_update_old: previous-iteration update sum (pct convergence criterion).
  # Updated each standard IPF iteration; never updated by SQUAREM (which omits pct).
  # Initialized here so the partial-convergence warning never references an undefined var.
  weight_update_old = NA_real_

  # Adaptive ordering state: rake_order is the variable sequence for each
  # iteration. var_dev tracks max relative deviation per variable from the
  # previous iteration and is used to reorder for the next.
  rake_order = names(target)
  var_dev    = setNames(rep(Inf, length(names(target))), names(target))

  # In the actual raking, we're going to get multipliers for each level of
  # a given target variable. So, for instance, we decide that "LLCs" get a
  # multiplier of 2, and "S-Corps" get a multiplier of 0.4 and ... -- now we
  # need to map those multipliers to rows. We do this by seeing which rows are
  # each thing by sgtring matching. But for a few reasons, doing this lookup
  # is only fast if the columns of the data frame are all factors. We can
  # avoid paying this cost by pre-caching it across all iterations.
  pre_cache = lapply(names(target), function(variable) {
    # Convert to factor once: one O(n) string scan at pre-cache time.
    # All subsequent per-iteration lookups use integer codes — O(1) per
    # element vs O(n) string hashing on every call. Levels order matches
    # names(target[[variable]]) exactly, so as.integer(f) gives the same
    # index as match(data[[variable]], names(target[[variable]])) but via
    # integer comparison rather than string comparison.
    # OOV values (valid strings not in target) become NA_integer_ in the
    # factor codes, so which(is.na(codes)) captures both NA and OOV rows —
    # fixes autumn-7m3 (OOV rows previously produced NA mult -> NA weights).
    f = factor(data[[variable]], levels = names(target[[variable]]))
    codes = as.integer(f)
    list(
      x       = f,                      # factor column — fast rowsum
      idx     = codes,                  # integer indices into target[[variable]]
      na_rows = which(is.na(codes))     # NA + OOV rows get multiplier 1
    )
  })
  names(pre_cache) = names(target)

  # one_pass: apply one full sweep over all V raking variables.
  # Used by both the standard loop and the SQUAREM accelerator.
  one_pass = function(w) {
    for(j in rake_order) {
      if(verbose > 2) message("  Raking variable: ", j)
      result     = single_adjust(w, target, j, pre_cache)
      w          = result$weights
      var_dev[j] <<- result$max_dev   # update parent-env var_dev for ordering
    }
    if(adaptive_order) rake_order <<- names(target)[order(var_dev, decreasing = TRUE)]
    # Clamp weights if necessary.
    # 1e-4: floating point tolerance; prevents spurious clamp on weights that
    # are marginally above max_weight due to floating point arithmetic.
    if(max(w) > max_weight + 1e-4) {
      if(verbose > 1) message("  Clamping weights.")
      w = clamp_weights_top(w, max_weight)
      if(enforce_mean) w = w / (sum(w) / length(w))
    }
    w
  }

  if(accelerate) {
    # SQUAREM SqS3 acceleration (Varadhan & Roland 2008).
    # Each super-step: 2 rake passes to build CBB extrapolation, 1 stabilisation pass.
    # Reduces ~500 standard iterations to ~30 super-steps for high-imbalance data.
    for(i in seq_len(max_iterations)) {
      old_weights = weights

      # Snapshot rake_order before the super-step so both F(w) and F(F(w))
      # apply the SAME variable ordering. SQUAREM's convergence proof requires
      # a stationary operator F; if adaptive_order=TRUE, one_pass() would mutate
      # rake_order after the first call and the second call would use a different
      # order — violating the stationary-F assumption.
      saved_rake_order = rake_order

      w1 = one_pass(weights)             # F(x_k) — may update rake_order
      rake_order = saved_rake_order      # restore: F(F(x_k)) must use same F
      w2 = one_pass(w1)                  # F(F(x_k))

      r = w1 - weights             # one-step residual
      v = w2 - w1                  # second residual: v = F(F(x)) - F(x)

      r_sq = sum(r * r)
      v_sq = sum(v * v)

      if(v_sq < .Machine$double.eps) {
        # v ≈ 0 means one pass was already exact; accept w2.
        weights = w2
        weight_update_sum = 0
        break
      }

      # CBB step length (always <= 0: extrapolate in the direction of r).
      alpha = -sqrt(r_sq / v_sq)
      alpha = max(alpha, -1000)    # cap prevents blow-up on first super-step

      # Extrapolated iterate with step-halving safeguard.
      # Standard SQUAREM step-halving (Varadhan & Roland 2008, Section 3.3):
      # halve alpha toward -1 until the residual norm of the stabilised iterate
      # is no worse than the plain second step (w2). This prevents weight death
      # (near-zero weights from over-extrapolation) and ensures the fixed-point
      # matches the IPF fixed-point.
      # alpha = -1 corresponds to the plain un-accelerated second step w2.
      plain_resid = sum((w2 - w1)^2)   # residual norm at plain step
      alpha_step = alpha
      weights_new = w2                  # default: use plain step
      for(.half in seq_len(16)) {       # at most 16 halvings (alpha -> -1 within 2^16)
        w_star = weights - 2 * alpha_step * r + alpha_step^2 * v
        w_star = pmax(w_star, .Machine$double.eps)
        w_cand = one_pass(w_star)
        cand_resid = sum((w_cand - w_star)^2)
        if(cand_resid <= plain_resid * 1.01) {
          weights_new = w_cand
          break
        }
        # Halve alpha_step toward -1 (plain step).
        # Interpolation: alpha_{k+1} = (alpha_k + (-1)) / 2
        alpha_step = (alpha_step + (-1)) / 2
        if(abs(alpha_step - (-1)) < 1e-3) {
          weights_new = w2   # fell back to plain step
          break
        }
      }
      weights = weights_new

      weight_update_sum = sum(abs(weights - old_weights))

      if(verbose > 1) {
        message("SQUAREM super-step ", i,
                " (alpha=", round(alpha, 4),
                ", weight_update=", round(weight_update_sum, 6), ")")
      }

      # Convergence checks (same criteria as standard loop, but no pct —
      # pct compares successive IPF iterations and is meaningless across
      # multi-IPF super-steps).
      if(weight_update_sum < convergence[["absolute"]]) {
        if(verbose > 1) message("Convergence (SQUAREM absolute criterion).")
        break
      }
      if("single_weight" %in% names(convergence) &&
         max(abs(weights - old_weights)) < convergence[["single_weight"]]) {
        if(verbose > 1) message("Convergence (SQUAREM single_weight criterion).")
        break
      }
      if("time" %in% names(convergence) &&
         !is.null(convergence[["time"]]) &&
         (difftime(Sys.time(), base_time, units = "secs") > convergence[["time"]])) {
        break
      }
    }

  } else {
    # Standard Gauss-Seidel IPF (existing behaviour, preserved exactly).
    for(i in seq_len(max_iterations)) {
      # Let the user know we're starting the iteration, and if it's not the first,
      # how much the weights changed since last time.
      if(verbose > 1) {
        message("Beginning iteration ", i,
                ifelse(i > 1,
                       paste0(" (total weight update: ", weight_update_sum, ")"),
                       ""))
      }

      # We need this to benchmark how much the weights change
      old_weights = weights

      # Rake each variable using one_pass helper (respects rake_order).
      weights = one_pass(weights)

      # If there's only one variable in the rake set, it is by definition raked
      # after a single iteration
      if(length(target) == 1) {
        if(verbose > 1) message("  Single variable rake is exactly correct.")
        weight_update_sum = 0
        break
      }

      # Assess whether the weights are changing or stable.
      weight_update_old  = weight_update_sum
      weight_update_sum  = sum(abs(weights - old_weights))

      # The amount the weights updated are too close to the amount the weights
      # updated last time, so we've converged.
      if(weight_update_sum > weight_update_old * (1 - convergence[["pct"]])) {
        if(verbose > 1) {
          message("Convergence at iteration ", i, " based on weight update > ",
                  (100 * (1 - convergence["pct"])), "% of previous iteration.")
        }
        break
      }

      # The weights have barely updated, let's finish faster
      if(weight_update_sum < convergence[["absolute"]]) {
        if(verbose > 1) {
          message("Convergence based on total weight update < ",
                  sprintf("%.8f", convergence[["absolute"]]))
        }
        break
      }

      # The weights have barely updated, let's finish faster.
      if("single_weight" %in% names(convergence) &&
         max(abs(weights - old_weights)) < convergence[["single_weight"]]) {
        if(verbose > 1) {
          message("Convergence based on max weight update < ",
                  sprintf("%.8f", convergence[["single_weight"]]))
        }
        break
      }

      # If user specified a timeout, timeout the raking process.
      if("time" %in% names(convergence) &&
         !is.null(convergence[["time"]]) &&
         (difftime(Sys.time(), base_time, units = "secs") > convergence[["time"]])) {
        break
      }
    }
  }

  # Note to the user if the weights were still in a state of flux when
  # we stopped processing -- versus ANESrake, this warning is based on the
  # overall length of the weights, since something with more observations
  # can have more updating with relatively speaking substantive impact.
  if(weight_update_sum > 0.001 * length(weights)) {
    warning("Partial convergence only after ", i, " iterations: ",
            weight_update_sum,
            if(!is.na(weight_update_old)) paste0(" / ", weight_update_old) else "")
  }

  # Return weights
  weights
}
