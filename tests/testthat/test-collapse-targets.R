test_that("collapse_threshold: zero respondents always collapses", {
  expect_true(autumn:::collapse_threshold(0L, 0.1, 100L, 5))
})

test_that("collapse_threshold: count below adaptive threshold collapses", {
  # n=100, p=0.1, max_weight=5
  # cap_floor = ceiling(100 * 0.1 / 5) = 2
  # min_abs   = max(3, floor(100 * 0.002)) = 3
  # threshold = 3; n_k=2 < 3 → TRUE
  expect_true(autumn:::collapse_threshold(2L, 0.1, 100L, 5))
})

test_that("collapse_threshold: count at threshold does not collapse", {
  # n_k = threshold = 3 → NOT < 3 → FALSE
  expect_false(autumn:::collapse_threshold(3L, 0.1, 100L, 5))
})

test_that("collapse_threshold: max_weight=Inf uses min_abs only", {
  # cap_floor = 0 regardless of p_k; min_abs=3 for n=100
  expect_true(autumn:::collapse_threshold(2L, 0.9, 100L, Inf))
  expect_false(autumn:::collapse_threshold(3L, 0.9, 100L, Inf))
})

test_that("collapse_threshold: min_abs scales with sample size", {
  # n=10000: min_abs = max(3, floor(10000*0.002)) = max(3,20) = 20
  expect_true(autumn:::collapse_threshold(15L, 0.001, 10000L, Inf))
  expect_false(autumn:::collapse_threshold(20L, 0.001, 10000L, Inf))
})

test_that("collapse_threshold: large target proportion raises cap_floor", {
  # n=100, p=0.5, max_weight=5: cap_floor=ceiling(100*0.5/5)=10; min_abs=3; threshold=10
  expect_true(autumn:::collapse_threshold(9L, 0.5, 100L, 5))
  expect_false(autumn:::collapse_threshold(10L, 0.5, 100L, 5))
})

test_that("collapse_threshold: p_k=0 with zero respondents uses min_abs only", {
  # cap_floor = ceiling(n * 0 / max_weight) = 0; threshold = min_abs = 3
  expect_true(autumn:::collapse_threshold(0L, 0.0, 100L, 5))
  expect_true(autumn:::collapse_threshold(2L, 0.0, 100L, 5))
  expect_false(autumn:::collapse_threshold(3L, 0.0, 100L, 5))
})

test_that("collapse_threshold: max_weight=0 produces Inf cap_floor (always collapses)", {
  # ceiling(n * p_k / 0) = Inf; n_k < Inf is always TRUE for finite n_k
  # This documents the behaviour for an invalid caller — collapse_threshold
  # is @keywords internal and relies on harvest() to validate max_weight > 0.
  expect_true(autumn:::collapse_threshold(999L, 0.5, 100L, 0))
})

test_that("cell_profile_distance: numeric column standardised mean difference", {
  d = data.frame(x = c(1, 2, 3, 7, 8, 9), stringsAsFactors = FALSE)
  # k=1:3 mean=2; j=4:6 mean=8; pooled sd of all 6 values
  sp = sd(c(1, 2, 3, 7, 8, 9))
  expected = abs(2 - 8) / sp
  result = autumn:::cell_profile_distance(d, 1:3, 4:6, "x")
  expect_equal(result, expected, tolerance = 1e-10)
})

test_that("cell_profile_distance: factor column total variation distance", {
  d = data.frame(cat = c("A","A","B", "B","B","B"), stringsAsFactors = FALSE)
  # k=1:3: A=2/3, B=1/3; j=4:6: A=0, B=1
  # TVD = (|2/3-0| + |1/3-1|) / 2 = 2/3
  result = autumn:::cell_profile_distance(d, 1:3, 4:6, "cat")
  expect_equal(result, 2/3, tolerance = 1e-10)
})

test_that("cell_profile_distance: multiple columns averaged unweighted", {
  d = data.frame(
    x = c(1, 1, 1, 5, 5, 5),
    y = c(0, 0, 0, 0, 0, 0),   # zero variance: contributes 0 to distance
    stringsAsFactors = FALSE
  )
  r_x    = autumn:::cell_profile_distance(d, 1:3, 4:6, "x")
  r_both = autumn:::cell_profile_distance(d, 1:3, 4:6, c("x", "y"))
  expect_equal(r_both, r_x / 2, tolerance = 1e-10)
})

test_that("cell_profile_distance: empty k_rows returns Inf", {
  d = data.frame(x = 1:6, stringsAsFactors = FALSE)
  expect_equal(autumn:::cell_profile_distance(d, integer(0), 4:6, "x"), Inf)
})

