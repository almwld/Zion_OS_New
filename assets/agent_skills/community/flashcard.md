---
name: flashcard
description: Generate Q&A flashcards from docs, notes, or topic for study and review
version: 0.1.0
execution-mode: advisory
argument-hint: "<generate|review|list> [topic] [source-file]"
category: fleet-ops
status: candidate
---
# [flashcard]

## When to Use
- Generating study flashcards from documentation or notes
- Reviewing previously created flashcard decks
- Preparing for certification exams (CCA-F, AWS, etc.)
- Converting meeting notes or research into retention-friendly format

## Execution

### Storage
- Decks: `_state/study/<topic>/cards.json`
- Review state: `_state/study/<topic>/review.json` (last reviewed, confidence per card)
- Card schema: `{"id", "q", "a", "tags", "difficulty", "last_reviewed", "confidence"}`

### Commands

**generate [topic] [source-file]**
1. If source-file provided, read it and extract key concepts
2. If topic only, generate cards from domain knowledge
3. Create 10-20 cards per session
4. Each card: clear question, concise answer (1-3 sentences)
5. Tag with topic and subtopic
6. Assign initial difficulty: easy/medium/hard
7. Save to `_state/study/<topic>/cards.json` (append to existing deck)
8. Report count and show 3 sample cards

**review [topic] [count]**
1. Load deck and review state
2. Prioritize: never reviewed > low confidence > due for spaced review
3. Present cards: show question, then answer after separator
4. Default count: 10 cards
5. Update review timestamps

**list [topic]**
1. Show all decks with card counts and review stats
2. Highlight decks due for review based on spaced repetition schedule

## Output Format

```
Flashcard | generate CCA-F governance-fundamentals
============================================================
Source: PROJECTS/hummbl-cca-f/notes/domain-1.md
Generated: 15 cards (5 easy, 7 medium, 3 hard)

Sample:
  Q: What are the three pillars of AI governance?
  A: Transparency, accountability, and fairness. These form the
     foundation for responsible AI deployment in organizations.

  Q: Define "algorithmic impact assessment" (AIA).
  A: A systematic evaluation of an AI system's potential effects
     on individuals, groups, and society, conducted before deployment.

  Q: What distinguishes AI governance from AI ethics?
  A: Governance provides enforceable structures (policies, processes,
     oversight) while ethics provides guiding principles and values.

Saved to: _state/study/cca-f/cards.json (15 new, 15 total)
------------------------------------------------------------
Next: [quiz] CCA-F (test yourself) or [flashcard] review CCA-F
```

## Skill Chains
- After `[flashcard] generate` -> suggest `[quiz]` for testing
- After `[flashcard] review` with low scores -> suggest `[study-plan]` adjustment
- Pair with `[cert-tracker]` to log study hours
