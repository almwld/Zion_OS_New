---
name: brainstorm
description: Design-first exploration -- no code until the user approves a design.
version: 0.1.0
execution-mode: advisory
argument-hint: <topic or feature to brainstorm>
category: fleet-ops
status: candidate
---
# Brainstorm Command

Structured design exploration that produces options and trade-offs before any code is written.

## Usage

```bash
[brainstorm] Add voice input to morning briefing
[brainstorm] Migrate from SQLite to PostgreSQL
[brainstorm] Agent-to-agent authentication
```

## Execution

### Phase 1: Clarify

Ask 2-3 clarifying questions of the operator with multiple-choice options. Focus on:
- Scope: what's in and out
- Constraints: performance, compatibility, stdlib-only, etc.
- Priority: speed, correctness, simplicity

### Phase 2: Research

Read relevant existing code to understand:
- Current implementation (if modifying)
- Adjacent modules and interfaces
- Test patterns in use
- Conventions from CLAUDE.md

**Existence check (required for system-expansion topics — new modules, new stages, new primitives):**
Before proposing a new module or concept, grep existing services and integrations for the concept:
```bash
grep -rl "<proposed-concept>" hummbl_governance/services/ hummbl_governance/integrations/ 2>/dev/null
```
If something already implements the concept, note it. Do not propose to build what already exists.
Examples: proposing "ETHOS" → check if BelongingBaseline exists; proposing "memory synthesis" → check if CLP consolidator exists.

### Phase 2.5: Synthesis and Gap Review

Before presenting options, synthesize what was found in Phase 2 and
identify research gaps:

1. **Synthesize**: Summarize the key findings from the research phase —
   what exists, what's missing, what constraints were discovered.
2. **Identify gaps**: What questions remain unanswered? What areas were
   not researched due to time or access constraints?
3. **Self-check**: "Did I research enough to present well-grounded options,
   or am I presenting options based on assumptions?"

If significant gaps exist, either (a) research them before presenting
options, or (b) explicitly note the gaps as assumptions in the options.
Do NOT skip this step and present options based on local inventory alone
when the topic requires broader research. (Origin: 2026-09-02 — options
were presented based on local inventory only, triggering operator pushback
on insufficient research.)

### Phase 3: Present Options

Present 2-3 alternative approaches:

```
Brainstorm | <topic>
═════════════════════

## Option A: <name>
**Approach**: <1-2 sentences>
**Pros**: <bullet list>
**Cons**: <bullet list>
**Effort**: S/M/L
**Risk**: Low/Medium/High

## Option B: <name>
...

## Option C: <name>
...

## Recommendation
<which option and why>
```

### Phase 4: Gate

**HARD GATE**: Do NOT write any implementation code until the user explicitly approves one of the options. Ask:
> "Which approach would you like me to implement, or would you like to explore further?"

### Phase 5: Implement (only after approval)

Once approved, proceed with the chosen approach. Consider using `[tdd]` for the implementation.

## Constraints

- **No code before approval.** This is the core rule.
- Present real trade-offs, not strawman options to push a preferred choice.
- Reference actual code and architecture, not hypothetical systems.
- Keep each option description under 10 lines.
- If the topic is trivial (< 10 lines of code), say so and offer to just implement it directly.