test_that("cell_profile_distance: empty j_rows returns Inf", {
  d = data.frame(x = 1:6, stringsAsFactors = FALSE)
  expect_equal(autumn:::cell_profile_distance(d, 1:3, integer(0), "x"), Inf)
})

# ── fixtures ──────────────────────────────────────────────────────────────────
# 6-row data: grp has A=3, B=3; no C in data; income separates A and B clearly
mk_unord = function() {
  list(
    data   = data.frame(
      grp = c("A","A","A","B","B","B"),
      inc = c(10, 12, 11, 50, 52, 51),
      stringsAsFactors = FALSE
    ),
    target = list(grp = c(A = 0.4, B = 0.3, C = 0.3))
  )
}

# 7-row data: grp A=3, B=3, C=1; C's income matches A not B
mk_small = function() {
  list(
    data   = data.frame(
      grp = c("A","A","A","B","B","B","C"),
      inc = c(1,  2,  3,  10, 11, 12, 2),
      stringsAsFactors = FALSE
    ),
    target = list(grp = c(A = 0.4, B = 0.35, C = 0.25))
  )
}
# ─────────────────────────────────────────────────────────────────────────────

test_that("collapse_targets: missing cell merges by proportion fallback", {
  f = mk_unord()
  # C has 0 rows → fallback to |p_k - p_j|: |0.3-0.4|=0.1 vs |0.3-0.3|=0; C→B
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5)
  )
  expect_equal(names(result$target$grp), c("A", "B"))
  expect_equal(unname(result$target$grp["B"]), 0.6)
  expect_equal(unname(result$target$grp["A"]), 0.4)
})

test_that("collapse_targets: missing cell recode in data", {
  f = mk_unord()
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5)
  )
  # No rows had C; data unchanged is fine but must not contain C
  expect_false("C" %in% unique(result$data$grp))
})

test_that("collapse_targets: small cell merges toward profile-similar cell", {
  f = mk_small()
  # n=7, p_C=0.25, max_weight=5: cap_floor=ceiling(7*0.25/5)=1; min_abs=3; threshold=3
  # C has 1 row → collapse. collapse_vars="inc": C's inc=2 is close to A (mean=2) not B (mean=11)
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target,
                              max_weight   = 5,
                              collapse_vars = "inc")
  )
  expect_equal(names(result$target$grp), c("A", "B"))
  expect_equal(unname(result$target$grp["A"]), 0.65)  # 0.4 + 0.25
})

test_that("collapse_targets: data recoded for small cell rows", {
  f = mk_small()
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target,
                              max_weight   = 5,
                              collapse_vars = "inc")
  )
  # Original C row (row 7) should now read "A"
  expect_equal(result$data$grp[7], "A")
})

test_that("collapse_targets: collapse_vars=NULL falls back to calibration vars", {
  f = mk_small()
  # collapse_vars=NULL → aux_vars = names(target) = "grp"
  # av = "grp"[!"grp"] = character(0) → proportion fallback
  # |p_A-p_C|=|0.4-0.25|=0.15 vs |p_B-p_C|=|0.35-0.25|=0.10 → C→B
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5)
  )
  expect_equal(unname(result$target$grp["B"]), 0.6)  # B absorbs C
})

test_that("collapse_targets: collapsed_levels attribute present and accurate", {
  f = mk_unord()
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_s3_class(cl, "data.frame")
  expect_equal(cl$variable, "grp")
  expect_equal(cl$from,     "C")
  expect_equal(cl$into,     "B")
  expect_equal(cl$n_from,   0L)
  expect_equal(cl$p_from,   0.3)
})

test_that("collapse_targets: no collapses returns NULL collapsed_levels", {
  d   = data.frame(grp = rep(c("A","B","C"), each = 10), stringsAsFactors = FALSE)
  tgt = list(grp = c(A = 1/3, B = 1/3, C = 1/3))
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  expect_null(attr(result, "collapsed_levels"))
})

test_that("collapse_targets: original data not mutated", {
  f = mk_small()
  orig = f$data$grp
  suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5, collapse_vars = "inc")
  )
  expect_equal(f$data$grp, orig)
})

test_that("collapse_targets: warning emitted per merge", {
  f = mk_unord()
  expect_warning(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5),
    "auto_collapse"
  )
})

# ── ordered fixture ───────────────────────────────────────────────────────────
# 11-row data: age groups 18-24=1, 25-34=5, 35-44=5
# 18-24 is sparse → should merge into 25-34 (adjacent), NOT 35-44
mk_ord = function() {
  list(
    data   = data.frame(
      age = factor(
        c("18-24",
          "25-34","25-34","25-34","25-34","25-34",
          "35-44","35-44","35-44","35-44","35-44"),
        levels  = c("18-24","25-34","35-44"),
        ordered = TRUE
      ),
      inc = c(22, 30,31,29,28,32, 50,51,49,52,48),
      stringsAsFactors = FALSE
    ),
    target = list(
      age = c("18-24" = 0.10, "25-34" = 0.40, "35-44" = 0.50)
    )
  )
}
# ─────────────────────────────────────────────────────────────────────────────

