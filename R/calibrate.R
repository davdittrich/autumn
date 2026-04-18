#' K-dimensional dual Newton calibration
#'
#' Optimises K Lagrange multipliers \eqn{\lambda} so that weighted marginals
#' match population targets. Weights are derived as
#' \eqn{w_i = d_i \cdot F(\mathbf{x}_i^\top \lambda)} where \eqn{F} is either
#' the raking (exp) or logit (sigmoid) distance function.
#'
#' This is the same algorithm as \code{survey::grake} (Deville & Sarndal 1992).
#'
#' @param X n×K binary indicator matrix (in-scope rows only; OOV rows excluded).
#'   Columns named \code{paste0(variable, level)} as produced by
#'   \code{model.matrix(~ . - 1, ...)}.
#' @param d Length-n vector of design weights for in-scope rows (already
#'   normalised to mean=1 by \code{harvest()}).
#' @param targets_adj Length-K named vector of adjusted target proportions:
#'   \code{targets_prop * n_all / n_inscope}. Names must match \code{colnames(X)}.
#' @param min_weight Absolute lower bound on weights. Must be \eqn{\geq 0}.
#'   Only active when \code{max_weight < Inf} (logit path).
#' @param max_weight Absolute upper bound on weights. \code{Inf} uses raking
#'   distance (unbounded); finite value uses logit distance (bounded by
#'   construction).
#' @param max_iter Maximum Newton iterations.
#' @param pct Relative convergence threshold: stop when
#'   \code{max(|g_k| / targets_adj_k) < pct}.
#' @param absolute Absolute floor used in the convergence denominator to
#'   prevent division by zero when any \code{targets_adj_k == 0}.
#' @return Length-n weight vector for in-scope rows, normalised to mean=1.
#' @keywords internal
calibrate_weights <- function(X, d, targets_adj,
                               min_weight = 0, max_weight = Inf,
                               max_iter = 100, pct = 1e-3, absolute = 1e-4) {

  # ── Input validation ────────────────────────────────────────────────────────
  if (min_weight < 0)
    stop("min_weight must be >= 0")
  if (min_weight >= max_weight)
    stop("min_weight must be strictly less than max_weight")
  if (any(d <= 0))
    stop("design weights d must be strictly positive")

  n <- nrow(X)
  K <- ncol(X)

  bounded <- is.finite(max_weight)

  # ── Per-respondent logit bounds (only used when bounded) ────────────────────
  if (bounded) {
    L <- min_weight / d   # lower ratio
    U <- max_weight / d   # upper ratio

    # Shift eta so lambda=0 gives w_i = d_i (not midpoint(min,max)).
    # Avoids huge initial residual when starting weights deviate far from d.
    # plogis(eta_offset_i) = (d_i - min_weight) / (max_weight - min_weight).
    p0 <- pmin(pmax((d - min_weight) / (max_weight - min_weight), 1e-8), 1 - 1e-8)
    eta_offset <- qlogis(p0)
  }

  # ── Weight and Hessian-weight computation ───────────────────────────────────
  compute_w <- function(lam) {
    eta <- as.vector(X %*% lam)
    if (!bounded) {
      if (max(abs(eta)) > 600)
        warning("raking: large lambda magnitude, exp() approaching overflow")
      d * exp(eta)
    } else {
      d * (L + (U - L) * plogis(eta + eta_offset))
    }
  }

  compute_h <- function(w) {
    # h_i = dw_i/deta_i: the per-respondent Hessian weight.
    if (!bounded) {
      w   # raking: w = d*exp(eta), so dw/deta = w
    } else {
      # logit: dw/deta = d*(U-L)*p*(1-p) = (w/d-L)*(U-w/d)*d / (U-L)
      # Note: naive (w/d-L)*(U-w/d)*d is (U-L) times too large.
      (w / d - L) * (U - w / d) * d / (U - L)
    }
  }

  # ── Newton loop ─────────────────────────────────────────────────────────────
  lambda         <- rep(0, K)
  best_lambda    <- lambda
  best_err       <- Inf
  no_step_count  <- 0L

  for (iter in seq_len(max_iter)) {
    w   <- compute_w(lambda)
    g   <- colMeans(X * w) - targets_adj
    err <- max(abs(g) / pmax(targets_adj, absolute))
    if (err < pct) break

    h     <- compute_h(w)
    # Divide by n: g uses colMeans scale (O(1)), H must match.
    # X^T diag(h) X / n gives the correct scaled Hessian for the dual problem.
    H     <- crossprod(X * sqrt(pmax(h, 0)), X * sqrt(pmax(h, 0))) / n
    ridge <- 1e-6 * mean(diag(H))
    delta <- tryCatch(
      solve(H + ridge * diag(K), g),
      error = function(e) {
        warning("calibrate_weights: Hessian solve failed at iter ", iter,
                ": ", conditionMessage(e), ". Using gradient step.")
        g / (diag(H) + ridge)
      }
    )

    # For raking: cap step so exp() stays safe.
    # X %*% delta is the per-respondent eta change. If unbounded, accumulated
    # lambda causes exp() overflow across iterations. Cap to max |eta| = 4
    # (exp(4) ≈ 55), preserving Newton direction, ~3x convergence overhead.
    if (!bounded) {
      eta_step <- as.vector(X %*% delta)
      max_eta  <- max(abs(eta_step))
      if (max_eta > 4) delta <- delta * 4 / max_eta
    }

    # Step-halving: reject step if no improvement found after 20 halvings.
    # If step-halving fails, lambda is unchanged, making the next iteration
    # compute identical w/g/H/delta and fail again. Break after 2 consecutive
    # failures to avoid burning max_iter iterations on identical work.
    step     <- 1.0
    improved <- FALSE
    g_norm   <- sqrt(sum(g^2))
    for (.h in seq_len(20)) {
      lambda_cand <- lambda - step * delta
      g_cand      <- colMeans(X * compute_w(lambda_cand)) - targets_adj
      if (sqrt(sum(g_cand^2)) < g_norm) {
        lambda   <- lambda_cand
        improved <- TRUE
        break
      }
      step <- step / 2
    }

    if (!improved) {
      no_step_count <- no_step_count + 1L
      if (no_step_count >= 2L) break
    } else {
      no_step_count <- 0L
    }

    # Update best AFTER lambda is finalised for this iteration
    if (err < best_err) {
      best_err    <- err
      best_lambda <- lambda
    }
  }

  if (iter == max_iter && best_err >= pct) {
    warning(sprintf(
      paste0("calibrate_weights did not converge in %d iterations. ",
             "Max relative error: %.2e (threshold: %.2e)"),
      max_iter, best_err, pct
    ))
  }

  w_final <- compute_w(best_lambda)
  w_final <- w_final / mean(w_final)
  if (bounded) w_final <- pmax(min_weight, pmin(max_weight, w_final))
  w_final
}
