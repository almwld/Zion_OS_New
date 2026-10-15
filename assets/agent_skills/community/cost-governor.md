---
name: cost-governor
category: finance-legal
description: "Set and enforce spending limits across cloud infrastructure, AI/LLM API calls, and agent fleet costs. Monitor burn rate, alert on threshold breach, automatically throttle or shut down non-critical resources when budget is exceeded. Use when you need to cap or control spending."
version: 0.1.0
status: candidate
execution-mode: side_effecting
argument-hint: "[--set-limit <amount> --scope cloud|ai|agents|all] [--check] [--throttle] [--report]"
---

# cost-governor

Enforces spending limits across three cost scopes with reversible throttling on
budget breach. **Governs** live spend — does not create budgets (`budget-plan`)
nor log expenses (`expense-log`). Every enforcement action is published to the
coordination bus for audit.

## Cost Scopes

| Scope | Tag | Covers | Data sources |
|-------|-----|--------|--------------|
| Cloud | `cloud` | AWS, GCP, Cloudflare, IaaS/PaaS/CDN | Billing APIs (Cost Explorer, BigQuery export), usage logs |
| AI | `ai` | OpenAI, Anthropic, LLM APIs, self-hosted inference | Provider usage APIs, gateway logs, token counters |
| Agents | `agents` | Fleet compute: orchestration hosts, sandboxes, tool overhead | Scheduler metrics, runtime telemetry |
| All | `all` | Union of the above | Aggregation of all per-scope sources |

Per-scope limits are secondary caps under an `all` limit; lower governs.

## Arguments

```
cost-governor [--set-limit <amount> --scope cloud|ai|agents|all]
              [--window daily|weekly|monthly]
              [--check] [--throttle] [--report]
```

- `--set-limit <amount>` — Budget ceiling (decimal, base currency default USD).
  Requires `--scope` and `--window`. Replaces any prior limit for scope+window.
- `--scope` — `cloud` | `ai` | `agents` | `all`. Required with `--set-limit`.
- `--window` — `daily` (UTC midnight), `weekly` (UTC Monday 00:00), `monthly`
  (1st of month). Default `monthly`.
- `--check` — Query spend vs limits, emit threshold alerts. No side effects.
- `--throttle` — Apply throttle actions for the highest breached tier.
- `--report` — Generate and publish a cost report.

Defaults to `--check` if no action flag given.

## Workflow

1. **Identify scopes.** Discover billing data sources. If unavailable, record
   the gap on the bus and estimate from usage logs.
2. **Set limits.** Persist limit for scope+window; emit `cost.limit.set`.
3. **Monitor spend.** Query billing APIs and usage logs. Normalize to base
   currency. Compute burn rate and project end-of-period.
4. **Evaluate thresholds.** Emit `cost.threshold.breach` at 50/75/90/100%.
5. **Apply throttles.** With `--throttle`, apply actions for the highest breached
   tier (additive across tiers).
6. **Generate report.** With `--report`, publish cost report as `cost.report`.
7. **Record enforcement.** Every action needs a bus receipt; if none returns,
   abort the action and notify the operator.

## Threshold & Throttle Rules

Evaluated as `spend / limit`; highest breached tier governs.

| Tier | Trigger | Throttle action (with `--throttle`) |
|------|---------|-------------------------------------|
| WARN-50 | >= 50% | None — informational alert only. |
| WARN-75 | >= 75% | Reduce agent fleet concurrency by 25%. Switch AI non-critical traffic to cheaper model tier. |
| WARN-90 | >= 90% | Reduce agent concurrency by 50%. Pause non-essential scheduled jobs (batch evals, background indexing, dev previews). Force AI to cheapest model tier for non-critical traffic. |
| HALT-100 | >= 100% | Pause all non-critical agent activity. Pause all non-essential cloud and AI workloads. Only critical services continue. Operator must raise the limit or wait for a new window to resume. |

### Throttle safety rules

- **Reversible only** — pause or downgrade, never delete/terminate. Every pause
  records the resource handle for resume.
- **Critical services exempt** — production, security monitoring, audit
  pipelines, the bus, and `cost-governor:critical`-tagged resources are never
  throttled. Skips emit `cost.exemption`.
- **Per-scope isolation** — a breach throttles only that scope (plus `agents`
  when AI/cloud reductions cut fleet work). An `all` breach applies everywhere.
- **Operator override** — `cost.throttle.override` lifts a tier until the window
  rolls or the limit is raised.

## Reporting Format

A `--report` run produces a report published as `cost.report`:

- **Summary** — base currency, total spend vs limit (%), projected end-of-period,
  burn rate (amount/day).
- **By Scope** — table: scope, spend, limit, %, projected, status
  (`OK`/`WARN-50`/`WARN-75`/`WARN-90`/`HALT-100`).
- **Trend** — vs prior window (+/-%), 3-window moving average.
- **Active Throttles** — scope, tier, since-timestamp, action summary.
- **Recommendations** — actionable suggestions.
- **Audit** — bus receipts count, unenforced actions count.

## Boundaries

- Does not replace `budget-plan` (creates budgets) — this enforces them.
- Does not replace `expense-log` (logs expenses) — this governs them.
- Never deletes resources — all throttle actions are reversible.
- Never throttles critical services — production, security, bus are exempt.
- No enforcement without a bus receipt — unreceipted actions are not performed.

## Bus Events

| Event | When |
|-------|------|
| `cost.limit.set` | Limit set/changed (scope, window, amount) |
| `cost.threshold.breach` | Threshold crossed (scope, tier, pct, spend, limit) |
| `cost.throttle.applied` | Throttle taken (scope, tier, action, resources) |
| `cost.throttle.lifted` | Throttle reversed (scope, tier, reason) |
| `cost.report` | Report generated (body, window, totals) |
| `cost.exemption` | Critical service skipped (scope, resource, tier) |
| `cost.action.no-receipt` | Action failed receipt (action, reason) |

## Exit Codes

- `0` — No breach or all actions receipted.
- `1` — Threshold breached; alerts emitted.
- `2` — Throttle actions applied and receipted.
- `3` — Actions lacked a bus receipt.
- `64` — Invalid arguments.
- `70` — Internal error (API unreachable, no fallback).
