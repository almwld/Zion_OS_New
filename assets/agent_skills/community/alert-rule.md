---
name: alert-rule
description: Create and manage alert rules for health probes, cost thresholds, and CI failures
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<action: list|add|remove|test> [rule-spec]"
category: governance-compliance
status: candidate
---
# [alert-rule]

## When to Use
- Setting up monitoring thresholds for new services
- Adjusting alert sensitivity after false positives
- Adding cost budget alerts before month-end
- Configuring CI failure notifications
- Reviewing current alert coverage

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=alert-rule] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load Current Alert Configuration
```bash
# Check for alert config files
find . -path "*/services/*" -o -path "*/integrations/*" | -name "*alert*" -o -name "*threshold*" -o -name "*monitor*" | grep -v __pycache__ | head -15
# Current alert module
cat services/alerts.py | head -40
# Health probe configuration
grep -rn "threshold\|alert\|warn\|critical" services/health.py | head -15
# Cost thresholds
grep -rn "budget\|threshold\|limit\|alert" integrations/cost_tracker.py | head -15
```

### 2. Parse Action
- **list**: show all configured alert rules with their current state
- **add**: create a new alert rule from spec
- **remove**: disable or delete an alert rule
- **test**: trigger an alert rule to verify it fires correctly

### 3. Rule Specification Format
When adding a rule:
```
Type:      health | cost | ci | bus | custom
Target:    <probe-name or metric-name>
Condition: <operator> <threshold> [for <duration>]
Channel:   console | file | webhook | signal
Severity:  info | warning | critical
Cooldown:  <minutes between repeat alerts>
```

Example: `add health github_adapter > 3 failures for 5m channel=console severity=warning cooldown=15`

### 4. Add Rule
- Validate the rule specification
- Check for conflicts with existing rules
- Add to alert configuration (alerts.py or config file)
- Generate test to verify the rule

### 5. Test Rule
```bash
# Run alert system tests
python -m pytest tests/ -k "alert" -v --tb=short
# Simulate a threshold breach
python -c "from hummbl_governance.services.alerts import *; # trigger test alert"
```

## Output Format

```
Alert Rules | <action> | <date>
============================================

Current Rules (list)
--------------------
  #  | Type   | Target          | Condition        | Channel  | Severity | Status
  ---|--------|-----------------|------------------|----------|----------|--------
  1  | health | github_adapter  | failures > 3/5m  | console  | warning  | ACTIVE
  2  | cost   | daily_budget    | spend > $5.00    | file     | critical | ACTIVE
  3  | ci     | main_branch     | 2 consecutive    | webhook  | critical | ACTIVE
  4  | bus    | message_gap     | silence > 30m    | console  | info     | PAUSED
  5  | health | all_adapters    | any circuit open | console  | warning  | ACTIVE

Action Result
-------------
  [ADD] Rule #6: cost monthly_budget spend > $50.00 channel=signal severity=critical
  Config updated: services/alerts.py
  Test generated: tests/test_alert_rule_6.py

  -- or --

  [TEST] Rule #1 (github_adapter failures): FIRED correctly in 0.3s
  Alert output: "WARNING: github_adapter 4 failures in 5m window"

Coverage Gaps
-------------
  [WARN] No alert on: kill_switch state changes
  [WARN] No alert on: delegation token expiry
  [INFO] 5/7 adapters have health alerts configured

Next action: <recommendation>
```

## Skill Chains

### Mandatory

None — config management; alerts are safety primitives and adding/removing rules does not destabilize the system.

### Advisory

- After `[alert-rule] add` → `[test-run]` to verify alert tests pass
- After `[alert-rule] list` → `[health]` to check current probe status
- After `[alert-rule]` → `[chaos-test]` to verify alerts fire under failure

## Authority

- **T1 (TRUSTED)**: May run freely (all actions: list, add, remove, test)
- **T2 (Active/High)**: May run freely (all actions: list, add, remove, test)
- **T3 (Medium)**: May run with operator notification (all actions permitted; notify operator after add/remove)
- **T4 (Probationary)**: May run read-only (list/view only); create/modify/remove BLOCKED
- **Operator**: Override any restriction
