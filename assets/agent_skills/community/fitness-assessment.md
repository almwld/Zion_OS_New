---
name: fitness-assessment
description: Administer and score the HUMMBL Fitness Assessment — an 18-question diagnostic instrument that identifies which of the 6 Fitness Profile modes a team or individual is operating from, maps results to belonging conditions, and generates a prioritized intervention report.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"SCOPE\" [--format pdf|text|json]"
migration_end_date: 2026-09-30
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# Fitness Assessment

Administer the 18-question HUMMBL Fitness Profile diagnostic. Identifies dominant mode, secondary mode, belonging condition diagnosis, and top 3 governance interventions.

**INTERNAL NOTE**: The Fitness Profile connects to BKI theory — belonging conditions determine which modes are accessible. Low-belonging → threat-state → Emotive/Somatic overdominance → Cognitive suppressed → governance adoption fails. This is the BKI→HUMMBL mechanism in practice.

## When to Use
- Beginning of a HUMMBL discovery engagement (baseline mode profile)
- Pre/post intervention measurement
- Team belonging audit
- Board or executive presentation showing concrete measurement methodology

## Usage

```
[fitness-assessment] "SCOPE"
[fitness-assessment] "individual"
[fitness-assessment] "team" --format json
[fitness-assessment] "organization"
```

**SCOPE:** `individual` | `team` (3-25 people) | `organization` (enterprise-wide)

---

## The Assessment Instrument

### Administration Protocol

Present each question to the respondent. For team assessments, average scores across all respondents before profiling.

**Response scale**: 1 (Almost never) | 2 (Rarely) | 3 (Sometimes) | 4 (Often) | 5 (Almost always)

---

### Section 1 — Sensory Mode (Perceptual Awareness)
*Ability to receive and process signals from the environment before interpreting them.*

**S1**: When our AI systems produce unexpected outputs, team members notice and flag them quickly — before they cause downstream problems.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**S2**: Team members pay attention to weak signals (small anomalies, edge cases, user feedback patterns) rather than only responding to major incidents.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**S3**: When something "feels off" about an AI output or process, people trust that perception enough to raise it — even before they can articulate why.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 1 score: __ / 15*

---

### Section 2 — Emotive Mode (Emotional Processing)
*Ability to acknowledge, process, and communicate emotional responses — especially fear, uncertainty, and concern.*

**E1**: When team members are worried about an AI system's behavior or a governance decision, they feel safe saying so openly.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**E2**: Frustration, fear, or discomfort with AI-related risks is expressed directly in meetings rather than communicated indirectly (passive resistance, workarounds, silence).
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**E3**: After AI incidents or near-misses, there is space to process what happened emotionally — not just technically. People aren't expected to move on immediately.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 2 score: __ / 15*

---

### Section 3 — Cognitive Mode (Reasoning and Problem-Solving)
*Access to complex, abstract thinking — pattern recognition, scenario planning, novel problem-solving.*

**C1**: When facing a new AI governance challenge, the team generates multiple approaches rather than defaulting to the most familiar compliance procedure.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**C2**: Team members can hold complexity and uncertainty without rushing to premature resolution. We sit with "we don't know yet" when that's the honest answer.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**C3**: People question whether our current AI governance framework is actually working — not just whether we're compliant with it.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 3 score: __ / 15*

---

### Section 4 — Somatic Mode (Embodied Awareness)
*Physical and energetic signals — burnout detection, capacity awareness, sustainable pace.*

**So1**: Team members recognize and communicate their physical/cognitive capacity limits before they reach burnout — not after.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**So2**: The team has sustainable working rhythms around AI governance work — it isn't all crammed into compliance deadlines.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**So3**: When someone is overwhelmed, that information enters the team's planning openly. There's no expectation to hide capacity limits.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 4 score: __ / 15*

---

### Section 5 — Relational Mode (Social Co-regulation)
*Ability to coordinate, build trust, and co-regulate across the social network of the team.*

