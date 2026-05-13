# How thanking peers sustains volunteer participation in public goods: parallel field experiments in four Wikipedia language communities

**Authors:** J. Nathan Matias¹*, Julia Kamin², Reem Al-Kashif, Wanqing Psyche He³, Max Klein, Eric Pennington⁴

¹ Cornell University, Department of Communication, Ithaca, USA
² Prosocial Design Network, USA
³ Cornell University, Department of Information Science, Ithaca, USA
⁴ Harvard University, Boston, USA

**Corresponding author:** J. Nathan Matias — <nathan.matias@cornell.edu>

**Date posted:** April 2026

**Status:** Manuscript currently under peer review.

---

## Brief description

This OSF repository serves for a scholarly paper reporting four parallel field experiments conducted on the Arabic, German, Persian, and Polish Wikipedia communities between August 2019 and February 2020. Across the four communities, 313 experienced volunteer editors used a custom software application ("Superthanker") to send private "Thanks" messages to a randomly selected half of 15,274 matched-pair vetted contributors. We measured the effect of receiving a single peer thank-you on (a) two-week retention rate of accounts, (b) labor hours per day over the next six weeks, and (c) the rate at which recipients went on to thank others.

We find that receiving private thanks from a peer increased (a) two-week retention, (b) labor hours per day among newcomers, and (c) the rate at which recipients sent thanks to other editors. Second-generation thanks went predominantly to third parties rather than back to the original sender, consistent with theories of upstream (generalized) reciprocity in public goods. Throughout this README file, **ITT** (intent-to-treat) means the effect of being randomly *assigned* to receive thanks, regardless of whether the thanks were actually delivered.

---

## Pre-registration

- Pre-analysis plan on the Open Science Framework (OSF): <https://osf.io/c67rg/>

---

## Wikipedia community announcements

The study was publicly described, and feedback invited, on the language-specific Village Pump of each participating Wikipedia community before recruitment began. The full per-community consent and governance process is documented in the *Community Consent and Governance* section of the Supporting Information.

The unified, cross-community research description was hosted on Meta-Wiki and on the Citizens and Technology Lab project page:

- <https://meta.wikimedia.org/wiki/Research:Testing_capacity_of_expressions_of_gratitude_to_enhance_experience_and_motivation_of_editors>
- <https://citizensandtech.org/research/how-do-wikipedians-thank-each-other/>

The eligibility criteria per language community is provided in **Table S3** of the Supporting Information, with direct links to the Wikimedia Foundation model pages for the three ORES good-faith classifiers used in Arabic, Persian, and Polish Wikipedia. German Wikipedia used the editor-assigned "flagged revision" status instead of ORES.

---

## Study materials

All participant-facing study materials (recruitment notices, consent and debriefing scripts, GDPR notices, survey instruments, and Superthanker UI strings) are included in this project in two places:

- **Translations of the volunteer-thanker ("Superthanker") web application UI** provided in Supporting Information (Figure S2) with the German example. The copy of the Arabic, German, Persian, and Polish translations is the project's source repository:
    - <https://github.com/citizensandtech/civilservant-wiki-thanker-web-ui/blob/master/src/assets/i10n/gratitude_internationalizations.csv.index.json>
    - This JSON manifest indexes per-language CSVs holding every UI string, button label, instruction, and explanatory paragraph shown to volunteer-thankers across the four communities.
- **Supplementary IRB materials, recruitment notices, and consent/debriefing scripts** — the consolidated PDF is included in this OSF project: https://osf.io/95q4d. It contains the full IRB protocol (including the May 2019 emendation) along with translations of the participant-facing communications used in each of the four language communities.
- **Power analysis** — the simulation-based pre-experiment power analysis and visualization are available in the OSF: `https://osf.io/j64vs/`, folder `power analysis`.

---

## Analysis materials

Everything needed to re-run the statistical analyses reported in the manuscript is in this project. There are three components:

1. **Code** — `code/01_main_analysis.ipynb` is the end-to-end Jupyter (R kernel) pipeline that performs every model fit, table, and figure in the paper. `code/02_power_analysis.R` is the standalone simulation-based power calculation referenced in Methods.
2. **Data** — four anonymized CSV files in `data/csv/` covering all units of observation used in the analysis.
3. **Data descriptor** — `data/data_descriptor.md` documents every column of every CSV, the dual-identifier scheme, the four date variables, and the sentinel values.

---

## Files and folders included in this OSF project

```
osf-submission/
├── README.md                              <- this file
├── code/                                  <- analysis code (single notebook + pre-experiment power analysis)
│   ├── README.md                          <- section-by-section walkthrough of the notebook
│   ├── 01_main_analysis.ipynb             <- canonical end-to-end Jupyter (R kernel) pipeline (19 sections)
│   └── 02_power_analysis.R                <- pre-experiment power simulation (Methods § statistical power)
├── data/
│   ├── data_descriptor.md                 <- per-column documentation of every CSV
│   ├── csv/                               <- four anonymized analysis CSVs
│   ├── active-user-count/                 <- four monthly-active-editor CSVs from Wikistats
│   ├── paper-data.RData                   <- cached analysis dataframes (produced by 01_main_analysis.ipynb)
│   └── ITT_table.RData                    <- cached ITT results (produced by 01_main_analysis.ipynb)
├── figs/                                  <- published figures (PDF + PNG); all analysis-derived figures regenerable from 01_main_analysis.ipynb
├── power analysis/                        <- the power analysis simulation and visualization
│   ├── thanks-recipient-experiment-power-analysis-terminal.R
│   ├── Plot Thank-Recipient Power Analysis Results June 2019.ipynb
│   ├── thanks-recipient-experiment-power-analysis-R.ipynb
├── pre-registration/                      <- two pre-registered study plans
│   ├── Receiving-Thanks-On-Wikipedia-Experiment-Plan-07.2019.pdf       <- the current study plan
│   ├── Sending-Thanks-Wikipedia-Experiment-Plan-07.2019.pdf            <- volunteer of thanks recruitment plan
├── tables/                                <- 6 published .tex tables (5 regenerable from 01_main_analysis.ipynb; thankee_table1.tex is hand-coded)
└── supplementary-materials/
    └── Wikipedia Thanker Study IRB Supplementary Materials Jan 2019, emended May 2019.pdf
```


