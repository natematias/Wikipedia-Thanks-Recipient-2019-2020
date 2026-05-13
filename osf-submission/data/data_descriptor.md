# Data descriptor

Documentation for the four anonymized CSV files in `csv/` and the auxiliary Wikistats counts in `active-user-count/`.

## References

- Pre-analysis plan: <https://osf.io/c67rg/>
- Analysis pipeline: `code/01_main_analysis.ipynb`

## Files

| File | Rows | Cols | Unit of observation |
|---|---:|---:|---|
| `csv/grat-thankee-all-pre-post-treatment-vars-max-cols.csv` | 15,558 | 40 | participant × wave |
| `csv/grat-thankee-all-pre-post-treatment-vars.csv` | 15,558 | 23 | participant × wave |
| `csv/gratitude-second-gen-thanks-analysis-with-reciprocal.csv` | 2,552 | 11 | second-gen thank event |
| `csv/2021-04-30-secondary-thanks.csv` | 488 | 5 | language × condition |
| `active-user-count/active user *.csv` | 4 files | — | language × month |

15,558 = 7,779 treated + 7,779 control across four language communities (3,072 ar, 5,434 de, 2,416 fa, 4,636 pl) and six recruitment waves between July 2019 and February 2020. 15,429 unique participants; 129 sampled into two waves.

## Important notes

### Identifiers (two of them)

- **`user.id.anonymous`** (str): user-level anonymized identifier. Same value for the same person across waves and across files. Use for cross-file joins (Max-Cols/Basic ⇄ second-gen-thanks).
- **`participant.wave.id`** (str, UUID): row-level. Unique within each wave. Use for the 1-to-1 row join between Max-Cols and Basic.

For 15,429/15,558 rows the two are equivalent. They differ only for the 129 participants sampled into multiple waves, where one `user.id.anonymous` corresponds to multiple `participant.wave.id` values.

### Date variables

- **`created.dt`**: randomization date (when the participant was added to the study system).
  - Caveat: First-wave control participants have `created.dt` 38 days later than their treated partner due to a DB ingestion artifact. As a result, the `created_dt` is incorrect for these control participants.
- **`behavior.start.dt`**: when the volunteer sent the first-generation thank to the treated member of the matched pair, or alternatively, the corrected date of assignment for members of the pair. This is **identical for both members of every matched pair. This is the correct lag baseline** for any "after thanks" analysis.
- **`first.gen.thank.ts`** (in the second-gen file only): `created_at` of an internal software record for the first-gen thanking event ≈ enrollment date that is useful for software diagnostics purposes. This is not the thanks-receipt date. Do not use in analysis.
- **`second.gen.thank.ts`**: when a second-generation thank was sent. The behavioral outcome.

### Special values

- Empty string `""` (= `NA` after read): value not observed.
- `"-1"` in `first.gen.sender.user.id.anonymous`: synthetic placeholder for a control participant (no real first-gen sender). 1,651/2,552 rows.
- `bin_deleted` in `prev.experience.treatment`: account was deleted by the user or by the Wikipedia platform before treatment could be delivered.

---

## 1. `grat-thankee-all-pre-post-treatment-vars-max-cols.csv` (Max-Cols)

Full participant-level dataset. One row per participant per wave. Canonical source for all ITT analyses.

### Identifier and randomization

- `user.id.anonymous` (str): user-level anonymized identifier. User-level join key.
- `participant.wave.id` (str, UUID): row-level identifier. Row-level join key.
- `randomization.block.id` (int): matched-pair (or matched-tuple) block. Treated and control members of the same block share this value.
- `randomization.arm` (int 0/1): 1 = assigned to receive a first-gen thank; 0 = matched control.
- `randomization.condition` (str): constant `"thankee"` for all rows.
- `lang` (str): `ar`, `de`, `fa`, `pl`.
- `year` (int): year of first edit (2005–2020).
- `prev.experience.assignment` (str): experience level at randomization. One of `bin_0` (newcomer, < 90 days), `bin_90`, `bin_180`, `bin_365`, `bin_730`, `bin_1460`, `bin_2920`.
- `prev.experience.assignment.post.candidate` (str): same levels as `prev.experience.assignment`, recomputed for the user interface at the moment the participant was about to be shown to a volunteer. Not used for assignment or analysis.
- `prev.experience.treatment` (str): experience level at the moment of treatment delivery. Adds the `bin_deleted` level for accounts deleted before treatment.

