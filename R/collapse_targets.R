#' Decide whether a calibration cell should be collapsed
#'
#' Returns TRUE when n_k is below the adaptive threshold derived from the
#' weight cap and the absolute minimum floor.
#' @keywords internal
collapse_threshold = function(n_k, p_k, n, max_weight) {
  min_abs   = max(3L, floor(n * 0.002))
  cap_floor = if (is.finite(max_weight)) ceiling(n * p_k / max_weight) else 0L
  n_k < max(min_abs, cap_floor)
}

#' Profile distance between two cells over a set of auxiliary columns
#'
#' Numeric columns use standardised mean difference (pooled SD).
#' Categorical/factor columns use total variation distance on the within-cell
#' marginal distribution. The result is the unweighted mean across all columns.
#' Returns Inf when either cell has zero rows (signals proportion fallback).
#' @keywords internal
cell_profile_distance = function(data, k_rows, j_rows, collapse_vars) {
  if (length(k_rows) == 0L || length(j_rows) == 0L) return(Inf)
  dists = vapply(collapse_vars, function(col) {
    xk = data[[col]][k_rows]
    xj = data[[col]][j_rows]
    if (is.numeric(data[[col]])) {
      mk = mean(xk, na.rm = TRUE)
      mj = mean(xj, na.rm = TRUE)
      if (is.na(mk) || is.na(mj)) return(Inf)
      sp = sd(c(xk, xj), na.rm = TRUE)
      if (is.na(sp) || sp < .Machine$double.eps) return(0)
      abs(mk - mj) / sp
    } else {
      levs = unique(c(as.character(xk), as.character(xj)))
      levs = levs[!is.na(levs)]
      if (!length(levs)) return(0)
      pk = table(factor(as.character(xk), levels = levs)) / max(length(xk), 1L)
      pj = table(factor(as.character(xj), levels = levs)) / max(length(xj), 1L)
      sum(abs(as.numeric(pk) - as.numeric(pj))) / 2
    }
  }, numeric(1L))
  mean(dists)
}
