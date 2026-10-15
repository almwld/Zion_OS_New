---
name: ethnography-plan
description: Plan ethnographic research - field site selection, access negotiation, observation protocols, and fieldnote frameworks
version: 0.1.0
execution-mode: advisory
argument-hint: "<field-site> [--duration weeks] [--role participant|observer|complete-observer]"
category: cognitive
status: candidate
---
# ethnography-plan | Ethnographic Research Planning

## When to Use
- Designing ethnographic or observational field studies
- Planning extended immersion in a community, workplace, or setting
- Establishing observation protocols and fieldnote frameworks before entering the field
- Negotiating access and ethical clearance for fieldwork

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: field site description (organization, community, setting)
- `--duration`: planned immersion in weeks (default 12)
- `--role`: participant (full participation), observer (observer-as-participant), complete-observer (no participation)
- Default role: `observer`

### 2. Field Site Selection
- Define site boundaries (physical, social, temporal)
- Assess accessibility, gatekeepers, and feasibility
- Document rationale for site selection
- Identify alternative or comparison sites if needed

### 3. Access Negotiation
- Identify gatekeepers and key informants
- Draft access request (purpose, duration, outputs, benefits to site)
- Plan informed consent procedures (individual and community level)
- Flag ethical review requirements (IRB/ethics committee)

### 4. Observation Protocol
- Define observation focus (behaviors, interactions, artifacts, spatial use)
- Set observation schedule (times, frequency, duration per visit)
- Choose recording methods (notes, audio, video, photos -- check consent)
- Plan for reactive effects (Hawthorne effect, observer influence)

### 5. Fieldnote Framework
- Structure: descriptive notes (thick description) vs. reflective notes (observer's interpretations)
- Template: date, time, location, participants, setting, events, impressions
- Plan jottings-to-fieldnotes workflow (rapid jottings in field, expanded notes within 24h)
- Establish coding and retrieval system for fieldnotes

### 6. Role and Reflexivity Plan
- Document researcher's positionality relative to site
- Plan for managing role conflict and boundary issues
- Schedule reflexive memo writing (weekly minimum)

### 7. Risk and Contingency Planning
- Identify risks (access withdrawal, ethical dilemmas, safety, burnout)
- Define exit strategy and debriefing plan
- Plan data security and anonymization procedures

## Output Format

```
ethnography-plan | <field-site>

## Configuration
- Duration: 12 weeks | Role: Observer-as-participant
- Observation focus: interactions, artifacts, spatial use

## Site Profile
- Site: <name> | Boundaries: <description>
- Gatekeepers: <names/roles> | Access status: PENDING

## Observation Protocol
- Schedule: 3 visits/week, 4 hours/visit
- Recording: fieldnotes + audio (consent-dependent)
- Reactive effects: plan 2-week acclimation period

## Fieldnote Framework
- Descriptive: thick description of events, setting, actors
- Reflective: observer interpretations, hunches, emotional responses
- Workflow: jottings in field -> expanded notes within 24h -> coded weekly

## Ethical Considerations
- Consent: individual + community | IRB: REQUIRED
- Anonymization: pseudonyms for all persons and site

## Risks & Contingencies
1. Access withdrawal -> backup site identified
2. Role conflict -> weekly reflexive memos + advisor debrief

## Verdict
PLAN READY | NEEDS REVISION (access unresolved) | NEEDS ETHICS REVIEW
```

## Skill Chains
- After plan approved -> `[field-research]` to execute fieldwork
- After fieldnotes collected -> `[coding-scheme]` to code observations
- Before planning -> `[research-ingest]` to review prior ethnographies of the site
