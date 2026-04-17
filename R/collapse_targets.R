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

#' Collapse sparse or missing calibration cells into nearest-neighbour cells
#'
#' For each variable in \code{target}, identifies levels whose respondent count
#' is below the adaptive threshold (derived from \code{max_weight} and sample
#' size) and merges them into the most similar surviving level.  Operates on a
#' copy of \code{data}; never mutates the caller's object.
#'
#' @param data A data frame.
#' @param target A list of named numeric vectors (proportion targets).
#' @param max_weight Scalar weight cap passed from \code{harvest()}.
#' @param collapse_vars Character vector of auxiliary column names for
#'   nearest-neighbour similarity.  \code{NULL} (default) uses
#'   \code{names(target)}.
#' @return A list with elements \code{$data} and \code{$target}.
#'   A \code{collapsed_levels} attribute (a data frame with columns
#'   \code{variable}, \code{from}, \code{into}, \code{n_from},
#'   \code{p_from}, \code{distance}) is attached when at least one merge
#'   occurred.
#' @keywords internal
collapse_targets = function(data, target, max_weight, collapse_vars = NULL) {
  data_out = data
  n        = nrow(data)
  vars     = names(target)

  # Resolve and validate collapse_vars
  if (is.null(collapse_vars)) {
    aux_vars = vars
  } else {
    bad = setdiff(collapse_vars, colnames(data))
    if (length(bad)) {
      stop("collapse_vars not found in data: ", paste(bad, collapse = ", "))
    }
    aux_vars = collapse_vars
  }

  collapsed_log = list()

  for (v in vars) {
    ordered_v   = is.ordered(data_out[[v]])
    level_names = names(target[[v]])

    repeat {
      # Respondent counts for current surviving levels
      counts = vapply(level_names, function(lv)
        sum(data_out[[v]] == lv, na.rm = TRUE), integer(1L))
      names(counts) = level_names

      props          = target[[v]]
      collapse_flags = vapply(level_names, function(k)
        collapse_threshold(counts[[k]], props[[k]], n, max_weight), logical(1L))

      if (!any(collapse_flags)) break

      if (length(level_names) <= 1L) {
        stop("auto_collapse: all levels of variable `", v,
             "` collapsed to one. Calibration is not possible.")
      }

      # Smallest collapsible cell first (fewest respondents)
      collapsible = level_names[collapse_flags]
      k_name      = collapsible[which.min(counts[collapsible])]
      k_rows      = which(data_out[[v]] == k_name)

      # Candidate pool: all survivors; restrict to adjacent if ordered
      survivors = level_names[level_names != k_name]
      if (ordered_v) {
        k_pos = match(k_name, level_names)
        adj   = level_names[abs(seq_along(level_names) - k_pos) == 1L]
        if (length(adj)) survivors = adj
      }

      # Auxiliary columns: exclude v itself (all same value within cell k)
      av = aux_vars[aux_vars != v]

      # Pick merge target
      if (!length(av) || length(k_rows) == 0L) {
        # Proportion-distance fallback
        j_name   = survivors[which.min(abs(props[survivors] - props[[k_name]]))]
        dist_val = abs(props[[j_name]] - props[[k_name]])
      } else {
        dists = vapply(survivors, function(j) {
          j_rows = which(data_out[[v]] == j)
          cell_profile_distance(data_out, k_rows, j_rows, av)
        }, numeric(1L))
        if (all(is.infinite(dists))) {
          # All candidates also have zero rows
          j_name   = survivors[which.min(abs(props[survivors] - props[[k_name]]))]
          dist_val = abs(props[[j_name]] - props[[k_name]])
        } else {
          j_name   = survivors[which.min(dists)]
          j_rows_f = which(data_out[[v]] == j_name)
          dist_val = cell_profile_distance(data_out, k_rows, j_rows_f, av)
        }
      }

      warning(sprintf(
        "auto_collapse: `%s`: level `%s` (n=%d, p=%.4f) merged into `%s`",
        v, k_name, counts[[k_name]], props[[k_name]], j_name
      ))

      collapsed_log[[length(collapsed_log) + 1L]] = data.frame(
        variable = v,
        from     = k_name,
        into     = j_name,
        n_from   = counts[[k_name]],
        p_from   = unname(props[[k_name]]),
        distance = dist_val,
        stringsAsFactors = FALSE
      )

      # Update target (sum proportions, remove k)
      target[[v]][[j_name]] = target[[v]][[j_name]] + target[[v]][[k_name]]
      target[[v]]           = target[[v]][names(target[[v]]) != k_name]

      # Recode data_out for the duration of calibration
      data_out[[v]][data_out[[v]] == k_name] = j_name

      # Update level list for the next repeat iteration
      level_names = names(target[[v]])
    }
  }

  result = list(data = data_out, target = target)
  if (length(collapsed_log)) {
    attr(result, "collapsed_levels") = do.call(rbind, collapsed_log)
  }
  result
}
