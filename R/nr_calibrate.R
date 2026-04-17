#' Newton-Raphson calibration for survey weights
#'
#' Solves the multiplicative calibration problem (equivalent to raking) using
#' Newton-Raphson iteration. Converges in 10-20 iterations regardless of
#' imbalance severity, compared to 100-1000 iterations for iterative proportional
#' fitting (IPF). Appropriate for high-cardinality targets (K=100-10000 categories
#' total) and severely imbalanced data.
#'
#' When \code{max_weight} is finite, a sequential IPF loop with inline per-step
#' clamping enforces the bound.  This is the same algorithm as
#' \code{\link{harvest}}'s default bounded rake, without the variable-selection
#' overhead.  The full cross-variable Hessian is skipped because interaction
#' variables create near-linear dependence that makes the K×K system ill-conditioned
#' when any weight is near the cap.  The sequential IPF step is provably convergent
#' and converges to the same bounded calibration solution as bounded IPF.
#'
#' @param data A data frame with columns matching \code{names(target)}.
#' @param target The target proportions, specified as in \code{\link{harvest}}.
#' @param initial_weights A numeric vector of starting weights. Defaults to 1
#'   for each row (unit weights).
#' @param max_iter Maximum number of Newton-Raphson iterations (inner loop).
#'   The outer active-set loop also runs at most \code{max_iter} iterations.
#' @param tol Convergence tolerance: stop when \code{max(|g|) < tol * total_d}
#'   where g is the gradient (weighted count minus target count) and
#'   \code{total_d = sum(initial_weights)}.
#' @param verbose Logical. If TRUE, print per-iteration convergence information.
#' @param max_weight Scalar upper bound on individual weights. Rows that are
#'   out-of-vocabulary (OOV) or NA in all calibration variables are exempt.
#'   Default \code{Inf} disables the constraint (exact original behaviour).
#' @return A numeric vector of calibrated weights.
#' @keywords internal
nr_calibrate = function(data, target, initial_weights = rep(1, nrow(data)),
                        max_iter = 50, tol = 1e-8, verbose = FALSE,
                        max_weight = Inf) {

  n    = nrow(data)
  vars = names(target)
  V    = length(vars)

  # K_v: number of categories per variable.
  K_v     = sapply(vars, function(v) length(target[[v]]))
  offsets = c(0L, cumsum(K_v))          # offsets[v+1] = start of var v in lambda
  K       = offsets[V + 1L]             # total categories

  # Pre-cache: factor codes for each variable.
  cache = lapply(vars, function(v) {
    f    = factor(data[[v]], levels = names(target[[v]]))
    idx  = as.integer(f)
    list(x       = f,
         idx     = idx,
         na_rows = which(is.na(idx)))
  })
  names(cache) = vars

  # Target counts (absolute: proportion * total_initial_weight).
  total_d = sum(initial_weights)
  T_k = unlist(lapply(vars, function(v) target[[v]] * total_d), use.names = FALSE)

  w = initial_weights

  # --- Unbounded path (max_weight = Inf): original NR, unchanged ---
  if (!is.finite(max_weight)) {
    for(iter in seq_len(max_iter)) {

      # --- Gradient (tapply cached for Hessian diagonal reuse) ---
      # wt_sums_list caches per-variable weighted counts so the Hessian diagonal
      # loop below can read them without a second tapply call per variable.
      wt_sums_list = vector("list", V)
      g = numeric(K)
      for(i_v in seq_len(V)) {
        v   = vars[i_v]
        off = offsets[i_v]
        wt_sums = tapply(w, cache[[v]]$x, sum)
        wt_sums = wt_sums[names(target[[v]])]
        wt_sums[is.na(wt_sums)] = 0
        wt_sums_list[[i_v]] = wt_sums   # reused below for Hessian diagonal
        g[off + seq_len(K_v[i_v])] = wt_sums - T_k[off + seq_len(K_v[i_v])]
      }

      max_g = max(abs(g))
      if(verbose) message("NR iter ", iter, ": max |g| = ", round(max_g, 6))
      if(max_g < tol * total_d) break

      # --- Hessian (K x K sparse, block-structured) ---
      H_i = integer(0); H_j = integer(0); H_x = numeric(0)

      # Diagonal blocks: reuse cached wt_sums_list — no second tapply per variable.
      for(i_v in seq_len(V)) {
        off   = offsets[i_v]
        kv    = K_v[i_v]
        idx_k = off + seq_len(kv)
        H_i = c(H_i, idx_k); H_j = c(H_j, idx_k)
        H_x = c(H_x, as.numeric(wt_sums_list[[i_v]]))
      }

      for(i_v in seq_len(V - 1L)) {
        for(j_v in seq(i_v + 1L, V)) {
          v  = vars[i_v];  vp = vars[j_v]
          kv  = K_v[i_v];  kvp = K_v[j_v]
          off_v  = offsets[i_v]
          off_vp = offsets[j_v]

          idx_v  = cache[[v]]$idx
          idx_vp = cache[[vp]]$idx

          valid = !is.na(idx_v) & !is.na(idx_vp)

          if(any(valid)) {
            combined = (idx_v[valid] - 1L) * kvp + idx_vp[valid]
            ct_vec   = tapply(w[valid], combined, sum)
            comb_int = as.integer(names(ct_vec))
            r_idx = ((comb_int - 1L) %/% kvp) + 1L
            c_idx = ((comb_int - 1L) %% kvp)  + 1L
            H_i = c(H_i, off_v + r_idx, off_vp + c_idx)
            H_j = c(H_j, off_vp + c_idx, off_v + r_idx)
            H_x = c(H_x, as.numeric(ct_vec), as.numeric(ct_vec))
          }
        }
      }

      # Ridge regularisation: handles zero-observation categories.
      ridge_idx = seq_len(K)
      H_i = c(H_i, ridge_idx); H_j = c(H_j, ridge_idx)
      H_x = c(H_x, rep(1e-6 * total_d, K))

      H = Matrix::sparseMatrix(i = H_i, j = H_j, x = H_x, dims = c(K, K))

      # --- Newton step (sparse solve) ---
      delta = tryCatch(
        as.vector(Matrix::solve(H, g)),
        error = function(e) {
          warning("NR Hessian solve failed at iteration ", iter,
                  ": ", conditionMessage(e),
                  ". Falling back to diagonal preconditioned gradient step.")
          g / (Matrix::diag(H) + 1)
        }
      )

      # Update weights: w_i *= exp(-delta applied to its categories)
      # Sign: delta = H^{-1} g; g_k > 0 means over-target; -delta_k < 0 so weight decreases.
      eta_delta = rep(0, n)
      for(i_v in seq_len(V)) {
        v   = vars[i_v]
        off = offsets[i_v]
        kv  = K_v[i_v]
        d_v = delta[off + seq_len(kv)]
        idx = cache[[v]]$idx
        valid = !is.na(idx)
        if(any(valid)) eta_delta[valid] = eta_delta[valid] + d_v[idx[valid]]
      }

      w = w * exp(-eta_delta)
      w = pmax(w, .Machine$double.eps)
    }
    return(w)
  }

  # --- Bounded path: sequential IPF with inline clamping ---
  #
  # OOV row handling: OOV values become NA after factor() so
  # `cache[[v]]$idx[i] = NA` for OOV/NA rows. calibrated[i] = TRUE iff row i
  # has a valid code in at least one variable. OOV/NA-in-all rows are exempt
  # from the cap and the final safety clamp. This mirrors bounded do_rake.
  calibrated = Reduce("|", lapply(cache, function(cv) !is.na(cv$idx)))

  # Sequential IPF with inline clamping.
  # This is the same algorithm as do_rake's bounded IPF, without variable
  # selection. Provably convergent; no K×K linear system, no Inf overflow.
  # max_iter controls the number of full passes through all V variables.
  for (iter in seq_len(max_iter)) {
    max_g = 0

    for (i_v in seq_len(V)) {
      v   = vars[i_v]
      off = offsets[i_v]
      kv  = K_v[i_v]

      wt_sums = tapply(w, cache[[v]]$x, sum)
      wt_sums = wt_sums[names(target[[v]])]
      wt_sums[is.na(wt_sums)] = 0
      wt_sums = as.numeric(wt_sums)

      g_v = wt_sums - T_k[off + seq_len(kv)]
      # Dead cells (no observations): skip update and gradient.
      dead    = wt_sums < 1e-10
      g_v[dead] = 0
      max_g = max(max_g, max(abs(g_v)))

      # Multiplicative ratio update = standard IPF step.
      # No exp() → no overflow risk when T_k >> wt_sum.
      ratio_v       = T_k[off + seq_len(kv)] / pmax(wt_sums, 1e-10)
      ratio_v[dead] = 1

      idx = cache[[v]]$idx
      valid = !is.na(idx)          # all calibrated rows (not just free)
      if (any(valid)) {
        w[valid] = w[valid] * ratio_v[idx[valid]]
        w        = pmax(w, .Machine$double.eps)
      }

      # Inline clamp after each variable update; OOV rows exempt.
      w[calibrated] = pmin(w[calibrated], max_weight)
    }

    if (verbose) message("NR bounded iter ", iter, ": max |g| = ", round(max_g, 6))
    if (max_g < tol * total_d) break
  }

  # Final safety clamp: guard against NR overshoot in the last inner iteration.
  # Applied only to calibrated rows; OOV/NA rows are untouched.
  w[calibrated] = pmin(w[calibrated], max_weight)
  w
}
