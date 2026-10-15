---
name: alert-triage
category: fleet-ops
description: >-
  Triage incoming alerts, suppress duplicates, correlate related alerts, route to the
  right responder, and escalate stale alerts. Use when alert volume is high and needs
  structured triage. Distinct from alert-rule (which creates alerting rules) and
  alert-noise-reduce (which reduces false positives) — this is the operational triage
  step for alerts that have already fired.
version: 0.1.0
status: candidate
execution-mode: side_effecting
argument-hint: "[--source <alerting-system>] [--window <minutes>] [--route] [--escalate] [--suppress]"
---

# alert-triage

Operational triage for alerts that have **already fired**. Ingests the alert stream,
groups and correlates alerts, routes to responders, suppresses symptomatic noise, and
escalates stale alerts. Decisions are published to the coordination bus.

## When to use

- Alert volume too high for manual triage.
- Multiple alerts share a root cause; responders paged redundantly.
- Need a structured triage step before incident response.
- Need to escalate alerts unacked past SLA.

## When NOT to use

- Create/edit alert rules → `alert-rule`.
- Reduce false positives at source → `alert-noise-reduce`.
- Resolve/remediate an incident → incident-response skill.

## Arguments

| Flag | Default | Purpose |
|------|---------|---------|
| `--source <system>` | auto-detect | `prometheus`, `grafana`, `datadog`, `custom` |
| `--window <minutes>` | `15` | Lookback window for recent alerts |
| `--route` | off | Assign each cluster to a responder by service ownership |
| `--escalate` | off | Escalate clusters unacknowledged beyond SLA |
| `--suppress` | off | Silence downstream symptom alerts of a routed root cause |

With no flags: pull last 15 min, deduplicate, correlate, emit report (read-only).

## Workflow

1. **Pull** recent alerts over `--window`; normalize to
   `{id, source, service, metric, severity, fired_at, labels, summary}`.
2. **Deduplicate** — group by root-cause signature (same service, metric family,
   overlapping time). Earliest firing is canonical.
3. **Correlate** — identify causal chains (e.g. DB down → API 5xx); build a directed
   causality graph.
4. **Classify severity** — re-evaluate using correlation context. Promote root causes
   of high-severity storms; demote downstream symptoms.
5. **Route** (`--route`) — assign each cluster to the root-cause service owner; fall
   back to on-call.
6. **Suppress** (`--suppress`) — silence downstream symptoms of routed+acked root
   causes; record reason + expiry.
7. **Escalate** (`--escalate`) — notify next tier for clusters unacked past SLA.
8. **Report** — clusters, routing, suppressions, escalations, correlation graph.
   Publish decisions to the coordination bus.

## Triage decision tree

```
Incoming alert
├─ Within --window? ── no ──▶ skip
├─ Duplicate of existing cluster? ── yes ──▶ attach, do not re-route
├─ Correlates to upstream? ── yes ──▶ mark as downstream symptom
│   ├─ root cause routed + acked + --suppress? ──▶ suppress (log reason + expiry)
│   └─ otherwise ──▶ keep visible, link to root-cause cluster
├─ Root cause (no upstream)? ── yes ──▶ promote to cluster head
│   ├─ re-evaluate severity from context
│   ├─ --route? ──▶ assign to owner / on-call
│   └─ --escalate + unacked past SLA? ──▶ escalate to next tier
└─ Emit cluster entry in triage report
```

## Correlation rules

Conservative — prefer under-correlating. Each decision records the rule and evidence
(time delta, labels, topology link).

1. **Same-root-cause signature**: same `service` + same `metric` family + firing times
   within `window` → duplicate group.
2. **Causal chain by topology**: A is a dependency of B, A fired before B by < 60s → A
   is likely upstream. Skip if topology metadata absent.
3. **Causal chain by metric family**: infra failures (DB, cache, queue) preceding app
   errors (5xx, latency) → candidate upstream. Only when infra fired first.
4. **Shared incident label**: same `incident_id` / correlation ID → grouped regardless.
5. **Anti-correlation**: unrelated services, no shared dependency, no consistent time
   ordering → **never** merged.

## Severity re-evaluation

| Situation | Action |
|-----------|--------|
| Root cause with high-severity downstream | Promote to at least max downstream severity |
| Downstream symptom, root cause routed | Demote to `info` if suppressed; else mark `symptom` |
| Single low-severity, no correlation | Unchanged |
| Cluster spanning multiple critical services | Promote to `critical` |

## Routing

Resolution order: (1) root-cause service owner, (2) parent-service team in topology,
(3) on-call rotation, (4) fleet-ops on-call (flagged unresolved). Unresolved ownership
signals a catalog gap, not a skip.

## Escalation

With `--escalate`, compare `now - fired_at` to SLA for re-evaluated severity:

| Severity | Ack SLA | Target |
|----------|---------|--------|
| critical | 5 min | Tier 2 on-call + incident channel |
| high | 15 min | Tier 2 on-call |
| medium | 30 min | Service owner (repeat) |
| low | 60 min | Service owner (info) |

Re-escalation uses backoff to avoid repeat pages.

## Coordination bus logging

Every side-effecting decision (route, suppress, escalate) publishes a structured event
to the bus (`skill`, `action`, `cluster_id`, `alert_ids`, `responder`, `reason`,
`rule`, `timestamp`). If logging fails, the action is skipped and flagged.

## Output

Triage report: clusters (head, members, dedup count, causal links, severity), routing
decisions, suppressed alerts (reason + expiry), escalations (from → to, elapsed, SLA
breached), correlation graph (edges with rule), metrics (alerts in, clusters out,
dedup/suppression rates, escalation count).

## Boundaries

- Does **not** create/modify alert rules → `alert-rule`.
- Does **not** reduce noise at source → `alert-noise-reduce`.
- Does **not** resolve/remediate — triages & routes.
- Decisions **logged to bus**; no silent changes.
