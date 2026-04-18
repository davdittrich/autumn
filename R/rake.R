#' Adjust weights based on current imbalance of a single variable.
#'
#' This function internally rakes the weights provided according to the
#' current imbalance in a single variable. When \code{max_weight} is finite,
#' bounded redistribution (water-filling) is used: rows that would exceed the
#' cap are set to \code{max_weight} and the remaining mass is redistributed
#' proportionally among uncapped rows in the same cell. This preserves the
#' per-cell calibration equation \eqn{\sum w_i^{(k)} = t_k \cdot W} exactly
#' for feasible cells (Deville-Sarndal truncated-linear distance). When
#' \code{max_weight = Inf}, behaviour is identical to multiplicative IPF.
#'
#' @param weights The current weights
#' @param target The target proportions, specified as in \code{\link{harvest}}
#' @param var A quoted character vector containing the variable we are currently
#'   raking on.
#' @param cache The pre_cache list from \code{do_rake}: each entry is a list
#'   with \code{x} (factor column), \code{idx} (integer level indices),
#'   \code{na_rows} (NA + OOV row positions), and \code{cell_rows} (list of
#'   row-index vectors, one per target level).
#' @param max_weight Scalar maximum weight. When finite, bounded redistribution
#'   is applied within each cell. Default \code{Inf} (unbounded).
#' @return A list with: \code{weights} (adjusted weight vector) and
#'   \code{max_dev} (max relative deviation of current from target before
#'   adjustment — used by \code{do_rake} for adaptive variable ordering).
#' @keywords internal
single_adjust = function(weights, target, var, cache, max_weight = Inf) {
  # Precondition: all weights must be non-negative. SQUAREM's step-halving
  # (harvest.R: pmax(w_star, .Machine$double.eps)) enforces this upstream;
  # the water-filling loop below would silently mis-calibrate on negative inputs.
  current = weighted_pct(cache[[var]]$x, weights)[names(target[[var]])]

  # max_dev: scalar imbalance measure before this adjustment.
  max_dev = max(abs(target[[var]] / current - 1), na.rm = TRUE)

  if (!is.finite(max_weight)) {
    # ── Unbounded path: original vectorised IPF ──────────────────────────────
    mult = unname(target[[var]] / current)[cache[[var]]$idx]
    mult[cache[[var]]$na_rows] = 1
    return(list(weights = weights * mult, max_dev = max_dev))
  }

  # ── Bounded path: water-filling redistribution per cell ───────────────────
  # For each cell k: target weight-sum T_k = target[k] * W (W = total weight,
  # denominator used by weighted_pct). Rows that would exceed max_weight are
  # clamped at max_weight; remaining target is redistributed proportionally to
  # unclamped rows. Iteration converges in ≤ K steps (one row clamped per step).
  #
  # Properties guaranteed:
  #   sum(new_w[cell_k]) = T_k  for feasible cells (T_k <= n_k * max_weight)
  #   new_w[i] <= max_weight    for all i in defined cells
  #   new_w[na_rows] unchanged  (OOV and NA rows not in any cell_rows[[k]])
  W     = sum(weights)
  new_w = weights   # copy; updated per cell; na_rows left at original values

  K = length(target[[var]])
  for (k in seq_len(K)) {
    cell_idx = cache[[var]]$cell_rows[[k]]
    if (length(cell_idx) == 0L) next

    T_k          = target[[var]][k] * W   # target weight-sum for this cell
    cell_w       = weights[cell_idx]      # ORIGINAL weights (not new_w) — ensures
                                          # all cells share the same pre-adjustment
                                          # baseline (simultaneous update semantics)
    free_local   = seq_along(cell_w)      # local indices into cell_w
    clamped_mass = 0                      # weight already assigned to clamped rows

    for (.iter in seq_len(length(cell_w) + 1L)) {  # +1L: one extra pass for the final uniform-m apply
      S_free = sum(cell_w[free_local])
      if (S_free <= .Machine$double.eps) break    # no free weight remains
      T_free = T_k - clamped_mass
      if (T_free <= 0) break                      # all mass accounted for
      m = T_free / S_free
      if (m <= 0) break

      newly_clamped = free_local[cell_w[free_local] * m > max_weight]
      if (length(newly_clamped) == 0L) {
        # No new clamps — apply uniform multiplier m to all free rows
        cell_w[free_local] = cell_w[free_local] * m
        break
      }
      # Clamp newly-clamped rows and update accounting
      cell_w[newly_clamped] = max_weight
      clamped_mass          = clamped_mass + length(newly_clamped) * max_weight
      free_local            = setdiff(free_local, newly_clamped)
      if (length(free_local) == 0L) break   # all rows clamped — infeasible cell
    }

    new_w[cell_idx] = cell_w
  }

  list(weights = new_w, max_dev = max_dev)
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
#' @param max_weight The maximum weight to cap at. When finite, bounded
#'   redistribution is used within each IPF step so that per-cell calibration
#'   equations are satisfied simultaneously with the weight cap (water-filling).
#'   When \code{Inf} (no cap), standard multiplicative IPF is used. See
#'   \code{\link{single_adjust}} for the algorithm.
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
    K     = length(levels(f))
    list(
      x         = f,                      # factor column — fast rowsum
      idx       = codes,                  # integer indices into target[[variable]]
      na_rows   = which(is.na(codes)),    # NA + OOV rows get multiplier 1
      # cell_rows[[k]]: integer vector of row positions belonging to level k.
      # Built once; used by bounded redistribution in single_adjust() when
      # max_weight is finite. O(N*K) total but K<=100 in practice; negligible
      # vs per-iteration cost.
      cell_rows = lapply(seq_len(K), function(k) which(codes == k))
    )
  })
  names(pre_cache) = names(target)

  # one_pass: apply one full sweep over all V raking variables.
  # Used by both the standard loop and the SQUAREM accelerator.
  one_pass = function(w) {
    for(j in rake_order) {
      if(verbose > 2) message("  Raking variable: ", j)
      result     = single_adjust(w, target, j, pre_cache, max_weight)
      w          = result$weights
      var_dev[j] <<- result$max_dev
    }
    if(adaptive_order) rake_order <<- names(target)[order(var_dev, decreasing = TRUE)]
    # Bounded redistribution inside single_adjust() now enforces max_weight during
    # the IPF step, making the mid-iteration pmin() clamp + enforce_mean rescale
    # redundant. When max_weight = Inf the clamp was already a no-op (condition
    # max(w) > Inf never fires). Removing the block prevents the enforce_mean
    # rescaling from pushing weights back above max_weight after redistribution.
    w
  }

  if(accelerate) {
    # SQUAREM SqS3 acceleration (Varadhan & Roland 2008).
    # Each super-step: 2 rake passes to build CBB extrapolation, 1 stabilisation pass.
    # Reduces ~500 standard iterations to ~30 super-steps for high-imbalance data.
    squarem_wu_old = Inf   # previous super-step weight_update_sum for pct-with-floor
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

      # Convergence checks.
      if(weight_update_sum < convergence[["absolute"]]) {
        if(verbose > 1) message("Convergence (SQUAREM absolute criterion).")
        break
      }

      # pct criterion: mirrors standard IPF — exit when weight_update_sum stops
      # improving by more than pct per super-step (or increases). Standard IPF
      # exits on the first WUS oscillation (~step 5 for ns_target); SQUAREM exits
      # similarly (~step 3). Both give partial convergence for bounded problems.
      # Safety for single-variable calibration (test-rake.R:171): v_sq = 0 fires
      # at line 219 and breaks BEFORE this block.
      if("pct" %in% names(convergence) &&
         weight_update_sum > squarem_wu_old * (1 - convergence[["pct"]])) {
        if(verbose > 1) message("Convergence (SQUAREM pct criterion).")
        break
      }
      squarem_wu_old = weight_update_sum
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

  # Return weights.
  # NOTE: no final clamp here. Bounded redistribution inside single_adjust()
  # enforces max_weight for all defined-cell rows during each IPF step.
  # OOV and NA rows are never inside any cell_rows[[k]] and must not be
  # clamped — pmin() is blind to row membership and would incorrectly cap them.
  # The old hard clamp + enforce_mean rescale have both been removed; neither
  # is needed and both cause incorrect results when max_weight is finite.
  weights
}
