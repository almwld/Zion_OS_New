---
name: evidence-review
description: Structured review of an evidence corpus for completeness, provenance, gaps, and fleet-readiness. Dual-mode (artifact evidence | tool evidence). Vendor/provider/model agnostic. Internal-only, sacred-test-sanitized. [Maps to IN5, IN6.]
version: 0.2.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: side_effecting
argument-hint: "[--mode artifact|tool] [--source <path|name>] [--redact] [--strict] [--min-grade B]"
schema_version: evidence_review_output.v0.1.0
eval_suite: eval/corpus/ (8 cases, 5 promotion gates, all passing)
expert_review: /redline (multi-agent peer review for high-stakes evidence corpora)
category: governance-compliance
providers:
  required: [python]
---

## Promotion Receipt

| Version | Date | Status | Eval Result | Gates |
|---------|------|--------|-------------|-------|
| 0.1.0 | 2026-06-26 | candidate | scaffold only | n/a |
| 0.2.0 | 2026-06-26 | tested | 8/8 cases, 100% verdict accuracy | 5/5 PASS |

## Benchmark

Scorer performance baseline at `eval/benchmarks/scorer_baseline.json`:
- 100 iterations, mean 0.03ms, stable
- Sub-millisecond; no regression risk for eval pipeline

## Live Context

!`echo "Skill count: $(ls ~/.agents/skills/ | wc -l) | Related: evidence-grade evidence-pack claims-review apply-review doc-harden"`

# Evidence Review

Structured review of an **evidence corpus** as a whole. Distinct from `/evidence-grade` (single-source quality scoring) and `/evidence-pack` (packaging artifacts for sharing). This skill reviews the evidence backing a claim set or tool: is the corpus complete, is provenance traceable, are there gaps, is it fleet-ready? Produces a review verdict that gates publication, merge, or adoption.

**Dual-mode:**
- `--mode artifact` — review the evidence corpus backing a document's claims (proposals, case studies, ADRs, research)
- `--mode tool` — review the evidence corpus backing a tool's/MCP server's capability claims (tests, benchmarks, receipts, CI)

**Isolation boundary (sacred-test-sanitized):**
- No external transmission: no web search, no outbound API calls, no external LLM calls
- All review is internal-only against local corpus + memory + fleet state
- Eval suites use synthetic/fictional test cases only — no real fleet data, vendor names, or production evidence in test fixtures

## When to Use

- After `/claims-review` returns APPROVE — audit the evidence backing the approved claims
- Before publishing or merging an artifact — verify the evidence corpus is complete and traceable
- Before adopting an MCP server, plugin, or tool — verify its evidence (tests, benchmarks, receipts) backs its claims
- When the user says "review the evidence", "audit the evidence", "is the evidence complete", "evidence gaps"
- As a chain after `/evidence-pack` (review what was bundled before sharing)
- Before `/redline` to scope evidence gaps the multi-agent review should address

## Arguments

| Flag | Default | Description |
|------|---------|-------------|
| `--mode` | `artifact` | `artifact`: review evidence backing a document. `tool`: review evidence backing a tool/MCP |
| `--source` | (auto-detect) | Path to artifact, or name of tool/MCP server |
| `--redact` | (off) | Redact vendor/provider/model names in output |
| `--strict` | (off) | Treat any GAP as REJECT instead of HOLD |
| `--min-grade` | `B` | Minimum acceptable evidence grade (A-F). Evidence below this grade counts as GAP |

## Execution

