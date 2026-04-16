# Survey raking benchmark: autumn vs competing packages
# Convergence standard: max marginal deviation < 1e-4 from targets (post-hoc)
# All packages run with max_iter=10000
# Generated: 2026-04-16

suppressPackageStartupMessages({
  library(bench)
  library(survey)
  library(anesrake)
  library(icarus)
  library(sampling)
  library(Matrix)
  library(devtools)
})

devtools::load_all(quiet = TRUE)
source("bench/helpers.R")

MAX_ITER  = 10000L
CONV_TOL  = 1e-4

# ── Factorial design: 32 conditions ──────────────────────────────────────────
conditions = expand.grid(
  n          = c(500L, 5000L, 50000L, 500000L),
  K_total    = c(10L, 100L),
  imbalance  = c("low", "high"),
  max_weight = c(Inf, 5),
  stringsAsFactors = FALSE
)
conditions$cond_id = seq_len(nrow(conditions))
stopifnot(nrow(conditions) == 32L)

# ── Result accumulator ────────────────────────────────────────────────────────
results = vector("list", nrow(conditions) * 7L)
res_idx = 1L

record = function(cond_id, impl, bm, w, data, targets, err = NA_character_) {
  if (!is.na(err)) {
    results[[res_idx]] <<- data.frame(
      cond_id      = cond_id,
      impl         = impl,
      median_ms    = NA_real_,
      mem_mb       = NA_real_,
      n_itr        = NA_integer_,
      max_marg_dev = NA_real_,
      non_converged= NA,
      error        = err,
      stringsAsFactors = FALSE
    )
  } else {
    dev = tryCatch(max_marginal_dev(data, w, targets), error = function(e) NA_real_)
    results[[res_idx]] <<- data.frame(
      cond_id      = cond_id,
      impl         = impl,
      median_ms    = as.numeric(bm$median) / 1e6,
      mem_mb       = as.numeric(bm$mem_alloc) / 1024^2,
      n_itr        = bm$n_itr,
      max_marg_dev = dev,
      non_converged= !is.na(dev) && dev > CONV_TOL,
      error        = NA_character_,
      stringsAsFactors = FALSE
    )
  }
  res_idx <<- res_idx + 1L
}

