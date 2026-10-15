---
name: forensic-recommendations
description: >-
  Act on recommendations from session forensic reports and cross-session
  analysis. Implements fixes for recurring issues found during forensics:
  bus protocol violations, AGENTS.md gaps, SSH connectivity problems,
  missing tools, and code bugs. Produces a structured action plan with
  status tracking. Use when the user says "fix the recommendations",
  "act on the forensics", "implement the fixes", or after a
  cross-session-learnings analysis produces recommendations.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--session <id>] [--all] [--dry-run]"
category: fleet-ops
status: candidate
---

# Forensic Recommendations

Act on recommendations from session forensic reports. Implements fixes
for issues found during forensics, with status tracking and verification.

## When to Use

- After `cross-session-learnings` produces recommendations
- When the user says "fix those recommendations" or "act on the forensics"
- After a forensic report identifies actionable fixes
- When the user wants to systematically address session findings

## Execution

### 1. Gather recommendations

From forensic reports:
```
~/PROJECTS/_internal/session-forensics/<session-id>/report.md
```

From cross-session analysis (output of `cross-session-learnings`).

### 2. Categorize each recommendation

| Category | Action | Skill/Tool |
|----------|--------|------------|
| Bus protocol | Fix bus-global.py or document protocol | `bus-post-check` |
| AGENTS.md gap | Update AGENTS.md with learning | `agents-md-update` |
| SSH connectivity | Document method, update AGENTS.md | `fleet-ssh-probe` |
| Missing tool/package | Install or document workaround | `exec` (needs sudo) |
| Code bug | Create fix, test, PR | `edit`, `exec` |
| CI failure | Investigate via `gh`, fix | `ci-monitor` |
| Skill gap | Create new skill | `skill-create` |
| Process change | Update operating principles | `agents-md-update` |

### 3. Assess each recommendation

For each recommendation, determine:
- **Can I fix this autonomously?** (code change, doc update, bus-global.py fix)
- **Does this need operator approval?** (sudo install, git push, PR merge)
- **Is this already resolved?** (check current state before acting)
- **What is the priority?** (high = security/data loss, medium = productivity, low = nice-to-have)

### 4. Execute fixes (autonomous ones)

For each autonomous fix:
1. Make the change (edit file, update config, fix code)
2. Verify the change works (run test, dry-run, grep verification)
3. Record the outcome

### 5. Escalate operator-dependent items

For items needing operator approval:
1. Clearly state what needs to be done
2. Explain why it needs operator involvement (sudo, push, merge)
3. Provide the exact command for the operator to run
4. Wait for approval before proceeding

### 6. Produce action plan

```
Forensic Recommendations | <N> items
══════════════════════════════════════════════════════════════════════

## Completed (autonomous)
  [x] <recommendation> — <what was done> — <verification>
  ...

## Needs Operator Approval
  [ ] <recommendation> — <why> — <command to run>
  ...

## Already Resolved
  [~] <recommendation> — <why it's already fixed>
  ...

## Deferred
  [ ] <recommendation> — <reason for deferral>
  ...
```

### 7. Verify completed fixes

For each completed fix, verify:
- **Code change**: run relevant test or type check
- **Doc update**: `grep -c "<unique phrase>" <file>` must return >= 1
- **Bus-global.py change**: `python ~/bin/bus-global.py post <from> <to> <type> "<msg>" --dry-run`
- **AGENTS.md update**: read back the updated section

### 8. Commit changes

If `--dry-run` is not specified, commit autonomous fixes:
- One commit per logical fix
- Conventional Commits format
- GPG-signed (per AGENTS.md)
- Do not push unless operator approves

## Cross-References

- Input: `session-forensics` reports, `cross-session-learnings` analysis
- Tools: `bus-post-check`, `agents-md-update`, `fleet-ssh-probe`, `workstation-git-sync`
- Verification: `dod` (Definition of Done) before marking complete
