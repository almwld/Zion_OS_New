---
name: claims-review
description: Structured peer review of a claim set from an artifact or tool. Dual-mode (artifact claims | tool capability claims). Vendor/provider/model agnostic. Internal-only, sacred-test-sanitized. [Maps to IN6, IN8.]
version: 0.2.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: side_effecting
argument-hint: "[--mode artifact|tool] [--source <path|name>] [--redact] [--strict]"
schema_version: claims_review_output.v0.1.0
eval_suite: eval/corpus/ (9 cases, 5 promotion gates, all passing)
expert_review: /redline (multi-agent peer review for high-stakes claim sets)
category: governance-compliance
providers:
  required: [python]
---

## Promotion Receipt

| Version | Date | Status | Eval Result | Gates |
|---------|------|--------|-------------|-------|
| 0.1.0 | 2026-06-26 | candidate | scaffold only | n/a |
| 0.2.0 | 2026-06-26 | tested | 9/9 cases, 100% verdict accuracy | 5/5 PASS |

## Benchmark

Scorer performance baseline at `eval/benchmarks/scorer_baseline.json`:
- 100 iterations, mean 0.04ms, CV 6.2%, 29K runs/sec
- Sub-millisecond; no regression risk for eval pipeline

## Live Context

!`echo "Skill count: $(ls ~/.agents/skills/ | wc -l) | Related: claim-verify evidence-grade evidence-review apply-review case-study-verify doc-harden"`

# Claims Review

Structured peer review of a body of claims. Distinct from `/claim-verify` (single-claim web verification) and `/evidence-grade` (single-source quality scoring). This skill reviews a **claim set** as a whole: coverage, consistency, provenance, internal contradictions, and fleet-readiness. Produces a peer-review verdict that gates publication, merge, or adoption.

**Dual-mode:**
- `--mode artifact` — review claims extracted from a document, proposal, case study, or report
- `--mode tool` — review capability claims made by an MCP server, plugin, or tool about itself

**Isolation boundary (sacred-test-sanitized):**
- No external transmission: no web search, no outbound API calls, no external LLM calls
- All review is internal-only against local corpus + memory + fleet state
- Eval suites use synthetic/fictional test cases only — no real fleet data, vendor names, or production claim text

## When to Use

- Before publishing or merging an artifact that contains a claim set (proposal, case study, ADR, research doc)
- Before adopting an MCP server, plugin, or tool — review its capability claims for accuracy
- When a peer agent's output needs structured review before fleet acceptance
- When the user says "review the claims", "audit these claims", "peer review", "are these claims sound"
- As a chain after `/doc-harden`, `/case-study`, `/proposal-write`, or `/mcp-test`
- Before `/redline` to scope what the multi-agent review should focus on

## Arguments

| Flag | Default | Description |
|------|---------|-------------|
| `--mode` | `artifact` | `artifact`: review claims from a document. `tool`: review capability claims from an MCP/plugin/tool |
| `--source` | (auto-detect) | Path to artifact file, or name of tool/MCP server to review |
| `--redact` | (off) | Redact vendor names, model names, and provider names in output. For sharing review results externally |
| `--strict` | (off) | Treat UNVERIFIABLE claims as REJECT instead of HOLD. For high-stakes gates |

## Execution