### 0. Emit SKILL_INVOKE
```
Type: SKILL_INVOKE
To: all
Message: [skill=evidence-review] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

### 1. Resolve source and mode
- If `--source` is a file path: read it, identify the claims it makes, set mode to `artifact` unless `--mode tool` set
- If `--source` is a tool/MCP name: probe local registry for its test suite, eval suite, benchmarks, receipts, CI
- If no `--source`: scan current dir for evidence files (.md, .jsonl, .json, test files)

### 2. Map the evidence corpus
- **Artifact mode**: For each claim in the artifact, identify what evidence backs it:
  - Citations/references in the text
  - Linked files (code, tests, data, receipts)
  - Fleet artifacts (bus messages, ledger entries, ADRs, governance logs)
  - Memory pins
- **Tool mode**: For each capability claim, identify:
  - Test files covering the capability
  - Eval suite cases
  - Benchmark results
  - CI workflow runs
  - Bus receipts / Krineia receipts
  - Promotion receipts (if a skill)

### 3. Provenance traceability check
- For each evidence item, trace its provenance:
  - Does the evidence file exist at the claimed path?
  - Does the receipt/ledger entry exist with the claimed SHA?
  - Is the test file actually testing the claimed capability?
  - Is the benchmark result recent and reproducible?
- Evidence with broken provenance → mark `PROVENANCE_BROKEN`
- Evidence with no provenance link → mark `UNTRACEABLE`

### 4. Completeness check
- For each claim, is there at least one piece of evidence?
- Is the evidence grade (per `/evidence-grade` rubric) at or above `--min-grade`?
- Claims with no evidence → mark `EVIDENCE_GAP`
- Claims with evidence below `--min-grade` → mark `EVIDENCE_WEAK`

### 5. Gap analysis
- What evidence types are missing from the corpus?
  - **Test evidence**: unit tests, integration tests, e2e tests
  - **Performance evidence**: benchmarks, load tests, latency measurements
  - **Governance evidence**: receipts, bus messages, ledger entries, ADRs
  - **External evidence**: peer review, external audit, third-party validation (note: this skill does NOT fetch external evidence — only flags its absence)
- Missing evidence types for high-stakes claims → mark `GAP_CRITICAL`

### 6. Fleet-readiness check (apex-nexus aware)
- Grep `~/.agents/rules/` for evidence requirements relevant to the claim domain
- Check if the evidence corpus meets fleet standards (e.g., skills need eval suites per `skill-audit`)
- For tool mode: check if the tool has a promotion receipt, eval baseline, and CI gates
- Flag any evidence corpus that doesn't meet fleet readiness standards

### 7. Sacred-test sanitization check
- Verify no real fleet data in evidence fixtures if `--redact` is set
- Verify eval fixtures use synthetic data only (for skill evidence review)
- Flag any PII or operational data leakage in the evidence corpus

### 8. Adjudicate evidence corpus
For each evidence item, assign a review status:

| Status | Meaning |
|--------|---------|
| `VERIFIED` | Evidence exists, provenance traces, grade >= min-grade |
| `PROVENANCE_BROKEN` | Evidence file/receipt missing or SHA mismatch |
| `UNTRACEABLE` | Evidence referenced but no link/path provided |
| `EVIDENCE_GAP` | Non-critical claim has no backing evidence |
| `EVIDENCE_WEAK` | Evidence exists but grade < min-grade |
| `GAP_CRITICAL` | High-stakes claim missing required evidence type (see table below) |
| `FLEET_INSUFFICIENT` | Evidence doesn't meet fleet readiness standards |

**Precedence rules for EVIDENCE_GAP vs GAP_CRITICAL:**
- For high-stakes claims (see table below), missing evidence is ALWAYS `GAP_CRITICAL`, never `EVIDENCE_GAP`
- `EVIDENCE_GAP` is for non-critical claims or missing evidence of non-required types
- A single evidence item can have both `GAP_CRITICAL` (missing required type) and `FLEET_INSUFFICIENT` (fails fleet standards) — they are orthogonal

**High-stakes claim categories and required evidence types:**

| Claim Category | High-Stakes? | Required Evidence Types |
|----------------|--------------|-------------------------|
| Safety-critical capability | YES | Tests, eval suite, CI gates |
| side_effecting tool | YES | Tests, eval suite, promotion receipt |
| Performance claim (>1K rps, >10K users) | YES | Benchmarks, load tests |
| Performance claim (small scale) | NO | Benchmarks (advisory) |
| Compliance claim (SOC2, GDPR, HIPAA) | YES | Audit reports, certificates |
| Security claim | YES | Security scan, threat model |
| Factual claim about internals | NO | Code, tests, docs |
| Opinion/prediction | N/A | OUT_OF_SCOPE (not reviewable) |

### 9. Set verdict
- **APPROVE** = zero PROVENANCE_BROKEN + zero EVIDENCE_GAP + zero GAP_CRITICAL + zero FLEET_INSUFFICIENT
- **HOLD** = any EVIDENCE_WEAK or UNTRACEABLE (or EVIDENCE_GAP/GAP_CRITICAL if `--strict` not set)
- **REJECT** = any PROVENANCE_BROKEN or GAP_CRITICAL (always), or EVIDENCE_GAP with `--strict`

### 10. Post review to bus
```
Type: STATUS
To: all
Message: [skill=evidence-review] [mode=artifact|tool] verdict=<APPROVE|HOLD|REJECT> source=<name> evidence_items=<N> verified=<N> provenance_broken=<N> gaps=<N> weak=<N> critical_gaps=<N> fleet_insufficient=<N> redacted=<true|false>
```

## Output Format

```
Evidence Review | <mode> | <source>
══════════════════════════════════════════════════

## Receipt
| Field | Value |
|-------|-------|
| skill | evidence-review |
| version | 0.2.0 |
| schema_version | evidence_review_output.v0.1.0 |
| mode | artifact | tool |
| source | <path or tool name> |
| evidence_items | {N} |
| min_grade | {B} |
| redacted | true | false |
| isolation | internal-only, no external transmission |

## Verdict: APPROVE | HOLD | REJECT

## Evidence Corpus Map

| Claim # | Claim (abbreviated) | Evidence Type | Status | Grade | Provenance |
|---------|---------------------|---------------|--------|-------|------------|
| 1 | {claim text} | test | VERIFIED | A | {path} |
| 2 | {claim text} | benchmark | EVIDENCE_WEAK | D | {path, below min-grade} |
| 3 | {claim text} | — | EVIDENCE_GAP | — | no evidence found |
| 4 | {claim text} | receipt | PROVENANCE_BROKEN | — | {SHA mismatch} |