test_that("ordered: sparse first level merges into second (adjacent only)", {
  f = mk_ord()
  # n=11, p_18-24=0.10, max_weight=5: cap_floor=ceiling(11*0.1/5)=1; min_abs=3; threshold=3
  # 18-24 has 1 row → collapse
  # Adjacent to 18-24: only 25-34 (35-44 is two steps away)
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target,
                              max_weight   = 5,
                              collapse_vars = "inc")
  )
  expect_equal(names(result$target$age), c("25-34", "35-44"))
  expect_equal(unname(result$target$age["25-34"]), 0.50)
})

test_that("ordered: merges into adjacent even when non-adjacent would be more similar", {
  f = mk_ord()
  # 18-24 income=22; adjacency forces merge into 25-34 only (not 35-44)
  result = suppressWarnings(
    autumn:::collapse_targets(f$data, f$target, max_weight = 5, collapse_vars = "inc")
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(cl$from, "18-24")
  expect_equal(cl$into, "25-34")
})

test_that("ordered: sparse last level merges into second-to-last", {
  d = data.frame(
    age = factor(
      c("18-24","18-24","18-24","18-24","18-24",
        "25-34","25-34","25-34","25-34","25-34",
        "35-44"),
      levels = c("18-24","25-34","35-44"), ordered = TRUE
    ),
    stringsAsFactors = FALSE
  )
  tgt = list(age = c("18-24"=0.40,"25-34"=0.40,"35-44"=0.20))
  # 35-44 has 1 row; adjacent is only 25-34
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(cl$from, "35-44")
  expect_equal(cl$into, "25-34")
})

test_that("ordered: zero-respondent level uses proportion fallback within adjacents", {
  d = data.frame(
    age = factor(
      c("25-34","25-34","25-34","25-34","25-34",
        "35-44","35-44","35-44","35-44","35-44"),
      levels = c("18-24","25-34","35-44"), ordered = TRUE
    ),
    stringsAsFactors = FALSE
  )
  tgt = list(age = c("18-24"=0.10,"25-34"=0.45,"35-44"=0.45))
  # 18-24 has 0 rows → proportion fallback among adjacents: only 25-34
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(cl$from, "18-24")
  expect_equal(cl$into, "25-34")
})

# ── Task 5: error conditions and agglomeration chain ──────────────────────────

test_that("collapse_targets: stops when all levels would collapse to one", {
  # n=2: both levels have 1 row; min_abs=max(3,floor(2*0.002))=3; both below 3
  # After A merges into B: B has 2 rows, p=1.0; threshold=max(3,ceiling(2/5))=3;
  # 2<3 TRUE while length(level_names)==1 → stop()
  d   = data.frame(grp = c("A", "B"), stringsAsFactors = FALSE)
  tgt = list(grp = c(A = 0.5, B = 0.5))
  expect_error(
    suppressWarnings(autumn:::collapse_targets(d, tgt, max_weight = 5)),
    "all levels"
  )
})

test_that("collapse_targets: stops for invalid collapse_vars", {
  f = mk_unord()
  expect_error(
    autumn:::collapse_targets(f$data, f$target,
                              max_weight    = 5,
                              collapse_vars = c("income_NONEXISTENT")),
    "collapse_vars not found"
  )
})

test_that("collapse_targets: agglomeration chain — A merges into B, B then passes threshold", {
  # n=7: A=1, B=2, C=4; tgt A=0.10, B=0.20, C=0.70
  # threshold_A=max(3,ceiling(7*0.1/5))=3; A(1)<3 → collapse
  # threshold_B=max(3,ceiling(7*0.2/5))=3; B(2)<3 → collapse
  # threshold_C=max(3,ceiling(7*0.7/5))=3; C(4)>=3 → OK
  # smallest=A(1); prop distances A→B=0.1, A→C=0.6 → A merges into B
  # After merge: B has 3 rows, p=0.30; threshold_B_new=max(3,1)=3; 3<3 FALSE → OK
  # Round 2: no collapse flags set → break; total 1 merge
  d   = data.frame(
    grp = c("A", "B","B", "C","C","C","C"),
    stringsAsFactors = FALSE
  )
  tgt = list(grp = c(A = 0.10, B = 0.20, C = 0.70))
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(nrow(cl), 1L)
  expect_equal(cl$from, "A")
  expect_equal(cl$into, "B")
  expect_equal(names(result$target$grp), c("B", "C"))
  expect_equal(unname(result$target$grp["B"]), 0.30)
})

test_that("collapse_targets: deep chain — A→B→C when B stays below threshold after merge", {
  # n=4: A=1, B=1, C=2; tgt A=0.25, B=0.25, C=0.50
  # All three below threshold=3; which.min(c(1,1,2))=A; A→B (|0.25-0.25|=0 < |0.25-0.5|)
  # After merge: B has 2 rows (p=0.50); threshold=max(3,ceiling(4*0.5/5))=3; 2<3 → still collapse
  # Round 2: B(2) and C(2) both below 3; which.min(c(2,2))=B; B→C
  # After merge: C has 4 rows, p=1.0; threshold=max(3,ceiling(4*1.0/5))=3; 4<3 FALSE → break
  # Total: 2 merges (A→B, B→C); final target has only C=1.0
  d   = data.frame(
    grp = c("A", "B", "C","C"),
    stringsAsFactors = FALSE
  )
  tgt = list(grp = c(A = 0.25, B = 0.25, C = 0.50))
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(nrow(cl), 2L)
  expect_equal(names(result$target$grp), "C")
  expect_equal(unname(result$target$grp["C"]), 1.0)
})

test_that("collapse_targets: warnings suppressible", {
  f = mk_unord()
  expect_no_warning(
    suppressWarnings(
      autumn:::collapse_targets(f$data, f$target, max_weight = 5)
    )
  )
})

test_that("collapse_targets: multiple variables processed independently", {
  d = data.frame(
    v1 = c("A","A","A","B"),
    v2 = c("X","X","X","Y"),
    stringsAsFactors = FALSE
  )
  tgt = list(
    v1 = c(A = 0.6, B = 0.4),
    v2 = c(X = 0.6, Y = 0.4)
  )
  result = suppressWarnings(
    autumn:::collapse_targets(d, tgt, max_weight = 5)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(nrow(cl), 2L)
  expect_setequal(cl$variable, c("v1", "v2"))
})

# ── Task 6: harvest() integration tests ──────────────────────────────────────

test_that("harvest auto_collapse=FALSE still errors on missing level", {
  f = mk_unord()
  expect_error(
    harvest(f$data, f$target, auto_collapse = FALSE),
    "missing levels in data"
  )
})

test_that("harvest auto_collapse=TRUE: missing level → weights produced", {
  f = mk_unord()
  result = suppressWarnings(
    harvest(f$data, f$target,
            auto_collapse  = TRUE,
            attach_weights = TRUE)
  )
  expect_s3_class(result, "data.frame")
  expect_true("weights" %in% colnames(result))
  expect_equal(nrow(result), 6L)
  expect_true(all(!is.na(result$weights)))
})

test_that("harvest auto_collapse=TRUE: returned data has ORIGINAL level names", {
  f = mk_unord()
  result = suppressWarnings(
    harvest(f$data, f$target,
            auto_collapse  = TRUE,
            attach_weights = TRUE)
  )
  # Original data had A and B only; returned data must match original
  expect_equal(sort(unique(result$grp)), c("A", "B"))
  expect_false("C" %in% result$grp)
})

test_that("harvest auto_collapse=TRUE: collapsed_levels attr attached", {
  f = mk_unord()
  result = suppressWarnings(
    harvest(f$data, f$target,
            auto_collapse  = TRUE,
            attach_weights = TRUE)
  )
  cl = attr(result, "collapsed_levels")
  expect_s3_class(cl, "data.frame")
  expect_true("from" %in% colnames(cl))
})

test_that("harvest auto_collapse=TRUE with collapse_vars: profile-driven merge", {
  f = mk_small()
  # With collapse_vars="inc", C's income ~A → C merges into A
  result = suppressWarnings(
    harvest(f$data, f$target,
            max_weight    = 5,
            auto_collapse = TRUE,
            collapse_vars = "inc",
            attach_weights = TRUE)
  )
  cl = attr(result, "collapsed_levels")
  expect_equal(cl$into, "A")
})

test_that("harvest auto_collapse=TRUE: attach_weights=FALSE returns weight vector", {
  f = mk_unord()
  w = suppressWarnings(
    harvest(f$data, f$target,
            auto_collapse  = TRUE,
            attach_weights = FALSE)
  )
  expect_type(w, "double")
  expect_length(w, 6L)
})

test_that("harvest auto_collapse=TRUE method=calibrate: weights produced and original names", {
  f = mk_unord()
  result = suppressWarnings(
    harvest(f$data, f$target,
            auto_collapse  = TRUE,
            method         = "calibrate",
            max_weight     = Inf,
            attach_weights = TRUE)
  )
  expect_s3_class(result, "data.frame")
  expect_equal(sort(unique(result$grp)), c("A", "B"))
  expect_true(!is.null(attr(result, "collapsed_levels")))
})

