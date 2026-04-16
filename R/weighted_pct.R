#' Weighted proportion table
#'
#' This is a fast, dependency-free weighted proportion table for 1D variables.
#'
#' @param x A vector of any type
#' @param weights A numeric vector of weights, equal in length to \code{x}
#' @return A named vector with weighted proportions.
#' @export
#' @examples
#' # Setup examle data
#' x <- c(rep(1, 5), rep(2, 5))
#' weights <- c(rep(1, 5), rep(2, 5))
#'
#' # Unweighted proportions: 0.5 / 0.5
#' prop.table(table(x))
#' # Weighted proportions: 0.33 / 0.66
#' weighted_pct(x, weights)
weighted_pct = function(x, weights) {
  # rowsum() performs a C-level grouped sum without the intermediate list
  # allocation that makes split()+vapply(sum) slow at large n.
  # Pass x directly (not as.character(x)): as.character(NA) produces the
  #   string "NA", creating a spurious named group instead of a missing label.
  # na.rm=TRUE: excludes NA values in weights from group sums. NA group labels
  #   are ALWAYS treated as a separate level by rowsum() regardless of na.rm
  #   (R docs: "NA values in group are always treated as a separate level,
  #   independent of na.rm"). Strip the NA-named row explicitly below.
  rs = suppressWarnings(rowsum(weights, x, na.rm = TRUE))
  # Strip the NA group row: rowsum() creates a row with NA_character_ rowname
  # for NA group labels. This matches split()'s behavior (NA-keyed elements
  # excluded). The denominator still includes NA-x row weights (intentional:
  # proportions reflect share of total population, not just classified rows).
  keep = !is.na(rownames(rs))
  setNames(as.vector(rs[keep, , drop = FALSE]), rownames(rs)[keep]) /
    sum(weights, na.rm = TRUE)
}
