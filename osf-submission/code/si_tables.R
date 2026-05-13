# si_tables.R
# Builder functions for the auto-generated tabular bodies in
# supporting-information-2.Rtex. Sourced from the SI's <<init>>= chunk; each
# builder returns a single character string containing a complete
# \begin{tabular}...\end{tabular} block (no \begin{table}, \caption, or
# \label - those are added by wrap_si_table() if a complete float is needed).
#
# All builders take the dataframes they need explicitly so they have no
# hidden globals; data is supplied by paper-data.RData and ITT_table.RData.
#
# Two consumers of these builders:
#   (1) supporting-information-2.Rtex - knitr chunks call build_*() inside a
#       hand-written \begin{table}...\end{table} float, with caption text
#       pulled from si_captions via \Sexpr{}.
#   (2) 01_main_analysis.ipynb - the "Write SI Tables" cell calls
#       wrap_si_table(build_*(...), si_captions$<key>, ...) to emit complete
#       standalone .tex files into tables/ for the OSF deliverable.
#
# si_captions is therefore the single source of truth for caption text.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ---------------------------------------------------------------------------
# Formatters
# ---------------------------------------------------------------------------

# Number: 2 dp, but 4 dp if rounds to 0.00; below 4-dp precision render as
# $<$0.0001 / $<-$0.0001 (so tiny floating-point noise prints cleanly).
fmt <- function(x) {
  sapply(x, function(v) {
    if (is.na(v)) return("--")
    if (v == 0) return("0")
    if (abs(v) < 5e-5)     return(if (v < 0) "$<-$0.0001" else "$<$0.0001")
    if (abs(v) >= 0.005)   return(sprintf("%.2f", v))
    sprintf("%.4f", v)
  })
}

# p-value: smart thresholds with LaTeX-safe '<' for very small values.
fmt_p <- function(p) {
  sapply(p, function(v) {
    if (is.na(v)) return("--")
    if (v < 0.0001) return("$<$0.0001")
    if (v < 0.001)  return(sprintf("%.4f", v))
    if (v < 0.01)   return(sprintf("%.3f", v))
    sprintf("%.2f", v)
  })
}

# Percentage with LaTeX-escaped '%'.
fmt_pct <- function(x) {
  sapply(x, function(v) {
    if (is.na(v)) return("--")
    if (v == 0) return("0\\%")
    if (abs(v) < 0.005) return(sprintf("%.4f\\%%", v))
    sprintf("%.2f\\%%", v)
  })
}

# Mean (SD) string.
fmt_mean_sd <- function(x) {
  paste0(fmt(mean(x, na.rm = TRUE)), " (", fmt(sd(x, na.rm = TRUE)), ")")
}

