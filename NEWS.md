# autumn 0.2.0

## Breaking Changes

* `design_effect(weights, outcome)` previously used the Spencer (2000)
  estimator, which is statistically invalid for raking/calibration weights:
  Spencer assumes design weights w_i = 1/(n * P_i), but calibration weights
  have no well-defined selection probability P_i. This call path now emits a
  warning and falls back to the Kish (1992) estimator.

  To use the outcome-aware Henry & Valliant (2015) estimator (recommended),
  pass the raking data frame and target proportions:
  `design_effect(weights, outcome, data, target)`

## New Features

* `design_effect()` and `effective_sample_size()` now accept optional `data`
  and `target` arguments. When all three of `outcome`, `data`, and `target`
  are supplied, the Henry & Valliant (2015) design effect is computed. This
  estimator accounts for correlation between the outcome and the calibration
  auxiliary variables: `deff_H = (1 - R^2_w) * deff_K`, where R^2_w is the
  weighted R^2 from regressing the outcome on dummy-coded calibration
  auxiliaries. If the calibration auxiliaries perfectly predict the outcome,
  the design effect approaches 0.

  Reference: Henry, K.A. & Valliant, R. (2015). Survey Methodology, 41(2),
  315-331.

# autumn 0.1.1

## Bug Fixes

* Fixed: error message when target proportions contain a level absent from
  the data now correctly names the missing levels (was blank due to
  `target_errors` vs `data_errors` variable bug).

* Fixed: error message when target proportions do not sum to 1 is now
  informative ("does not sum to 1") rather than a cryptic internal R error
  ("argument is not interpretable as logical").

* Fixed: `add_na_proportion` with a numeric vector of length > 1 no longer
  crashes with "attempt to select more than one element" in both
  `freeze_na_proportion()` and `update_na_values()`.

* Fixed: `anesrake(type = "nlim")` no longer errors with "requires the
  following parameter(s): count" (was passing `number =` instead of
  `count =` in `select_params`).

* Fixed: `diagnose_weights()` and `design_effect()` now correctly detect
  the `.weights_autumn` weight column (without a numeric suffix) that
  `harvest()` attaches when the data frame already has a `weights` column.

* Fixed: `select_number()` no longer produces NA indices when `count`
  exceeds the number of available variables.

* Fixed: `harvest()` now correctly records the caller's variable name in
  `attr(data, "target_symbol")` for use by `diagnose_weights()` auto-
  detection (was recording `"target"` after promise forcing).

* Fixed: primitive functions (e.g., `sum`) are now accepted as valid
  inputs to the `error_function` and `select_function` arguments.
