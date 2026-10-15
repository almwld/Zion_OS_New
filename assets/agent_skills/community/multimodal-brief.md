---
name: multimodal-brief
description: Synthesize information from multiple data types -- text, screenshots, logs, metrics, diagrams. Maps to CO19.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"TOPIC\" from [screenshots, logs, metrics, code, docs]"
category: data-science
status: candidate
---
# Multimodal Brief (CO19: Multi-Modal Integration)

Synthesize a briefing from multiple data modalities -- not just text, but screenshots, log files, metric dashboards, architecture diagrams, and code.

## When to Use
- Debugging with both error logs AND screenshots of the dashboard
- Reviewing a PR with both code diff AND visual output changes
- Preparing a demo with both technical details AND UX flow
- Incident review with logs AND timeline AND architecture diagram

## Execution

### 1. Gather sources across modalities

| Modality | Source | Tool |
|----------|--------|------|
| **Text** | Bus messages, git log, docs | Read, Grep |
| **Screenshots** | Dashboard, UI, error screens | Read (image files) |
| **Logs** | Service logs, error traces | `[log-tail]` |
| **Metrics** | Health probes, test counts, coverage | `[health]`, `[coverage]` |
| **Diagrams** | Architecture, dependency graphs | `[arch-diagram]`, `[dependency-graph]` |
| **Code** | Diffs, specific functions | Read, Grep |
| **Data** | Bus TSV, ledger JSONL, state JSON | `[bus]`, `[ledger]` |

### 2. Cross-reference
Find what each modality reveals that others don't:
- Screenshot shows the error the user sees
- Logs show the stack trace behind it
- Metrics show when it started
- Code shows why it happens
- Bus shows which agent was active

### 3. Synthesize
Produce a unified narrative that weaves all modalities together:

```
At 07:05 UTC, the health dashboard [screenshot] showed github adapter as RED.
The error log [log] shows: "ConnectionError: DNS resolution failed".
Bus messages [data] show lead-doctor posted HEALTH_TRANSITION at 07:05.
The circuit breaker [metric] opened at 07:06 (3 consecutive failures).
Root cause [code]: github_adapter.py:142 uses hostname without fallback IP.
```

### 4. Attach evidence
Each claim should reference its source modality.

## Output Format
```
Multimodal Brief | <topic>
════════════════════════════

## Sources Used
- [text] <what text sources>
- [visual] <what screenshots/diagrams>
- [data] <what structured data>
- [code] <what code was examined>

## Synthesis
<unified narrative weaving all modalities>

## Evidence Chain
| Claim | Source | Modality |
|-------|--------|----------|

## Gaps
<what modality is missing that would help>
```

## Base120 Context
- Primary: **CO19** (Multi-Modal Integration)
- Related: **CO6** (Gestalt Integration), **SY18** (Measurement & Telemetry), **P19** (Sensemaking)
