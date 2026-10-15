---
name: async-update
description: Quick 3-sentence async update for any stakeholder. Where things stand, what's next, what they need to know. Signal-ready, email-ready, Slack-ready. Not a formal stakeholder-update.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<person> [topic]  — e.g., \"dan product\" or \"investor wave1\""
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# [async-update]

> Don't let stakeholders wonder. A 3-sentence update once a week is worth more than a 3-page report once a month.

Different from `[stakeholder-update]` (formal monthly update with metrics, formatted document) — this is the **quick async ping**. Three sentences, right format for the channel, sent in 2 minutes.

## When to Use
- "I should probably let Dan know where things stand"
- Investor asks "how's it going?" and you want to respond thoughtfully
- After a week of heads-down work with no external comms
- Pre-meeting quick-set (so they're oriented before the call)
- When something changes that a stakeholder needs to know about

## The 3-Sentence Formula

**Sentence 1 — Where things stand:**
State of play. One fact. No hedging.
> "Wave 1 emails are drafted and deliverability is confirmed — sending Wednesday morning."

**Sentence 2 — What's next:**
The next concrete action or milestone.
> "After send, I'll track responses and be ready for discovery calls by end of week."

**Sentence 3 — What they need to know / any ask:**
Anything that affects them, or a low-friction ask.
> "If you're going to Diligent Elevate Apr 22-24, there's a warm lead worth a quick intro to."

## Format Options

**Signal-ready** (plain text, no markdown, < 160 chars per sentence):
Just the 3 sentences, line breaks only.

**Email-ready** (subject + body):
Subject: `[Quick update] <topic>`
Body: 3 sentences + signature block.

**Slack-ready** (brief with context):
3 sentences with minimal formatting. Add a link if relevant.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=async-update] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load person context
```bash
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
cat "$RUNTIME_MEM/people_<name>.md" 2>/dev/null | \
  grep -E "status|update|last|open|pending" -i | head -10
```

### 2. Check recent activity
```bash
# Recent bus activity related to topic
grep -i "<topic>" ~/.cache/bus/messages.tsv 2>/dev/null | \
  tail -5 | awk -F'\t' '{printf "[%s] %.80s\n", substr($1,12,5), $5}'
```

### 3. Draft the 3 sentences
Keep it honest. If things are behind, say so simply — "We're a week behind on X; here's why and what I'm doing about it." Stakeholders forgive delays more than they forgive surprises.

## Person-Specific Defaults

| Person | Channel | Typical topic | Tone |
|--------|---------|--------------|------|
| Dan Matha | Signal | Product direction, ATL strategy, onboarding timeline | Collegial, direct |
| Investors | Email | Traction, pipeline, milestones | Confident, factual |
| Travis Morrison | Email | Alpha testing, product updates | Founder-to-early-user |
| Jenna | None / in person | N/A — not a work stakeholder | |

## Output Format

```
Async Update | <person> | <topic> | <channel>
═══════════════════════════════════════════════

## Draft (3 sentences)
[1. Where things stand]
[2. What's next]
[3. What they need to know / ask]

---
Channel: <Signal / Email / Slack>
Ready to send: [send-email] <person> | [send-signal] <person>
```

## Chain
- After drafting → `[send-signal] dan` or `[send-email] <person>`
- If it turns into a longer update → `[stakeholder-update]`
- After sending → note in `people_<name>.md` last-contact date
- Weekly: async-update Dan + any investor who's been quiet > 2 weeks

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before sending externally — async updates are stakeholder-facing communications.

### Advisory

- After drafting → `[send-signal]` or `[send-email]` to deliver
- If it turns into a longer update → `[stakeholder-update]`
- After sending → note in `people_<name>.md` last-contact date

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator approval + `[content-review]` before sending
- **T4 (Probationary)**: May draft but may not send
- **Operator**: Override any restriction
