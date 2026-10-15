---
name: changelog-digest
description: Generate a human-readable digest of changes for non-technical stakeholders.
version: 0.1.0
execution-mode: advisory
argument-hint: "[week | month | since TAG]"
category: dev-tools
status: candidate
---
# Changelog Digest

Transform git history into a human-readable summary for non-technical audiences (investors, advisors, users).

## How It Differs From [changelog]
`[changelog]` produces Conventional Commits formatted output for developers.
`[changelog-digest]` produces plain English summaries for non-technical readers.

## Execution

### 1. Gather raw changes
```bash
git log --oneline --since="$PERIOD" | head -50
```

### 2. Classify by audience impact

| Category | What To Include | Example |
|----------|----------------|---------|
| **New capabilities** | Features users can see/use | "Morning Briefing now includes Linear priorities" |
| **Reliability** | Fixes that affect uptime/correctness | "Fixed OAuth token refresh to prevent briefing failures" |
| **Security** | Security improvements | "Added content scanning to prevent prompt injection in shared memory" |
| **Performance** | Speed/efficiency gains | "Reduced briefing generation time by 40%" |
| **Infrastructure** | Under-the-hood (brief mention) | "Added 53 new operational skills" |

### 3. Write the digest

**Rules:**
- No commit hashes or file paths
- No jargon (say "shared memory" not "CLP ledger")
- Lead with what CHANGED for the user, not what code was written
- Quantify where possible ("53 new skills" not "many new skills")
- Group related changes into a single bullet

## Output Format
```
What's New | <period>
═══════════════════════

## Highlights
- <biggest user-visible change>
- <second biggest>

## New Capabilities
- <feature 1>
- <feature 2>

## Reliability & Security
- <fix or hardening>

## Under the Hood
- <infrastructure change, brief>

## By the Numbers
| Metric | Before | After |
|--------|--------|-------|
```

## Base120 Context
- Primary: **P9** (Cultural Lens Shifting -- technical to non-technical)
- Related: **RE4** (Nested Story -- layered detail), **P8** (Narrative Framing)
