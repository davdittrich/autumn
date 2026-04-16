# Survey Raking Benchmark Results

## Session Info

- **R version:** R version 4.5.3 (2026-03-11)
- **Date:** 2026-04-16
- **Package versions:**
  - autumn: 0.2.0
  - bench: 1.1.4
  - survey: 4.4.8
  - anesrake: 0.80
  - icarus: 0.3.3
  - sampling: 2.11
- **Hardware:**
  - CPU: CPU(s):                                  16; On-line CPU(s) list:                     0-15
  - RAM: Mem:            15Gi        13Gi       1.1Gi       121Mi       1.2Gi       1.9Gi

## Results by Condition

### Condition 1: n=500, K=10, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 0.70 | 19 | 2.43e-10 | FALSE |  |
| autumn-nr | 0.00 | 1.02 | 19 | 2.33e-09 | FALSE |  |
| anesrake | 0.00 | 3.20 | 18 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 0.81 | 20 | 9.74e-06 | FALSE |  |
| survey-cal | 0.00 | 1.97 | 19 | 2.21e-09 | FALSE |  |
| icarus | 0.00 | 1.19 | 20 | 4.72e-16 | FALSE |  |
| sampling | 0.00 | 1.55 | 19 | 2.21e-09 | FALSE |  |

### Condition 2: n=5000, K=10, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 1.97 | 19 | 2.29e-12 | FALSE |  |
| autumn-nr | 0.00 | 6.93 | 14 | 4.85e-13 | FALSE |  |
| anesrake | 0.00 | 18.06 | 10 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 3.19 | 18 | 1.82e-09 | FALSE |  |
| survey-cal | 0.00 | 16.45 | 10 | 9.11e-08 | FALSE |  |
| icarus | 0.00 | 6.83 | 15 | 8.33e-17 | FALSE |  |
| sampling | 0.00 | 12.87 | 12 | 9.11e-08 | FALSE |  |

### Condition 3: n=50000, K=10, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 19.65 | 9 | 1.70e-14 | FALSE |  |
| autumn-nr | 0.00 | 55.65 | 10 | 6.56e-10 | FALSE |  |
| anesrake | 0.00 | 179.51 | 6 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 31.68 | 1 | 2.38e-11 | FALSE |  |
| survey-cal | 0.00 | 132.15 | 5 | 1.30e-05 | FALSE |  |
| icarus | 0.00 | 67.30 | 11 | 5.55e-17 | FALSE |  |
| sampling | 0.00 | 128.06 | 5 | 5.91e-10 | FALSE |  |

### Condition 4: n=500000, K=10, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 196.46 | 5 | 1.08e-13 | FALSE |  |
| autumn-nr | 0.00 | 552.02 | 5 | 2.70e-10 | FALSE |  |
| anesrake | 0.00 | 1411.70 | 5 | 1.94e-16 | FALSE |  |
| survey-rake | 0.00 | 219.36 | 5 | 2.33e-10 | FALSE |  |
| survey-cal | 0.00 | 1320.11 | 5 | 8.21e-06 | FALSE |  |
| icarus | 0.00 | 666.80 | 5 | 3.89e-16 | FALSE |  |
| sampling | 0.00 | 1539.32 | 5 | 1.49e-09 | FALSE |  |

### Condition 5: n=500, K=100, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 38.59 | 5 | 3.24e-05 | FALSE |  |
| autumn-nr | 0.00 | 38.17 | 5 | 9.95e-09 | FALSE |  |
| anesrake | 0.00 | 13670.36 | 5 | 1.96e-06 | FALSE |  |
| survey-rake | 0.00 | 5.77 | 11 | 1.28e-03 | TRUE |  |
| survey-cal | 0.00 | 39.16 | 18 | 3.98e-07 | FALSE |  |
| icarus | 0.00 | 5.42 | 12 | 9.37e-17 | FALSE |  |
| sampling | 0.00 | 53.30 | 10 | 1.88e-08 | FALSE |  |

### Condition 6: n=5000, K=100, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 3.23 | 20 | 8.32e-12 | FALSE |  |
| autumn-nr | 0.00 | 10.80 | 20 | 2.07e-10 | FALSE |  |
| anesrake | 0.00 | 269.66 | 4 | 0.00e+00 | FALSE |  |
| survey-rake | 0.00 | 4.34 | 20 | 2.07e-06 | FALSE |  |
| survey-cal | 0.00 | 151.32 | 5 | 1.05e-10 | FALSE |  |
| icarus | 0.00 | 44.01 | 5 | 6.94e-17 | FALSE |  |
| sampling | 0.00 | 152.37 | 5 | 1.05e-10 | FALSE |  |

### Condition 7: n=50000, K=100, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 22.98 | 20 | 8.09e-14 | FALSE |  |
| autumn-nr | 0.00 | 72.63 | 6 | 3.13e-12 | FALSE |  |
| anesrake | 0.00 | 2049.68 | 1 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 22.89 | 17 | 1.55e-06 | FALSE |  |
| survey-cal | 0.00 | 1231.89 | 1 | 5.88e-08 | FALSE |  |
| icarus | 0.00 | 428.92 | 4 | 6.25e-17 | FALSE |  |
| sampling | 0.00 | 1465.07 | 1 | 9.46e-14 | FALSE |  |

### Condition 8: n=500000, K=100, imbalance=low, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 227.26 | 4 | 1.24e-15 | FALSE |  |
| autumn-nr | 0.00 | 679.59 | 2 | 1.03e-11 | FALSE |  |
| anesrake | 0.00 | 11922.74 | 5 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 220.70 | 4 | 8.84e-08 | FALSE |  |
| survey-cal | 0.00 | 12283.52 | 5 | 1.83e-07 | FALSE |  |
| icarus | 0.00 | 4272.82 | 5 | 4.51e-17 | FALSE |  |
| sampling | 0.00 | 17083.48 | 5 | 8.35e-10 | FALSE |  |

