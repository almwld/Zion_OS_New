---
name: evidence-pack
description: Bundle bus logs, guardrails, ADRs, and governance artifacts into a shareable evidence pack for demos, pitches, audits, and case studies.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope incident|agent|full|custom] [--agent gemini|kimi|codex|all] [--since DATE] [--redact] [--format md|dir]"
category: governance-compliance
status: candidate
---
# Evidence Pack

Bundle governance artifacts from the live system into a self-contained, shareable package. Designed for demos, pitch decks, compliance audits, case studies, and conference talks.

## When to Use
- Preparing a pitch or investor meeting (proof of governance in action)
- Writing a case study or conference talk (real evidence, not hypotheticals)
- Compliance audit or NIST AI RMF evidence submission
- Post-incident review that needs to be shared externally
- Onboarding a new team member who needs to see governance in action
- When user says "bundle the evidence" or "make it shareable"

## What Gets Bundled

### Core Artifacts

| Artifact | Source | What It Shows |
|----------|--------|--------------|
| **Bus messages** | `$PROJECT_ROOT/_state/coordination/messages.tsv` | Multi-agent coordination, message flow, identity enforcement |
| **Guardrails docs** | `.claude/rules/*-guardrails.md` | Operating rules, scope gates, escalation triggers, audit history |
| **ADRs** | `$PROJECT_ROOT/docs/adrs/ADR-*.md` | Architectural decisions with context, alternatives, consequences |
| **Security ADRs** | `$PROJECT_ROOT/docs/security/adrs/ADR-*.md` | Security architecture decisions (HMAC, fail-close, hash chains) |
| **Bus protocol** | `.claude/rules/bus-protocol.md` | Append-only coordination protocol |
| **Governance bus logs** | `$PROJECT_ROOT/_state/governance/*.jsonl` | IDP delegation audit trail |
| **Kill switch state** | Kill switch config/state | Safety primitive evidence |
| **Circuit breaker state** | Circuit breaker config | Resilience primitive evidence |

### Optional Artifacts

| Artifact | When to Include | Source |
|----------|----------------|--------|
| **Agent audit trail** | Incident-focused packs | Guardrails doc audit history |
| **Enforcement hooks** | Compliance packs | `scripts/git-hooks/guard-*.sh` |
| **CI workflows** | Full governance packs | `.github/workflows/security.yml`, `pr-guardrails.yml` |
| **CLP ledger entries** | Knowledge governance | `$PROJECT_ROOT/_state/cognition/ledger.jsonl` |
| **Test counts** | Maturity evidence | pytest collection stats |

## Scopes

### `incident` -- Single agent incident
Bundles: bus messages from agent, guardrails doc (full audit history), remediation rules, enforcement hooks. Best for: case studies, talks, "what went wrong and how we caught it."

### `agent` -- Full agent governance profile
Bundles: guardrails doc, approved scope, bus messages, commit history, trust score. Best for: agent onboarding, audit, trust assessment.

### `full` -- Complete governance system
Bundles: all guardrails, all ADRs, bus protocol, security ADRs, enforcement hooks, CI workflows, IDP state, kill switch, circuit breakers. Best for: compliance audits, investor due diligence, partnership discussions.

### `custom` -- Pick specific artifacts
User specifies which artifacts to include. Best for: targeted evidence for a specific claim or question.

## Execution

### 1. Collect artifacts

```bash
# Create output directory
PACK_DIR="_evidence/evidence-pack-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$PACK_DIR"/{bus,guardrails,adrs,security,governance,hooks,ci}
```

### 2. Bus messages

Filter by scope:

```bash
# Full bus (copy with header)
cp $PROJECT_ROOT/_state/coordination/messages.tsv "$PACK_DIR/bus/messages.tsv"

# Agent-filtered (e.g., agent-name)
head -1 $PROJECT_ROOT/_state/coordination/messages.tsv > "$PACK_DIR/bus/messages-filtered.tsv"
grep -i "$AGENT_NAME" $PROJECT_ROOT/_state/coordination/messages.tsv >> "$PACK_DIR/bus/messages-filtered.tsv"

# Time-filtered (since a date)
head -1 $PROJECT_ROOT/_state/coordination/messages.tsv > "$PACK_DIR/bus/messages-since.tsv"
awk -v since="$SINCE_DATE" '$1 >= since' $PROJECT_ROOT/_state/coordination/messages.tsv >> "$PACK_DIR/bus/messages-since.tsv"
```

