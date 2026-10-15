---
name: disaster-recovery
category: governance-compliance
description: "Define RTO/RPO objectives, design failover procedures, document recovery runbooks, and run DR drills. Use when planning for or testing disaster recovery. Distinct from backup-verify (which checks backup integrity) — this covers full recovery procedures including failover, data restoration, and service migration."
version: 0.1.0
status: candidate
execution-mode: advisory
argument-hint: "[--plan|--drill|--audit] [--service <name>] [--rto <minutes>] [--rpo <minutes>]"
---

# Disaster Recovery

Guides creation, documentation, testing, and improvement of DR plans. **Advisory** mode: produces plans, runbooks, drill reports, and audit findings — never executes live failover or mutates production.

## When to Use / Not to Use

Use when establishing DR objectives, documenting runbooks, preparing/reviewing a drill, auditing a DR plan, or comparing planned vs. actual RTO/RPO. Do **not** use for **verifying backup integrity** (use `backup-verify`), **executing live failover** (operational action — this skill produces the runbook, not the failover), or capacity planning.

## Core Concepts

### RTO (Recovery Time Objective)

Maximum acceptable time between a disaster and full service restoration. *How long can we be down?* Measured from failure detection to service accepting production traffic again. Includes detection, decision, failover, and validation. Tighter RTOs require automation and pre-provisioned standby.

### RPO (Recovery Point Objective)

Maximum acceptable data loss, measured in time. *How much data can we lose?* Interval between last good backup/replication point and the failure. RPO 0 = zero data loss (synchronous replication); RPO 15 min = up to 15 min of recent writes may be lost.

### RTO/RPO Tiering

| Tier | Label | RTO | RPO | Typical Services |
|---|---|---|---|---|
| T0 | Mission-critical | <15m | 0 | Auth, payments, core API |
| T1 | Critical | <1hr | <5m | Primary datastore, queue |
| T2 | Important | <4hr | <1hr | Reporting, internal tools |
| T3 | Non-critical | <24hr | <24hr | Batch jobs, analytics |

Every service needs an explicit, documented RTO/RPO — no implicit objectives.

## Workflow

1. **Identify critical services and dependencies.** Enumerate downstream dependencies (databases, caches, queues, object storage, external APIs, DNS, TLS), upstream dependents, shared infra, SPOFs. Produce a dependency graph — RTO cannot be tighter than the slowest dependency.
2. **Define RTO/RPO per service.** Assign tier and explicit targets. Document rationale: business impact, SLAs, cost tradeoffs.
3. **Map recovery procedures.** Detection → declaration → failover → data restoration (dependency order) → service startup → validation → cutover.
4. **Document recovery runbooks.** One per service (template below). Step-by-step, executable under stress, version-controlled, access-restricted, reviewed after every drill and incident.
5. **Identify SPOFs.** For each: component, mitigation (redundancy, multi-AZ/region, automated failover, circuit breakers), residual risk, owner.
6. **Run a DR drill.** Minimum cadence: quarterly (procedure below).
7. **Generate drill report.** Planned vs. actual RTO/RPO, timeline, findings, root causes, improvement actions.
8. **Update the DR plan.** Revise failed/ambiguous steps. Adjust RTO/RPO only with business approval. Record new SPOFs. Re-version and log changes.

## DR Drill Procedure

1. **Scope**: select service(s) and failure scenario (e.g., region loss, datastore corruption).
2. **Pre-checks**: standby healthy, backups recent, participants briefed.
3. **Simulate failure**: in a non-production or isolated environment, trigger the failure.
4. **Execute recovery**: follow the runbook exactly — deviations become findings.
5. **Measure**: record timestamps for detection, declaration, failover, validation. Calculate actual RTO/RPO.
6. **Restore**: return the drill environment to pre-drill state.

## Runbook Template

```markdown
# Runbook: <Service Name> Recovery
- Service / Tier / RTO / RPO / Owner / Last reviewed / Version
## Dependencies
- Databases / Queues / External APIs / Shared infra
## Failure Scenarios
1. <scenario description>
## Recovery Steps (each with expected time)
1. [Detection] Confirm failure via <signal>.
2. [Declaration] Notify <role>, obtain authorization.
3. [Failover] <exact command or console action>.
4. [Data restore] Restore from <source> to <target> (dependency order).
5. [Startup] Start services in order: <list>.
6. [Validation] Run <health check / smoke test>.
7. [Cutover] <steps to return to steady state>.
## Rollback / Contacts / Post-Recovery
- Rollback: <revert steps> · Contacts: On-call / Owner / Vendor · Post: incident report + plan review
```

## Audit Mode (`--audit`)

Review an existing DR plan for: RTO/RPO for every critical service; runbook completeness; drill cadence (≥1/quarter per T0/T1); SPOF mitigations have owners; documentation access-restricted and version-controlled; changelog current. Produce a gap list with severity (critical/high/medium/low) and remediations.

## Boundaries

- **Does not replace `backup-verify`** — backup integrity is a prerequisite, not a function here.
- **Does not manage live failover** — produces runbooks/reports; failover is operational.
- **Drills mandatory** — tested quarterly; untested = non-compliant.
- **Documentation is version-controlled and access-restricted.**
- **RTO/RPO changes need business sign-off** — this skill never relaxes objectives alone.

## Arguments

`--plan` (produce/update plan + runbooks) · `--drill` (guide drill + report) · `--audit` (audit existing plan) · `--service <name>` (scope to one service) · `--rto <m>` / `--rpo <m>` (set/validate targets)

## Output Artifacts

- **DR Plan** (`--plan`): service inventory, dependency graph, RTO/RPO table, SPOF register.
- **Runbook** (`--plan`): one per service (template above).
- **Drill Report** (`--drill`): scenario, timeline, planned vs. actual RTO/RPO, findings.
- **Audit Report** (`--audit`): gap list with severities and remediations.
