---
name: delphi-study
description: Delphi method expert consensus study - iterative surveys with anonymous feedback rounds until consensus
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [--rounds 3] [--panel-size 15] [--consensus-threshold 0.7]"
category: hummbl-research
status: candidate
---
# delphi-study | Delphi Method Expert Consensus

## When to Use
- Achieving expert consensus on topics lacking empirical resolution
- Forecasting future trends or scenarios with expert panels
- Prioritizing issues, criteria, or recommendations via structured iteration
- Avoiding groupthink through anonymous, iterative feedback

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: topic or research question for consensus
- `--rounds`: number of Delphi rounds (default 3)
- `--panel-size`: number of expert panelists (default 15)
- `--consensus-threshold`: proportion for agreement (default 0.7)
- Minimum panel: 7; recommended: 15-30

### 2. Panel Recruitment
- Define expert inclusion criteria (experience, credentials, diversity)
- Recruit panel ensuring disciplinary and geographic diversity
- Obtain informed consent and commitment for all rounds
- Document panel composition (anonymized demographics)

### 3. Round 1 -- Open-Ended
- Distribute open-ended questionnaire on the topic
- Collect responses and perform qualitative analysis (thematic or content coding)
- Synthesize statements/items for Round 2 rating

### 4. Round 2 -- Rating
- Distribute structured questionnaire (Likert 1-7 or 1-9 scale)
- Each panelist rates all items independently
- Compute central tendency (median) and dispersion (IQR) per item
- Provide anonymous feedback: panel median + panelist's own score

### 5. Round 3 -- Re-Rating with Feedback
- Panelists re-rate items with knowledge of group response
- Allow space for qualitative justification of outlier positions
- Compute updated medians and IQRs

### 6. Consensus Assessment
- Item achieves consensus if: proportion agreeing >= threshold OR IQR <= 1 (on 7-point scale)
- Items not reaching consensus: flag for discussion or exclusion
- Compute overall consensus rate across all items

### 7. Reporting
- Report item-level medians, IQRs, and consensus status per round
- Track stability (change between rounds) -- convergence indicates consensus forming
- Document dissenting opinions and panel attrition per round

## Output Format

```
delphi-study | <topic>

## Configuration
- Rounds: 3 | Panel size: 15 | Consensus threshold: 0.70
- Scale: 7-point Likert

## Panel Profile
- N = 15 | Fields: A, B, C | Attrition: 1 (Round 2)

## Round Results
| Item | R1 Median | R1 IQR | R2 Median | R2 IQR | R3 Median | R3 IQR | Consensus |
|------|-----------|--------|-----------|--------|-----------|--------|-----------|
| 1    | 5         | 2      | 6         | 1      | 6         | 1      | YES       |
| 2    | 4         | 3      | 4         | 2      | 5         | 2      | NO        |

## Consensus Summary
- Items reaching consensus: 8/10 (80%)
- Items unresolved: 2 (flagged for expert discussion)

## Stability
- Convergence rate: 85% of items moved toward median between R2 and R3

## Verdict
CONSENSUS REACHED | PARTIAL CONSENSUS | NO CONSENSUS (additional round needed)
```

## Skill Chains
- After consensus reached -> `[meta-synthesis]` to integrate with existing literature
- Before Delphi study -> `[research-ingest]` to review prior consensus studies on the topic
