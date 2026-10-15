---
name: ab-test-analyzer
category: data-science
description: "Analyze A/B test results for statistical significance, effect size, and practical importance. Supports frequentist (t-test, chi-square, z-test) and Bayesian approaches. Produces a verdict table with confidence intervals, p-values, and recommendations. Use when an A/B test has concluded and you need to decide whether to ship the variant."
version: 0.1.0
status: candidate
execution-mode: advisory
argument-hint: "[--control <data>] [--variant <data>] [--metric conversion|revenue|retention|custom] [--test frequentist|bayesian|both] [--significance 0.05]"
---

# ab-test-analyzer

Analyze concluded A/B test results and produce a ship/hold/iterate verdict with
full statistical backing. **Advisory** — computes numbers, frames trade-offs;
operator makes the final ship decision.

## When to Use / Not to Use

**Use:** A/B test has concluded (reached pre-registered n or stopping rule) and
you need a go/no-go decision. You have per-group summary or raw observation data.

**Don't use:** Designing tests or tracking running experiments (use
`experiment-track`). Bandits, adaptive allocation, sequential/SPRT testing.
Causal inference on observational data (assumes random assignment).

## Arguments

| Flag | Values | Default |
|------|--------|---------|
| `--control` | data ref (CSV/JSON/inline) | required |
| `--variant` | data ref (CSV/JSON/inline) | required |
| `--metric` | `conversion`\|`revenue`\|`retention`\|`custom` | `conversion` |
| `--test` | `frequentist`\|`bayesian`\|`both` | `frequentist` |
| `--significance` | float 0–1 | `0.05` |

## Workflow

### 1. Load Test Data
Accept summary form (n, mean, variance per arm; or conversions+n for binomial)
or raw observation-level values. Validate both groups present and non-empty.

### 2. Validate Test Setup
- **Sample size**: warn if <30/arm (continuous) or <100 conversions/arm
  (binomial). Flag **underpowered** if power <0.80.
- **SRM**: chi-square goodness-of-fit on n_control vs n_variant vs expected
  ratio (50/50). If p<0.001, flag **SRM DETECTED** — results unreliable.
- **Randomization**: if segment metadata available, check covariate balance.

### 3. Descriptive Statistics
Per arm: n, mean (or conversion rate), median (continuous), variance, SE.
Binomial SE = √(p(1-p)/n).

### 4. Significance Tests

| Metric | Data shape | Frequentist | Bayesian |
|--------|-----------|-------------|----------|
| `conversion` (binomial) | successes/total | **Two-proportion z-test** (≡ chi-square 2×2) | Beta-Binomial posteriors, simulate draws |
| `revenue` (~normal) | per-user, n>30 | **Welch's t-test** (unequal var) | Normal-Normal conjugate or MCMC |
| `revenue` (skewed) | zeros & whales | **Mann-Whitney U** + median diff | Bootstrap posterior of median diff |
| `retention` (binary Dn) | retained flag | **Chi-square / z-test** | Beta-Binomial (same as conversion) |
| `custom` (continuous) | user-supplied | Welch t-test if ~normal; else Mann-Whitney | Bootstrap or conjugate |

**Assumptions:** CLT covers t-test for n>30; small n → Shapiro-Wilk →
Mann-Whitney. Default to Welch's (unequal variance). One row per user.

**Frequentist:** test → statistic, p-value, α comparison, 95% CI. CI excludes
0 = significant; width = precision.

**Bayesian:** Beta(1,1) or Beta(0.5,0.5) priors. Draw 100k posterior samples
per arm. Report: **P(variant > control)** (probability of superiority), **95%
credible interval** of lift, **expected loss** if variant is actually worse.

### 5. Effect Size
- **Cohen's d**: 0.2=small, 0.5=medium, 0.8=large.
- **Relative lift**: `(variant - control) / control × 100%`.
- **Absolute difference**: `variant - control` in raw units.

### 6. Practical Significance
Statistical ≠ practical. Is lift above pre-registered MDE? Is absolute diff
business-relevant? Does CI lower bound clear the practical threshold? Does
expected gain exceed shipping cost? Flag if no MDE was set.

### 7. Novelty & Heterogeneity
- **Novelty**: if time-series available, compare early vs late lift. Decay
  suggests novelty, not durable improvement.
- **Segment heterogeneity**: lift per segment (new/returning, mobile/desktop,
  geo). Flag cross-segment harm.

### 8. Verdict Table

```
| Metric       | Control | Variant | Lift   | p-value | 95% CI      | Verdict |
|--------------|---------|---------|--------|---------|-------------|---------|
| conv. rate   | 4.20%   | 4.65%   | +10.7% | 0.003   | [+1.4,+8.0] | SHIP    |
| avg revenue  | $2.41   | $2.38   | -1.2%  | 0.34    | [-4.1,+1.7] | HOLD    |
```

| Verdict | Condition |
|---------|-----------|
| **SHIP** | Significant (p<α) AND practically significant (lift>MDE, CI lower bound>0) AND no SRM AND no harmful segment interaction |
| **HOLD** | Not significant, OR significant but trivial, OR CI too wide — extend or rerun |
| **ITERATE** | Significant but harmful segment interaction, novelty decay, or mixed metrics — needs revision |
| **KILL** | Significant **negative** effect — variant worse than control |

### 9. Recommendations
- **SHIP**: rollout plan (staged ramp?), guardrails to watch, holdout if feasible.
- **HOLD**: underpowered (extend) or null (consider killing). State specific action.
- **ITERATE**: identify segment/sub-metric to optimize, recommend follow-up test.
- **KILL**: archive variant, document negative result to prevent re-testing.

## Output Format

1. Pre-flight checks → 2. Descriptive stats → 3. Significance results
4. Effect size → 5. Practical significance → 6. Novelty & heterogeneity
7. Verdict table → 8. Recommendation + next steps

## Boundaries

- Does not design or track A/B tests (use `experiment-track`).
- Requires minimum sample size — warns if underpowered.
- No bandits or sequential testing — fixed-horizon only.
- Results are advisory — operator makes the ship decision.
- No peeking correction — if operator peeked, p-values invalid; flag and
  recommend fresh test with alpha-spending if needed.

## Dependencies

`scipy.stats`, `numpy`, `pandas` (fleet toolchain). No external APIs. Bayesian
uses `numpy` sampling.
