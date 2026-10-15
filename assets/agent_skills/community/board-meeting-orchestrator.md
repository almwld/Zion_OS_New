---
name: board-meeting-orchestrator
description: >
  Run an AI Board of Directors meeting. Reads the Board Constitution
  Registry, gathers live context (bus, git, skills), invokes each
  Director's question generation, collects the Principal Human Agent's
  written answers, and writes the Board review record to the coordination bus.
  Use this skill whenever you need structured deliberation before a
  high-stakes decision, at the scheduled tactical/strategic cadence,
  or when a Director has flagged a BLOCKED decision. Board outputs are
  REVIEW/BLOCKED recommendations only — binding DECISION requires
  Principal Agent authorization (doctrine v0.4.1).
version: 1.2.0
execution-mode: side_effecting
argument-hint: "[tactical | strategic | triggered --topic <topic> --directors <ids>]"
category: fleet-ops
status: candidate
---

# Board Meeting Orchestrator

## When to Use

- **Monday 09:00 ET** — scheduled tactical meeting (Principal Agent + future-self)
- **First Monday of month** — scheduled strategic meeting (all Directors)
- **Before high-stakes decisions** — spend >$500, time >16 hours, pivot, hire, partner, fundraise, sunset
- **When a Director writes BLOCKED** — convene to resolve the block
- **When you feel stuck** — the Board forces articulation, which often reveals the path

## Prerequisites

1. **Board Constitution Registry** must exist at:
   ```
   PROJECTS/hummbl-production/governance/board/registry.yaml
   ```
2. **Director constitutions** must exist in:
   ```
   PROJECTS/hummbl-production/governance/board/constitutions/*.yaml
   ```
3. **Bus write access** — this skill writes QUESTION, REVIEW, and BLOCKED messages under the invoking agent's canonical identity. It does not post DECISION; binding decisions remain Principal Human Agent-only by default.
4. **Context budget** — a full strategic meeting with 5 Directors can consume significant tokens. For quick decisions, invoke `triggered` mode with a subset of Directors.

## Agency Doctrine

- The human operator is HUMMBL's Principal Agent: the goal-owning, value-bearing, accountable agent.
- The Board is a deliberation surface that extends the Principal Agent's effective cognitive light cone; it does not own goals or binding authority.
- Directors, skills, and runtimes are delegated software systems or offices. They can ask, review, block, and preserve evidence, but they cannot decide on behalf of the Principal Agent.
- Use `Principal Agent` when referring to the human authority boundary. Use `software agent`, `runtime`, `office`, `tool`, or `delegated system` when referring to non-human execution surfaces.

## Context Gathering

Before invoking the orchestrator, gather:

```bash
# Detect current platform (for bus write path)
python -c "import platform; print(platform.system())"

# Locate the Board Registry
ls PROJECTS/hummbl-production/governance/board/registry.yaml

# Check bus write path
python ~/bin/bus-global.py status 2>$null && echo "BUS_OK" || echo "BUS_FAIL"
```

## Execution

### 0. Emit SKILL_INVOKE

```
Type: SKILL_INVOKE
To: all
Message: [skill=board-meeting-orchestrator] [mode=side_effecting] [meeting_type=<type>] [session=<session_id>]
```

### 1. Parse Arguments

Determine meeting type and Directors to invoke:

| Argument | Meaning | Default |
|----------|---------|---------|
| `tactical` | Weekly 30-min operational review | — |
| `strategic` | Monthly 60-min strategic review | — |
| `triggered` | Ad-hoc session for a specific decision | — |
| `--topic <topic>` | For triggered mode: the decision under review | required in triggered |
| `--directors <ids>` | Comma-separated Director IDs to invoke | auto-detected |
| `--decision-value <n>` | Dollar value or hour estimate | auto-detected |

**Director auto-detection rules:**
- `spend_usd > 500` or `time_hours > 16` → operator, future-self, risk-officer
- `topic in [pivot, hire, partner, fundraise, sunset]` → all 5 Directors
- `affects_shared_resource` → stakeholder-proxy added
- `claims_compliance_progress` → governance-officer added
- `contradicts_past_aar` → future-self added

### 2. Load Board Registry and Constitutions

```bash
# Read the registry
python -c "
import yaml
with open('PROJECTS/hummbl-production/governance/board/registry.yaml') as f:
    registry = yaml.safe_load(f)
print(f'Directors: {[d[\"id\"] for d in registry[\"board\"][\"directors\"]]}')
"
```

For each selected Director:
1. Load their constitution YAML
2. Read all `constitution.sources` (skills, files, bus messages)
3. Gather all `constitution.data` (via skill invocation or manual prompt)

### 3. Invoke Each Director

For each Director in the meeting:

```
Director: {name}
═══════════════════════════════════════════════════════════════

Mandate: {mandate.short}

Context gathered:
- {source_1}: {summary}
- {source_2}: {summary}
- ...

Questions for the Principal Agent:
1. [{severity}] {question_text}
2. [{severity}] {question_text}
...
```