### Additional Timestamps

- `removed.dt` (datetime | NA): when the participant was removed from the study (GDPR request, account deletion).
- ``first.thank.dt` (datetime | ""): when this participant first received a first-gen thank. Populated only for treated participants who were actually thanked.
- `user.registration.dt` (datetime): when the participant created their Wikipedia account.
- `user.registration.dt.sync.object` (datetime): same as above; used for data integrity checks within the software system.
- `created.dt.sync.object` (datetime): when the matched-pair `sync_object` was created in the CivilServant DB. Not used in analysis.

### Pre- / post-treatment outcomes

The 84-day pre-intervention window ends at `behavior.start.dt`. The post-window is the 84 days starting at `behavior.start.dt` for retention and labor hours; cumulative thanks-sent counts span the full post-treatment study period.

- `two.week.retention` (bool): edited at least once during days 1–14 after `behavior.start.dt`.
- `labor.hours.pre.treatment` (num): total estimated labor hours over the 84-day pre-window. Computed using the method described in [Halfaker et al 2013](https://dl.acm.org/doi/10.1145/2441776.2441873).
- `labor.hours.post.treatment` (num): total estimated labor hours over the 84 day post-window. Computed using the method described in [Halfaker et al 2013](https://dl.acm.org/doi/10.1145/2441776.2441873).
- `labor.hours.per.day.pre.treatment` (num): `labor.hours.pre.treatment / 84`.
- `labor.hours.per.day.post.treatment` (num): `labor.hours.post.treatment / 84`.
- `labor.hours.per.day.diff` (num): `post − pre`. The pre-registered ITT outcome.
- `thanks.sent` (int): number of first-gen thanks the participant **sent** to other editors during the post-window. Pre-registered ITT outcome for second-gen thanks.
- `thanks.sent.pre.treatment` (int): same, pre-window.

### Treatment-delivery internal software records

- `number.thanks.received` (int): number of first-gen thanks received from volunteers in the study as part of the treatment using the research software. By design, 0 for control; ≥ 1 for the 31% of treated newcomers / 43% of treated experienced who were actually selected and thanked. If a participant was thanked outside of the software that delivered the intervention, it would not be recorded here.
- `number.skips.received` (int): times a volunteer was shown this participant in the app but clicked *Skip*.
- `num.messages` (int): times a volunteer-thanker sent a thanks message via the app's UI (separate from the MediaWiki Thanks extension).
- `num.errors` (int): times the app recorded a delivery error.
- `received.multiple.thanks` (bool): `number.thanks.received >= 2`.
- `thanks.not.received.skipped` (bool): skipped at least once and never thanked.
- `thanks.not.received.not.seen` (bool): loaded into the app but never shown to a volunteer.
- `thanks.not.received.error` (bool): at least one delivery attempt errored.
- `thanks.not.received.user.deleted` (bool): account deleted before treatment.
- `complier` (bool): pre-registered compliance — `randomization.arm == 1` AND `number.thanks.received >= 1`. 786 / 7,779 treated.
- `complier.app.any.reason` (bool): broader compliance — treated AND seen by a volunteer (received, skipped, or errored).
- `consent` (bool): always `True` in the public dataset.
- `has.email` (bool): account had a verified email at sampling. Eligibility for the survey arm; not used in pre-registered ITT analyses.

### Survey responses

Dichotomized to `True/False/NA`. Present only for participants who responded to the post-study debriefing survey. The other pre-registered survey items (overall experience, three social-value items, two social-warmth items, etc.) were withdrawn after data collection because of low response rate and are not included in this dataset. Full questionnaire in `supplementary-materials/Wikipedia Thanker Study IRB Supplementary Materials Jan 2019, emended May 2019.pdf`.

- `community` (bool): sense-of-community composite.
- `remembered.thanks` (bool): self-reported recall of receiving thanks. Used as the manipulation check.

---

## 2. `grat-thankee-all-pre-post-treatment-vars.csv` (Basic)

A 23-column subset of Max-Cols holding only the columns referenced in the pre-registered specifications. Same row count, same identifiers.

Columns (all defined in § 1): `user.id.anonymous`, `participant.wave.id`, `randomization.block.id`, `randomization.arm`, `lang`, `year`, `has.email`, `prev.experience.assignment`, `prev.experience.treatment`, `labor.hours.per.day.diff`, `two.week.retention`, `thanks.sent`, `thanks.sent.pre.treatment`, `remembered.thanks`, `complier`, `complier.app.any.reason`, `number.thanks.received`, `number.skips.received`, `thanks.not.received.skipped`, `thanks.not.received.not.seen`, `thanks.not.received.error`, `thanks.not.received.user.deleted`, `received.multiple.thanks`.

The labor-hour pre/post columns are **not** in this file (the pre-registered specification used only `labor.hours.per.day.diff`). To recover them, merge with Max-Cols on `participant.wave.id`:

```r
pre.post <- max[, c("participant.wave.id",
                    "labor.hours.pre.treatment", "labor.hours.post.treatment",
                    "labor.hours.per.day.pre.treatment", "labor.hours.per.day.post.treatment")]
