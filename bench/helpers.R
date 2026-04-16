# Survey raking benchmark helpers
# Generated: 2026-04-16

#' Generate benchmark inputs for all packages
#'
#' @param n Number of rows
#' @param K_total Total number of categories across all variables
#' @param n_vars Number of raking variables (default 2)
#' @param imbalance c("low", "high")
#' @param seed Random seed
#' @return A list with: data, targets, weights, Xs (for sampling::calib),
#'         d_totals (for survey::calibrate), pop_margins (for survey::rake),
#'         svy_design (pre-built svydesign object)
bench_generate = function(n, K_total, n_vars = 2, imbalance = "low", seed = 42) {
  set.seed(seed)
  K_per_var = max(2L, K_total %/% n_vars)

  # Build imbalanced sample proportions
  if (imbalance == "low") {
    make_probs = function(K) { p = runif(K, 0.5, 1.5); p / sum(p) }
  } else {
    make_probs = function(K) { p = (1 / seq_len(K))^1.2; p / sum(p) }
  }

  vars = paste0("var", seq_len(n_vars))
  data = as.data.frame(setNames(lapply(vars, function(v) {
    lvls  = paste0(v, "_", seq_len(K_per_var))
    probs = make_probs(K_per_var)
    factor(sample(lvls, n, replace = TRUE, prob = probs), levels = lvls)
  }), vars))

  # Uniform targets
  targets = setNames(lapply(vars, function(v) {
    K = K_per_var
    setNames(rep(1 / K, K), paste0(v, "_", seq_len(K)))
  }), vars)

  weights = rep(1, n)

  # Calibration matrix for sampling::calib
  Xs = do.call(cbind, lapply(vars, function(v) {
    lvls = levels(data[[v]])
    mat  = matrix(0L, nrow = n, ncol = length(lvls))
    for (k in seq_along(lvls)) mat[data[[v]] == lvls[k], k] = 1L
    mat
  }))
  Xs_colnames = unlist(lapply(vars, function(v) paste0(v, "_", seq_len(K_per_var))))
  colnames(Xs) = Xs_colnames

  # Population totals for survey::calibrate
  d_totals = setNames(
    unlist(lapply(vars, function(v) targets[[v]] * n)),
    Xs_colnames
  )
  for (v in vars) {
    idx = which(startsWith(names(d_totals), paste0(v, "_")))
    d_totals[idx[1]] = n - sum(d_totals[idx[-1]])
  }

  # Population margin data frames for survey::rake
  pop_margins = lapply(seq_along(vars), function(i) {
    v    = vars[i]
    lvls = names(targets[[v]])
    freq = targets[[v]] * n
    freq = round(freq)
    freq[1] = n - sum(freq[-1])
    df = data.frame(x = factor(lvls, levels = lvls), Freq = as.numeric(freq))
    names(df)[1] = v
    df
  })

  # Pre-build svydesign
  svy_design = survey::svydesign(ids = ~1, weights = ~1, data = data)

  list(
    data        = data,
    targets     = targets,
    weights     = weights,
    Xs          = Xs,
    d_totals    = d_totals,
    pop_margins = pop_margins,
    svy_design  = svy_design,
    n_vars      = n_vars,
    K_per_var   = K_per_var
  )
}


#' Measure max marginal deviation from targets post-hoc
max_marginal_dev = function(data, weights, targets) {
  devs = vapply(names(targets), function(v) {
    wt_prop = tapply(weights, data[[v]], sum) / sum(weights)
    wt_prop = wt_prop[names(targets[[v]])]
    wt_prop[is.na(wt_prop)] = 0
    max(abs(wt_prop - targets[[v]]))
  }, numeric(1))
  max(devs)
}


#' Format targets for anesrake
format_anesrake_targets = function(targets, n) {
  list(
    targets_anes = targets,
    caseid       = seq_len(n)
  )
}


#' Build calibration formula and population for survey::calibrate
#'
#' survey::calibrate with `- 1` formula uses treatment contrasts: all K levels
#' for the first variable, but K-1 levels (reference dropped) for subsequent
#' variables. Population totals must match the model.matrix column structure.
build_survey_calibrate_inputs = function(inputs) {
  vars    = names(inputs$targets)
  formula = as.formula(paste("~", paste(vars, collapse = " + "), "- 1"))
  mm      = model.matrix(formula, inputs$data)
  pop     = setNames(numeric(ncol(mm)), colnames(mm))
  for (cn in names(pop)) {
    for (v in vars) {
      if (startsWith(cn, v)) {
        lvl = substring(cn, nchar(v) + 1L)   # strip variable-name prefix
        if (lvl %in% names(inputs$targets[[v]])) {
          pop[cn] = inputs$targets[[v]][lvl] * nrow(inputs$data)
        }
      }
    }
  }
  list(
    formula    = formula,
    population = pop
  )
}
