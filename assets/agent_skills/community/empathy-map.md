---
name: empathy-map
description: >
  Map the emotional, cognitive, and experiential landscape of the humans the
  agent serves — what they think, feel, see, say, do, and what pains and gains
  they experience. Bridges the inward-facing cognitive science layer (HRSI,
  BKI, Fitness Profile) with the outward-facing UX layer (user-journey,
  cognitive-load, ethnography). Invoke when an agent says "empathy map", "what
  do they feel", "what do they think", "user experience map", "pains and
  gains", "empathy-mapping", or before designing for human experience.
version: 0.1.0
execution-mode: advisory
argument-hint: "<person, team, or user segment> [optional: --observe | --assess | --synthesize | --track]"
category: cognitive
status: candidate
---

# Empathy-Map

Map the emotional, cognitive, and experiential landscape of the humans the
agent serves. This is the deepest layer of other-discovery: not just who the
humans are or what they need, but what they EXPERIENCE.

## Why Empathy-Mapping Matters

Agents that don't understand human experience make avoidable mistakes:

- An agent designs a workflow that ignores cognitive load on the human
- An agent communicates in a register that triggers RSD in a neurodivergent user
- An agent optimizes for efficiency when the human needs belonging
- An agent ships a feature that's technically correct but emotionally wrong
- An agent doesn't recognize that a user is in shutdown or burnout
- An agent treats cognitive difficulty as a personal failing rather than an
  environment problem

Empathy-mapping is not sentiment analysis — it is experiential calibration.
Understand the experience before you design for it.

## The Two Traditions

The HUMMBL skill catalog has two parallel empathy-mapping traditions that this
skill bridges:

1. **Inward-facing (cognitive science)**: HRSI → BKI → Fitness Profile →
   cogstate → HULE → dream. Deep, theoretically grounded, but self-administered
   only (the operator maps their own experience).

2. **Outward-facing (product/UX)**: user-journey → cognitive-load → ux-audit →
   usability-test → inclusive-design. Practical, other-oriented, but lacks the
   belonging/cognitive-science depth.

This skill composes both traditions into a unified empathy-mapping procedure
that can be applied to any human — operator, team member, client, or user.

## The Discovery Procedure

Follow these 6 phases in order. Each phase has probe commands and reflection
questions.

### Phase 1: Frame (Who is the human?)

**What to discover:** The identities, roles, and contexts of the human being
mapped.

**Probe commands:**

```
[identity-map] "<human's role or context>"
[icp-profile] "<segment>"  (if external user)
[cultural-adapt]  (if cross-cultural context)
```

**Reflection questions:**
- Who is this human? What identities do they carry?
- What context are they in? (work, home, crisis, recovery)
- What cultural lens shapes their experience?
- What role are they playing in this interaction?

**Record:** `frame: { identities: [...], contexts: [...], cultural_lens: ..., role: ... }`

### Phase 2: Assess (What do they experience?)

**What to discover:** The human's cognitive state, belonging baseline, energy,
and cognitive load.

**Probe commands:**

For the operator (self-administered data):
```
[fitness-assessment] "individual"  (if operator)
[hrsi-checkin]  (latest, if operator)
[energy-map]  (energy patterns)
```

For others (observational/inferred):
```
[cognitive-load] "<task or workflow>"  (NASA-TLX, Hick's law)
[energy-map]  (if data available)
```

**Reflection questions:**
- What is their cogstate? (AVAILABLE, DEPLETED, HYPERFOCUS, RECOVERY, RSD_RISK,
  SHUTDOWN, TRANSITION)
- What is their belonging baseline? (safety, mattering, connection — 1-5)
- What is their cognitive load? (mental demand, effort, frustration)
- What is their energy pattern? (peak hours, crash times)
- Which Fitness Profile modes are accessible? Which are suppressed?
- Are there threat-state indicators?

**Record:** `assessment: { cogstate: ..., belonging: { safety, mattering, connection }, cognitive_load: { mental_demand, effort, frustration }, energy_pattern: ..., bos_modes: { dominant: [...], suppressed: [...] }, threat_state: true|false }`

### Phase 3: Observe (What do they do and say?)

**What to discover:** The human's observable behavior and language.

**Probe commands:**

