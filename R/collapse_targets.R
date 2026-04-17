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