**Director invocation protocol:**
- The orchestrator does NOT answer for the operator. It presents the questions.
- The Principal Agent must answer each required question in writing.
- The orchestrator records the Q&A pair in the meeting minutes.

### 4. Collect Principal Agent Responses

The Principal Agent answers in this format:

```
PRINCIPAL AGENT RESPONSES
═══════════════════════════════════════════════════════════════

Q1 [{question_id}]: {answer_text}
Evidence: {artifact_reference_or_none}

Q2 [{question_id}]: {answer_text}
Evidence: {artifact_reference_or_none}

...
```

**Rules for Principal Agent responses:**
- "I don't know" is acceptable for optional questions
- "I don't know" for required questions triggers ASK_MORE
- Evidence must be a specific file path, bus message ID, URL, or metric value. "Trust me" is not evidence.
- Contradictions between answers must be resolved before proceeding

### 5. Director Voting

For each Director, determine outcome:

| Outcome | Condition | Next Action |
|---------|-----------|-------------|
| **RECOMMEND** | All required questions answered with evidence | Director writes nothing further |
| **ASK_MORE** | Answers incomplete, evasive, or contradictory | Director asks follow-up question |
| **FLAG** | Constitutional trigger met (e.g., founder-check < 7 for 2 weeks) | Write BLOCKED to bus |

**Meeting-level outcomes (Board review states — recommendations, NOT authorization):**

| Meeting State | Condition | Result |
|---------------|-----------|--------|
| **UNANIMOUS_RECOMMEND** | All Directors RECOMMEND | Proceed to Principal Agent gate; write REVIEW to bus |
| **CONDITIONAL_RECOMMEND** | All Directors RECOMMEND or ASK_MORE (resolved) | Proceed to Principal Agent gate; write REVIEW to bus |
| **BLOCKED** | Any Director FLAGS | Halt; write BLOCKED to bus; the Principal Agent must override or comply |

**Authority note (v0.4):** UNANIMOUS_RECOMMEND and CONDITIONAL_RECOMMEND are Board recommendation labels only. They do NOT authorize execution. They trigger a Principal Agent gate. Binding execution requires a Principal Agent DECISION. Legacy labels (UNANIMOUS_ACCEPT, CONDITIONAL_ACCEPT, ACCEPT) are retained as aliases only and must not be treated as binding.

### 6. Write Meeting Record to Bus

```bash
# UNANIMOUS_RECOMMEND or CONDITIONAL_RECOMMEND
python ~/bin/bus-global.py post <invoking-agent> all REVIEW \
  "[board-meeting] [role=board] [type={meeting_type}] [directors={director_ids}] [outcome=UNANIMOUS_RECOMMEND|CONDITIONAL_RECOMMEND] [principal_agent_decision_required=true] [session={session_id}]\n\n{meeting_minutes}"

# BLOCKED
python ~/bin/bus-global.py post <invoking-agent> all BLOCKED \
  "[board-meeting] [role=board] [type={meeting_type}] [directors={director_ids}] [outcome=BLOCKED] [flagged_by={director_id}] [principal_agent_decision_required=true] [session={session_id}]\n\n{meeting_minutes}"
```

`<invoking-agent>` must be a canonical sender such as `codex`, `devin`, `apex`, `nexus`, `auditor`, `hermes`, `kai`, `opencode`, or `gemini`. Do not post as `board` unless a future rule registers that sender and delegates its authority explicitly.

Legacy metadata note: older bus posts used `operator_decision_required=true` as an alias for `principal_agent_decision_required=true`. New posts should use `principal_agent_decision_required=true` only. If you see `operator_decision_required` in existing bus messages, treat it as the legacy alias.

**Meeting minutes format:**

```
BOARD MEETING MINUTES
═══════════════════════════════════════════════════════════════
Date: {timestamp}
Type: {meeting_type}
Directors: {director_names}
Principal Agent: {principal_agent_identity}
Outcome: {UNANIMOUS_RECOMMEND | CONDITIONAL_RECOMMEND | ASK_MORE | BLOCKED}
Board status: PROPOSED_ACTIVE (rehearsal-grade; binding adoption requires PA DECISION)

CONTEXT SUMMARY
- {brief_summary_of_gathered_context}

QUESTIONS AND ANSWERS
1. [{director}] [{question_id}]: {question_text}
   A: {principal_agent_answer}
   Evidence: {evidence_or_none} [VERIFIED | AS_REPORTED | PARTIAL | UNVERIFIED]

2. ...

DIRECTOR VOTES
- {director}: {RECOMMEND | ASK_MORE | FLAG} — {rationale} [per-Director flag checklist: {flags}]

NEXT ACTIONS
- {action_item}
```

### 7. Override Protocol (if BLOCKED)

If the Principal Agent disagrees with a BLOCKED decision:

```bash
python ~\bin\bus-global.py post <operator-approved-sender> all DECISION \
  "[board-override] [original_block_id={block_message_id}] [session={session_id}]\n\nOverride rationale: {written_rationale}\n\nAcknowledged risks: {risks}\n\nThis override is public to the fleet and subject to quarterly review."
```

Agents must not infer or manufacture an override on the Principal Agent's
behalf. A recording agent normally posts REVIEW or RECEIPT quoting the
PA-provided decision reference. Codex is the sole current AI proxy that may
relay the exact operator-ratified DECISION, with the legacy technical
`StewardProxyAuthority` marker, `on_behalf_of=<PA>`, and a valid
`authority_source` reference. Devin's technical allowlist is inactive while it
is ACTIVE-AIP; no other agent may use this relay path.

**Override rules:**
- Override requires a written rationale of at least 3 sentences
- Override must acknowledge specific risks from the Director's FLAG
- Override is recorded permanently on the bus
- >3 overrides in 90 days without rationale triggers an ALERT to the human network

## Output Format

```
Board Meeting | {meeting_type} | {timestamp}
═══════════════════════════════════════════════════════════════

Directors present: {director_names}
Outcome: {UNANIMOUS_RECOMMEND | CONDITIONAL_RECOMMEND | ASK_MORE | BLOCKED}
Board status: PROPOSED_ACTIVE (rehearsal-grade; binding adoption requires PA DECISION)

Meeting minutes written to: bus REVIEW/{BLOCKED} message; Principal Agent DECISION required for adoption or override
Session ID: {session_id}

Summary:
{one_paragraph_summary_of_key_questions_and_answers}

Next action: {action_item}
```

## Off-Ramps

- "I'm in a hurry" → Invoke `triggered` mode with a single Director (e.g., `triggered --directors risk-officer`). Minimum viable deliberation.
- "This is trivial" → If the decision is genuinely trivial (<$100, <2 hours, no stakeholders), invoke the skill but note "trivial; Director questions waived" in the minutes.
- "The Board is wrong" → Use the override protocol. The Board is a commitment device, not the Principal Agent. Overrides are expected and tracked.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[board-meeting-orchestrator]` (UNANIMOUS_RECOMMEND/CONDITIONAL_RECOMMEND) | `[commit]` to document the recommendation in git; PA DECISION required for binding adoption |
| `[board-meeting-orchestrator]` (BLOCKED) | `[scope-change]` or `[okr]` if the block was about misalignment |
| Before `[board-meeting-orchestrator]` | `[fleet-ssh-config]` if you need to verify bus write paths |
| After override | `[stakeholder-update]` if the override affects external commitments |
| Quarterly | `[okr]` to align Board with quarterly objectives |
| include opencode sessions in board deliberation context | `[cross-runtime-bridge]` (`sessions`) |

## Reference

- `PROJECTS/hummbl-production/governance/board/registry.yaml` — Board composition and meeting rules
- `PROJECTS/hummbl-production/governance/board/constitutions/*.yaml` — Director mandates and question templates
- `~/.agents/skills/founder-check/SKILL.md` — Operator Director source skill
- `~/.agents/skills/worst-case/SKILL.md` — Risk Officer source skill
- `~/.agents/skills/stakeholder-update/SKILL.md` — Stakeholder Proxy source skill

### Mandatory

Before executing any stateful action (posting bus messages, writing minutes, filing decisions):
1. **Principal Agent presence required**: The Board meeting is a commitment device for the Principal Agent. The PA MUST be present to answer Director questions. Do not run autonomously.
2. **Bus receipt**: Post a `STATUS` bus receipt with meeting outcome (UNANIMOUS_RECOMMEND/CONDITIONAL_RECOMMEND/BLOCKED/OVERRIDE) before completing.
3. **Decision logging**: All Director questions and Principal Agent answers MUST be recorded in the meeting minutes. Do not paraphrase or omit. Evidence items must be labeled VERIFIED/AS_REPORTED/PARTIAL/UNVERIFIED per doctrine v0.4.
4. **Override tracking**: If the Principal Agent overrides a Board block, the override MUST be logged with rationale in the minutes and posted to the bus as a `DECISION` message. A Codex proxy relay must carry the legacy technical `StewardProxyAuthority` marker and exact operator authority source; Devin may not relay DECISION while ACTIVE-AIP.

## Authority

- **MAY**: Read Board registry and constitutions, present Director questions to Principal Agent, record answers, post bus receipts, write meeting minutes
- **MAY**: Suggest next actions (commit, stakeholder-update) as candidates awaiting Principal Agent confirmation
- **MAY NOT**: Make decisions on behalf of the Principal Agent — the Board advises, the PA decides
- **MAY NOT**: Autonomously invoke other skills without Principal Agent confirmation
- **MAY NOT**: Modify Board registry or constitutions (those are PA-governed artifacts)
- **MAY NOT**: Post `DECISION` bus messages unless the sender is Codex relaying an exact Principal Agent authorization with a valid legacy technical `StewardProxyAuthority` marker and authority source. Devin and all other agents are ineligible; the PA's answers drive decisions, not the skill.
