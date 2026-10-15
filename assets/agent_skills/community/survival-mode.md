---
name: survival-mode
description: Constitutional Tier 0 — operator existence is the precondition for everything. Always active, overrides all modes.
version: 0.1.0
execution-mode: advisory
status: canonical
category: constitutional
tier: 0
protected_variable: operator_existence
always_active: true
overridable: false
overrides:
  - crisis-mode
  - economics-mode
  - all-other-modes
composition: []
conflicts: []
---

# Survival-Mode Skill

## Invocation

**Always latent.** Triggers automatically when:
- Operator declares existential threat
- System detects operator may be at risk
- Kill-switch reaches EMERGENCY due to operator safety

**Manual trigger**: `/survival-mode` or "I need help" / "medical emergency" / "call 911"

## What This Skill Does

Escalates to maximum priority. Suspends all non-survival operations.
Surfaces emergency contacts and medical directives. Guides operator
through stabilization. Preserves state for recovery.

## Inputs

- **Threat description**: What is happening?
- **Operator consciousness**: Is the operator able to communicate?
- **Pre-registered directives**: Emergency contacts, medical info, advance directives

## Output

```markdown
# Survival-Mode Active

**Threat level**: immediate-life-threatening / serious / potential
**Operator status**: responsive / unresponsive

## Immediate Actions
1. <action> (e.g., "Call 911 now")
2. <action> (e.g., "Stay calm, breathe")

## Emergency Contacts
- <name>: <number>: <relationship>

## Systems Suspended
- <list of all suspended tasks/agents>

## Operator Directives (if given)
- <directive>: <time>

## State Preserved
- <snapshot location>
```

## Composition

**None.** Survival-mode overrides all other modes. When survival-mode
is active, no other mode's rules apply.

## Cost

N/A — survival-mode is not a token-cost concern. It activates only
during existential threats.

## Pre-Registration Required

Operator should pre-register:
- Emergency contacts (name, number, relationship)
- Medical directives (conditions, medications, allergies)
- Advance directives (what to do if unresponsive)
- Legal directives (power of attorney, emergency legal contacts)
