---
name: contract-negotiate
description: Review contract/SOW terms, flag risky clauses, and suggest alternatives
version: 0.1.0
execution-mode: advisory
argument-hint: "<contract_file> [--perspective client|vendor]"
category: dev-tools
status: candidate
---
# Contract Negotiate

Review contract or SOW terms from either client or vendor perspective. Flags risky clauses related to IP ownership, liability, termination, payment terms, and scope. Suggests alternative language and highlights negotiation leverage points.

## When to Use
- When reviewing a client's contract before signing
- When drafting or reviewing your own SOW for protective clauses
- When a client proposes changes to standard terms
- When evaluating subcontractor or partner agreements

## Execution
1. Parse `$ARGUMENTS` for contract file path and perspective (default: vendor)
2. Read the contract file and extract key clauses
3. Analyze each clause category: IP/ownership, liability/indemnification, termination, payment terms, confidentiality, non-compete, scope/change orders, warranty/SLA
4. Flag clauses as: FAVORABLE, NEUTRAL, RISKY, or DEAL_BREAKER based on perspective
5. For RISKY and DEAL_BREAKER clauses, suggest alternative language
6. Identify missing protective clauses that should be added
7. Summarize negotiation priorities in order of importance

## Output Format
```
Contract Review | <perspective> perspective
=============================================

## Clause Analysis
| Clause | Category | Risk Level | Notes |
|--------|----------|------------|-------|
| ... | IP | RISKY | ... |
| ... | Payment | FAVORABLE | ... |
| ... | Termination | DEAL_BREAKER | ... |

## Flagged Clauses

### [DEAL_BREAKER] <clause title>
- Current: "<quoted text>"
- Issue: <why this is problematic>
- Suggested: "<alternative language>"

### [RISKY] <clause title>
- Current: "<quoted text>"
- Issue: ...
- Suggested: "<alternative language>"

## Missing Clauses
- <clause that should be added>: <why it matters>

## Negotiation Priorities (ordered)
1. ...
2. ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Terms agreed, need formal SOW | `[sow-generate]` to produce the final SOW |
| Need deeper legal review | `[legal-check]` for compliance and IP analysis |
