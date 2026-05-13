# Code

End-to-end analysis pipeline for the Wikipedia Thanks Recipient study.

```
code/
├── 01_main_analysis.ipynb        <- main analysis (Jupyter, R kernel)
├── 02_power_analysis.R           <- pre-experiment power analysis
├── si_tables.R                   <- LaTeX table builders sourced by supporting-information-2.Rtex
└── README.md                     <- this file
```

The notebook writes outputs to `osf-submission/figs/`, `osf-submission/tables/`, and `osf-submission/data/`. Each location can be redirected via the `WIKIPEDIA_FIGS_DIR`, `WIKIPEDIA_TABLES_DIR`, `WIKIPEDIA_DATA_DIR`, `WIKIPEDIA_RDATA_DIR`, or `WIKIPEDIA_ACTIVE_USER_DIR` environment variables.

**Acronyms used.** *ITT* = intent-to-treat (effect of being assigned to receive thanks, regardless of whether thanks were actually delivered). *CACE* / *IV* = complier-average causal effect, estimated by two-stage least squares; we explored these but the published paper reports ITT only. *DHARMa* = an R package for residual diagnostics on generalized linear (mixed) models. *Tweedie GLMM* = the general linear mixed model family used for the labor-hours outcome (handles the overdisperson of zeros and highly skewed data).


## What `02_power_analysis.R` does

Standalone pre-experiment simulation that motivated the sample-size targets in Methods. It generates synthetic data under the pre-registered minimum detectable effects (15-minute increase in daily labor hours, 25% relative increase in two/four-week retention, 0.1 additional thanks sent per participant over 90 days) and reports the empirical power. It does not read the experimental data.

