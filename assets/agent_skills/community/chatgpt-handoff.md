---
name: chatgpt-handoff
description: Ingest a ChatGPT response, route to downstream skills based on category tag, confirm scope, execute. Closed loop for the ChatGPT ↔ Claude Code workflow.
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
---
# ChatGPT Handoff Command

Operationalize the ChatGPT ↔ Claude Code workflow. Operator runs a ChatGPT conversation using a starter template, pastes the response back tagged `[handoff: <category>]`, and this skill routes the response to the right downstream skill chain.

Cross-model handoff governance is defined in `~/.agents/rules/handoff-governance.md` and the v2 spec at `PROJECTS/platform/docs/operations/HANDOFF_SPEC_v2.md`. This skill is the operational shell.

## Context Gathering

Before executing this skill, gather the following context:
- Run `ls -1 $HOME/_internal/chatgpt-templates/ 2>/dev/null`
- Run `ls -t $HOME/_internal/handoffs/CHATGPT_*.md 2>/dev/null | head -5`

## When to Use

- Operator pastes a ChatGPT response that starts with `[handoff: <category>]`
- Operator pastes a ChatGPT response without a tag, but explicitly invokes `[chatgpt-handoff]`
- Operator says "here's a chatgpt handoff" / "chatgpt came back with X"
- After running any starter template at `_internal/chatgpt-templates/`

## Procedure

### Step 1 — Detect category

Parse the `[handoff: <category>]` tag from the operator's pasted content. If missing or ambiguous, ask:

> "What category is this handoff? Options: `dev-audit`, `dev-pr-review`, `intel-competitive`, `intel-market`, `intel-funding`, `copy-drift`, `architecture-review`, `other`"

### Step 2 — Persist the raw handoff

Save the full pasted content to `_internal/handoffs/CHATGPT_<YYYY-MM-DD>_<category>_<slug>.md` with frontmatter:

```yaml
---
source: chatgpt
date: YYYY-MM-DD
category: communication
template_used: <template filename or "ad-hoc">
ingested_by: claude-code
session_id: <if available>
---
```

This is the audit trail. Cross-references the v2 spec.

### Step 3 — Route to downstream skills

Per category, suggest the standard chain:

| Category | Default chain | Notes |
|---|---|---|
| `dev-audit` | `[portfolio-score]` → `[pr-scope-check]` (per repo) → memory pin → `[aar]` | The today's-session pattern |
| `dev-pr-review` | `[review-pr] <n>` → `[pr-scope-check]` → cross-check vs ChatGPT findings | For external-model PR review |
| `intel-competitive` | `[competitive-intel]` → `[research-ingest]` (Tier-A claims only) → `[atl-watch]` if local | Apply `intel-surge-quality.md` R1-R4 discipline |
| `intel-market` | `[research-ingest]` → `[decision-log]` if strategic shift | Apply intel-surge R1-R4 |
| `intel-funding` | `[research-ingest]` → `[crm]` (if names new contacts) → `[competitive-intel]` (if competitor) | Apply intel-surge R1-R4 |
| `copy-drift` | `[case-study-verify]` (if case-study cited) + `[content-review]` → fix-list memo → operator decision per fix | Public-facing copy class |
| `architecture-review` | `[decision-log]` (if arch decision triggered) → `[adr-review]` (if existing ADR affected) → memory pin | External-pattern lens |
| `other` | Ask operator what chain to run | Catch-all |

### Step 4 — Confirm with operator

Before running any chain:

```
ChatGPT Handoff | <category> | <date>
═══════════════════════════════════════

Tag: [handoff: <category>]
Length: <N> chars
Template: <filename or "ad-hoc">
Saved to: _internal/handoffs/CHATGPT_<date>_<category>_<slug>.md

Recommended chain: <chain from table>

Run the chain? (y/n/modify)
```

Wait for operator confirmation. If operator wants different chain, run the modified one. If operator says skip, just persist the handoff and exit.

### Step 5 — Execute confirmed chain

Run each skill in sequence. After each:
- Surface findings
- Capture any new artifacts (paths)
- Cross-reference handoff file

### Step 6 — Close the loop

Final post:

```
ChatGPT Handoff complete.
Handoff: <path>
Chain ran: <list of skills>
Artifacts produced: <paths>
Next action: <if any>
```

Optional: post bus STATUS if work was consequential.

## Templates

Available at `$HOME/_internal/chatgpt-templates/`:

| Template | Category | Use case |
|---|---|---|
| `dev-audit-codebase.md` | dev-audit | Broad multi-pass GitHub audit (today's pattern) |
| `dev-audit-single-repo.md` | dev-audit | Focused deep-dive on one repo |
| `dev-pr-review.md` | dev-pr-review | Adversarial PR review by outside model |
| `intel-competitive-scan.md` | intel-competitive | Competitor product/pricing/positioning sweep |
| `intel-market-segment.md` | intel-market | Market segment intel (Atlanta, AI governance, etc.) |
| `intel-funding-signals.md` | intel-funding | Funding announcements + hiring signals |
| `copy-drift-scan.md` | copy-drift | Public copy vs source of truth audit |
| `architecture-external-pattern-review.md` | architecture-review | External pattern (vendor, OSS) vs HUMMBL implementation |

## Constraints

- **Persist before route**: always save the raw handoff first (Step 2). Audit trail is load-bearing.
- **Confirm before execute**: do NOT run downstream skills without operator confirmation (Step 4).
- **Source-class on claims**: ChatGPT outputs are SECONDARY source per `intel-surge-quality.md` R3 — no Tier-A claim ships externally without operator-confirmed primary-source verification.
- **No silent route**: every chain execution leaves a paper trail (bus STATUS or artifact file path).

## Skill Chains

- Before: any `_internal/chatgpt-templates/*.md` (operator runs template → ChatGPT → paste back)
- After: depends on category — see Step 3 table

## Related

- `_internal/chatgpt-templates/` — starter prompt library
- `~/.agents/rules/handoff-governance.md` — cross-model authority rules
- `PROJECTS/platform/docs/operations/HANDOFF_SPEC_v2.md` — v2 spec
- `~/.agents/rules/intel-surge-quality.md` — R1-R4 discipline for intel categories
- `~/.agents/rules/claim-honesty-protocol.md` — claim verification for any external-bound ChatGPT output