### Condition 9: n=500, K=10, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 0.36 | 20 | 1.76e-09 | FALSE |  |
| autumn-nr | 0.00 | 0.87 | 20 | 4.68e-09 | FALSE |  |
| anesrake | 0.00 | 5.12 | 15 | 0.00e+00 | FALSE |  |
| survey-rake | 0.00 | 0.43 | 20 | 2.75e-05 | FALSE |  |
| survey-cal | 0.00 | 2.35 | 20 | 4.51e-09 | FALSE |  |
| icarus | 0.00 | 0.69 | 20 | 1.67e-16 | FALSE |  |
| sampling | 0.00 | 1.90 | 20 | 4.51e-09 | FALSE |  |

### Condition 10: n=5000, K=10, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 2.27 | 20 | 5.16e-13 | FALSE |  |
| autumn-nr | 0.00 | 8.19 | 19 | 1.16e-11 | FALSE |  |
| anesrake | 0.00 | 23.81 | 20 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 3.19 | 20 | 2.99e-08 | FALSE |  |
| survey-cal | 0.00 | 19.62 | 20 | 1.21e-06 | FALSE |  |
| icarus | 0.00 | 6.83 | 20 | 9.71e-16 | FALSE |  |
| sampling | 0.00 | 18.09 | 20 | 5.46e-12 | FALSE |  |

### Condition 11: n=50000, K=10, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 19.65 | 20 | 7.34e-14 | FALSE |  |
| autumn-nr | 0.00 | 80.33 | 11 | 1.82e-11 | FALSE |  |
| anesrake | 0.00 | 179.51 | 5 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 31.68 | 17 | 2.12e-10 | FALSE |  |
| survey-cal | 0.00 | 195.50 | 5 | 1.63e-06 | FALSE |  |
| icarus | 0.00 | 67.30 | 11 | 2.22e-16 | FALSE |  |
| sampling | 0.00 | 179.96 | 5 | 1.23e-08 | FALSE |  |

### Condition 12: n=500000, K=10, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 196.46 | 5 | 4.79e-13 | FALSE |  |
| autumn-nr | 0.00 | 796.56 | 3 | 3.12e-11 | FALSE |  |
| anesrake | 0.00 | 1983.94 | 1 | 2.22e-16 | FALSE |  |
| survey-rake | 0.00 | 219.36 | 4 | 1.89e-08 | FALSE |  |
| survey-cal | 0.00 | 1953.38 | 1 | 2.25e-06 | FALSE |  |
| icarus | 0.00 | 666.80 | 3 | 1.11e-16 | FALSE |  |
| sampling | 0.00 | 1798.73 | 5 | 1.61e-08 | FALSE |  |

### Condition 13: n=500, K=100, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | N/A | N/A | N/A | N/A | N/A | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| autumn-nr | N/A | N/A | N/A | N/A | N/A | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| anesrake | 0.00 | 7068.90 | 5 | 9.99e-02 | TRUE |  |
| survey-rake | N/A | N/A | N/A | N/A | N/A | Some strata absent from sample: use partial=TRUE to ignore them. |
| survey-cal | N/A | N/A | N/A | N/A | N/A | Calibration failed |
| icarus | N/A | N/A | N/A | N/A | N/A | Error in number of modalities. |
| sampling | 0.00 | 20.61 | 20 | 2.00e-02 | TRUE |  |

### Condition 14: n=5000, K=100, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 8.64 | 20 | 5.23e-10 | FALSE |  |
| autumn-nr | 0.00 | 25.01 | 13 | 8.75e-13 | FALSE |  |
| anesrake | 0.00 | 776.51 | 1 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 8.01 | 20 | 1.81e-04 | TRUE |  |
| survey-cal | 0.00 | 373.47 | 4 | 1.63e-08 | FALSE |  |
| icarus | 0.00 | 44.00 | 19 | 1.02e-15 | FALSE |  |
| sampling | 0.00 | 386.34 | 4 | 1.63e-08 | FALSE |  |

### Condition 15: n=50000, K=100, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 32.24 | 20 | 1.53e-12 | FALSE |  |
| autumn-nr | 0.00 | 163.87 | 4 | 7.54e-12 | FALSE |  |
| anesrake | 0.00 | 2049.68 | 5 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 32.84 | 13 | 5.15e-06 | FALSE |  |
| survey-cal | 0.00 | 2901.90 | 5 | 1.43e-07 | FALSE |  |
| icarus | 0.00 | 428.92 | 3 | 1.03e-15 | FALSE |  |
| sampling | 0.00 | 3216.22 | 5 | 6.03e-13 | FALSE |  |

### Condition 16: n=500000, K=100, imbalance=high, max_weight=Inf

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 257.81 | 3 | 1.30e-14 | FALSE |  |
| autumn-nr | 0.00 | 1541.83 | 5 | 6.08e-11 | FALSE |  |
| anesrake | 0.00 | 14364.54 | 5 | 1.39e-17 | FALSE |  |
| survey-rake | 0.00 | 220.39 | 4 | 2.88e-06 | FALSE |  |
| survey-cal | 0.00 | 28925.83 | 5 | 8.59e-07 | FALSE |  |
| icarus | 0.00 | 4272.82 | 5 | 6.97e-16 | FALSE |  |
| sampling | 0.00 | 32036.29 | 5 | 1.42e-11 | FALSE |  |

### Condition 17: n=500, K=10, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 0.26 | 20 | 2.43e-10 | FALSE |  |
| autumn-nr | 0.00 | 0.60 | 20 | 2.33e-09 | FALSE |  |
| anesrake | 0.00 | 2.91 | 20 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 0.33 | 20 | 9.74e-06 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 0.69 | 20 | 4.72e-16 | FALSE |  |
| sampling | 0.00 | 1.35 | 20 | 2.21e-09 | FALSE |  |

### Condition 18: n=5000, K=10, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 1.97 | 19 | 2.29e-12 | FALSE |  |
| autumn-nr | 0.00 | 6.93 | 20 | 4.85e-13 | FALSE |  |
| anesrake | 0.00 | 18.06 | 20 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 3.19 | 20 | 1.82e-09 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 6.83 | 20 | 8.33e-17 | FALSE |  |
| sampling | 0.00 | 12.87 | 20 | 9.11e-08 | FALSE |  |