```
[ethnography-plan] "<field site or context>"  (for structured observation)
[usability-test] "<task>"  (for product interaction observation)
[discovery-call] "<person>"  (for interview-based discovery)
[bki-reframe]  (if operator — observe language patterns for belonging signals)
```

**Reflection questions:**
- What do they DO? (observable actions, workflows, task sequences)
- What do they SAY? (verbatim quotes, language patterns, word choices)
- What do they SEE? (their environment, tools, interfaces, information)
- What language signals indicate belonging shifts? ("have to" vs "get to")
- Where do they struggle? Where do they succeed?
- What do they avoid? (tasks, topics, people, situations)

**Record:** `observation: { do: [...], say: [...], see: [...], language_signals: [...], struggles: [...], successes: [...], avoidances: [...] }`

### Phase 4: Synthesize (What do they think and feel?)

**What to discover:** The human's internal experience — thoughts, feelings,
pains, and gains.

**Probe commands:**

```
[grounded-theory]  (code observational data into categories)
[thematic-analysis]  (identify experiential themes)
[user-journey] "<persona>" --stage all  (map DO/THINK/FEEL per stage)
[reframe]  (BKI Frame — surface belonging/trust gaps underneath patterns)
```

**Reflection questions:**
- What do they THINK? (beliefs, assumptions, mental models, expectations)
- What do they FEEL? (emotions, anxieties, hopes, frustrations)
- What are their PAINS? (obstacles, fears, frustrations, risks)
- What are their GAINS? (successes, hopes, what they want to achieve)
- What belonging/trust gaps underlie observed patterns?
- What experiential themes recur across observations?

**Record:** `synthesis: { think: [...], feel: [...], pains: [...], gains: [...], belonging_gaps: [...], themes: [...] }`

### Phase 5: Belonging Conditions Needed

**What to discover:** What belonging conditions does this human need, and are
they present?

**Reflection questions:**
- Which BKI dimensions are eroding? (Safety, Mattering, Connection)
- Which Fitness Profile modes are suppressed due to low belonging?
- What environmental/cognitive barriers exist? (inclusive-design audit)
- What neurodivergent-specific needs exist? (if applicable — masking
  conditions, sensory environment, RSD triggers, hyperfocus support)
- What belonging conditions would unlock suppressed modes?

**Probe commands (if applicable):**

```
[inclusive-design]  (environmental/cognitive barriers)
[professor]  (if neurodivergent — AuDHD-aware calibration model)
```

**Record:** `belonging_needs: { eroding_dimensions: [...], suppressed_modes: [...], barriers: [...], neurodivergent_needs: [...], conditions_needed: [...] }`

### Phase 6: Persist and Track

**What to discover:** How to persist empathy-map findings and track changes
over time.

**Probe commands:**

```
[insight-capture]  (store findings in cognitive ledger)
[reasoning-trace-hummbl]  (structure as typed reasoning steps)
[bki-session-export]  (package for knowledge transfer)
```

**Reflection questions:**
- What are the key insights to persist?
- How should this empathy map be tracked over time?
- What evidence supports the empathy-map claims?
- What should be validated through further research?

**Record:** `persistence: { key_insights: [...], tracking_plan: ..., evidence: [...], validation_needs: [...] }`

## Producing the Empathy Map

### Empathy Map Canvas (human-readable)

```markdown
# Empathy Map — <person or segment>

## WHO
- Identities: [list]
- Context: [description]
- Role: [role]

## WHAT THEY DO
- [observable actions]

## WHAT THEY SAY
- "[verbatim quotes]"

## WHAT THEY SEE
- [environment, tools, interfaces]

## WHAT THEY THINK
- [beliefs, assumptions, mental models]

## WHAT THEY FEEL
- [emotions, anxieties, hopes]

## PAINS
- [obstacles, fears, frustrations]

## GAINS
- [successes, hopes, achievements]

## COGNITIVE STATE
- Cogstate: [state]
- Cognitive load: [level]
- Energy: [pattern]
- Fitness modes: [dominant/suppressed]

## BELONGING CONDITIONS
- Safety: [score/5]
- Mattering: [score/5]
- Connection: [score/5]
- Eroding dimensions: [list]
- Conditions needed: [list]

## NEURODIVERGENT CONSIDERATIONS (if applicable)
- Masking conditions: [description]
- Sensory environment needs: [list]
- RSD triggers: [list]
- Hyperfocus support needs: [list]

## BELONGING GAPS
- [gaps identified]

## EXPERIENTIAL THEMES
- [recurring themes]

## WHAT THIS AGENT SHOULD KNOW
- [3-5 actionable insights for designing for this human's experience]
```

