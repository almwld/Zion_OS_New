---
name: onboard-human
description: Onboard a new human team member -- dev environment, access, context, first tasks.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "\"NAME\" [role: engineer|ops|founder]"
category: sales-marketing
status: candidate
---
# Onboard Human

Structured onboarding for a new team member joining the hummbl-governance project.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=onboard-human] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Environment setup
```bash
# Clone the repo
git clone git@github.com:$GITHUB_ORG/hummbl-governance.git
cd hummbl-governance

# Python environment
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e ".[test]"

# Verify
python -m pytest tests/ -x -q --timeout=60
```

### 2. Access provisioning
- [ ] GitHub: Add to `$GITHUB_ORG` org with appropriate role
- [ ] Tailscale: Invite to tailnet for $REMOTE_HOST access
- [ ] SSH: Add public key to $REMOTE_HOST (`/Users/<user>/.ssh/authorized_keys`)
- [ ] Claude Code: Install and authenticate with their own account
- [ ] Signal: Add to team Signal group (if applicable)

### 3. Context documents (reading order)
1. `README.md` -- project overview (5 min)
2. `CLAUDE.md` -- architecture, commands, conventions (15 min)
3. `AGENTS.md` -- multi-agent coordination model (10 min)
4. `CONTRIBUTING.md` -- commit format, PR process (5 min)
5. `state/briefings/` -- recent briefings for current state (10 min)
6. `docs/reference/` -- security guides, tier matrix (as needed)

### 4. First tasks (by role)

**Engineer:**
1. Run the full test suite and verify it passes
2. Read the most recent 5 commits and understand the changes
3. Pick up a P2 bug or small feature
4. Submit a PR and go through the review process

**Ops:**
1. SSH to $REMOTE_HOST and run `[health]`
2. Check all services are running (`[process-check] $REMOTE_HOST`)
3. Read the last 3 daily briefings
4. Monitor a morning briefing run end-to-end

**Founder:**
1. Read the investor update (`[investor-update]`)
2. Review the sprint status (`[sprint-status]`)
3. Check the runway (`[runway]`)
4. Browse the agent registry for competitive context

### 5. Create their agent profile
If they'll be running agents:
```bash
# On $REMOTE_HOST (if they need server access)
sudo sysadminctl -addUser <username> -fullName "<Name>" -password - -admin
sudo dscl . -append /Groups/hummbl GroupMembership <username>
```

### 6. Post onboarding record
```bash
source .venv/bin/activate
python -m hummbl_governance.cognition post \
  --vendor "${AGENT_VENDOR:?set AGENT_VENDOR to the provider actually running}" --model "${AGENT_MODEL:?set AGENT_MODEL to the model actually running}" \
  --type decision --scope process \
  --content "Onboarded <name> (<role>). Access: <what was granted>." \
  --tags "onboarding,team"
# The skill invocation runtime injects the caller's canonical identity as agent.
```

## Output Format
```
Onboarding | <name> (<role>)
═══════════════════════════════

## Access Granted
- [ ] GitHub
- [ ] Tailscale
- [ ] SSH
- [ ] Claude Code
- [ ] Signal

## Reading Assigned
<ordered list>

## First Tasks
<3 specific tasks>

## Notes
<anything specific to this person>
```

## Skill Chains

### Mandatory

None — onboarding is a standard procedure with no destructive side effects beyond environment setup and access provisioning.

### Advisory

- After environment setup → `[health]` to verify system state
- After access provisioning → `[process-check]` to verify services are running
- After onboarding complete → `[async-update]` to inform stakeholders of new team member

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator approval
- **T4 (Probationary)**: BLOCKED — access provisioning requires elevated trust
- **Operator**: Override any restriction