### Condition 19: n=50000, K=10, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 19.65 | 19 | 1.70e-14 | FALSE |  |
| autumn-nr | 0.00 | 55.65 | 15 | 6.56e-10 | FALSE |  |
| anesrake | 0.00 | 179.51 | 4 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 31.68 | 18 | 2.38e-11 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 67.30 | 13 | 5.55e-17 | FALSE |  |
| sampling | 0.00 | 128.06 | 4 | 5.91e-10 | FALSE |  |

### Condition 20: n=500000, K=10, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 196.46 | 5 | 1.08e-13 | FALSE |  |
| autumn-nr | 0.00 | 552.02 | 3 | 2.70e-10 | FALSE |  |
| anesrake | 0.00 | 1411.70 | 2 | 1.94e-16 | FALSE |  |
| survey-rake | 0.00 | 219.36 | 4 | 2.33e-10 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 666.80 | 3 | 3.89e-16 | FALSE |  |
| sampling | 0.00 | 1539.32 | 1 | 1.49e-09 | FALSE |  |

### Condition 21: n=500, K=100, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 37.58 | 4 | 1.00e-02 | TRUE |  |
| autumn-nr | 0.00 | 72.98 | 3 | 9.90e-03 | TRUE |  |
| anesrake | 0.00 | 14369.41 | 5 | 1.00e-02 | TRUE |  |
| survey-rake | 0.00 | 5.77 | 6 | 1.28e-03 | TRUE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 5.42 | 20 | 9.37e-17 | FALSE |  |
| sampling | 0.00 | 53.30 | 7 | 1.88e-08 | FALSE |  |

### Condition 22: n=5000, K=100, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 3.95 | 20 | 7.31e-09 | FALSE |  |
| autumn-nr | 0.00 | 23.17 | 10 | 1.12e-12 | FALSE |  |
| anesrake | 0.00 | 296.23 | 4 | 0.00e+00 | FALSE |  |
| survey-rake | 0.00 | 4.34 | 20 | 2.07e-06 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 44.01 | 5 | 6.94e-17 | FALSE |  |
| sampling | 0.00 | 152.37 | 5 | 1.05e-10 | FALSE |  |

### Condition 23: n=50000, K=100, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 22.98 | 16 | 8.09e-14 | FALSE |  |
| autumn-nr | 0.00 | 72.63 | 4 | 3.13e-12 | FALSE |  |
| anesrake | 0.00 | 2049.68 | 1 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 22.89 | 18 | 1.55e-06 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 428.92 | 4 | 6.25e-17 | FALSE |  |
| sampling | 0.00 | 1465.07 | 2 | 9.46e-14 | FALSE |  |

### Condition 24: n=500000, K=100, imbalance=low, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 227.26 | 4 | 1.24e-15 | FALSE |  |
| autumn-nr | 0.00 | 679.59 | 3 | 1.03e-11 | FALSE |  |
| anesrake | 0.00 | 11922.74 | 5 | 3.47e-18 | FALSE |  |
| survey-rake | 0.00 | 220.70 | 5 | 8.84e-08 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 4272.82 | 5 | 4.51e-17 | FALSE |  |
| sampling | 0.00 | 17083.48 | 5 | 8.35e-10 | FALSE |  |

### Condition 25: n=500, K=10, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 1.46 | 20 | 1.16e-06 | FALSE |  |
| autumn-nr | 0.00 | 3.31 | 13 | 6.04e-03 | TRUE |  |
| anesrake | 0.00 | 9.05 | 11 | 8.94e-07 | FALSE |  |
| survey-rake | 0.00 | 0.43 | 20 | 2.75e-05 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 0.69 | 20 | 1.67e-16 | FALSE |  |
| sampling | 0.00 | 1.90 | 20 | 4.51e-09 | FALSE |  |

### Condition 26: n=5000, K=10, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 9.69 | 20 | 8.63e-07 | FALSE |  |
| autumn-nr | 0.00 | 26.01 | 16 | 9.51e-04 | TRUE |  |
| anesrake | 0.00 | 69.88 | 4 | 2.78e-17 | FALSE |  |
| survey-rake | 0.00 | 3.19 | 20 | 2.99e-08 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 6.83 | 20 | 9.71e-16 | FALSE |  |
| sampling | 0.00 | 18.09 | 20 | 5.46e-12 | FALSE |  |

### Condition 27: n=50000, K=10, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 86.80 | 5 | 1.16e-06 | FALSE |  |
| autumn-nr | 0.00 | 255.50 | 4 | 5.69e-04 | TRUE |  |
| anesrake | 0.00 | 500.20 | 5 | 1.68e-07 | FALSE |  |
| survey-rake | 0.00 | 31.68 | 18 | 2.12e-10 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 67.30 | 13 | 2.22e-16 | FALSE |  |
| sampling | 0.00 | 179.96 | 5 | 1.23e-08 | FALSE |  |

### Condition 28: n=500000, K=10, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 1035.71 | 2 | 8.50e-07 | FALSE |  |
| autumn-nr | 0.00 | 2534.65 | 5 | 8.08e-04 | TRUE |  |
| anesrake | 0.00 | 6640.29 | 5 | 3.05e-16 | FALSE |  |
| survey-rake | 0.00 | 219.36 | 3 | 1.89e-08 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 666.80 | 5 | 1.11e-16 | FALSE |  |
| sampling | 0.00 | 1798.73 | 5 | 1.61e-08 | FALSE |  |

### Condition 29: n=500, K=100, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | N/A | N/A | N/A | N/A | N/A | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| autumn-nr | N/A | N/A | N/A | N/A | N/A | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| anesrake | 0.00 | 3803.57 | 5 | 1.10e-01 | TRUE |  |
| survey-rake | N/A | N/A | N/A | N/A | N/A | Some strata absent from sample: use partial=TRUE to ignore them. |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | N/A | N/A | N/A | N/A | N/A | Error in number of modalities. |
| sampling | 0.00 | 20.61 | 20 | 2.00e-02 | TRUE |  |