### 3. Guardrails

```bash
# All agent guardrails
for f in .claude/rules/*-guardrails.md; do
    cp "$f" "$PACK_DIR/guardrails/" 2>/dev/null
done

# Bus protocol
cp .claude/rules/bus-protocol.md "$PACK_DIR/guardrails/"
```

### 4. ADRs

```bash
# All project ADRs
cp $PROJECT_ROOT/docs/adrs/ADR-*.md "$PACK_DIR/adrs/" 2>/dev/null

# Security ADRs
cp $PROJECT_ROOT/docs/security/adrs/ADR-*.md "$PACK_DIR/security/" 2>/dev/null
```

### 5. Enforcement hooks (if scope includes)

```bash
# Git hooks that enforce agent guardrails
cp scripts/git-hooks/guard-*.sh "$PACK_DIR/hooks/" 2>/dev/null
```

### 6. CI workflows (if scope=full)

```bash
cp .github/workflows/security.yml "$PACK_DIR/ci/"
cp .github/workflows/pr-guardrails.yml "$PACK_DIR/ci/"
cp .github/workflows/agent-scope.yml "$PACK_DIR/ci/" 2>/dev/null
```

### 7. Governance / IDP (if scope=full)

```bash
# IDP governance logs
cp $PROJECT_ROOT/_state/governance/*.jsonl "$PACK_DIR/governance/" 2>/dev/null

# Kill switch and circuit breaker state (read-only snapshot, if available)
echo "Kill switch: check project-specific command" > "$PACK_DIR/governance/kill-switch-state.txt"
```

### 8. Redaction (if --redact)

When preparing for external sharing, redact:

```bash
# Redact patterns that could leak info
# - Secret keys, tokens, API keys
# - Internal IPs (except 127.0.0.1)
# - Tailscale IPs
# - File paths containing usernames
# - Email addresses (unless public)

for f in $(find "$PACK_DIR" -type f -name "*.md" -o -name "*.tsv" -o -name "*.jsonl" -o -name "*.txt" -o -name "*.yml"); do
    # Tailscale IPs → [REDACTED-IP]
    sed -i 's/100\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[REDACTED-IP]/g' "$f"
    # Home directory paths → [HOME]/
    sed -i 's|/Users/[a-zA-Z0-9_-]*/|[HOME]/|g' "$f"
    sed -i 's|C:\\Users\\[a-zA-Z0-9_-]*\\|[HOME]\\|g' "$f"
    # Email addresses (simple pattern) → [REDACTED-EMAIL]
    sed -i 's/[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]\{2,\}/[REDACTED-EMAIL]/g' "$f"
done
```

### 9. Generate index

Create a `README.md` at the pack root:

```markdown
# Evidence Pack | {date} | {scope}

Generated by governance system.

## Contents

| Directory | Contents | Count |
|-----------|----------|-------|
| `bus/` | Coordination bus messages | {N} messages |
| `guardrails/` | Agent operating rules | {N} docs |
| `adrs/` | Architecture Decision Records | {N} ADRs |
| `security/` | Security ADRs | {N} ADRs |
| `governance/` | IDP audit logs, kill switch state | {N} files |
| `hooks/` | Enforcement hook scripts | {N} scripts |
| `ci/` | CI workflow definitions | {N} workflows |

## System Overview

- **Agents governed**: {list from guardrails docs}
- **Bus messages total**: {count}
- **ADRs recorded**: {count}
- **Test coverage**: {N}+ tests
- **Safety primitives**: Kill switch (4 modes), Circuit breakers (per-adapter), IDP delegation tokens

## Key Evidence

{Scope-dependent highlights -- e.g., for incident scope:}
- Agent exceeded authority: {summary}
- Detection mechanism: {what caught it}
- Remediation: {rules added}
- System impact: {none / contained}

## Redaction Notice
{If --redact: "This pack has been redacted for external sharing. Internal IPs, file paths, and email addresses have been replaced with placeholders."}
{If not redacted: "This pack contains internal paths and identifiers. Review before sharing externally."}
```

### 10. Package

