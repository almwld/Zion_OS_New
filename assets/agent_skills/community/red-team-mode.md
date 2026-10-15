---
name: red-team-mode
description: Adversarial analysis — find how it breaks, not how it works. Every finding has severity and fix.
version: 0.1.0
execution-mode: advisory
status: approved
category: security
protected_variable: flaw_discovery
composition:
  - deep-research-mode
conflicts: []
---

# Red-Team-Mode Skill

## Invocation

```
/red-team-mode
```

Or "stress-test this".

## What This Skill Does

Activates red-team-mode for adversarial analysis. Deliberately searches for
flaws, exploits, contradictions, weak claims, edge cases, and governance
bypasses. Every finding has severity, attack path, and fix recommendation.

## Inputs

- **Target**: What system/document/hypothesis/decision to red-team?
- **Scope**: What is in/out of bounds?
- **Time budget**: How long to spend (default: 30 minutes)

## Output

```markdown
# Red-Team Findings

**Target**: <what was red-teamed>
**Scope**: <in/out of bounds>
**Time budget**: <allocated / used>

## Findings

### [CRITICAL] <finding title>
- **Attack path**: <step-by-step from normal to failure>
- **Fix recommendation**: <how to address>

### [HIGH] <finding title>
- **Attack path**: <steps>
- **Fix recommendation**: <how to address>

### [MEDIUM] <finding title>
...

### [LOW] <finding title>
...

## Checked and Clean
- <what was tested and found no flaws>

## Not Checked
- <what was out of scope or time-budget>

## Overall Assessment
<robust / adequate / needs work / broken>
```

## Composition

- **red-team-mode + deep-research-mode**: Research-backed adversarial analysis. Deep-research finds sources; red-team stress-tests them.

## Conflicts

No explicit skill conflicts are declared until the paired skills exist in this registry.

## Cost

~15K-40K tokens per session (depends on target complexity and time budget).