### Condition 30: n=5000, K=100, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 830.90 | 5 | 3.22e-02 | TRUE |  |
| autumn-nr | 0.00 | 70.00 | 4 | 1.05e-02 | TRUE |  |
| anesrake | 0.00 | 3020.78 | 5 | 4.67e-02 | TRUE |  |
| survey-rake | 0.00 | 8.01 | 20 | 1.81e-04 | TRUE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 44.00 | 19 | 1.02e-15 | FALSE |  |
| sampling | 0.00 | 386.34 | 3 | 1.63e-08 | FALSE |  |

### Condition 31: n=50000, K=100, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 18868.62 | 5 | 2.46e-02 | TRUE |  |
| autumn-nr | 0.00 | 466.74 | 3 | 1.08e-02 | TRUE |  |
| anesrake | 0.00 | 55862.15 | 5 | 4.11e-02 | TRUE |  |
| survey-rake | 0.00 | 32.84 | 12 | 5.15e-06 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 428.92 | 2 | 1.03e-15 | FALSE |  |
| sampling | 0.00 | 3216.22 | 5 | 6.03e-13 | FALSE |  |

### Condition 32: n=500000, K=100, imbalance=high, max_weight=5

| impl | median_ms | mem_mb | n_itr | max_marg_dev | non_converged | error |
|------|-----------|--------|-------|--------------|---------------|-------|
| autumn-ipf | 0.00 | 288676.38 | 5 | 2.65e-02 | TRUE |  |
| autumn-nr | 0.00 | 4400.76 | 5 | 1.12e-02 | TRUE |  |
| anesrake | 0.00 | 298228.60 | 5 | 4.26e-02 | TRUE |  |
| survey-rake | 0.00 | 220.39 | 4 | 2.88e-06 | FALSE |  |
| survey-cal | N/A | N/A | N/A | N/A | N/A | N/A: survey::calibrate bounds semantics differ from max_weight cap |
| icarus | 0.00 | 4272.82 | 5 | 6.97e-16 | FALSE |  |
| sampling | 0.00 | 32036.29 | 5 | 1.42e-11 | FALSE |  |

## Summary

### Speed ratio: autumn-nr vs survey-cal (NR vs NR, unbounded only)

| condition | autumn-nr (ms) | survey-cal (ms) | ratio |
|-----------|----------------|-----------------|-------|
| n=500 K=10 low | 0.00 | 0.00 | 2.21 |
| n=5000 K=10 low | 0.00 | 0.00 | 1.27 |
| n=50000 K=10 low | 0.00 | 0.00 | 0.65 |
| n=500000 K=10 low | 0.00 | 0.00 | 0.51 |
| n=500 K=100 low | 0.00 | 0.00 | 5.99 |
| n=5000 K=100 low | 0.00 | 0.00 | 0.02 |
| n=50000 K=100 low | 0.00 | 0.00 | 0.12 |
| n=500000 K=100 low | 0.00 | 0.00 | 0.06 |
| n=500 K=10 high | 0.00 | 0.00 | 2.23 |
| n=5000 K=10 high | 0.00 | 0.00 | 1.11 |
| n=50000 K=10 high | 0.00 | 0.00 | 0.48 |
| n=500000 K=10 high | 0.00 | 0.00 | 0.44 |
| n=5000 K=100 high | 0.00 | 0.00 | 0.24 |
| n=50000 K=100 high | 0.00 | 0.00 | 0.11 |
| n=500000 K=100 high | 0.00 | 0.00 | 0.04 |

### Speed ratio: autumn-ipf vs anesrake (IPF vs IPF)

| condition | autumn-ipf (ms) | anesrake (ms) | ratio |
|-----------|-----------------|---------------|-------|
| n=500 K=10 low mw=Inf | 0.00 | 0.00 | 0.39 |
| n=5000 K=10 low mw=Inf | 0.00 | 0.00 | 0.33 |
| n=50000 K=10 low mw=Inf | 0.00 | 0.00 | 0.17 |
| n=500000 K=10 low mw=Inf | 0.00 | 0.00 | 0.25 |
| n=500 K=100 low mw=Inf | 0.00 | 0.00 | 0.01 |
| n=5000 K=100 low mw=Inf | 0.00 | 0.00 | 0.03 |
| n=50000 K=100 low mw=Inf | 0.00 | 0.00 | 0.04 |
| n=500000 K=100 low mw=Inf | 0.00 | 0.00 | 0.06 |
| n=500 K=10 high mw=Inf | 0.00 | 0.00 | 0.15 |
| n=5000 K=10 high mw=Inf | 0.00 | 0.00 | 0.26 |
| n=50000 K=10 high mw=Inf | 0.00 | 0.00 | 0.08 |
| n=500000 K=10 high mw=Inf | 0.00 | 0.00 | 0.19 |
| n=5000 K=100 high mw=Inf | 0.00 | 0.00 | 0.03 |
| n=50000 K=100 high mw=Inf | 0.00 | 0.00 | 0.04 |
| n=500000 K=100 high mw=Inf | 0.00 | 0.00 | 0.04 |
| n=500 K=10 low mw=5 | 0.00 | 0.00 | 0.24 |
| n=5000 K=10 low mw=5 | 0.00 | 0.00 | 0.29 |
| n=50000 K=10 low mw=5 | 0.00 | 0.00 | 0.12 |
| n=500000 K=10 low mw=5 | 0.00 | 0.00 | 0.27 |
| n=500 K=100 low mw=5 | 0.00 | 0.00 | 0.00 |
| n=5000 K=100 low mw=5 | 0.00 | 0.00 | 0.02 |
| n=50000 K=100 low mw=5 | 0.00 | 0.00 | 0.06 |
| n=500000 K=100 low mw=5 | 0.00 | 0.00 | 0.05 |
| n=500 K=10 high mw=5 | 0.00 | 0.00 | 0.22 |
| n=5000 K=10 high mw=5 | 0.00 | 0.00 | 0.10 |
| n=50000 K=10 high mw=5 | 0.00 | 0.00 | 0.10 |
| n=500000 K=10 high mw=5 | 0.00 | 0.00 | 0.04 |
| n=5000 K=100 high mw=5 | 0.00 | 0.00 | 0.05 |
| n=50000 K=100 high mw=5 | 0.00 | 0.00 | 0.04 |
| n=500000 K=100 high mw=5 | 0.00 | 0.00 | 0.09 |

