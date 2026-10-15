---
name: talk-prep
description: Conference talk preparation -- abstract, outline, slide structure, speaker notes, timing
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [--length 5|15|20|30|45] [--event EVENT_NAME]"
category: cognitive
status: candidate
---
# Talk Prep

Prepare a complete conference talk package: abstract for submission, slide outline with timing per section, speaker notes, and audience engagement points. Calibrated to talk length.

## When to Use
- You are preparing a conference talk or meetup presentation
- You need a structured abstract for a CFP (Call for Papers) submission
- You want slide-by-slide speaker notes with timing guidance
- You need to rehearse and want a timing checklist

## Execution
1. Parse `$ARGUMENTS` for topic, talk length (default 20 min), and optional event name
2. Draft a 150-word abstract suitable for CFP submission
3. Create slide outline with estimated time per section
4. Allocate time: 10% intro, 70% content (3-5 sections), 10% demo/examples, 10% Q&A
5. Write speaker notes for each slide (2-3 key points per slide)
6. Identify audience engagement moments (questions, live polls, demos)
7. List technical requirements (projector, internet, demo machine)
8. Present the complete talk package

## Output Format
```
Talk Prep | <topic> (<length> min)

## Abstract (for CFP)
<150-word abstract>

## Talk Outline
| # | Section | Slides | Time | Key Point |
|---|---------|--------|------|-----------|
| 1 | Introduction | 1-2 | 2 min | Hook + context |
| 2 | <section> | 3-6 | 5 min | <key point> |
| ... | ... | ... | ... | ... |
| N | Q&A | - | 3 min | Prepared questions |

## Speaker Notes
### Slide 1: <title>
- <talking point>
- <talking point>

## Technical Requirements
- <list of needs>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Need slide deck | `[docgen]` to generate the presentation file |
| Need meeting context | `[meeting-prep]` for audience research |
| Need a demo script | `[demo-script]` for the live demo portion |
