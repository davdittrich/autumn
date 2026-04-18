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
  }

  # ── Weight and Hessian-weight computation ───────────────────────────────────
  compute_w <- function(lam) {
    eta <- as.vector(X %*% lam)
    if (!bounded) {
      if (max(abs(eta)) > 600)
        warning("raking: large lambda magnitude, exp() approaching overflow")
      d * exp(eta)
    } else {
      d * (L + (U - L) * plogis(eta))
    }
  }

  compute_h <- function(w) {
    # h_i = dw_i/deta_i (Hessian diagonal weight per respondent)
    if (!bounded) {
      w   # raking: dw/deta = w
    } else {
      (w / d - L) * (U - w / d) * d   # logit: (sigma)(1-sigma)(U-L)^2 * d
    }
  }

  # ── Newton loop ─────────────────────────────────────────────────────────────
  lambda      <- rep(0, K)
  best_lambda <- lambda
  best_err    <- Inf

  for (iter in seq_len(max_iter)) {
    w   <- compute_w(lambda)
    g   <- colMeans(X * w) - targets_adj
    err <- max(abs(g) / pmax(targets_adj, absolute))
    if (err < pct) break

    h     <- compute_h(w)
    H     <- crossprod(X * sqrt(pmax(h, 0)), X * sqrt(pmax(h, 0)))
    ridge <- 1e-6 * mean(diag(H))
    delta <- tryCatch(
      solve(H + ridge * diag(K), g),
      error = function(e) {
        warning("calibrate_weights: Hessian solve failed at iter ", iter,
                ": ", conditionMessage(e), ". Using gradient step.")
        g / (diag(H) + ridge)
      }
    )

    # Step-halving: reject step if no improvement found after 10 halvings
    step     <- 1.0
    improved <- FALSE
    g_norm   <- sqrt(sum(g^2))
    for (.h in seq_len(10)) {
      lambda_cand <- lambda - step * delta
      g_cand      <- colMeans(X * compute_w(lambda_cand)) - targets_adj
      if (sqrt(sum(g_cand^2)) < g_norm) {
        lambda   <- lambda_cand
        improved <- TRUE
        break
      }
      step <- step / 2
    }
    # if !improved: lambda unchanged (step rejected)

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
  w_final / mean(w_final)   # return mean-1 weights
}
