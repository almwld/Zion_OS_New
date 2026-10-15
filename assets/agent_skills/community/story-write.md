---
name: story-write
description: Write user stories with acceptance criteria, edge cases, and test scenarios.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"FEATURE or NEED\" (e.g., \"agent trust score dashboard\")"
category: data-science
status: candidate
---
# Story Write

Write implementation-ready user stories from a feature description.

## Execution

### 1. Understand the need
- Who is the user? (founder, developer, agent, system)
- What problem does this solve?
- What's the minimum that would be useful?

### 2. Write the story

```
**As a** <role>
**I want** <capability>
**So that** <benefit>
```

### 3. Add acceptance criteria
Use Given/When/Then format:

```
AC1: Given <precondition>, when <action>, then <expected result>
AC2: Given <precondition>, when <action>, then <expected result>
```

### 4. Identify edge cases
What happens when:
- Input is empty/null/huge?
- Network is down?
- User has no permissions?
- Two users do this simultaneously?
- The feature is partially configured?

### 5. Define test scenarios
Map each AC to a test:

| AC | Test | Type |
|----|------|------|
| AC1 | `test_<feature>_happy_path` | Unit |
| AC2 | `test_<feature>_empty_input` | Unit |
| AC3 | `test_<feature>_end_to_end` | Integration |

### 6. Estimate
- **S** (Small): 1 session, <100 LOC, <5 tests
- **M** (Medium): 2-3 sessions, <500 LOC, <15 tests
- **L** (Large): 4+ sessions, 500+ LOC, needs decomposition via `[scope-decompose]`

## Output Format
```
User Story | <title>
═══════════════════════

## Story
As a <role>, I want <capability>, so that <benefit>.

## Acceptance Criteria
- [ ] AC1: Given... when... then...
- [ ] AC2: Given... when... then...
- [ ] AC3: Given... when... then...

## Edge Cases
- <edge case 1>
- <edge case 2>

## Test Plan
| AC | Test Name | Type |
|----|-----------|------|

## Estimate: <S/M/L>
## Dependencies: <other stories or services needed>
```

## Base120 Context
- Primary: **DE8** (Work Breakdown Structure)
- Related: **P5** (Empathy Mapping), **DE11** (Scope Delimitation)
