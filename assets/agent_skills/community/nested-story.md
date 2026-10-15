---
name: nested-story
description: Structure complex information as layered narratives -- executive summary nesting into technical detail. Maps to RE4.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"COMPLEX TOPIC\" [for AUDIENCE_LEVELS]"
category: data-science
status: candidate
---
# Nested Story (RE4: Nested Narratives)

Structure information as stories within stories -- each layer adds depth for those who want it, while the outer layer stands alone.

## When to Use
- Writing docs that serve both executives and engineers
- Structuring an AAR with summary + detail layers
- Creating a README with quickstart + deep dive
- Presenting findings where different stakeholders need different depth
- Building briefings that scale from "30 seconds" to "30 minutes"

## Execution

### 1. Define the nesting levels

| Level | Audience | Time | What They Need |
|-------|----------|------|---------------|
| **L0: Headline** | Anyone | 5 sec | One sentence answer |
| **L1: Summary** | Executives | 30 sec | Key findings + decision needed |
| **L2: Analysis** | Technical leads | 5 min | Evidence, tradeoffs, recommendations |
| **L3: Detail** | Implementers | 30 min | Code paths, config changes, test plans |

### 2. Write inside-out
Start with L3 (full detail), then compress up:
- L3 -> L2: Remove implementation detail, keep evidence and tradeoffs
- L2 -> L1: Remove evidence, keep findings and recommendations
- L1 -> L0: Remove recommendations, keep the single most important thing

### 3. Link layers
Each level should explicitly point to the next level of detail:

```markdown
## Headline (L0)
Bus signing breaks 43 tests locally. Fixed.

## Summary (L1)
BUS_SIGNING_SECRET in env wraps messages in JSON envelopes. 43 tests
expected raw messages. Fixed by adding _unwrap_payload() helper.
**See Analysis for details.**

## Analysis (L2)
Root cause: ASI07 auto-signing (shipped 2026-03-01) transforms the
message column from plain text to `{"c":"msg","n":"nonce","s":"sig"}`.
Tests written before this feature didn't account for the envelope.
**See Detail for file-by-file changes.**

## Detail (L3)
9 test files modified: test_bus_formatting.py, test_bus_hardening.py...
```

### 4. Verify each level stands alone
- Can someone read L0 and get the point? (yes/no)
- Can someone read L1 without L2 and make a decision? (yes/no)
- Does L2 have enough evidence to be convincing without L3? (yes/no)

## Output Format
```
Nested Story | <topic>
═══════════════════════

## L0: Headline
<one sentence>

## L1: Summary
<3-5 sentences, decision-ready>

## L2: Analysis
<evidence, tradeoffs, recommendations>

## L3: Detail
<implementation specifics, code paths, config>
```

## Base120 Context
- Primary: **RE4** (Nested Narratives)
- Related: **P8** (Narrative Framing), **CO8** (Layered Abstraction), **DE10** (Abstraction Laddering)