basic <- merge(basic, pre.post, by = "participant.wave.id")
```

---

## 3. `gratitude-second-gen-thanks-analysis-with-reciprocal.csv` (Second-gen edge list)

One row per `(second-gen sender, second-gen recipient, second-gen timestamp)` triple involving a study participant.

- `user.id.anonymous` (str): focal study participant for this row. Equals one of `second.gen.sender.user.id.anonymous` or `second.gen.recipient.user.id.anonymous` depending on which side of the second-gen thank the participant was on. Join key into Max-Cols/Basic.
- `second.gen.thank.ts` (datetime): when the second-gen thank was sent. Range: 2019-07-31 to 2020-03-15.
- `second.gen.sender.user.id.anonymous` (str): anonymized identifier of the editor who sent the second-gen thank. May or may not be a study participant.
- `second.gen.recipient.user.id.anonymous` (str): anonymized identifier of the editor who received it. May or may not be a study participant.
- `lang` (str): language community of the second-gen event.
- `first.gen.recipient.user.id.anonymous` (str): anonymized identifier of the participant who received the first-gen thank that connects this row to the experiment.
- `first.gen.sender.user.id.anonymous` (str | "-1"): anonymized identifier of the volunteer-thanker. `-1` for synthetic control rows (1,651/2,552).
- `first.gen.thank.ts` (datetime): `created_at` of the CivilServant ExperimentThing — **enrollment**, not thanks-receipt date. Do not use as a lag baseline.
- `behavior.start.dt` (datetime): when the volunteer actually sent the first-gen thank. Identical for both members of every matched pair. The correct lag baseline.
- `second.gen.recipient.is.first.gen.sender` (bool): `True` (6 rows) = participant thanked back the volunteer who originally thanked them (direct reciprocation). `False` (2,546 rows) = third party (upstream/generalized reciprocity).
- `within_experiment_window` (bool): `True` everywhere in this file.

---

## 4. `2021-04-30-secondary-thanks.csv` (Aggregate counts)

Per-language per-condition aggregate counts. No identifiers — pure counts. 488 rows.

- `condition` (int 0/1): 1 = treated, 0 = control.
- `lang` (str): `ar`, `de`, `fa`, `pl`.
- `identifiable.thanks.sent` (int): second-gen thanks where sender, recipient, and timestamp could all be matched against the experiment's records.
- `reciprocal.thanks.sent` (int): subset where the recipient was the participant's first-gen sender.
- `nonreciprocal.thanks.sent` (int): `identifiable.thanks.sent − reciprocal.thanks.sent`.

---

## 5. `active-user-count/active user {arabic,german,persian,polish}.csv` (Wikistats)

Monthly active-editor counts per language, exported from Wikistats. Used to compute per-1,000-active-editor adjustments in Tables S11–S12. Aggregate community counts only (no individual identifiers).

- `month` (str, "YYYY-MM-DD"): first day of the month.
- `total.total` (int): total active editors that month.
- (Additional Wikistats columns retained verbatim.)

---

## Cached analysis outputs (not raw data)

- `paper-data.RData`: 38 R dataframes produced by `code/01_main_analysis.ipynb` § 14. The manuscript LaTeX reads this file when it is compiled, to fill in inline numbers (means, percentages, p-values, sample sizes).
- `ITT_table.RData`: cached ITT results produced by `code/01_main_analysis.ipynb` § 6. Read by the manuscript LaTeX alongside `paper-data.RData`.

Both regenerable by re-running the notebook from the four CSVs above.
