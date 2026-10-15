---
name: succession-mode
description: Constitutional Tier 5 — what happens when the operator is no longer available. A will, not a feature. Pre-registration required.
version: 0.1.0
execution-mode: advisory
status: approved
category: fleet-ops
tier: 5
protected_variable: operator_stated_wishes
always_active: false
overridable: false
overrides:
  - all-modes
composition: []
conflicts: []
trigger:
  - operator-unresponsive-7-days
  - emergency-contact-confirms-unavailable
  - operator-manual-activation
  - survival-mode-exit-unresponsive
---

# Succession-Mode Skill

## Invocation

**Triggered only when:**
1. Operator unresponsive for 7 days (default)
2. Emergency contact confirms operator is unavailable
3. Operator manually activates ("I'm leaving, execute succession")
4. Survival-mode exits with operator still unresponsive

**Manual trigger**: `/succession-mode` (requires confirmation)

**Pre-registration required**: Operator must complete the succession
directive template in the doctrine before this mode can function.

## What This Skill Does

Executes operator's pre-registered succession plan:
- Transfers authority to named successor (if any)
- Preserves or archives operator's work and data
- Notifies designated contacts
- Winds down or continues operations per directives
- Protects operator's privacy and legacy

## Inputs

- **Succession directives**: Pre-registered by operator (contacts, successor, wind-down plan, legacy preservation, privacy protection)
- **Trigger reason**: Why succession-mode activated
- **Operator status**: Unresponsive / confirmed unavailable / manual departure

## Output

```markdown
# Succession-Mode Activation

**Trigger**: <reason>
**Operator status**: <unavailable>
**Directives found**: yes / no / partial
**Successor**: <name / none>

## Directives Executed
- <directive>: <status>

## Contacts Notified
- <contact>: <time>: <response>

## State Preserved
- <archive location>: <contents>

## Authority Transfer
- <successor>: <accepted / pending / none>

## Final State
- preserved / wound-down / continuing / awaiting-return
```

## Pre-Registration

**The operator must complete the succession directive template before
this mode can activate meaningfully.** Without pre-registered directives,
the system enters preservation mode (archive everything, execute nothing, wait).

To pre-register:
1. Read `docs/modes/succession-mode/SUCCESSION_MODE_DOCTRINE.md`
2. Complete the "Succession Directive Template" section
3. Store in a location known to the system and at least one emergency contact
4. Review annually

## Composition

**None.** Succession-mode overrides all other modes. When active, only
the operator's pre-registered directives govern — not mission-mode,
not crisis-mode, not any operational mode.

## Cost

N/A — succession-mode activates only during operator unavailability.
The cost of pre-registration is ~30 minutes annually.
