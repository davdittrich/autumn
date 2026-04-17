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
