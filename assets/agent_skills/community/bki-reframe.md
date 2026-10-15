---
name: bki-reframe
description: Capture and classify somatic-linguistic belonging reframes ("have to" vs "get to"). Names the BKI dimension, Fitness mode, and persists as HULE data. Real-time micro-intervention between /hrsi-checkin and /dream.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "\"<the reframe observation, e.g. I said get to instead of have to about coaching>\""
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# [bki-reframe]

> The reframe happens in the body before the mind names it. This skill catches it.

Captures the moment when language reveals a belonging shift — "have to" becomes "get to,"
"they won't listen" becomes "I haven't found the right frame yet." These micro-reframes
are BKI Proposition 3 (embodied knowing) in action: the somatic system shifts first,
language follows, cognition integrates last.

Different from `[reframe]` (generates 5 cognitive reframes for a problem statement).
`[bki-reframe]` captures a reframe that **already happened** in the human and classifies
it as belonging data.

## When to Use
- You notice yourself using different language about the same activity
- "Have to" → "get to" (or the reverse — belonging erosion is data too)
- A task that felt heavy suddenly feels light (or vice versa)
- You catch yourself volunteering for something you used to avoid
- After `[hrsi-checkin]` when scores don't match the felt sense
- During `[dream]` when a pattern surfaces about approach vs avoidance

## Belonging Dimensions

| Dimension | Signal | "Have to" tells you | "Get to" tells you |
|-----------|--------|--------------------|--------------------|
| **Safety** | Threat vs calm | Environment feels unsafe; fawn/flee active | Enough trust to be wrong |
| **Mattering** | Invisible vs seen | Work feels pointless; no one notices | Contribution is valued and visible |
| **Connection** | Isolated vs held | Doing it alone; no relational anchor | Part of something; others care |

## Fitness Mode Detection

The reframe reveals which Fitness Profile mode is active:

| Mode | Reframe signature |
|------|-------------------|
| **Sensory** | "I noticed..." / "It felt different when..." |
| **Emotive** | "I was surprised by how much I wanted to..." |
| **Cognitive** | "I realized that..." / "The frame shifted when..." |
| **Somatic** | "My body just..." / "I didn't decide to, I just did..." |
| **Relational** | "When they said X, I felt..." / "Being around them makes me..." |
| **Temporal** | "Last time I dreaded this, now..." / "This used to be..." |

## Execution

### If user provides the reframe inline (e.g. "I said 'get to' about coaching"):

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=bki-reframe] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Name it** — state the before/after language and the activity
2. **Classify the belonging dimension** — safety, mattering, or connection (can be multiple)
3. **Identify Fitness mode** — which mode caught the reframe first?
4. **Direction** — belonging accrual (+) or erosion (-)
5. **Contrast** — is there a domain where the opposite pattern holds? (e.g., coaching = "get to" but selling = "have to")
6. **Persist** — log to ledger as discovery + tag `bki-reframe,hule`
7. **Bus post** — STATUS with reframe summary
8. **Pattern check** — query prior bki-reframe entries for recurring domains

### If user just says `[bki-reframe]` with no args:

1. Query recent reframe entries:
   ```bash
   source $HOME/.venv/bin/activate && \
     python3 -m hummbl_governance.cognition query --tags bki-reframe --limit 7
   ```
2. Show pattern summary (which domains accrue belonging, which erode)
3. Prompt the operator for today's observation

## Ledger Post

```bash
source $HOME/.venv/bin/activate && \
  python3 -m hummbl_governance.cognition post \
    --agent reuben --vendor human --model human \
    --type discovery --scope process \
    --content "<reframe content>" \
    --tags bki-reframe hule hrsi <dimension> <direction>
```

## Bus Post

Post STATUS to the bus with the reframe result.
```
Type: STATUS
To: all
Message: BKI reframe: <activity> shifted <have-to|get-to> → <get-to|have-to>. Dimension: <safety|mattering|connection>. Fitness: <mode>. Direction: <accrual|erosion>.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Output Format

```
BKI Reframe | YYYY-MM-DD
═════════════════════════

Activity:     <what was reframed>
Before:       "<old language>"
After:        "<new language>"
Direction:    + accrual | - erosion

Dimension:    Safety / Mattering / Connection
Fitness Mode:     <which mode caught it first>
Broccolilly:  S=_ T=_ I=_ C=_ D=_ → R=_

Contrast:     <domain where opposite pattern holds, if any>

Pattern (last 7):
  + coaching (3x) — mattering, connection
  + HUMMBL build (2x) — safety, mattering
  - GTM outreach (2x) — safety, connection
  - cold email (1x) — mattering

Ledger:       clp-<id>
Next:         [dream] (if erosion pattern found) | [hrsi-checkin] (update scores)
```

## Broccolilly Scoring (optional, if user wants depth)

For the reframed activity, score each factor:

- **S (Sovereignty)**: Did you choose this freely? (1-5)
- **T (Trust)**: Do you trust the environment/people? (1-5)
- **I (Integration)**: Are mind and body aligned on this? (1-5)
- **C (Clarity)**: Is the purpose clear? (1-5)
- **D (Depth)**: Are you engaging fully or surface-level? (1-5)
- **R (Result)**: S x T x I x C x D

A "get to" reframe typically shows S and T elevated. A "have to" shows S or T suppressed.

## Chain
- After `[bki-reframe]` with erosion → `[dream]` (process the threat signal)
- After `[bki-reframe]` with accrual → `[hrsi-checkin]` (update belonging scores)
- After `[bki-reframe]` with contrast → `[reframe]` (apply cognitive reframe to the eroding domain)
- Pattern shows persistent erosion in one domain → `[fitness-assessment]`
- Reframe changes GTM approach → `[discovery-call]` or `[pitch]`

## Skill Chains

### Mandatory

None — data capture; appends to the cognition ledger which is low-risk and append-only.

### Advisory

- After `[bki-reframe]` with erosion → `[dream]` (process the threat signal)
- After `[bki-reframe]` with accrual → `[hrsi-checkin]` (update belonging scores)
- After `[bki-reframe]` with contrast → `[reframe]` (apply cognitive reframe to the eroding domain)
- Pattern shows persistent erosion in one domain → `[fitness-assessment]`

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (ledger append is low-risk and append-only)
- **Operator**: Override any restriction