## Provenance Trace
- {trace results: confirmed paths, broken links, missing files}

## Gap Analysis
| Gap Type | Claims Affected | Severity |
|----------|----------------|----------|
| Test evidence missing | {claim #s} | {critical|moderate|low} |
| Performance evidence missing | {claim #s} | {severity} |
| Governance evidence missing | {claim #s} | {severity} |
| External evidence missing | {claim #s} | {severity} |

## Fleet-Readiness
- {standards met, or "insufficient: {what's missing}"}

## Sanitization
- {redaction status, eval fixture check, PII scan result}

## Summary
| Status | Count | Claim #s |
|--------|-------|----------|
| VERIFIED | {N} | {list} |
| PROVENANCE_BROKEN | {N} | {list} |
| UNTRACEABLE | {N} | {list} |
| EVIDENCE_GAP | {N} | {list} |
| EVIDENCE_WEAK | {N} | {list} |
| GAP_CRITICAL | {N} | {list} |
| FLEET_INSUFFICIENT | {N} | {list} |

## Suggested Next Action
- If APPROVE: evidence corpus is fleet-ready. Chain: `/evidence-pack` (bundle for sharing) or proceed to publication
- If HOLD: chain `/evidence-grade` to re-grade weak evidence, or generate missing evidence (write tests, run benchmarks)
- If REJECT: fix PROVENANCE_BROKEN evidence (restore files, fix SHAs), address GAP_CRITICAL claims, then re-review
```

## Base120 Context

- Primary: **IN5** (Absence Audit — surfaces what evidence is missing from the corpus)
- Related: **IN6** (Proof by Contradiction — does the evidence contradict the claims?), **IN8** (Proof by Contrapositive — if the evidence were fake, what would reveal it?)

## Skill Chains

### Mandatory (MUST pass before any state-changing action)

- **Branch safety check** MUST pass before bus post or commit:
  - Run `git branch --show-current` — must return a branch name (not detached HEAD)
  - Run `git status --short` — verify no unexpected dirty state
  - If detached HEAD or unexpected state: emit BLOCKED to bus, do not proceed
  - This is a procedure (not a skill invocation) — run the git commands directly

### Advisory

- After `/evidence-review` APPROVE → `/evidence-pack` (bundle the verified corpus for sharing)
- After `/evidence-review` HOLD → `/evidence-grade` (re-grade weak evidence), `/test-run` (generate missing test evidence), `/benchmark` (generate missing performance evidence)
- After `/evidence-review` REJECT → `/root-cause` (diagnose why provenance broke), then fix and re-review
- Before `/evidence-review` → `/claims-review` (review the claims first, then review their evidence)
- Before `/evidence-review` → `/nexus` (scan for fleet evidence standards)
- After `/evidence-review` on high-stakes artifact → `/redline` (multi-agent peer review of evidence)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run (notify operator)
- **T4 (Probationary)**: May run with operator approval
- **Operator**: Override any restriction

## Expert Review Routing

This skill touches safety (evidence review gates publication/merge/adoption). For high-stakes evidence corpora, route to expert review:

- **High-stakes artifact** (case study, proposal, ADR going to publication): chain to `/redline` for multi-agent peer review after this skill's verdict
- **Tool adoption** (MCP server, plugin being adopted fleet-wide): chain to `/mcp-test` for behavioral verification, then `/redline` if high-stakes
- **PROVENANCE_BROKEN verdict**: always route to `/root-cause` to diagnose why provenance broke, then `/redline` if the artifact is high-stakes
- **GAP_CRITICAL verdict**: always route to `/redline` — critical evidence gaps need multi-agent adjudication before proceeding
- **REJECT verdict on safety-touching artifact**: always route to `/redline` before any state-changing action

## Isolation Constraints

- **No external transmission**: this skill never calls web search, external APIs, or outbound LLM endpoints. All review is against local corpus + memory + fleet state.
- **Sacred-test-sanitized**: eval suites and benchmarks for this skill use synthetic/fictional test cases only. No real fleet data, vendor names, or production evidence in test fixtures.
- **Vendor agnostic**: `--redact` mode strips vendor/provider/model names from output. Review logic does not privilege any vendor.
- **Internal-only**: review results are posted to the internal bus only. Never transmitted externally unless explicitly authorized by the operator.

## Companion Skills

- `/evidence-grade` — single-source quality scoring (this skill uses its rubric but reviews the whole corpus)
- `/evidence-pack` — packaging evidence for sharing (chains after this skill on APPROVE)
- `/claims-review` — claim set review (chains before this skill)
- `/claim-verify` — single-claim web verification (for claims that need external verification)
- `/doc-harden` — claim extraction + evidence grading from documents (chains before this skill)
- `/case-study-verify` — pre-publish source verification (narrower: case studies only)
- `/skill-audit` — security + epistemic rigor audit of SKILL.md files (this skill is broader: any evidence corpus)
