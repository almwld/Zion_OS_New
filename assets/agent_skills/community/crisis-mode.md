---
name: crisis-mode
description: Calm-first crisis response — stabilize before you solve, preserve evidence, postmortem mandatory.
version: 0.1.0
execution-mode: advisory
status: approved
category: fleet-ops
protected_variable: calm_first_response
composition:
  - economics-mode
conflicts:
  - deep-research-mode
---

# Crisis-Mode Skill

## Invocation

```
/crisis-mode
```

Or automatic when kill-switch reaches HALT_ALL or EMERGENCY.

## What This Skill Does

Activates crisis-mode for incident response. Enforces calm-first assessment,
severity classification, containment-before-fix, evidence preservation, and
mandatory postmortem.

## Inputs

- **Crisis description**: What happened?
- **Affected systems**: What is broken or at risk?
- **Current kill-switch state**: DISENGAGED / HALT_NONCRITICAL / HALT_ALL / EMERGENCY

## Output

```markdown
# Crisis-Mode Incident Response

**Crisis ID**: <unique-id>
**Severity**: P0 / P1 / P2 / P3
**Summary**: <1-sentence>

## Assessment (within 5 minutes)
- **What is broken**: <list>
- **Blast radius**: <what is affected>
- **What is bleeding**: <active damage>
- **What can wait**: <non-urgent issues>

## Containment Actions
- <time>: <action> → <result>
- <time>: <action> → <result>

## Evidence Preserved
- <snapshot location>
- <log path>

## Communication Log
- <time>: <status update sent>

## Postmortem
- **Scheduled**: <date>
- **Root cause**: <identified / pending>
```

## Composition

- **crisis-mode + economics-mode**: Financial crisis. Economics-mode evaluates financial impact while crisis-mode stabilizes.

## Conflicts

- **crisis-mode + deep-research-mode**: Crisis demands fast action; research demands slow exploration. Use sequentially, not simultaneously.

## Cost

~5K-15K tokens per incident (depends on severity and duration).