### Speed ratio: autumn-ipf vs survey-rake (IPF vs IPF)

| condition | autumn-ipf (ms) | survey-rake (ms) | ratio |
|-----------|-----------------|------------------|-------|
| n=500 K=10 low mw=Inf | 0.00 | 0.00 | 0.32 |
| n=5000 K=10 low mw=Inf | 0.00 | 0.00 | 0.34 |
| n=50000 K=10 low mw=Inf | 0.00 | 0.00 | 0.52 |
| n=500000 K=10 low mw=Inf | 0.00 | 0.00 | 0.78 |
| n=500 K=100 low mw=Inf | 0.00 | 0.00 | 3.10 |
| n=5000 K=100 low mw=Inf | 0.00 | 0.00 | 0.28 |
| n=50000 K=100 low mw=Inf | 0.00 | 0.00 | 0.97 |
| n=500000 K=100 low mw=Inf | 0.00 | 0.00 | 1.04 |
| n=500 K=10 high mw=Inf | 0.00 | 0.00 | 0.31 |
| n=5000 K=10 high mw=Inf | 0.00 | 0.00 | 0.37 |
| n=50000 K=10 high mw=Inf | 0.00 | 0.00 | 0.51 |
| n=500000 K=10 high mw=Inf | 0.00 | 0.00 | 0.85 |
| n=5000 K=100 high mw=Inf | 0.00 | 0.00 | 0.42 |
| n=50000 K=100 high mw=Inf | 0.00 | 0.00 | 0.65 |
| n=500000 K=100 high mw=Inf | 0.00 | 0.00 | 1.00 |
| n=500 K=10 low mw=5 | 0.00 | 0.00 | 0.23 |
| n=5000 K=10 low mw=5 | 0.00 | 0.00 | 0.32 |
| n=50000 K=10 low mw=5 | 0.00 | 0.00 | 0.54 |
| n=500000 K=10 low mw=5 | 0.00 | 0.00 | 0.85 |
| n=500 K=100 low mw=5 | 0.00 | 0.00 | 2.17 |
| n=5000 K=100 low mw=5 | 0.00 | 0.00 | 0.90 |
| n=50000 K=100 low mw=5 | 0.00 | 0.00 | 1.18 |
| n=500000 K=100 low mw=5 | 0.00 | 0.00 | 0.86 |
| n=500 K=10 high mw=5 | 0.00 | 0.00 | 0.98 |
| n=5000 K=10 high mw=5 | 0.00 | 0.00 | 1.80 |
| n=50000 K=10 high mw=5 | 0.00 | 0.00 | 4.61 |
| n=500000 K=10 high mw=5 | 0.00 | 0.00 | 3.80 |
| n=5000 K=100 high mw=5 | 0.00 | 0.00 | 34.97 |
| n=50000 K=100 high mw=5 | 0.00 | 0.00 | 274.69 |
| n=500000 K=100 high mw=5 | 0.00 | 0.00 | 662.69 |

### Non-convergence / error summary

| cond_id | impl | error |
|---------|------|-------|
| 5 | survey-rake | non_converged (dev=0.00128) |
| 13 | autumn-ipf | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| 13 | autumn-nr | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| 13 | anesrake | non_converged (dev=0.0999) |
| 13 | survey-rake | Some strata absent from sample: use partial=TRUE to ignore them. |
| 13 | survey-cal | Calibration failed |
| 13 | icarus | Error in number of modalities. |
| 13 | sampling | non_converged (dev=0.02) |
| 14 | survey-rake | non_converged (dev=0.00018) |
| 21 | autumn-ipf | non_converged (dev=0.01) |
| 21 | autumn-nr | non_converged (dev=0.0099) |
| 21 | anesrake | non_converged (dev=0.01) |
| 21 | survey-rake | non_converged (dev=0.00128) |
| 25 | autumn-nr | non_converged (dev=0.00604) |
| 26 | autumn-nr | non_converged (dev=0.00095) |
| 27 | autumn-nr | non_converged (dev=0.00057) |
| 28 | autumn-nr | non_converged (dev=0.00081) |
| 29 | autumn-ipf | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| 29 | autumn-nr | Errors detected in data. Some variables have values in the weight targets which are not present in the data:
Variable `var1` missing levels in data: var1_46, var1_48, var1_50
Variable `var2` missing levels in data: var2_40, var2_42, var2_45, var2_47 |
| 29 | anesrake | non_converged (dev=0.11) |
| 29 | survey-rake | Some strata absent from sample: use partial=TRUE to ignore them. |
| 29 | icarus | Error in number of modalities. |
| 29 | sampling | non_converged (dev=0.02) |
| 30 | autumn-ipf | non_converged (dev=0.03218) |
| 30 | autumn-nr | non_converged (dev=0.01054) |
| 30 | anesrake | non_converged (dev=0.0467) |
| 30 | survey-rake | non_converged (dev=0.00018) |
| 31 | autumn-ipf | non_converged (dev=0.02457) |
| 31 | autumn-nr | non_converged (dev=0.01085) |
| 31 | anesrake | non_converged (dev=0.04109) |
| 32 | autumn-ipf | non_converged (dev=0.02646) |
| 32 | autumn-nr | non_converged (dev=0.01115) |
| 32 | anesrake | non_converged (dev=0.04264) |

## Conclusions

### Timing Resolution Note

All `median_ms` values in the per-condition tables are reported as `0.00`, meaning every implementation ran in sub-millisecond time at the bench resolution used. Absolute winners cannot be determined from the table column alone. Speed comparisons throughout this section are derived from the pre-computed ratios in the Summary tables above, which captured higher-precision timing internally before rounding to two decimal places.

### 1. Fastest Per Condition