# Null-coalescing operator (R has no built-in)
`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# Effect-size helpers
# ---------------------------------------------------------------------------

# Cohen's d (pooled SD).
cohen_d <- function(x1, x2) {
  m1 <- mean(x1, na.rm = TRUE); m2 <- mean(x2, na.rm = TRUE)
  s1 <- sd(x1,   na.rm = TRUE); s2 <- sd(x2,   na.rm = TRUE)
  s_pool <- sqrt((s1^2 + s2^2) / 2)
  if (is.na(s_pool) || s_pool == 0) return(0)
  (m2 - m1) / s_pool
}

# Cramer's V from a chi-squared test object.
cramer_v <- function(chi, n, k) sqrt(chi$statistic / (n * (k - 1)))

# ---------------------------------------------------------------------------
# Internal row emitters
# ---------------------------------------------------------------------------

# Used by the pooled and per-language ITT tables (S6, S7).
.itt_row <- function(r, group_label, mod_labels, est_labels, is_first) {
  mname <- as.character(r$model)
  sprintf("%s & %s & %s & %s & %s & %s & %s & [%s, %s] \\\\",
    if (is_first) group_label else "",
    mod_labels[mname], est_labels[mname],
    formatC(r$n.size, big.mark = ","),
    fmt(r$Estimate), fmt(r$Std..Error), fmt_p(r$pvalue),
    fmt(r$CI.Lower), fmt(r$CI.Upper))
}

# ---------------------------------------------------------------------------
# Table: Pre-treatment balance (Treatment vs Control)  -> table:balance
# ---------------------------------------------------------------------------
build_balance_table <- function(participants) {
  ctrl <- subset(participants, TREAT == 0)
  trt  <- subset(participants, TREAT == 1)

  exp_levels <- sort(unique(participants$prev.experience.assignment.days))
  exp_labels <- ifelse(exp_levels == 0, "Newcomer (0 days)",
                       paste0(exp_levels, " days"))

  L <- c(
    "\\begin{tabular}{lrrrll}",
    "\\toprule",
    " & \\textbf{Control} & \\textbf{Treatment} & \\textbf{Total} & \\textbf{p-value} & \\textbf{Std.~Diff.} \\\\",
    sprintf(" & (N = %s) & (N = %s) & (N = %s) & & \\\\",
            formatC(nrow(ctrl), big.mark = ","),
            formatC(nrow(trt),  big.mark = ","),
            formatC(nrow(participants), big.mark = ",")),
    "\\midrule",
    "\\multicolumn{6}{l}{\\textit{Previous experience category}} \\\\"
  )

  # Experience rows (chi-squared test stats appended to the LAST row only)
  chi_exp <- chisq.test(table(participants$prev.experience.assignment.days,
                              participants$TREAT))
  v_exp <- cramer_v(chi_exp, nrow(participants), length(exp_levels))
  for (i in seq_along(exp_levels)) {
    lvl <- exp_levels[i]
    n_c <- sum(ctrl$prev.experience.assignment.days == lvl)
    n_t <- sum(trt$prev.experience.assignment.days  == lvl)
    n_a <- n_c + n_t
    is_last <- (i == length(exp_levels))
    L <- c(L, sprintf(
      "\\quad %s & %s (%.2f\\%%) & %s (%.2f\\%%) & %s (%.2f\\%%) & %s & %s \\\\",
      exp_labels[i],
      formatC(n_c, big.mark = ","), n_c / nrow(ctrl) * 100,
      formatC(n_t, big.mark = ","), n_t / nrow(trt)  * 100,
      formatC(n_a, big.mark = ","), n_a / nrow(participants) * 100,
      if (is_last) fmt_p(chi_exp$p.value) else "",
      if (is_last) fmt(v_exp) else ""))
  }

  # Newcomer status
  L <- c(L, "\\addlinespace",
         "\\multicolumn{6}{l}{\\textit{Newcomer status}} \\\\")
  n_new_c <- sum(ctrl$newcomer); n_new_t <- sum(trt$newcomer)
  n_exp_c <- sum(!ctrl$newcomer); n_exp_t <- sum(!trt$newcomer)
  chi_new <- chisq.test(table(participants$newcomer, participants$TREAT))
  d_new <- cohen_d(as.numeric(ctrl$newcomer), as.numeric(trt$newcomer))
  L <- c(L, sprintf(
    "\\quad Newcomer & %s (%.2f\\%%) & %s (%.2f\\%%) & %s (%.2f\\%%) & & \\\\",
    formatC(n_new_c, big.mark = ","), n_new_c / nrow(ctrl) * 100,
    formatC(n_new_t, big.mark = ","), n_new_t / nrow(trt)  * 100,
    formatC(n_new_c + n_new_t, big.mark = ","),
    (n_new_c + n_new_t) / nrow(participants) * 100))
  L <- c(L, sprintf(
    "\\quad Experienced & %s (%.2f\\%%) & %s (%.2f\\%%) & %s (%.2f\\%%) & %s & %s \\\\",
    formatC(n_exp_c, big.mark = ","), n_exp_c / nrow(ctrl) * 100,
    formatC(n_exp_t, big.mark = ","), n_exp_t / nrow(trt)  * 100,
    formatC(n_exp_c + n_exp_t, big.mark = ","),
    (n_exp_c + n_exp_t) / nrow(participants) * 100,
    fmt_p(chi_new$p.value), fmt(d_new)))

  # Language
  L <- c(L, "\\addlinespace",
         "\\multicolumn{6}{l}{\\textit{Language}} \\\\")
  lang_names <- c(ar = "Arabic", de = "German", fa = "Persian", pl = "Polish")
  chi_lang <- chisq.test(table(participants$lang, participants$TREAT))
  v_lang <- cramer_v(chi_lang, nrow(participants),
                     length(unique(participants$lang)))
  for (l in names(lang_names)) {
    n_c <- sum(ctrl$lang == l); n_t <- sum(trt$lang == l); n_a <- n_c + n_t
    is_last <- (l == tail(names(lang_names), 1))
    L <- c(L, sprintf(
      "\\quad %s & %s (%.2f\\%%) & %s (%.2f\\%%) & %s (%.2f\\%%) & %s & %s \\\\",
      lang_names[l],
      formatC(n_c, big.mark = ","), n_c / nrow(ctrl) * 100,
      formatC(n_t, big.mark = ","), n_t / nrow(trt)  * 100,
      formatC(n_a, big.mark = ","), n_a / nrow(participants) * 100,
      if (is_last) fmt_p(chi_lang$p.value) else "",
      if (is_last) fmt(v_lang) else ""))
  }

  # Helper: emit a "Mean (SD) / Median" two-row block for a continuous variable
  .cont_block <- function(header, ctrl_x, trt_x, all_x) {
    ctrl_x <- as.numeric(ctrl_x); trt_x <- as.numeric(trt_x)
    all_x  <- as.numeric(all_x)
    w <- suppressWarnings(wilcox.test(ctrl_x, trt_x))
    d <- cohen_d(ctrl_x, trt_x)
    c("\\addlinespace",
      sprintf("\\multicolumn{6}{l}{\\textit{%s}} \\\\", header),
      sprintf("\\quad Mean (SD) & %s & %s & %s & %s & %s \\\\",
              fmt_mean_sd(ctrl_x), fmt_mean_sd(trt_x), fmt_mean_sd(all_x),
              fmt_p(w$p.value), fmt(d)),
      sprintf("\\quad Median & %s & %s & %s & & \\\\",
              fmt(median(ctrl_x, na.rm = TRUE)),
              fmt(median(trt_x,  na.rm = TRUE)),
              fmt(median(all_x,  na.rm = TRUE))))
  }

  L <- c(L, .cont_block("Pre-study labor hours per day",
                         ctrl$labor.hours.per.day.pre.treatment,
                         trt$labor.hours.per.day.pre.treatment,
                         participants$labor.hours.per.day.pre.treatment))
  L <- c(L, .cont_block("Pre-study labor hours (total)",
                         ctrl$labor.hours.pre.treatment,
                         trt$labor.hours.pre.treatment,
                         participants$labor.hours.pre.treatment))

  # Thanks sent (with extra "% with any sent" row)
  w_sent <- suppressWarnings(wilcox.test(ctrl$thanks.sent.pre.treatment,
                                          trt$thanks.sent.pre.treatment))
  d_sent <- cohen_d(ctrl$thanks.sent.pre.treatment,
                    trt$thanks.sent.pre.treatment)
  L <- c(L,
    "\\addlinespace",
    "\\multicolumn{6}{l}{\\textit{Thanks sent (pre-study)}} \\\\",
    sprintf("\\quad Mean (SD) & %s & %s & %s & %s & %s \\\\",
            fmt_mean_sd(ctrl$thanks.sent.pre.treatment),
            fmt_mean_sd(trt$thanks.sent.pre.treatment),
            fmt_mean_sd(participants$thanks.sent.pre.treatment),
            fmt_p(w_sent$p.value), fmt(d_sent)),
    sprintf("\\quad Median & %s & %s & %s & & \\\\",
            fmt(median(ctrl$thanks.sent.pre.treatment, na.rm = TRUE)),
            fmt(median(trt$thanks.sent.pre.treatment,  na.rm = TRUE)),
            fmt(median(participants$thanks.sent.pre.treatment, na.rm = TRUE))),
    sprintf("\\quad \\%% with any sent & %s & %s & %s & & \\\\",
            fmt_pct(mean(ctrl$thanks.sent.pre.treatment > 0, na.rm = TRUE) * 100),
            fmt_pct(mean(trt$thanks.sent.pre.treatment  > 0, na.rm = TRUE) * 100),
            fmt_pct(mean(participants$thanks.sent.pre.treatment > 0, na.rm = TRUE) * 100)))

  # Thanks received (with extra "% with any received" row)
  w_recv <- suppressWarnings(wilcox.test(ctrl$number.thanks.received,
                                          trt$number.thanks.received))
  d_recv <- cohen_d(ctrl$number.thanks.received,
                    trt$number.thanks.received)
  L <- c(L,
    "\\addlinespace",
    "\\multicolumn{6}{l}{\\textit{Thanks received (pre-study)}} \\\\",
    sprintf("\\quad Mean (SD) & %s & %s & %s & %s & %s \\\\",
            fmt_mean_sd(ctrl$number.thanks.received),
            fmt_mean_sd(trt$number.thanks.received),
            fmt_mean_sd(participants$number.thanks.received),
            fmt_p(w_recv$p.value), fmt(d_recv)),
    sprintf("\\quad Median & %s & %s & %s & & \\\\",
            fmt(median(ctrl$number.thanks.received, na.rm = TRUE)),
            fmt(median(trt$number.thanks.received,  na.rm = TRUE)),
            fmt(median(participants$number.thanks.received, na.rm = TRUE))),
    sprintf("\\quad \\%% with any received & %s & %s & %s & & \\\\",
            fmt_pct(mean(ctrl$number.thanks.received > 0, na.rm = TRUE) * 100),
            fmt_pct(mean(trt$number.thanks.received  > 0, na.rm = TRUE) * 100),
            fmt_pct(mean(participants$number.thanks.received > 0, na.rm = TRUE) * 100)))

  L <- c(L, "\\bottomrule", "\\end{tabular}")
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Table: Pre-Drop vs Post-Drop ITT estimates  -> table:predrop_results
# ---------------------------------------------------------------------------
build_predrop_results_table <- function(pre, post,
                                         n_pre  = NULL, n_post = NULL) {
  n_pre  <- n_pre  %||% max(pre$n.size,  na.rm = TRUE)
  n_post <- n_post %||% max(post$n.size, na.rm = TRUE)

  row_model <- function(model_name, display_name, estimator_name) {
    rp <- pre[pre$model   == model_name, ]
    ro <- post[post$model == model_name, ]
    if (nrow(rp) == 0 || nrow(ro) == 0) return(character(0))
    sprintf(
      "%s & %s & %s & %s & %s & %s & [%s, %s] & %s & %s & %s & %s & [%s, %s] \\\\",
      display_name, estimator_name,
      formatC(rp$n.size[1], big.mark = ","),
      fmt(rp$Estimate[1]), fmt(rp$Std..Error[1]),
      fmt_p(rp$pvalue[1]), fmt(rp$CI.Lower[1]), fmt(rp$CI.Upper[1]),
      formatC(ro$n.size[1], big.mark = ","),
      fmt(ro$Estimate[1]), fmt(ro$Std..Error[1]),
      fmt_p(ro$pvalue[1]), fmt(ro$CI.Lower[1]), fmt(ro$CI.Upper[1]))
  }

  L <- c(
    "\\begin{tabular}{llrrrllrrrll}",
    "\\toprule",
    sprintf(" & & \\multicolumn{5}{c}{\\textbf{Pre-Drop (N = %s)}} & \\multicolumn{5}{c}{\\textbf{Post-Drop (N = %s)}} \\\\",
            formatC(n_pre, big.mark = ","), formatC(n_post, big.mark = ",")),
    "\\cmidrule(lr){3-7} \\cmidrule(lr){8-12}",
    "\\textbf{Outcome} & \\textbf{Estimator} & N & Est. & SE & p & 95\\% CI & N & Est. & SE & p & 95\\% CI \\\\",
    "\\midrule",
    row_model("thanks sent",         "Thanks sent",         "NegBin"),
    row_model("retention",           "Two-week retention",  "DiM"),
    row_model("labor hours per day", "Labor hours per day", "Tweedie"),
    "\\addlinespace",
    row_model("manipulation check",  "Manipulation check",  "DiM"),
    "\\bottomrule",
    "\\end{tabular}"
  )
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Table: Pooled ITT by subgroup  -> table:full_itt_subgroup
# ---------------------------------------------------------------------------
build_pooled_itt_table <- function(all.lang.results) {
  mod_labels <- c("thanks sent" = "Thanks sent",
                  "retention" = "Two-week retention",
                  "labor hours per day" = "Labor hours per day",
                  "labor hours" = "Labor hours (DiM)",
                  "manipulation check" = "Manipulation check")
  est_labels <- c("thanks sent" = "NegBin",
                  "retention" = "DiM",
                  "labor hours per day" = "Tweedie",
                  "labor hours" = "DiM",
                  "manipulation check" = "DiM")
  pooled <- all.lang.results[all.lang.results$lang == "all", ]
  groups <- list(
    list(label = "All participants", data = pooled[pooled$subgroup == "all", ]),
    list(label = "Newcomers",        data = pooled[pooled$subgroup == "newcomer", ]),
    list(label = "Experienced",      data = pooled[pooled$subgroup == "experienced", ])
  )
  L <- c(
    "\\begin{tabular}{llcrrrrl}",
    "\\toprule",
    "\\textbf{Subgroup} & \\textbf{Outcome} & \\textbf{Estimator} & \\textbf{N} & \\textbf{Est.} & \\textbf{SE} & \\textbf{\\textit{p}} & \\textbf{95\\% CI} \\\\",
    "\\midrule"
  )
  first_emitted <- TRUE
  for (g in seq_along(groups)) {
    d <- groups[[g]]$data
    if (nrow(d) == 0) next
    if (!first_emitted) L <- c(L, "\\addlinespace")
    first_emitted <- FALSE
    for (i in seq_len(nrow(d))) {
      L <- c(L, .itt_row(d[i, ], groups[[g]]$label, mod_labels, est_labels, i == 1))
    }
  }
  L <- c(L, "\\bottomrule", "\\end{tabular}")
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Table: Per-language ITT  -> table:full_itt_language
# ---------------------------------------------------------------------------
build_lang_itt_table <- function(all.lang.results) {
  mod_labels <- c("thanks sent" = "Thanks sent",
                  "retention" = "Two-week retention",
                  "labor hours per day" = "Labor hours per day",
                  "labor hours" = "Labor hours (DiM)",
                  "manipulation check" = "Manipulation check")
  est_labels <- c("thanks sent" = "NegBin",
                  "retention" = "DiM",
                  "labor hours per day" = "Tweedie",
                  "labor hours" = "DiM",
                  "manipulation check" = "DiM")
  lang_d <- all.lang.results[all.lang.results$lang != "all", ]
  lang_order <- list(
    list(lang = "ar", subgroup = "newcomer",    label = "Arabic (newcomers)"),
    list(lang = "de", subgroup = "newcomer",    label = "German (newcomers)"),
    list(lang = "pl", subgroup = "newcomer",    label = "Polish (newcomers)"),
    list(lang = "fa", subgroup = "experienced", label = "Persian (experienced)"),
    list(lang = "pl", subgroup = "experienced", label = "Polish (experienced)")
  )
  groups <- lapply(lang_order, function(x) {
    list(label = x$label,
         data  = lang_d[lang_d$lang == x$lang & lang_d$subgroup == x$subgroup, ])
  })
  L <- c(
    "\\begin{tabular}{llcrrrrl}",
    "\\toprule",
    "\\textbf{Language (group)} & \\textbf{Outcome} & \\textbf{Estimator} & \\textbf{N} & \\textbf{Est.} & \\textbf{SE} & \\textbf{\\textit{p}} & \\textbf{95\\% CI} \\\\",
    "\\midrule"
  )
  first_emitted <- TRUE
  for (g in seq_along(groups)) {
    d <- groups[[g]]$data
    if (nrow(d) == 0) next
    if (!first_emitted) L <- c(L, "\\addlinespace")
    first_emitted <- FALSE
    for (i in seq_len(nrow(d))) {
      L <- c(L, .itt_row(d[i, ], groups[[g]]$label, mod_labels, est_labels, i == 1))
    }
  }
  L <- c(L, "\\bottomrule", "\\end{tabular}")
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Table: Full labor-per-day interaction model  -> table:full_labor_perday
# ---------------------------------------------------------------------------
build_labor_perday_table <- function(labor_per_day_results) {
  sg     <- c("all", "newcomer", "experienced")
  sg_lab <- c("All participants", "Newcomers", "Experienced")
  pl <- c("(Intercept)" = "Intercept",
          "TREAT1" = "TREAT",
          "centered.labor.hours.per.day.pre.treatment" =
            "Pre-treatment labor hours per day",
          "TREAT1:centered.labor.hours.per.day.pre.treatment" =
            "TREAT $\\times$ Pre-treatment labor hours per day")
  # %-change is only shown for the binary TREAT effect and its interaction;
  # for the intercept and the linear pre-treatment slope, the column is left blank.
  show_pct <- c("TREAT1" = TRUE,
                "TREAT1:centered.labor.hours.per.day.pre.treatment" = TRUE)

  L <- c(
    "\\begin{tabular}{llr@{\\hskip 0.5em}lrl}",
    "\\toprule",
    "\\textbf{Subgroup} & \\textbf{Predictor} & \\multicolumn{2}{c}{\\textbf{Estimate (\\% change)}} & \\textbf{SE} & \\textbf{\\textit{p}} \\\\",
    "\\midrule"
  )
  first_emitted <- TRUE
  for (s in seq_along(sg)) {
    d <- labor_per_day_results[labor_per_day_results$subgroup == sg[s], ]
    if (nrow(d) == 0) next
    if (!first_emitted) L <- c(L, "\\addlinespace")
    first_emitted <- FALSE
    for (i in seq_len(nrow(d))) {
      pred <- d$predictor[i]
      plab <- if (pred %in% names(pl)) pl[pred] else pred
      est  <- d$Estimate[i]
      pct  <- if (isTRUE(show_pct[pred])) {
        sprintf("(%.1f\\%%)", (exp(est) - 1) * 100)
      } else {
        ""
      }
      L <- c(L, sprintf("%s & %s & %s & %s & %s & %s \\\\",
        if (i == 1) sg_lab[s] else "",
        plab, fmt(est), pct,
        fmt(d$Std..Error[i]), fmt_p(d$pvalue[i])))
    }
  }
  L <- c(L, "\\bottomrule", "\\end{tabular}")
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Table: Distribution of thanks  -> table:thanks-distribution
# ---------------------------------------------------------------------------
build_thanks_distribution_table <- function(first.gen.data,
                                             treated.thanks.in.all.thanks,
                                             control.thanks.in.all.thanks) {
  lang_names <- c(ar = "Arabic", de = "German", fa = "Persian", pl = "Polish")

  first_gen_summary <- first.gen.data %>%
    group_by(lang, experience) %>%
    summarise(first_gen = n(), .groups = "drop")

  treated_summary <- treated.thanks.in.all.thanks %>%
    group_by(lang.y, experience) %>%
    summarise(second_gen_treated = n(), .groups = "drop") %>%
    rename(lang = lang.y)

  control_summary <- control.thanks.in.all.thanks %>%
    group_by(lang.y, experience) %>%
    summarise(control = n(), .groups = "drop") %>%
    rename(lang = lang.y)

  thanks_table <- first_gen_summary %>%
    full_join(treated_summary, by = c("lang", "experience")) %>%
    full_join(control_summary, by = c("lang", "experience")) %>%
    replace(is.na(.), 0) %>%
    arrange(lang, desc(experience))

  lang_totals <- thanks_table %>%
    group_by(lang) %>%
    summarise(first_gen = sum(first_gen),
              second_gen_treated = sum(second_gen_treated),
              control = sum(control), .groups = "drop")
  exp_totals <- thanks_table %>%
    group_by(experience) %>%
    summarise(first_gen = sum(first_gen),
              second_gen_treated = sum(second_gen_treated),
              control = sum(control), .groups = "drop")
  grand <- thanks_table %>%
    summarise(first_gen = sum(first_gen),
              second_gen_treated = sum(second_gen_treated),
              control = sum(control))

  fmt_n_pct <- function(n, total)
    sprintf("%s (%.1f\\%%)",
            formatC(n, format = "d", big.mark = ","),
            n / total * 100)

  L <- c(
    "\\begin{tabular}{lrrr}",
    "\\toprule",
    " & \\textbf{First-Gen} & \\textbf{Second-Gen} & \\textbf{Control} \\\\",
    " & \\textbf{(Received)} & \\textbf{(Treated)} & \\textbf{(Sent)} \\\\",
    sprintf(" & (N = %s) & (N = %s) & (N = %s) \\\\",
            formatC(grand$first_gen, big.mark = ","),
            formatC(grand$second_gen_treated, big.mark = ","),
            formatC(grand$control, big.mark = ",")),
    "\\midrule",
    "\\multicolumn{4}{l}{\\textit{Experience level}} \\\\"
  )
  for (i in seq_len(nrow(exp_totals))) {
    L <- c(L, sprintf("\\quad %s & %s & %s & %s \\\\",
      exp_totals$experience[i],
      fmt_n_pct(exp_totals$first_gen[i],          grand$first_gen),
      fmt_n_pct(exp_totals$second_gen_treated[i], grand$second_gen_treated),
      fmt_n_pct(exp_totals$control[i],            grand$control)))
  }
  L <- c(L, "\\addlinespace",
         "\\multicolumn{4}{l}{\\textit{Language}} \\\\")
  for (l in c("ar", "de", "fa", "pl")) {
    row <- lang_totals[lang_totals$lang == l, ]
    if (nrow(row) == 0) next
    L <- c(L, sprintf("\\quad %s & %s & %s & %s \\\\",
      lang_names[l],
      fmt_n_pct(row$first_gen,          grand$first_gen),
      fmt_n_pct(row$second_gen_treated, grand$second_gen_treated),
      fmt_n_pct(row$control,            grand$control)))
  }
  L <- c(L, "\\addlinespace",
         "\\multicolumn{4}{l}{\\textit{Language $\\times$ Experience}} \\\\")
  for (l in c("ar", "de", "fa", "pl")) {
    rows <- thanks_table[thanks_table$lang == l, ]
    for (j in seq_len(nrow(rows))) {
      L <- c(L, sprintf("\\quad %s -- %s & %s & %s & %s \\\\",
        lang_names[l], rows$experience[j],
        fmt_n_pct(rows$first_gen[j],          grand$first_gen),
        fmt_n_pct(rows$second_gen_treated[j], grand$second_gen_treated),
        fmt_n_pct(rows$control[j],            grand$control)))
    }
  }
  L <- c(L, "\\bottomrule", "\\end{tabular}")
  paste(L, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Caption text (single source of truth, shared by SI .Rtex and notebook).
# Uses R 4.0+ raw strings (r"(...)") to avoid double-escaping LaTeX backslashes.
# ---------------------------------------------------------------------------

si_captions <- list(

  balance = r"(Balance table comparing pre-treatment characteristics of treatment and control groups. P-values are from Wilcoxon rank-sum tests (continuous variables) or chi-squared tests (categorical variables). Std.~Diff.~is Cohen's $d$ for continuous and binary variables or Cram\'er's $V$ for multi-category variables. With $N > 15{,}000$, small p-values can arise from trivially small differences; all $|d| < 0.05$ for genuine pre-treatment covariates confirm negligible imbalance. The large standardized difference for \textit{Thanks received (pre-study)} ($d = 1.05$) is expected: receiving a first-generation thank is the treatment itself, so by design treated participants have thanks received $> 0$ and control participants have thanks received $= 0$. This row serves as a manipulation check confirming treatment delivery, not a covariate balance diagnostic.)",

  predrop_results = r"(ITT estimates before and after removing 284 participants (142 matched pairs in which one or both members had deleted their account or received multiple thanks due to software errors or volunteer decisions). The table has two column groups: \textit{Pre-Drop} ($N = 15{,}558$, all enrolled participants) and \textit{Post-Drop} ($N = 15{,}274$, analysis sample). Within each group: \textit{Est.}\ = point estimate; \textit{SE} = standard error; \textit{p} = Holm-adjusted p-value (except manipulation check); \textit{CI} = 95\% confidence interval. Consistency of estimates across both samples confirms that the exclusions do not materially affect the conclusions.)",

  full_itt_subgroup = r"(Full ITT estimates by participant subgroup, pooled across all four Wikipedia language editions. \textit{Subgroup} = participant group analyzed (all participants, newcomers $<$90 days old, or experienced contributors $\geq$90 days old); \textit{Estimator} = NegBin, DiM, or Tweedie (log link); \textit{Est.}\ = point estimate; \textit{SE} = standard error; \textit{p} = Holm-adjusted p-value (except manipulation check); \textit{CI} = 95\% confidence interval.)",

  full_itt_language = r"(Full ITT estimates by Wikipedia language edition. Each language block reports estimates for the primary participant subgroup used in language-specific models (newcomers for Arabic, German, and Polish; experienced contributors for Persian, following pre-registration). \textit{Estimator} = NegBin, DiM, or Tweedie (log link); \textit{Est.}\ = point estimate; \textit{SE} = standard error; \textit{p} = Holm-adjusted p-value within language (except manipulation check); \textit{CI} = 95\% confidence interval. The point estimates and confidence intervals vary visibly across language editions. Because the number of language groups is small and this study was not designed to formally test cross-language heterogeneity, we offer the following as post-hoc speculation rather than confirmatory inference. Plausible sources of variation include (i) differences in volunteer dosage---32\% of newcomers versus 43\% of experienced accounts in the treatment group actually received a first-generation thanks, and this rate varied by community; (ii) differences in active-editor community size (Table~\ref{table:second-gen-community}), which affect both the pool of eligible thanking targets and the extent to which spillover circulates back to controls; (iii) community-specific calibration of the ORES good-faith classifiers (Table~\ref{table:mlresults}) and the German flagged-revision criterion, which produce different eligibility thresholds across editions; and (iv) differences in newcomer-versus-experienced socialization dynamics in each community. These factors are not independent of one another, and we do not treat any single one as causal.)",

  full_labor_perday = r"(Full coefficient estimates from labor hours per day interaction models (Tweedie GLMM, log link), estimated separately for all participants, newcomers ($<$90 days old), and experienced contributors ($\geq$90 days old). All models include random intercepts for randomization blocks to account for the matched-pair design. \textit{Predictor} rows: \textit{Intercept} = baseline log-scale mean; \textit{TREAT} = main effect of treatment assignment; \textit{Pre-treatment labor hours per day} = covariate for pre-treatment activity (centered within subgroup); \textit{TREAT $\times$ Pre-treatment labor hours} = interaction term. \textit{\% change} is $(e^{\hat{\beta}} - 1) \times 100$, expressing the multiplicative effect on the original (non-log) scale.)",

  thanks_distribution = r"(Distribution of thanks by group, Wikipedia language edition, and participant experience level. Three columns correspond to three distinct types of thanks: \textit{First-Gen (Received)} = first-generation thanks sent by volunteers to treatment-group participants as part of the intervention ($N$ = total thanks in this category); \textit{Second-Gen (Treated)} = second-generation thanks subsequently sent by treated participants to other editors; \textit{Control (Sent)} = thanks sent by control-group participants who did not receive the intervention. Within each column, rows show the breakdown by language and experience level; percentages are column-wise (i.e., each column sums to 100\%).)"
)

# ---------------------------------------------------------------------------
# wrap_si_table(): wrap a tabular body in a complete LaTeX table float.
# Used by the notebook to write standalone .tex files; not used by the SI
# (which provides its own \begin{table} ... \end{table} hand-written wrapper).
# ---------------------------------------------------------------------------
#
# Args:
#   tabular   character(1)  - the \begin{tabular}...\end{tabular} block
#                             returned by one of the build_*() builders.
#   caption   character(1)  - caption text (no surrounding \caption{...}).
#   label     character(1)  - LaTeX label, e.g. "table:balance".
#   env       character(1)  - "table" (single-column) or "table*" (full-width).
#   placement character(1)  - LaTeX float placement specifier, e.g. "ht", "t".
#   small     logical(1)    - if TRUE, emit \small after \centering.
#
# Returns:
#   character(1) - a complete LaTeX float ready to be written to a .tex file.

wrap_si_table <- function(tabular, caption, label,
                          env       = "table",
                          placement = "ht",
                          small     = FALSE) {
  pieces <- c(
    sprintf("\\begin{%s}[%s]", env, placement),
    "\\centering",
    if (isTRUE(small)) "\\small" else NULL,
    sprintf("\\caption{%s}", caption),
    sprintf("\\label{%s}", label),
    tabular,
    sprintf("\\end{%s}", env)
  )
  paste(pieces, collapse = "\n")
}

# ---------------------------------------------------------------------------
# write_si_tex_files(): one-shot writer used by the notebook. Takes all the
# dataframes the builders need and emits the six .tex files into out_dir.
# ---------------------------------------------------------------------------

write_si_tex_files <- function(out_dir,
                               participants,
                               all.results.pre.drop,
                               all.results,
                               all.lang.results,
                               labor_per_day_results,
                               first.gen.data,
                               treated.thanks.in.all.thanks,
                               control.thanks.in.all.thanks,
                               n_pre  = NULL,
                               n_post = NULL) {
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Each build is wrapped in a thunk so it is only evaluated inside the
  # per-table tryCatch below. That way one failing table does not prevent
  # the others from being written.
  spec <- list(
    list(
      file      = "balance_table.tex",
      build     = function() build_balance_table(participants),
      caption   = si_captions$balance,
      label     = "table:balance",
      env       = "table*", placement = "t", small = FALSE
    ),
    list(
      file      = "predrop_results_table.tex",
      build     = function() build_predrop_results_table(all.results.pre.drop, all.results,
                                                         n_pre = n_pre, n_post = n_post),
      caption   = si_captions$predrop_results,
      label     = "table:predrop_results",
      env       = "table", placement = "ht", small = TRUE
    ),
    list(
      file      = "si_table_pooled_itt.tex",
      build     = function() build_pooled_itt_table(all.lang.results),
      caption   = si_captions$full_itt_subgroup,
      label     = "table:full_itt_subgroup",
      env       = "table", placement = "ht", small = TRUE
    ),
    list(
      file      = "si_table_lang_itt.tex",
      build     = function() build_lang_itt_table(all.lang.results),
      caption   = si_captions$full_itt_language,
      label     = "table:full_itt_language",
      env       = "table", placement = "ht", small = TRUE
    ),
    list(
      file      = "si_table_labor_full.tex",
      build     = function() build_labor_perday_table(labor_per_day_results),
      caption   = si_captions$full_labor_perday,
      label     = "table:full_labor_perday",
      env       = "table", placement = "ht", small = TRUE
    ),
    list(
      file      = "thanks_distribution_table.tex",
      build     = function() build_thanks_distribution_table(first.gen.data,
                                                             treated.thanks.in.all.thanks,
                                                             control.thanks.in.all.thanks),
      caption   = si_captions$thanks_distribution,
      label     = "table:thanks-distribution",
      env       = "table*", placement = "t", small = FALSE
    )
  )

  written <- character(0)
  failed  <- character(0)
  for (s in spec) {
    res <- tryCatch({
      tabular <- s$build()
      out     <- wrap_si_table(tabular, s$caption, s$label,
                               env = s$env, placement = s$placement, small = s$small)
      path    <- file.path(out_dir, s$file)
      writeLines(out, path)
      path
    }, error = function(e) {
      message(sprintf("[write_si_tex_files] %s failed: %s",
                      s$file, conditionMessage(e)))
      NA_character_
    })
    if (is.na(res)) failed <- c(failed, s$file) else written <- c(written, res)
  }
  if (length(failed) > 0) {
    warning(sprintf("write_si_tex_files: %d of %d tables failed (%s)",
                    length(failed), length(spec), paste(failed, collapse = ", ")),
            call. = FALSE)
  }
  invisible(written)
}