### `data/csv/`

The four anonymized analysis CSVs. Participants are identified by `user.id.anonymous` (user-level) and `participant.wave.id` (row-level). See `data/data_descriptor.md` for full documentation.

| File | Rows | Cols | Description |
|---|---:|---:|---|
| `grat-thankee-all-pre-post-treatment-vars-max-cols.csv` | 15,558 | 40 | The "Max-Cols" datafile: full participant-level dataset with randomization, time stamps, pre-/post-treatment outcomes, treatment-delivery audit fields, and the two retained survey items (sense-of-community composite and recall-of-thanks manipulation check). |
| `grat-thankee-all-pre-post-treatment-vars.csv` | 15,558 | 23 | The "Basic" datafile: 23-column subset of the Max-Cols file containing only the columns referenced in the pre-registered specifications. |
| `gratitude-second-gen-thanks-analysis-with-reciprocal.csv` | 2,552 | 11 | Edge list of every second-generation thank event traceable to a study participant, with first-generation provenance. Used for the spillover and reciprocity analyses. |
| `2021-04-30-secondary-thanks.csv` | 488 | 5 | Per-condition per-language aggregate counts of identifiable, reciprocal, and non-reciprocal second-gen thanks. |

---

## License

Code and text are released under the [Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/deed.en).

---

## Appendix: `sessionInfo()`

The session information below was captured under R 4.5.1 on macOS, with all packages used by `code/01_main_analysis.ipynb` attached.

```text
R version 4.5.1 (2025-06-13)
Platform: aarch64-apple-darwin25.0.0
Running under: macOS Tahoe 26.4.1

Matrix products: default
BLAS:   /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
LAPACK: /opt/homebrew/Cellar/r/4.5.1/lib/R/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] C.UTF-8/C.UTF-8/C.UTF-8/C/C.UTF-8/C.UTF-8

time zone: America/New_York
tzcode source: internal

attached base packages:
[1] grid      stats     graphics  grDevices utils     datasets  methods
[8] base

other attached packages:
 [1] sysfonts_0.8.9     scales_1.4.0       ggridges_0.5.7     DHARMa_0.4.7
 [5] performance_0.15.2 glmmTMB_1.1.13     knitr_1.51         png_0.1-8
 [9] ggpubr_0.6.2       lmerTest_3.1-3     lme4_1.1-37        Matrix_1.7-4
[13] ri2_0.4.1          randomizr_1.0.0    gridExtra_2.3      estimatr_1.0.6
[17] MASS_7.3-65        gmodels_2.19.1     magrittr_2.0.4     lubridate_1.9.4
[21] forcats_1.0.1      stringr_1.5.2      dplyr_1.1.4        purrr_1.1.0
[25] readr_2.1.5        tidyr_1.3.1        tibble_3.3.0       ggplot2_4.0.2
[29] tidyverse_2.0.0    AER_1.2-15         survival_3.8-3     sandwich_3.1-1
[33] lmtest_0.9-40      zoo_1.8-14         car_3.1-3          carData_3.0-5
[37] plyr_1.8.9

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.1    farver_2.1.2        S7_0.2.1
 [4] estimability_1.5.1  timechange_0.3.0    lifecycle_1.0.5
 [7] gdata_3.0.1         compiler_4.5.1      rlang_1.1.7
[10] tools_4.5.1         ggsignif_0.6.4      RColorBrewer_1.1-3
[13] abind_1.4-8         withr_3.0.2         numDeriv_2016.8-1.1
[16] xtable_1.8-4        emmeans_2.0.0       gtools_3.9.5
[19] insight_1.4.2       cli_3.6.5           mvtnorm_1.3-3
[22] reformulas_0.4.2    generics_0.1.4      otel_0.2.0
[25] tzdb_0.5.0          minqa_1.2.8         splines_4.5.1
[28] vctrs_0.7.1         boot_1.3-31         hms_1.1.4
[31] rstatix_0.7.3       Formula_1.2-5       glue_1.8.0
[34] nloptr_2.2.1        stringi_1.8.7       gtable_0.3.6
[37] pillar_1.11.1       R6_2.6.1            TMB_1.9.18
[40] Rdpack_2.6.4        evaluate_1.0.5      lattice_0.22-7
[43] rbibutils_2.3       backports_1.5.0     broom_1.0.12
[46] Rcpp_1.1.0          nlme_3.1-168        mgcv_1.9-3
[49] xfun_0.54           pkgconfig_2.0.3
```