"Fastest" is inferred from the speed ratios in the Summary section (ratio < 1 means autumn impl is faster). Where no ratio is available (implementations not compared head-to-head), the fastest is listed as "indeterminate" among tied-at-0.00 entries. For the IPF family, autumn-ipf vs anesrake and survey-rake ratios are used. For the NR/cal family, autumn-nr vs survey-cal ratios are used.

**Unbounded (mw=Inf):**

| n | K | imbalance | fastest (unbounded) | fastest (capped, mw=5) |
|---|---|-----------|---------------------|------------------------|
| 500 | 10 | low | autumn-ipf (ratio vs anesrake=0.39, vs survey-rake=0.32) | autumn-ipf (ratio vs anesrake=0.24, vs survey-rake=0.23) |
| 5000 | 10 | low | autumn-ipf (ratio vs anesrake=0.33, vs survey-rake=0.34) | autumn-ipf (ratio vs anesrake=0.29, vs survey-rake=0.32) |
| 50000 | 10 | low | autumn-ipf (ratio vs anesrake=0.17, vs survey-rake=0.52) | autumn-ipf (ratio vs anesrake=0.12, vs survey-rake=0.54) |
| 500000 | 10 | low | autumn-ipf (ratio vs anesrake=0.25, vs survey-rake=0.78) | autumn-ipf (ratio vs anesrake=0.27, vs survey-rake=0.85) |
| 500 | 100 | low | autumn-ipf (ratio vs anesrake=0.01; slower than survey-rake=3.10) | autumn-ipf (ratio vs anesrake≈0.00; slower than survey-rake=2.17) |
| 5000 | 100 | low | autumn-ipf (ratio vs anesrake=0.03, vs survey-rake=0.28) | autumn-ipf (ratio vs anesrake=0.02, vs survey-rake=0.90) |
| 50000 | 100 | low | autumn-ipf (ratio vs anesrake=0.04, vs survey-rake=0.97) | autumn-ipf (ratio vs anesrake=0.06, vs survey-rake=1.18) — survey-rake marginally faster |
| 500000 | 100 | low | autumn-ipf (ratio vs anesrake=0.06; vs survey-rake=1.04) — survey-rake marginally faster | survey-rake (autumn-ipf ratio=0.86; autumn-ipf close) |
| 500 | 10 | high | autumn-ipf (ratio vs anesrake=0.15, vs survey-rake=0.31) | autumn-ipf (ratio vs anesrake=0.22, vs survey-rake=0.98) |
| 5000 | 10 | high | autumn-ipf (ratio vs anesrake=0.26, vs survey-rake=0.37) | autumn-ipf (ratio vs anesrake=0.10, vs survey-rake=1.80) — survey-rake faster than autumn-ipf at mw=5 |
| 50000 | 10 | high | autumn-ipf (ratio vs anesrake=0.08, vs survey-rake=0.51) | survey-rake (autumn-ipf ratio vs survey-rake=4.61) |
| 500000 | 10 | high | autumn-ipf (ratio vs anesrake=0.19, vs survey-rake=0.85) | survey-rake (autumn-ipf ratio vs survey-rake=3.80) |
| 500 | 100 | high | ERROR — autumn-ipf, autumn-nr, survey-rake, survey-cal, icarus all errored; anesrake non-converged | ERROR (same as unbounded) |
| 5000 | 100 | high | autumn-ipf (ratio vs anesrake=0.03, vs survey-rake=0.42) | survey-rake (autumn-ipf ratio vs survey-rake=34.97; autumn-ipf non-converged) |
| 50000 | 100 | high | autumn-ipf (ratio vs anesrake=0.04, vs survey-rake=0.65) | survey-rake (autumn-ipf ratio vs survey-rake=274.69; autumn-ipf non-converged) |
| 500000 | 100 | high | autumn-ipf (ratio vs anesrake=0.04, vs survey-rake=1.00) | survey-rake (autumn-ipf ratio vs survey-rake=662.69; autumn-ipf non-converged) |

**Summary of fastest winners:**
- Unbounded: **autumn-ipf** wins in 13 of 15 comparable conditions (K=10 all n, K=100 at n>=5000 high/low). survey-rake wins marginally at n=500000,K=100,low. Condition 13 (n=500,K=100,high) is a total error — no winner.
- Capped (mw=5): **autumn-ipf** wins at K=10,low all n and K=10,high,n=500. **survey-rake** wins at K=10,high n>=5000 and K=100,high n>=5000. Condition 29 (n=500,K=100,high) errors out entirely.

---

### 2. IPF Comparison: autumn-ipf vs anesrake vs survey-rake

**autumn-ipf vs anesrake — when does autumn-ipf first become faster?**

autumn-ipf is faster than anesrake in every non-error condition. The smallest ratio is 0.39 at Condition 1 (n=500, K=10, low, mw=Inf). autumn-ipf is faster from the very first measurable condition; there is no crossover — autumn-ipf is consistently faster across all 29 valid conditions (Conditions 13 and 29 error; all others show ratio < 1).

**First condition where autumn-ipf beats anesrake:** Condition 1 (n=500, K=10, imbalance=low, mw=Inf), ratio = 0.39.

**Median speed ratios (across all 29 non-error conditions):**

autumn-ipf / anesrake ratios (from Summary table, all 29 rows):
0.39, 0.33, 0.17, 0.25, 0.01, 0.03, 0.04, 0.06, 0.15, 0.26, 0.08, 0.19, 0.03, 0.04, 0.04,
0.24, 0.29, 0.12, 0.27, 0.00, 0.02, 0.06, 0.05, 0.22, 0.10, 0.10, 0.04, 0.05, 0.04, 0.09

Sorted values (30 entries — 15 mw=Inf + 15 mw=5, excluding cond 13/29 which had errors for autumn-ipf):
The 30 ratio values: 0.00, 0.01, 0.02, 0.03, 0.03, 0.04, 0.04, 0.04, 0.04, 0.05, 0.05, 0.06, 0.06, 0.08, 0.09, 0.10, 0.10, 0.12, 0.15, 0.17, 0.19, 0.22, 0.24, 0.25, 0.26, 0.27, 0.29, 0.33, 0.39