### 0. Emit SKILL_INVOKE
```
Type: SKILL_INVOKE
To: all
Message: [skill=claims-review] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

### 1. Resolve source and mode
- If `--source` is a file path: read it, set mode to `artifact` unless `--mode tool` explicitly set
- If `--source` is a tool/MCP name: probe local MCP server list, skill registry, or `~/.agents/` for its declared capabilities
- If no `--source`: scan default locations (current dir for .md/.txt, `~/.agents/skills/` for tool mode)

### 2. Extract claim set
- **Artifact mode**: Extract all factual claims using atomic claim extraction (same protocol as `/claim-verify` step 1). Group by category.
- **Tool mode**: Extract declared capabilities from the tool's SKILL.md, README, manifest, or MCP tool descriptions. Each "supports X" or "can do Y" is a claim.

### 3. Internal consistency check
- Cross-reference claims against each other: do any two claims contradict?
- Check for over-claiming: does the claim set assert capabilities/scope beyond what the artifact/tool demonstrates?
- Check for under-claiming: are notable features/capabilities omitted that would be expected?

### 4. Provenance check (internal-only, no external lookup)
- For each claim, check if it traces to:
  - A local source file (code, test, doc, memory pin)
  - A fleet artifact (bus message, ledger entry, ADR, receipt)
  - A prior review verdict
- Claims with no internal provenance → mark `UNVERIFIABLE_INTERNAL`
- **Do NOT web-search** — this skill is internal-only. If web verification is needed, chain to `/claim-verify`

### 5. Fleet-readiness check (apex-nexus aware)
- Grep `~/.agents/rules/` for any rule that governs the claim's domain
- Check if the claim set aligns with fleet doctrine (CONSTITUTION, guardrails, agent roster)
- For tool mode: check if the tool's claims align with its declared execution-mode and authority tier
- Flag any claim that conflicts with an existing rule or guardrail

### 6. Sacred-test sanitization check
- Verify no real fleet data (bus messages, ledger entries with real agent names, production URLs) appears in the claim set if `--redact` is set
- Verify eval fixtures (if reviewing a skill) use synthetic data only
- Flag any PII or operational data leakage in the claim set

### 7. Adjudicate claim set
For each claim, assign a review verdict:

| Verdict | Meaning |
|---------|---------|
| `CONFIRMED` | Internal source confirms the claim |
| `CONSISTENT` | No internal source but claim is consistent with fleet doctrine |
| `UNVERIFIABLE_INTERNAL` | No internal source found; needs `/claim-verify` for web check |
| `CONTRADICTED` | Internal source or another claim in the set contradicts this |
| `OVERCLAIMED` | Claim asserts more than the evidence supports |
| `DOCTRINE_CONFLICT` | Claim conflicts with an existing fleet rule or guardrail |
| `OUT_OF_SCOPE` | Claim is not reviewable internally (opinion, prediction, external fact) |

### 8. Set verdict
- **APPROVE** = zero CONTRADICTED + zero DOCTRINE_CONFLICT + zero OVERCLAIMED
- **HOLD** = any UNVERIFIABLE_INTERNAL (or CONTRADICTED/OVERCLAIMED if `--strict` not set)
- **REJECT** = any CONTRADICTED or DOCTRINE_CONFLICT (always), or UNVERIFIABLE_INTERNAL with `--strict`

### 9. Post review to bus
```
Type: STATUS
To: all
Message: [skill=claims-review] [mode=artifact|tool] verdict=<APPROVE|HOLD|REJECT> source=<name> claims=<N> confirmed=<N> consistent=<N> unverifiable=<N> contradicted=<N> overclaimed=<N> doctrine_conflict=<N> redacted=<true|false>
```

## Output Format

```
Claims Review | <mode> | <source>
══════════════════════════════════════════════════

## Receipt
| Field | Value |
|-------|-------|
| skill | claims-review |
| version | 0.2.0 |
| schema_version | claims_review_output.v0.1.0 |
| mode | artifact | tool |
| source | <path or tool name> |
| claims_extracted | {N} |
| redacted | true | false |
| isolation | internal-only, no external transmission |

## Verdict: APPROVE | HOLD | REJECT

## Claim Set: {N} claims

