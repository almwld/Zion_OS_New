---
name: scope-decompose
description: Break an epic or feature into ordered user stories with acceptance criteria.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"FEATURE DESCRIPTION\""
category: fleet-ops
status: candidate
---
# Scope Decompose

Break a feature or epic into implementable user stories with clear acceptance criteria and dependency ordering.

## Execution

### 1. Understand the scope
Read the feature description. Ask clarifying questions if the scope is ambiguous:
- Who is the user?
- What's the minimum viable version?
- What are the hard constraints (stdlib-only, no new deps, etc.)?

### 2. Decompose into stories
Each story must be:
- **Independent** where possible (can be implemented without other stories)
- **Negotiable** (implementation details flexible)
- **Valuable** (delivers user-visible value or reduces risk)
- **Estimable** (small enough to reason about)
- **Small** (completable in 1-2 sessions)
- **Testable** (clear acceptance criteria)

### 3. Order by dependencies
Identify which stories block others. Produce a DAG:
```
S1 (no deps) -> S3 (needs S1)
S2 (no deps) -> S3 (needs S1, S2)
               S4 (needs S3)
```

### 4. Write acceptance criteria
Each story gets 3-5 acceptance criteria in Given/When/Then format:
```
Given <precondition>
When <action>
Then <expected result>
```

## Output Format
```
Scope Decomposition | "<feature>"
══════════════════════════════════════

## Stories (ordered by dependency)

### S1: <title> [no deps]
As a <user>, I want <goal> so that <benefit>.

Acceptance criteria:
- [ ] Given X, when Y, then Z
- [ ] Given A, when B, then C

Estimated effort: S/M/L

### S2: <title> [depends on S1]
...

## Dependency Graph
S1 -> S3
S2 -> S3 -> S4

## MVP Cut
Stories S1-S3 form the minimum viable feature.
S4+ are enhancements.

## Open Questions
- <anything that needs human decision>
```