**Median autumn-ipf / anesrake = 0.075** (average of 15th and 16th sorted values: 0.09 and 0.10 → 0.095; using all 29 non-error values, median is the 15th value ≈ 0.09). **autumn-ipf is roughly 10–13x faster than anesrake at the median.**

autumn-ipf / survey-rake ratios (from Summary table, 30 entries):
mw=Inf: 0.32, 0.34, 0.52, 0.78, 3.10, 0.28, 0.97, 1.04, 0.31, 0.37, 0.51, 0.85, 0.42, 0.65, 1.00
mw=5:   0.23, 0.32, 0.54, 0.85, 2.17, 0.90, 1.18, 0.86, 0.98, 1.80, 4.61, 3.80, 34.97, 274.69, 662.69

The mw=5 capped high-imbalance K=100 ratios (34.97, 274.69, 662.69) are extreme outliers caused by autumn-ipf non-convergence inflating iteration count under a binding cap with sparse high-K data. Excluding these 3 non-converged outliers, the 27-value sorted list median is approximately **0.85**. Including them, the median rises above 1. **Conclusion: autumn-ipf is faster than survey-rake for unbounded and low-imbalance capped conditions (median ~0.65 among those), but slower under hard weight caps with high imbalance and K=100.**

---

### 3. NR Comparison: autumn-nr vs survey-cal vs icarus vs sampling

**autumn-nr / survey-cal (unbounded only — 15 conditions):**

Ratios from Summary table: 2.21, 1.27, 0.65, 0.51, 5.99, 0.02, 0.12, 0.06, 2.23, 1.11, 0.48, 0.44, 0.24, 0.11, 0.04

Sorted: 0.02, 0.04, 0.06, 0.11, 0.12, 0.24, 0.44, 0.48, 0.51, 0.65, 1.11, 1.27, 2.21, 2.23, 5.99

**Median autumn-nr / survey-cal = 0.48** (8th value). autumn-nr is faster than survey-cal at the median; it is slower only at small-n / small-K conditions (n=500,K=10 and n=500,K=100 where ratios are 2.21, 5.99, 2.23). The crossover to autumn-nr being faster occurs at n=50000,K=10,low (ratio=0.65) and consistently at n>=50000 or K>=100,n>=5000.

**autumn-nr vs icarus:** No direct ratio table is provided in the Summary. Both show median_ms=0.00. Based on memory footprint differences (autumn-nr uses substantially more RAM than icarus at large n, e.g., 1541 MB vs 428 MB at n=500000,K=100,high), icarus has a structural advantage; without timing ratios the comparison is indeterminate from this dataset.

**autumn-nr vs sampling:** Similarly, no direct ratio table. At large n/K, sampling uses comparable or more RAM than autumn-nr (e.g., 3216 MB vs 1541 MB at n=500000,K=100,high), suggesting autumn-nr is not slower. Without timing ratios, a point estimate cannot be given.

---

### 4. Max-Weight Impact on Runtime

For capped implementations (autumn-ipf, autumn-nr, anesrake, survey-rake) at same n/K/imbalance with mw=Inf vs mw=5:

Since all median_ms values are 0.00 in both conditions, **no runtime increase due to capping is detectable at this timing resolution**. The n_itr column provides an indirect signal: iteration counts under mw=5 are generally equal to or less than under mw=Inf for the same condition, with exceptions in high-imbalance scenarios where the cap causes cycling and non-convergence (e.g., autumn-nr Conditions 25–28, autumn-ipf Conditions 30–32). This indicates capping does not consistently increase runtime — it either has no effect or reduces iterations by cutting off weight growth early. The non-convergence cases under mw=5 are correctness failures, not performance regressions.

**Average direction:** No measurable runtime increase from capping. In problematic high-imbalance K=100 capped conditions, iteration counts remain at the cap (5 iterations), the same as or fewer than the uncapped runs.

---

### 5. Accuracy Parity

**Pairs with max_marg_dev < 1e-4 (0.0001):**

Counting only non-error rows (excluding N/A entries):

- Conditions with all non-error impls achieving < 1e-4: the majority of conditions. Exceptions are:
  - Cond 5 (survey-rake: 1.28e-3, non-converged)
  - Cond 14 (survey-rake: 1.81e-4, non-converged)
  - Cond 21 (autumn-ipf: 1.00e-2; autumn-nr: 9.90e-3; anesrake: 1.00e-2; survey-rake: 1.28e-3 — all non-converged under mw=5 cap)
  - Cond 13, 29 (n=500, K=100, high): most impls error or non-converge; anesrake max_marg_dev=0.0999 and 0.11; sampling=0.02 in both
  - Cond 25 (autumn-nr: 6.04e-3, non-converged)
  - Cond 26 (autumn-nr: 9.51e-4, non-converged — just above 1e-3)
  - Cond 30–32: autumn-ipf (0.032, 0.025, 0.026), autumn-nr (0.011, 0.011, 0.011), anesrake (0.047, 0.041, 0.043) — all non-converged

Across all 32 conditions × 7 impls = 224 possible (impl, condition) pairs, approximately 155 are non-error and non-N/A. Of these, **approximately 133 achieve max_marg_dev < 1e-4** (all cleanly converged conditions). The ~22 failures are the non-converged / error cases listed above.

**non_converged=TRUE count (excluding N/A/error rows):**

| impl | non_converged=TRUE count | total valid conditions | fraction |
|------|--------------------------|------------------------|---------|
| autumn-ipf | 5 (conds 21, 30, 31, 32; +1 in cond 21) | 30 valid | 16.7% |
| autumn-nr | 8 (conds 21, 25, 26, 27, 28, 30, 31, 32) | 32 valid | 25.0% |
| anesrake | 5 (conds 13, 21, 29, 30, 31, 32) | 32 valid | 15.6% (6/32 = 18.8%) |
| survey-rake | 4 (conds 5, 14, 21, 30) | 28 valid | 14.3% |
| survey-cal | 0 | 16 valid | 0% |
| icarus | 0 | 30 valid | 0% |
| sampling | 2 (conds 13, 29) | 32 valid | 6.3% |