# ── Main loop ─────────────────────────────────────────────────────────────────
for (i in seq_len(nrow(conditions))) {
  cond     = conditions[i, ]
  cid      = cond$cond_id
  n        = cond$n
  K        = cond$K_total
  imb      = cond$imbalance
  mw       = cond$max_weight
  mw_cap   = if (is.infinite(mw)) 1000 else mw

  cat(sprintf("\n[%02d/32] n=%-7d K=%-4d imb=%-5s max_weight=%s\n",
              cid, n, K, imb, ifelse(is.infinite(mw), "Inf", mw)))

  # ── Pre-build all inputs OUTSIDE timed block ────────────────────────────────
  inp  = bench_generate(n, K, imbalance = imb, seed = 42L)
  data = inp$data
  tgts = inp$targets
  wts  = inp$weights
  vars = names(tgts)

  # anesrake
  anes_fmt = format_anesrake_targets(tgts, n)

  # survey::rake
  svy_samp_margins = lapply(vars, function(v) as.formula(paste("~", v)))

  # survey::calibrate
  svy_cal_inp = build_survey_calibrate_inputs(inp)

  # icarus: colWeights must be column name string; add weights to data frame
  K_max_icarus = max(sapply(vars, function(v) length(tgts[[v]])))
  data_icarus  = cbind(inp$data, initial_weight = wts)
  margin_rows_icarus = lapply(vars, function(v) {
    K_v    = length(tgts[[v]])
    totals = round(tgts[[v]] * n)
    c(v, K_v, totals, rep(0, K_max_icarus - K_v))
  })
  margin_mat_icarus = do.call(rbind, margin_rows_icarus)

  # ── autumn-ipf ──────────────────────────────────────────────────────────────
  bm = tryCatch(
    bench::mark(
      autumn_ipf = harvest(data, target = tgts, start_weights = wts,
                           method = "rake", max_weight = mw_cap,
                           max_iterations = MAX_ITER,
                           convergence = c(absolute = CONV_TOL, pct = CONV_TOL),
                           attach_weights = FALSE),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "autumn-ipf", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    w_out = harvest(data, target = tgts, start_weights = wts,
                    method = "rake", max_weight = mw_cap,
                    max_iterations = MAX_ITER,
                    convergence = c(absolute = CONV_TOL, pct = CONV_TOL),
                    attach_weights = FALSE)
    record(cid, "autumn-ipf", bm, w_out, data, tgts)
  }

  # ── autumn-nr ───────────────────────────────────────────────────────────────
  bm = tryCatch(
    bench::mark(
      autumn_nr = harvest(data, target = tgts, start_weights = wts,
                          method = "nr", max_weight = mw_cap,
                          max_iterations = MAX_ITER,
                          convergence = c(absolute = CONV_TOL, pct = CONV_TOL),
                          attach_weights = FALSE),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "autumn-nr", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    w_out = harvest(data, target = tgts, start_weights = wts,
                    method = "nr", max_weight = mw_cap,
                    max_iterations = MAX_ITER,
                    convergence = c(absolute = CONV_TOL, pct = CONV_TOL),
                    attach_weights = FALSE)
    record(cid, "autumn-nr", bm, w_out, data, tgts)
  }

  # ── anesrake ────────────────────────────────────────────────────────────────
  bm = tryCatch(
    bench::mark(
      anesrake_run = anesrake::anesrake(
        inputter   = anes_fmt$targets_anes,
        dataframe  = data,
        caseid     = anes_fmt$caseid,
        weightvec  = wts,
        cap        = mw_cap,
        maxit      = MAX_ITER,
        type       = "nolim",
        convcrit   = 1e-4
      ),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "anesrake", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    res_anes = anesrake::anesrake(
      inputter   = anes_fmt$targets_anes,
      dataframe  = data,
      caseid     = anes_fmt$caseid,
      weightvec  = wts,
      cap        = mw_cap,
      maxit      = MAX_ITER,
      type       = "nolim",
      convcrit   = 1e-4
    )
    record(cid, "anesrake", bm, res_anes$weightvec, data, tgts)
  }

  # ── survey-rake ─────────────────────────────────────────────────────────────
  bm = tryCatch(
    bench::mark(
      survey_rake = rake(
        design             = inp$svy_design,
        sample.margins     = svy_samp_margins,
        population.margins = inp$pop_margins,
        control            = list(maxit = MAX_ITER, epsilon = CONV_TOL)
      ),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "survey-rake", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    raked = rake(
      design             = inp$svy_design,
      sample.margins     = svy_samp_margins,
      population.margins = inp$pop_margins,
      control            = list(maxit = MAX_ITER, epsilon = CONV_TOL)
    )
    record(cid, "survey-rake", bm, weights(raked), data, tgts)
  }

  # ── survey-calibrate ─────────────────────────────────────────────────────────
  # Skipped for binding max_weight=5: survey::calibrate bounds semantics differ.
  if (is.infinite(mw)) {
    bm = tryCatch(
      bench::mark(
        survey_cal = calibrate(
          design     = inp$svy_design,
          formula    = svy_cal_inp$formula,
          population = svy_cal_inp$population,
          calfun     = cal.raking,
          maxit      = MAX_ITER,
          epsilon    = CONV_TOL
        ),
        min_iterations = 5L, max_iterations = 20L, check = FALSE
      ),
      error = function(e) e
    )
    if (inherits(bm, "error")) {
      record(cid, "survey-cal", NULL, NULL, data, tgts, err = conditionMessage(bm))
    } else {
      cal_obj = calibrate(
        design     = inp$svy_design,
        formula    = svy_cal_inp$formula,
        population = svy_cal_inp$population,
        calfun     = cal.raking,
        maxit      = MAX_ITER,
        epsilon    = CONV_TOL
      )
      record(cid, "survey-cal", bm, weights(cal_obj), data, tgts)
    }
  } else {
    record(cid, "survey-cal", NULL, NULL, data, tgts,
           err = "N/A: survey::calibrate bounds semantics differ from max_weight cap")
  }

  # ── icarus ───────────────────────────────────────────────────────────────────
  # Note: icarus has no weight-cap parameter; max_weight condition is recorded
  # but not enforced. Both mw=Inf and mw=5 rows reflect uncapped convergence.
  bm = tryCatch(
    bench::mark(
      icarus_run = icarus::calibration(
        data           = data_icarus,
        marginMatrix   = margin_mat_icarus,
        colWeights     = "initial_weight",
        maxIter        = MAX_ITER,
        calibTolerance = CONV_TOL,
        description    = FALSE
      ),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "icarus", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    w_out = icarus::calibration(
      data           = data_icarus,
      marginMatrix   = margin_mat_icarus,
      colWeights     = "initial_weight",
      maxIter        = MAX_ITER,
      calibTolerance = CONV_TOL,
      description    = FALSE
    )
    record(cid, "icarus", bm, w_out, data, tgts)
  }

  # ── sampling::calib ──────────────────────────────────────────────────────────
  # Note: sampling::calib has no weight-cap parameter. Both mw=Inf and mw=5
  # rows reflect uncapped convergence.
  bm = tryCatch(
    bench::mark(
      sampling_calib = sampling::calib(
        Xs      = inp$Xs,
        d       = wts,
        total   = inp$d_totals,
        method  = "raking",
        max_iter= MAX_ITER
      ),
      min_iterations = 5L, max_iterations = 20L, check = FALSE
    ),
    error = function(e) e
  )
  if (inherits(bm, "error")) {
    record(cid, "sampling", NULL, NULL, data, tgts, err = conditionMessage(bm))
  } else {
    w_out = sampling::calib(
      Xs      = inp$Xs,
      d       = wts,
      total   = inp$d_totals,
      method  = "raking",
      max_iter= MAX_ITER
    )
    record(cid, "sampling", bm, w_out * wts, data, tgts)
  }
}

# ── Compile results ───────────────────────────────────────────────────────────
res_df = do.call(rbind, results[!vapply(results, is.null, logical(1))])
res_df = merge(res_df, conditions[, c("cond_id", "n", "K_total", "imbalance", "max_weight")],
               by = "cond_id")

# ── Write bench/results-comparison.md ────────────────────────────────────────
out_path = "bench/results-comparison.md"
r_ver = R.version$version.string
pkg_ver = vapply(
  c("autumn", "bench", "survey", "anesrake", "icarus", "sampling"),
  function(p) tryCatch(as.character(packageVersion(p)), error = function(e) "not installed"),
  character(1)
)
hw_info  = tryCatch(system("lscpu | grep 'Model name\\|CPU(s)' | head -2", intern=TRUE), error=function(e) "unavailable")
ram_info = tryCatch(system("free -h | grep Mem:", intern=TRUE), error=function(e) "unavailable")

sink(out_path)

cat("# Survey Raking Benchmark Results\n\n")
cat("## Session Info\n\n")
cat(sprintf("- **R version:** %s\n", r_ver))
cat(sprintf("- **Date:** %s\n", Sys.Date()))
cat("- **Package versions:**\n")
for (nm in names(pkg_ver)) cat(sprintf("  - %s: %s\n", nm, pkg_ver[nm]))
cat("- **Hardware:**\n")
cat(sprintf("  - CPU: %s\n", paste(hw_info, collapse = "; ")))
cat(sprintf("  - RAM: %s\n", paste(ram_info, collapse = " ")))
cat("\n")

cat("## Results by Condition\n\n")
for (cid in unique(res_df$cond_id)) {
  sub      = res_df[res_df$cond_id == cid, ]
  cond_row = conditions[conditions$cond_id == cid, ]
  cat(sprintf("### Condition %d: n=%d, K=%d, imbalance=%s, max_weight=%s\n\n",
              cid, cond_row$n, cond_row$K_total, cond_row$imbalance,
              ifelse(is.infinite(cond_row$max_weight), "Inf", cond_row$max_weight)))
  cat("| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |\n")
  cat("|------|-----------|--------|-------|--------------|---------------|-------|\n")
  for (j in seq_len(nrow(sub))) {
    r = sub[j, ]
    cat(sprintf("| %s | %s | %s | %s | %s | %s | %s |\n",
      r$impl,
      ifelse(is.na(r$median_ms),    "N/A", sprintf("%.2f",  r$median_ms)),
      ifelse(is.na(r$mem_mb),       "N/A", sprintf("%.2f",  r$mem_mb)),
      ifelse(is.na(r$n_itr),        "N/A", as.character(r$n_itr)),
      ifelse(is.na(r$max_marg_dev), "N/A", sprintf("%.2e",  r$max_marg_dev)),
      ifelse(is.na(r$non_converged),"N/A", as.character(r$non_converged)),
      ifelse(is.na(r$error),        "",    r$error)
    ))
  }
  cat("\n")
}

# ── Summary ratio tables ──────────────────────────────────────────────────────
cat("## Summary\n\n")

cat("### Speed ratio: autumn-nr vs survey-cal (NR vs NR, unbounded only)\n\n")
cat("| condition | autumn-nr (ms) | survey-cal (ms) | ratio |\n")
cat("|-----------|----------------|-----------------|-------|\n")
nr_sub   = res_df[res_df$impl == "autumn-nr"  & !is.na(res_df$median_ms), ]
scal_sub = res_df[res_df$impl == "survey-cal" & !is.na(res_df$median_ms), ]
merged_nr = merge(nr_sub[, c("cond_id","median_ms")], scal_sub[, c("cond_id","median_ms")],
                  by="cond_id", suffixes=c("_nr","_scal"))
merged_nr = merge(merged_nr, conditions[, c("cond_id","n","K_total","imbalance","max_weight")], by="cond_id")
for (j in seq_len(nrow(merged_nr))) {
  r = merged_nr[j, ]
  ratio = if (!is.na(r$median_ms_scal) && r$median_ms_scal > 0) r$median_ms_nr / r$median_ms_scal else NA
  cat(sprintf("| n=%d K=%d %s | %.2f | %.2f | %s |\n",
    r$n, r$K_total, r$imbalance,
    r$median_ms_nr, r$median_ms_scal,
    ifelse(is.na(ratio), "N/A", sprintf("%.2f", ratio))
  ))
}
cat("\n")

cat("### Speed ratio: autumn-ipf vs anesrake (IPF vs IPF)\n\n")
cat("| condition | autumn-ipf (ms) | anesrake (ms) | ratio |\n")
cat("|-----------|-----------------|---------------|-------|\n")
ipf_sub  = res_df[res_df$impl == "autumn-ipf" & !is.na(res_df$median_ms), ]
anes_sub = res_df[res_df$impl == "anesrake"   & !is.na(res_df$median_ms), ]
merged_ipf = merge(ipf_sub[, c("cond_id","median_ms")], anes_sub[, c("cond_id","median_ms")],
                   by="cond_id", suffixes=c("_ipf","_anes"))
merged_ipf = merge(merged_ipf, conditions[, c("cond_id","n","K_total","imbalance","max_weight")], by="cond_id")
for (j in seq_len(nrow(merged_ipf))) {
  r = merged_ipf[j, ]
  ratio = if (!is.na(r$median_ms_anes) && r$median_ms_anes > 0) r$median_ms_ipf / r$median_ms_anes else NA
  cat(sprintf("| n=%d K=%d %s mw=%s | %.2f | %.2f | %s |\n",
    r$n, r$K_total, r$imbalance,
    ifelse(is.infinite(r$max_weight), "Inf", as.character(r$max_weight)),
    r$median_ms_ipf, r$median_ms_anes,
    ifelse(is.na(ratio), "N/A", sprintf("%.2f", ratio))
  ))
}
cat("\n")

cat("### Speed ratio: autumn-ipf vs survey-rake (IPF vs IPF)\n\n")
cat("| condition | autumn-ipf (ms) | survey-rake (ms) | ratio |\n")
cat("|-----------|-----------------|------------------|-------|\n")
srake_sub = res_df[res_df$impl == "survey-rake" & !is.na(res_df$median_ms), ]
merged_srake = merge(ipf_sub[, c("cond_id","median_ms")], srake_sub[, c("cond_id","median_ms")],
                     by="cond_id", suffixes=c("_ipf","_srake"))
merged_srake = merge(merged_srake, conditions[, c("cond_id","n","K_total","imbalance","max_weight")], by="cond_id")
for (j in seq_len(nrow(merged_srake))) {
  r = merged_srake[j, ]
  ratio = if (!is.na(r$median_ms_srake) && r$median_ms_srake > 0) r$median_ms_ipf / r$median_ms_srake else NA
  cat(sprintf("| n=%d K=%d %s mw=%s | %.2f | %.2f | %s |\n",
    r$n, r$K_total, r$imbalance,
    ifelse(is.infinite(r$max_weight), "Inf", as.character(r$max_weight)),
    r$median_ms_ipf, r$median_ms_srake,
    ifelse(is.na(ratio), "N/A", sprintf("%.2f", ratio))
  ))
}
cat("\n")

cat("### Non-convergence / error summary\n\n")
failed = res_df[(!is.na(res_df$error) & !startsWith(as.character(res_df$error), "N/A")) |
                (!is.na(res_df$non_converged) & res_df$non_converged == TRUE), ]
if (nrow(failed) == 0) {
  cat("All implementations converged in all conditions.\n\n")
} else {
  cat("| cond_id | impl | error |\n")
  cat("|---------|------|-------|\n")
  for (j in seq_len(nrow(failed))) {
    r = failed[j, ]
    cat(sprintf("| %d | %s | %s |\n", r$cond_id, r$impl,
                ifelse(is.na(r$error), paste0("non_converged (dev=", round(r$max_marg_dev,5), ")"), r$error)))
  }
  cat("\n")
}

sink()

message("Done. Results written to: ", out_path)
message(sprintf("Total result rows: %d", nrow(res_df)))