### Empathy Map (bus summary)

```
EMPATHY_MAP: human=<person> cogstate=[state] belonging=[S:X,M:X,C:X] pains=[N] gains=[N] themes=[N] belonging_gaps=[list] neurodivergent=[yes|no] intel_type=TOPOINT
```

### Empathy Map (ledger persistence)

```
[ledger] post --type empathy-map --tags empathy,discovery,bki,fitness --content "<map JSON>"
```

## When to Re-Run Empathy-Mapping

- **Before designing for human experience**: Products, workflows, communications
- **After cogstate shift**: If the human's cognitive state changes
- **Quarterly**: Track empathy-map evolution over time
- **After belonging change**: Safety/mattering/connection scores shift
- **After neurodivergent pattern change**: New RSD triggers, hyperfocus
  patterns, masking needs
- **When asked**: "What do they feel?" / "What do they experience?"

## Argument Modes

- `[empathy-map] "<person>"` — Full 6-phase procedure (default)
- `[empathy-map] "<person>" --observe` — Phase 3 only (behavioral observation)
- `[empathy-map] "<person>" --assess` — Phase 2 only (cognitive/belonging
  assessment)
- `[empathy-map] "<person>" --synthesize` — Phase 4 only (think/feel/pains/gains
  synthesis, requires existing observation data)
- `[empathy-map] "<person>" --track` — Phase 6 only (longitudinal tracking,
  requires existing empathy map)

## Composition Chain

- `[self-discovery]` → `[operator-discovery]` → `[empathy-map]` — Full
  calibration with empathy as the deepest layer
- `[user-discovery]` → `[empathy-map]` — User profile feeds empathy mapping
- `[stakeholder-discovery]` → `[empathy-map]` — Stakeholder analysis identifies
  who to map
- `[empathy-map]` → `[inclusive-design]` — Empathy map informs accessible
  design
- `[empathy-map]` → `[content-design]` — Empathy map shapes user-facing
  language
- `[empathy-map]` → `[fitness-assessment]` — Empathy map can trigger
  Fitness assessment for teams

## Anti-Patterns

- **Don't confuse empathy with sympathy**: Empathy is understanding the
  experience, not feeling sorry. Map what IS, not what you wish were true.
- **Don't fabricate feelings**: If you don't have observational data, say
  "unknown." Don't invent what someone thinks or feels.
- **Don't pathologize**: Neurodivergent patterns are cognitive differences, not
  deficits. Frame as "how this person's cognition works" not "what's wrong."
- **Don't skip belonging conditions**: The BKI layer is what makes this
  empathy-mapping, not just UX research. Belonging conditions determine which
  cognitive modes are accessible.
- **Don't make it static**: Human experience changes. Track longitudinally.
- **Don't apply inward-only instruments outward without adaptation**: HRSI and
  dream are self-administered. Don't run them for others — adapt the framework,
  not the instrument.

## Known Limitations

- The deepest empathy-mapping instruments (hrsi-checkin, dream, hyperfocus-exit
  body scan) are designed for self-administration. Applying them to others
  requires adaptation, not direct use.
- `[fitness-assessment]` is the one exception — it's designed for team/org
  assessment. But it's a CONCEPT INSTRUMENT (not yet psychometrically
  validated).
- No standalone empathy-map visualization skill exists. The canvas is
  text-based.
- No "what they SAY" capture mechanism exists for non-operator humans.
  Language signal capture is limited to `[bki-reframe]` (operator only).
- No neurodivergent-specific empathy-mapping protocol exists as a standalone.
  Neurodivergent considerations are integrated into Phase 5 but not
  separately structured.
- No longitudinal empathy-map tracking skill exists. Phase 6 proposes a
  tracking plan but doesn't automate it.

## After This Skill Runs

- `[inclusive-design]` — Use empathy map to design accessible experiences
- `[content-design]` — Use empathy map to shape user-facing language
- `[user-journey]` — Deepen journey map with empathy data
- `[fitness-assessment]` — If belonging gaps suggest team-level
  intervention
- `[bki-evidence-flywheel]` — Validate empathy-mapping claims against
  literature