```bash
# Create tarball
tar -czf "${PACK_DIR}.tar.gz" -C "$(dirname $PACK_DIR)" "$(basename $PACK_DIR)"

# Or zip for Windows/email compatibility
# (cd to parent, zip the directory)
cd "$(dirname $PACK_DIR)" && zip -r "$(basename $PACK_DIR).zip" "$(basename $PACK_DIR)"
```

## Output Format

```
Evidence Pack | {date} | {scope}
================================

## Pack Created
Path: {PACK_DIR}
Archive: {PACK_DIR}.tar.gz
Size: {size}

## Contents Summary
| Artifact | Count | Notes |
|----------|-------|-------|
| Bus messages | {N} | {filtered by: agent/date/all} |
| Guardrails docs | {N} | {which agents} |
| ADRs (arch) | {N} | ADR-FM-000 through ADR-FM-{latest} |
| ADRs (security) | {N} | HMAC, fail-close, hash chains |
| Enforcement hooks | {N} | {which hooks} |
| CI workflows | {N} | {which workflows} |
| Governance logs | {N} | IDP, kill switch |

## Redaction
{Applied / Not applied}
{If applied: what was redacted}

## Suggested Use
{Based on scope:}
- incident → "Ready for case study or conference talk. Key narrative: detection → containment → remediation."
- agent → "Agent governance profile complete. Suitable for trust assessment or onboarding doc."
- full → "Complete governance evidence. Suitable for compliance audit, investor DD, or partnership review."
- custom → "Custom selection. Review contents before sharing."

## Next Steps
- [ ] Review for sensitive content before sharing
- [ ] {If not redacted: consider running with --redact for external use}
- [ ] {Suggest relevant follow-up skill}
```

## Predefined Packs

For common use cases, these are ready-to-go configurations:

### "Agent Incident Story" (pitch/talk)
```
[evidence-pack] --scope incident --agent <agent-name> --since <start-date> --redact
```
Bundles the full audit trail: escalating violations, detection, remediation, current guardrails. The narrative arc that sells governance.

### "Compliance Package" (audit)
```
[evidence-pack] --scope full --redact
```
Everything: all guardrails, all ADRs, all enforcement mechanisms, IDP state, kill switch, CI. For NIST AI RMF evidence or SOC 2 preparation.

### "Agent Trust Profile" (onboarding)
```
[evidence-pack] --scope agent --agent <agent-name>
```
Single-agent deep dive: operating rules, approved scope, bus history, audit trail. For trust assessment or new agent onboarding comparison.

### "Architecture Decisions" (technical review)
```
[evidence-pack] --scope custom
# Then select: adrs + security adrs only
```
Just the decision records. For technical reviews, architecture discussions, or "why did you choose X" questions.

## What to Persist

- Evidence packs are ephemeral by default (written to `_evidence/` which is gitignored)
- If a pack is created for a specific audit or engagement, note it in the CLP ledger
- Do NOT commit evidence packs to git (they may contain bus messages with internal details)

## Skill Chains

### Mandatory (MUST pass before external sharing)

- **`[content-review]`** MUST pass for any pack shared externally — no exceptions.
  Evidence packs contain bus messages, internal paths, and agent communications.
  Redaction (`--redact`) is necessary but NOT sufficient — content-review is the gate.

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Pack for pitch | `[pitch]` to build the deck around the evidence |
| Pack for audit | `[nist-map]` to map evidence to framework controls |
| Pack for case study | `[case-study]` to write the narrative |
| Pack for talk | `[paper]` or `[docgen]` to draft the abstract/slides |
| Pack for compliance | `[soc2-check]` or `[iso-crosswalk]` to verify coverage |
| Pack for investor | `[investor-update]` to contextualize the evidence |
| Pack for onboarding | `[onboard-human]` to use the pack in onboarding |
| Redacted pack | `[content-review]` to verify nothing sensitive leaked |

## Authority

- **T1 (TRUSTED)**: May generate packs without restriction; external sharing requires `[content-review]`
- **T2 (Active/High)**: May generate packs; external sharing requires `[content-review]` passed
- **T3 (Medium)**: May generate packs; external sharing requires operator approval AND `[content-review]`
- **T4 (Probationary)**: May generate packs (read-only bundling); external sharing BLOCKED
- **Operator**: Override any restriction
