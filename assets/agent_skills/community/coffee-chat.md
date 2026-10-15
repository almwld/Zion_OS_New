---
name: coffee-chat
description: Informal networking call prep. Who is this person, what to learn (not pitch), 3 questions, 30-sec HUMMBL context only if asked. Post-call routes to /deal-memo.
version: 1.0.0
execution-mode: side_effecting
argument-hint: <person name or context>
category: fleet-ops
status: candidate
---
# [coffee-chat]

> The goal of a coffee chat is not to pitch. It's to learn enough to know whether pitching is worth it — and to be remembered as someone worth talking to again.

Different from `[meeting-prep]` (formal agenda, prep for structured meeting) and `[discovery-call]` (sales-intent, structured). This is the 20-min informal call — networking, warm intro, or early-stage relationship building.

## When to Use
- Any informal 1:1 call (virtual coffee, warm intro, LinkedIn connection meeting)
- ATL ecosystem networking
- Pre-sales relationship building before the discovery call stage
- Conference hallway conversations (quick prep before an intro)

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=coffee-chat] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load person context

```bash
# Check people memory (resolve runtime memory dir)
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
ls ${RUNTIME_MEM:+$RUNTIME_MEM/people_*.md} 2>/dev/null | \
  xargs grep -l "<person name>" -i 2>/dev/null | head -3

# If found, read it
cat "$RUNTIME_MEM/people_<name>.md" 2>/dev/null
```

If no memory file: do a quick web/LinkedIn scan for context.

### 2. Build the prep brief

**Their world** (what you need to know before the call):
- Role, company, tenure
- Recent public activity (posts, articles, talks, company news)
- Any mutual connections or context for why you're talking
- Known pain points or priorities for their role

**What I want to LEARN** (not pitch):
The goal is information, not conversion. 3 specific things to learn:
1. What does [their industry / role] care about most right now?
2. What's not working that they haven't solved?
3. Who else in their network should I know?

**3 questions to ask:**
Questions should be genuinely curious, not setup pitches. Bad: "Are you dealing with AI governance challenges?" Good: "What's the most surprising thing about your role right now?"

**The 30-second HUMMBL context (only if asked "what do you do"):**
> "I'm building HUMMBL — it's AI governance infrastructure for enterprises. We make it possible for companies to deploy AI with accountability — so legal, risk, and IT can all see what AI is doing and why. Early stage, working with a handful of companies in Atlanta right now."

Keep it short. Don't pitch. If they ask follow-up questions, that's the signal to go deeper.

**Exit with:**
- A reason to follow up (share an article, make an intro, send a resource)
- Not a pitch. Never end a coffee chat with "so can I schedule a demo?"

## Output Format

```
Coffee Chat Prep | <person name> | <date/time>
══════════════════════════════════════════════

## Who They Are
- Role: <title, company>
- Context: <how you know them / why you're talking>
- Recent: <any notable recent activity>

## What I Want to Learn
1. <question area>
2. <question area>
3. <question area>

## 3 Questions to Ask
1. "<specific, curious question>"
2. "<specific, curious question>"
3. "<specific, curious question>"

## If They Ask "What Do You Do"
> [30-second HUMMBL context — see above]

## Exit Strategy
Follow-up hook: <specific thing to send/do after — article, intro, resource>
Never: pitch a demo at the end

## Post-Call
Run [deal-memo] to capture signal while it's fresh
```

## Chain
- Before call → this skill
- After call → `[deal-memo]` to capture signal
- If they're a real prospect → `[discovery-call]` for next interaction
- If they made an intro → `[coffee-chat] [new person]`
- Update their `people_*.md` file same session

## Skill Chains

### Mandatory

None — this skill generates a prep document only; no upstream chain is required before producing the output.

### Advisory

- After call → `[deal-memo]` to capture signal while it's fresh
- If they're a real prospect → `[discovery-call]` for next interaction
- If they made an intro → `[coffee-chat]` with the new person
- Update their `people_*.md` file same session

## Authority

- **T1 (TRUSTED)**: Full access — generate prep docs, update people memory
- **T2 (Active/High)**: Full access — generate prep docs, update people memory
- **T3 (Medium)**: Full access — generate prep docs, update people memory
- **T4 (Probationary)**: May run — file generation only (prep doc output)
- **Operator**: Override any restriction
