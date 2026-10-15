---
name: counterfactual
description: Explore "what if we'd chosen differently" for past decisions. Maps to IN17.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"DECISION to re-examine\" (e.g., \"what if we used Redis instead of TSV bus\")"
category: dev-tools
status: candidate
---
# Counterfactual (IN17: Counterfactual Negation)

Imagine the alternate timeline where a key decision went differently. Not to second-guess, but to validate current direction and extract transferable insights.

## Execution

### 1. Identify the decision
Find the decision in the CLP ledger, git history, or decision-log:
```bash
source .venv/bin/activate
python -m your_package.cognition query --type decision --limit 10
```

### 2. State the counterfactual
"What if we had chosen [ALTERNATIVE] instead of [ACTUAL CHOICE]?"

### 3. Trace the consequences
| Dimension | Actual Path | Counterfactual Path |
|-----------|-------------|-------------------|
| Complexity | <what we got> | <what we'd have> |
| Capability | <what we can do> | <what we could do> |
| Cost | <what it costs> | <what it would cost> |
| Risk | <current risks> | <alternate risks> |
| Speed | <how fast we move> | <how fast we'd move> |
| Lock-in | <what we're locked into> | <what we'd be locked into> |

### 4. Assess
- **Validated**: The original decision still looks right given what we know now
- **Questionable**: The alternate path might have been better, worth revisiting
- **Reversed**: We should actually switch to the alternate now

### 5. Extract transferable insight
What did this analysis teach us that applies to FUTURE decisions?

## Output Format
```
Counterfactual | "<decision>"
══════════════════════════════

Original: <what we chose>
Alternative: <what we didn't choose>
Date: <when the decision was made>

## Consequence Trace
<dimension table>

## Assessment: [VALIDATED | QUESTIONABLE | REVERSED]
<rationale>

## Transferable Insight
<what this teaches us for future decisions>
```

## Base120 Context
- Primary: **IN17** (Counterfactual Negation)
- Related: **SY7** (Path Dependence), **P15** (Assumption Surfacing), **IN13** (Opportunity Cost)
