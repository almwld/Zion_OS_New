---
name: cultural-adapt
description: Adapt communication, docs, and UX for different audiences -- technical vs business, US vs international. Maps to P9.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"CONTENT\" for \"AUDIENCE\" (e.g., \"API docs\" for \"non-technical founders\")"
category: dev-tools
status: candidate
---
# Cultural Adapt (P9: Cultural Lens Shifting)

Rewrite content for a different audience without losing meaning. Technical to business, expert to novice, US to international.

## When to Use
- Writing GaaS marketing copy for non-technical founders
- Adapting API docs for different developer experience levels
- Preparing investor materials (finance language, not engineering)
- Localizing content for international markets
- Translating agent bus messages into human-readable briefings

## Execution

### 1. Identify source and target culture

| Dimension | Source | Target |
|-----------|--------|--------|
| **Technical depth** | Engineer | Executive / Founder / Investor |
| **Jargon level** | Internal (bus, CLP, IDP) | External (shared memory, governance) |
| **Formality** | Casual (bus messages) | Professional (investor update) |
| **Detail level** | Implementation | Outcome |
| **Metric focus** | Tests, LOC, coverage | Revenue, runway, growth |

### 2. Translation rules

| Internal Term | External Translation |
|---------------|---------------------|
| Coordination bus | Agent communication layer |
| CLP / Cognitive Ledger | Shared memory across AI agents |
| IDP delegation tokens | Secure permission system |
| Circuit breaker | Automatic failure protection |
| Kill switch | Emergency stop system |
| Base120 | Mental model framework (120 decision tools) |
| SWE-bench | Industry-standard coding benchmark |
| Stdlib-only | Zero external dependencies (maximum security) |

### 3. Rewrite
Transform the content, preserving meaning while shifting register.

### 4. Verify
- Does it still say the same thing?
- Would the target audience understand every sentence?
- Are there any remaining jargon terms?
- Is the tone appropriate?

## Output Format
```
Cultural Adapt | <source> -> <target audience>
══════════════════════════════════════════════

## Original (for <source audience>)
<original text>

## Adapted (for <target audience>)
<rewritten text>

## Translation Notes
- <term changes and why>
```

## Base120 Context
- Primary: **P9** (Cultural Lens Shifting)
- Related: **P5** (Empathy Mapping), **P8** (Narrative Framing), **P17** (Frame Control)
