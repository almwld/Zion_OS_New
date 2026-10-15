---
name: hummbl-business-review
description: "Create evidence-backed internal business reviews of HUMMBL across strategy, offers, funnels, product proof, repositories, brand, risk, and operating priorities. Use for HUMMBL quarterly, board-style, current-state, GTM, portfolio, brand, or 30/60/90 reviews involving hummbl.io, reubenbowlby.com, hummbl-production, hummbl-brand, the hummbl-io GitHub organizations, or related internal business intelligence."
version: 0.1.0
execution-mode: advisory
category: governance-compliance
status: candidate
---

# HUMMBL Business Review

Produce a decision-ready review, not a promotional summary. Treat current results, dated plans, hypotheses, and unknowns as different evidence classes.

## Start safely

1. Confirm the requested audience, review period, output format, and whether the artifact is internal or external. If unspecified, use an internal operator review covering the latest verifiable state.
2. Read [references/source-map.md](references/source-map.md), [references/review-method.md](references/review-method.md), and [references/brand-and-claims.md](references/brand-and-claims.md).
3. For a presentation, also read [references/deck-blueprint.md](references/deck-blueprint.md).
4. Follow local `AGENTS.md`, operator-authority, and coordination-bus rules. Reviewing does not authorize publishing, messaging, spending, repository changes, or strategic decisions.

## Build the evidence base

1. Record an `as_of` timestamp and inventory the sources actually accessible in this run.
2. Prefer canonical current sources. Check status labels, document dates, capture dates, release tags, default branches, and live/public surfaces.
3. Build an evidence ledger before drafting conclusions. For each material claim capture:
   - claim or metric
   - value and unit
   - period and comparison period
   - observed/captured date
   - source path or URL
   - source class and scope
   - freshness: current, stale, historical, or unknown
   - confidence: high, medium, or low
   - confidentiality: public, internal, or restricted
4. Preserve contradictions in a drift register. Identify both sources, dates, authority levels, and the decision needed. Do not silently reconcile them.
5. Verify volatile public claims against their primary surface. Repository text, plans, and manifests are evidence about a moment, not permanent truth.

## Apply HUMMBL evidence rules

- `unknown`, blank, `?`, `pending`, and em dash are not zero.
- A target, roadmap item, market estimate, or strategy proposal is not an achieved result.
- A README test count is a reported claim unless a fresh run or release artifact verifies it.
- Internal aggregate validation counts are not package release test counts.
- Keep `hummbl-governance`, Base120, BaseN, MCP Server, the root `hummbl` package, and fleet infrastructure as separate artifacts unless a source explicitly defines an aggregate.
- Compliance mapping is not certification; positioning is not authorization; internal dogfood is not an external customer case study.
- Do not infer customers, revenue, conversion, retention, pipeline, or market traction from technical activity.
- Do not expose private repository content, budgets, credentials, identifiers, or restricted strategy in an external artifact.

## Analyze the business system

Cover the dimensions supported by evidence:

1. Executive state: what is proven, emerging, blocked, and unknown.
2. Customer and problem: ICP evidence, pain, use cases, interviews, and customer proof.
3. Offer and pricing: current ladder, delivery promise, commercial proof, and cross-surface drift.
4. Acquisition and funnel: attention, CTA paths, booked calls, qualified opportunities, conversion, and measurement gaps.
5. Product and technical proof: releases, tests, installs, usage, benchmarks, case studies, and maturity boundaries.
6. Portfolio: canonical, candidate, supporting, experimental, historical, and retired repositories or products.
7. Delivery and economics: capacity, cycle time, revenue, cost, margin, cash, and runway when verified.
8. Brand and claims: positioning consistency, identity controls, proof language, accessibility, IP/legal holds, and reputation risk.
9. Operations and governance: decision rights, dependencies, security, release process, evidence freshness, and single points of failure.
10. Priorities: decisions required and a sequenced 30/60/90-day plan with owners and success measures.

Do not force unsupported sections. State the missing evidence and the smallest collection step that would resolve it.

## Write the review

Lead with a one-sentence verdict. Then provide:

- what changed since the prior period, if comparable evidence exists
- an evidence-quality scorecard
- verified KPIs with periods, sources, and freshness
- findings by business-system dimension
- a drift and contradiction register
- top risks and opportunities
- decisions required from the operator
- a 30/60/90 plan with owners, gates, and measures
- a source appendix and explicit unknowns

Use factual language. Label inferences. Keep private facts out of public-facing drafts.

## Create a presentation

Use the installed Business Review template capability when available, following its retained-reference workflow. Preserve the reference visual system unless the user requests a HUMMBL-branded treatment. Never invent metrics to fill a slide.

Use short on-slide source footers and put the full evidence ledger in notes or an appendix. Prefer tables for exact comparisons, timelines for dated changes, and diagrams only when relationships are hard to explain in prose.

## Quality gate

Before delivery, verify:

- every material claim traces to the evidence ledger
- dates, periods, denominators, units, and scopes are explicit
- unknowns and hypotheses are labeled
- conflicts are visible rather than smoothed over
- no restricted information leaks into an external artifact
- conclusions match the evidence and decisions have owners
- presentation pages render without overflow, overlap, illegible text, or misleading charts

Report limitations and the `as_of` timestamp with the final artifact.