| # | Claim (abbreviated) | Category | Verdict | Provenance |
|---|---------------------|----------|---------|------------|
| 1 | {claim text} | capability | CONFIRMED | {internal source} |
| 2 | {claim text} | scope | OVERCLAIMED | {what's overstated} |
| 3 | {claim text} | factual | UNVERIFIABLE_INTERNAL | — (needs /claim-verify) |

## Internal Consistency
- {contradictions found, or "no internal contradictions detected"}

## Fleet-Readiness
- {doctrine alignment, or "conflict with {rule name}"}

## Sanitization
- {redaction status, eval fixture check, PII scan result}

## Summary
| Verdict | Count | Claim #s |
|---------|-------|----------|
| CONFIRMED | {N} | {list} |
| CONSISTENT | {N} | {list} |
| UNVERIFIABLE_INTERNAL | {N} | {list} |
| CONTRADICTED | {N} | {list} |
| OVERCLAIMED | {N} | {list} |
| DOCTRINE_CONFLICT | {N} | {list} |
| OUT_OF_SCOPE | {N} | {list} |

## Suggested Next Action
- If APPROVE: proceed to publication/merge/adoption. Chain: `/evidence-review` (audit backing evidence)
- If HOLD: chain `/claim-verify` for UNVERIFIABLE_INTERNAL claims, then re-review
- If REJECT: fix CONTRADICTED/DOCTRINE_CONFLICT claims, then re-review
```

## Base120 Context

- Primary: **IN6** (Proof by Contradiction — search for internal contradictions in the claim set)
- Related: **IN8** (Proof by Contrapositive — if a claim were false, what internal source would reveal it?), **IN5** (Absence Audit — what claims are missing from the set?)

## Skill Chains

### Mandatory (MUST pass before any state-changing action)

- **Branch safety check** MUST pass before bus post or commit:
  - Run `git branch --show-current` — must return a branch name (not detached HEAD)
  - Run `git status --short` — verify no unexpected dirty state
  - If detached HEAD or unexpected state: emit BLOCKED to bus, do not proceed
  - This is a procedure (not a skill invocation) — run the git commands directly

### Advisory

- After `/claims-review` APPROVE → `/evidence-review` (audit the evidence corpus backing the claims)
- After `/claims-review` HOLD → `/claim-verify` (web-verify UNVERIFIABLE_INTERNAL claims)
- After `/claims-review` REJECT → `/content-review` (fix the artifact before re-review)
- After `/claims-review` on a tool → `/mcp-test` (test the tool's actual behavior against its claims)
- Before `/claims-review` → `/nexus` (scan governance landscape for relevant rules)
- Before `/claims-review` → `/doc-harden` (if artifact needs claim extraction first)
- After `/claims-review` on high-stakes artifact → `/redline` (multi-agent peer review)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run (notify operator)
- **T4 (Probationary)**: May run with operator approval
- **Operator**: Override any restriction

## Expert Review Routing

This skill touches safety (claim verification gates publication/merge/adoption). For high-stakes claim sets, route to expert review:

- **High-stakes artifact** (case study, proposal, ADR going to publication): chain to `/redline` for multi-agent peer review after this skill's verdict
- **Tool adoption** (MCP server, plugin being adopted fleet-wide): chain to `/mcp-test` for behavioral verification, then `/redline` if high-stakes
- **DOCTRINE_CONFLICT verdict**: always route to `/redline` — doctrine conflicts need multi-agent adjudication
- **REJECT verdict on safety-touching artifact**: always route to `/redline` before any state-changing action

## Isolation Constraints

- **No external transmission**: this skill never calls web search, external APIs, or outbound LLM endpoints. All review is against local corpus + memory + fleet state.
- **Sacred-test-sanitized**: eval suites and benchmarks for this skill use synthetic/fictional test cases only. No real fleet data, vendor names, or production claim text in test fixtures.
- **Vendor agnostic**: `--redact` mode strips vendor/provider/model names from output. Review logic does not privilege any vendor.
- **Internal-only**: review results are posted to the internal bus only. Never transmitted externally unless explicitly authorized by the operator.

## Companion Skills

- `/claim-verify` — single-claim web verification (this skill chains to it for UNVERIFIABLE_INTERNAL claims)
- `/evidence-grade` — single-source quality scoring (complementary, not overlapping)
- `/evidence-review` — evidence corpus review (chains after this skill on APPROVE)
- `/apply-review` — person-specific fabrication gate (different scope: Reuben's professional materials)
- `/case-study-verify` — pre-publish source verification for case studies (narrower: case studies only)
- `/doc-harden` — claim extraction + evidence grading from documents (chains before this skill)