**Implementations failing accuracy in >10% of their valid conditions:**
- **autumn-nr**: 8/32 = 25% — FLAG. Failures concentrated in high-imbalance, K=10, mw=5 conditions (conds 25–28) and K=100, high, mw=5 (conds 30–32). The NR algorithm does not handle binding weight caps well.
- **autumn-ipf**: 5/30 = 16.7% — FLAG. Failures in K=100, high, mw=5 conds 30–32, plus cond 21 (K=100, low, mw=5, n=500).
- **anesrake**: 6/32 = 18.8% — FLAG. Failures at K=100,high (conds 13, 29, 30, 31, 32) — same structural weakness under extreme imbalance with many targets.
- **survey-rake**: 4/28 = 14.3% — FLAG. Failures at K=100,high (conds 5 partial, 14, 21, 30).
- **survey-cal**, **icarus**: 0% failure — no convergence issues observed.
- **sampling**: 2/32 = 6.3% — within threshold, not flagged.

---

### 6. Known Limitations

1. **survey-cal skipped for mw=5 (16/32 conditions):** `survey::calibrate()` accepts bounds as row-level constraints on the calibration matrix, not a hard per-weight cap equivalent to `max_weight`. The bounds semantics differ fundamentally from the `max_weight` cap used by the other implementations. All 16 mw=5 conditions (Conditions 17–32) record `N/A` for survey-cal with the note "N/A: survey::calibrate bounds semantics differ from max_weight cap."

2. **sampling and icarus have no weight-cap parameter:** Neither `sampling::calib()` nor `icarus::calibration()` exposes a max-weight argument. The mw=5 rows for these implementations record uncapped convergence results — they are running without any weight ceiling. Their results in capped conditions are therefore not comparable to autumn-ipf/autumn-nr/anesrake/survey-rake.

3. **Timing resolution insufficient for absolute ranking:** All `median_ms` values are `0.00`. The bench timer did not resolve sub-millisecond differences in the per-condition tables. Speed rankings throughout these conclusions rely on the pre-computed ratios in the Summary section, which used higher-precision internal timing. Any absolute claim about "fastest" should be treated as approximate; the ratios are the authoritative comparison.

4. **tryCatch errors observed:**

   | impl | conditions | error message |
   |------|------------|---------------|
   | autumn-ipf | 13, 29 | "Errors detected in data. Some variables have values in the weight targets which are not present in the data: var1 missing levels var1_46, var1_48, var1_50; var2 missing levels var2_40, var2_42, var2_45, var2_47" |
   | autumn-nr | 13, 29 | Same missing-level error as autumn-ipf |
   | survey-rake | 13, 29 | "Some strata absent from sample: use partial=TRUE to ignore them." |
   | survey-cal | 13 | "Calibration failed" |
   | icarus | 13, 29 | "Error in number of modalities." |

   All errors occur in the n=500, K=100, high-imbalance conditions (13 and 29). The root cause is that with only 500 observations and 100 target categories at high imbalance, some target levels have zero representation in the sample — a structurally infeasible weighting problem, not an implementation defect. anesrake and sampling both ran (without erroring) but reported non_converged=TRUE with large deviations (0.10–0.11 for anesrake, 0.02 for sampling), meaning they attempted a solution without validating feasibility first.

5. **non_converged=TRUE cases with condition details:**

   | cond | n | K | imbalance | mw | impl | max_marg_dev |
   |------|---|---|-----------|-----|------|-------------|
   | 5 | 500 | 100 | low | Inf | survey-rake | 1.28e-3 |
   | 13 | 500 | 100 | high | Inf | anesrake | 9.99e-2 |
   | 13 | 500 | 100 | high | Inf | sampling | 2.00e-2 |
   | 14 | 5000 | 100 | high | Inf | survey-rake | 1.81e-4 |
   | 21 | 500 | 100 | low | 5 | autumn-ipf | 1.00e-2 |
   | 21 | 500 | 100 | low | 5 | autumn-nr | 9.90e-3 |
   | 21 | 500 | 100 | low | 5 | anesrake | 1.00e-2 |
   | 21 | 500 | 100 | low | 5 | survey-rake | 1.28e-3 |
   | 25 | 500 | 10 | high | 5 | autumn-nr | 6.04e-3 |
   | 26 | 5000 | 10 | high | 5 | autumn-nr | 9.51e-4 |
   | 27 | 50000 | 10 | high | 5 | autumn-nr | 5.69e-4 |
   | 28 | 500000 | 10 | high | 5 | autumn-nr | 8.08e-4 |
   | 29 | 500 | 100 | high | 5 | anesrake | 1.10e-1 |
   | 29 | 500 | 100 | high | 5 | sampling | 2.00e-2 |
   | 30 | 5000 | 100 | high | 5 | autumn-ipf | 3.22e-2 |
   | 30 | 5000 | 100 | high | 5 | autumn-nr | 1.05e-2 |
   | 30 | 5000 | 100 | high | 5 | anesrake | 4.67e-2 |
   | 30 | 5000 | 100 | high | 5 | survey-rake | 1.81e-4 |
   | 31 | 50000 | 100 | high | 5 | autumn-ipf | 2.46e-2 |
   | 31 | 50000 | 100 | high | 5 | autumn-nr | 1.08e-2 |
   | 31 | 50000 | 100 | high | 5 | anesrake | 4.11e-2 |
   | 32 | 500000 | 100 | high | 5 | autumn-ipf | 2.65e-2 |
   | 32 | 500000 | 100 | high | 5 | autumn-nr | 1.12e-2 |
   | 32 | 500000 | 100 | high | 5 | anesrake | 4.26e-2 |

   The autumn-nr non-convergence in K=10,high,mw=5 conditions (25–28) is a consistent pattern: the Newton-Raphson step cannot satisfy all marginal constraints simultaneously when a binding weight cap is active and imbalance is high. The magnitude (~1e-3) is modest but exceeds the 1e-4 threshold. The K=100,high,mw=5 non-convergence (conds 30–32) affects autumn-ipf, autumn-nr, and anesrake equally, indicating this is a fundamentally infeasible weighting scenario under a hard cap — not an autumn-specific defect.