**R1**: Team members proactively share AI governance concerns with colleagues in other functions (legal, engineering, business) rather than siloing within their own domain.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**R2**: When there's a disagreement about AI risk levels or governance priorities, the team works through it productively — it doesn't get buried or escalated prematurely.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**R3**: New team members and external reviewers are genuinely heard on AI governance questions — not just tolerated.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 5 score: __ / 15*

---

### Section 6 — Temporal Mode (Strategic Continuity)
*Ability to maintain identity and purpose across time — connecting past learning to future planning.*

**T1**: The team knows why past AI governance decisions were made — institutional memory exists and is accessible.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**T2**: Lessons from AI incidents and near-misses are captured and incorporated into future governance practice — not just documented and filed.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

**T3**: The team connects their daily AI governance work to a longer-term narrative — we know where we're going and why it matters.
- 1: Almost never | 2: Rarely | 3: Sometimes | 4: Often | 5: Almost always

*Section 6 score: __ / 15*

---

## Scoring and Profile

### Mode Score Calculation
| Mode | Questions | Raw Score ([15]) | Normalized (%) |
|------|-----------|-----------------|----------------|
| Sensory | S1, S2, S3 | __ | __% |
| Emotive | E1, E2, E3 | __ | __% |
| Cognitive | C1, C2, C3 | __ | __% |
| Somatic | So1, So2, So3 | __ | __% |
| Relational | R1, R2, R3 | __ | __% |
| Temporal | T1, T2, T3 | __ | __% |

**Total score**: __ / 90

### Mode Dominance Interpretation

**Dominant mode** (highest score): Where the team's energy and attention is currently concentrated.
**Suppressed mode** (lowest score): Where capacity has collapsed — often the site of the belonging gap.

#### Score Ranges by Mode
- **12–15 (80–100%)**: Mode is accessible and active. Leverage this.
- **9–11 (60–73%)**: Mode is partially accessible. Inconsistent. Opportunity area.
- **6–8 (40–53%)**: Mode is constrained. Belonging conditions are limiting access.
- **3–5 (20–33%)**: Mode is suppressed. Threat-state indicators present. Intervention needed.

---

## Belonging Gap Diagnosis

Based on the mode profile, identify the primary belonging gap:

### Pattern: Emotive Low + Cognitive Low (≤8 each)
**Diagnosis**: Threat-state operating environment. Amygdala dominance suppressing prefrontal cortex. Classic low-belonging pattern.
**What this looks like**: Compliance theater (doing the forms without the thinking), incident under-reporting, change resistance, "that's not my job" behavior around AI risks.
**BKI connection**: Without belonging infrastructure, teams cannot surface AI harms. This is why governance frameworks fail — they assume the emotional safety for honest reporting already exists.

### Pattern: Relational Low (≤8), Cognitive Moderate (9–11)
**Diagnosis**: Siloed intelligence. People have ideas but aren't sharing them across boundaries. Knowledge is trapped in functional units.
**What this looks like**: Parallel workarounds, "we figured that out separately," AI risks known in engineering but not communicated to legal or compliance.

### Pattern: Temporal Low (≤8), Relational Moderate-High (≥12)
**Diagnosis**: Strong present-moment collaboration, weak institutional memory and strategic narrative. Team cohesion without organizational continuity.
**What this looks like**: Good crisis response, poor lesson integration. The same AI incidents recurring because learning didn't stick. Turnover erases governance context.

### Pattern: Somatic Low (≤8) across board
**Diagnosis**: Burnout-driven governance. Compliance work is being done by exhausted people under deadline pressure. Quality is low because capacity is low.
**What this looks like**: Rushed assessments, rubber-stamp approvals, documentation done to check boxes rather than to think.

