---
name: field-research
description: Field research methodology - site selection, data collection (observation/interviews/artifacts), and fieldnote management
version: 0.1.0
execution-mode: advisory
argument-hint: "<site> [--methods observation|interview|artifact] [--duration days]"
category: cognitive
status: candidate
---
# field-research | Field Research Methodology

## When to Use
- Collecting primary data in natural settings (not lab or controlled environments)
- Combining observation, interviews, and artifact collection in a single study
- Managing fieldnotes and multi-source data during extended fieldwork
- Complementing ethnographic plans with execution-phase methodology

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: field site (organization, community, location)
- `--methods`: comma-separated data collection methods (observation, interview, artifact)
- `--duration`: planned fieldwork duration in days (default 30)
- Default methods: `observation,interview`

### 2. Site Selection and Preparation
- Confirm site access (gatekeepers, permissions, ethical approval)
- Map the site: physical layout, social structure, key actors, routines
- Identify key informants and initial contacts
- Prepare fieldwork kit: notebooks, recorder, consent forms, camera (if permitted)

### 3. Observation Data Collection
- Conduct structured or semi-structured observation per protocol
- Record jottings in real time; expand to full fieldnotes within 24 hours
- Distinguish descriptive (what happened) from reflective (observer interpretation) notes
- Track observation time per visit and cumulative hours

### 4. Interview Data Collection
- Develop interview guide (semi-structured recommended for fieldwork)
- Conduct interviews in situ when possible (contextual richness)
- Record and transcribe; verify transcripts with participants if feasible
- Document interview context (location, duration, interruptions, body language)

### 5. Artifact Collection
- Identify relevant artifacts (documents, schedules, physical objects, digital traces)
- Collect or photograph with permission; log provenance and context
- Analyze artifacts as both products of and inputs to social processes

### 6. Fieldnote Management
- Standardize fieldnote template: header (date, time, site, observer), body, reflections
- Version control fieldnotes (dated filenames or VCS)
- Code fieldnotes incrementally (preliminary codes updated weekly)
- Back up data daily; encrypt sensitive materials

### 7. Reflexivity and Ethics in the Field
- Write reflexive memos after each field visit
- Monitor for ethical issues (confidentiality breaches, role drift, informant vulnerability)
- Schedule periodic debriefs with advisor or research team

## Output Format

```
field-research | <site>

## Configuration
- Methods: Observation, Interview | Duration: 30 days
- Site: <name> | Access: CONFIRMED

## Data Collection Summary
| Method     | Sessions | Hours | Artifacts |
|------------|----------|-------|-----------|
| Observation| 15       | 45.0  | 0         |
| Interview  | 12       | 9.5   | 12 transcripts |
| Artifact   | 8        | --    | 8 items   |

## Fieldnote Status
- Total fieldnotes: 45 | Coded: 30 (67%) | Pending: 15
- Average expansion time: 35 min/session

## Preliminary Codes (top 10)
1. routine disruption (28)  2. informal hierarchy (22)  3. ...

## Ethical Log
- Consent re-confirmed: Participant 7 (Day 12)
- Anonymization: all names replaced with pseudonyms

## Reflexive Memos
- Day 5: observer influence on meeting dynamics
- Day 14: growing rapport with key informant -- boundary check needed

## Verdict
FIELDWORK ON TRACK | BEHIND SCHEDULE (fieldnote backlog) | ACCESS AT RISK
```

## Skill Chains
- After data collected -> `[coding-scheme]` to formalize coding of fieldnotes
- After patterns emerge -> `[thematic-analysis]` for theme identification
- Before fieldwork -> `[research-ingest]` to review site background and prior studies
