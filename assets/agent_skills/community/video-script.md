---
name: video-script
description: Script for explainer or tutorial video with sections, timing, and visual notes
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [--style explainer|tutorial|promo] [--duration MINUTES]"
category: cognitive
status: candidate
---
# Video Script

Write a complete video script with sections, per-section timing, visual/screen direction notes, and narration text. Supports explainer, tutorial, and promotional styles.

## When to Use
- You are creating a YouTube tutorial or explainer video
- You need a scripted walkthrough with visual direction cues
- You want to plan a promotional video with precise timing
- You need screen recording instructions alongside narration

## Execution
1. Parse `$ARGUMENTS` for topic, style (explainer/tutorial/promo), and duration (default 5 min)
2. Determine structure based on style:
   - Explainer: hook, problem, solution, how it works, CTA
   - Tutorial: intro, prerequisites, step-by-step, recap, next steps
   - Promo: hook, pain point, demo, social proof, CTA
3. Write narration script for each section with word count (150 words/min pace)
4. Add visual direction notes (screen recordings, slides, animations, b-roll)
5. Include timing markers and transition cues
6. Calculate total duration and adjust pacing if needed

## Output Format
```
Video Script | <topic> (<style>, <duration> min)

## Summary
Style: <explainer|tutorial|promo>
Target duration: <N> min
Word count: <N> (~<N> min at 150 wpm)

## Script

### [0:00 - 0:30] Hook
VISUAL: <direction>
NARRATION: "<script text>"

### [0:30 - 1:30] <Section Title>
VISUAL: <direction>
NARRATION: "<script text>"

### [N:00 - N:30] Call to Action
VISUAL: <direction>
NARRATION: "<script text>"

## Production Notes
- Equipment: <recommendations>
- Music: <suggestions>
- Thumbnail: <concept>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Script needs review | `[content-review]` for accuracy and tone |
| Video supports brand | `[brand-guidelines]` to verify visual guidelines |