### Pattern: Sensory High (≥12), Cognitive Low (≤8)
**Diagnosis**: Noticing without processing. People sense problems but can't think them through. Often fear of consequences suppresses the reasoning step.
**What this looks like**: "Everyone knew something was wrong" post-incident. Sensing happens; speaking and analyzing don't.

---

## Intervention Recommendations by Profile

### For Threat-State Profiles (Emotive + Cognitive Low)
1. **Belonging Infrastructure Audit** — Map the psychological safety conditions in every team that touches AI governance. Use conversation cards before any governance training.
2. **Anonymous Signal Channels** — Create low-friction, low-risk ways to surface AI concerns before they become incidents.
3. **HUMMBL Governance Receipt System** — Shift from "sign off on compliance docs" to "document what you actually reviewed and changed." Substantive HITL replaces rubber-stamp.

### For Siloed Intelligence Profiles (Relational Low)
1. **Cross-Functional Belonging Architecture** — Build belonging connections across functional boundaries before requiring cross-functional governance collaboration.
2. **Joint AI Risk Reviews** — Engineering + Legal + Compliance in the same room, with facilitated belonging protocols before the technical content.
3. **Shared Symbolic Language** — Develop a shared vocabulary for AI risk that crosses functional dialects. HUMMBL's role: translate between technical and governance registers.

### For Amnesia Profiles (Temporal Low)
1. **AI Governance Knowledge Architecture** — Implement an append-only decision log for all AI governance decisions, including the reasoning. Base4-aligned: write as proof.
2. **Incident Learning Protocol** — Structured process for converting AI incidents into institutional knowledge, not just incident reports.
3. **Strategic Narrative Workshops** — Connect daily governance tasks to organizational purpose and multi-year direction.

---

## Output Report Format

When scoring is complete, produce:

```
HUMMBL Fitness Assessment Report
Scope: [individual/team/organization]
Date: [YYYY-MM-DD]
Respondents: [N]

═══════════════════════════════════
MODE PROFILE
═══════════════════════════════════
Sensory:    [score/15] [████████░░] [%]
Emotive:    [score/15] [███░░░░░░░] [%]
Cognitive:  [score/15] [███░░░░░░░] [%]
Somatic:    [score/15] [██████░░░░] [%]
Relational: [score/15] [████████░░] [%]
Temporal:   [score/15] [████░░░░░░] [%]

Dominant mode: [MODE]
Suppressed mode: [MODE]

═══════════════════════════════════
BELONGING GAP DIAGNOSIS
═══════════════════════════════════
Pattern detected: [PATTERN NAME]
[2-3 sentence plain-language diagnosis]

═══════════════════════════════════
TOP 3 INTERVENTIONS
═══════════════════════════════════
1. [Intervention] — [one-line rationale]
2. [Intervention] — [one-line rationale]
3. [Intervention] — [one-line rationale]

═══════════════════════════════════
NEXT STEPS
═══════════════════════════════════
[ ] Share this report with [stakeholder]
[ ] Schedule belonging audit kickoff
[ ] Book discovery call: hummbl.io
```

---

## After This Skill Runs

- `[evidence-pack]` — bundle the assessment report with governance artifacts for client delivery
- `[arcana-to-pitch] "ciso" "one-pager"` — generate HUMMBL positioning doc for the same audience
- `[bki-cite-audit]` — verify the Walton+Cohen and Edmondson citations underlying the mode-belonging connection
- `[governance-maturity]` — pair with governance maturity score for full picture

---

## Validation Status

**Current status**: CONCEPT INSTRUMENT — not validated with external groups.
- Questions designed from BKI theory + Fitness Profile mode definitions
- Scoring rubric is face-valid, not psychometrically validated
- Do not represent as validated in enterprise sales materials until external validation is complete
- Recommended first validation: administer to 3–5 known-belonging-condition teams (at least 1 high-belonging, 1 low-belonging), check if mode profiles predict in expected directions
- See BKI_03 Open Questions — Broccolilly Equation validation path applies here too
