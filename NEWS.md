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
