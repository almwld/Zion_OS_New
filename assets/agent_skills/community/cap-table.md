---
name: cap-table
description: Build or update an equity cap table. Founders, investors, option pool. Shows ownership %, dilution through rounds, fully-diluted totals. Saves to _internal/finance/. Powered by cfo-advisor agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"COMPANY\" [--stage pre-seed|seed|series-a] [--option-pool X%]"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Cap Table

Generate or update a capitalization table for an early-stage company.

## When to Use

- Incorporating or forming an LLC with multiple stakeholders
- Before issuing any options or equity to employees
- Before a fundraising conversation
- When an investor asks "what does the cap table look like?"
- After each funding round closes

## Required Inputs

| Field | Example |
|-------|---------|
| Company | HUMMBL, LLC |
| Founders | Reuben Bowlby — 100% |
| Existing investors | None / Seed round: $500K at $5M pre-money |
| Option pool | 10% fully-diluted (before or after round) |
| Advisor shares | 0.25% to [name], fully vested |
| Convertible notes | $200K SAFE at $4M cap |

## Cap Table Sections

### Pre-Money (Current State)
```
Stockholder          Shares      %
-------------------------------------------
Reuben Bowlby        8,000,000   80.0%
Option Pool          1,000,000   10.0%
[Advisor 1]            250,000    2.5%
SAFEs (converted)      750,000    7.5%
-------------------------------------------
TOTAL               10,000,000  100.0%
```

### Post-Money (After Proposed Round)
Shows dilution of each stakeholder after new investment closes.

### Fully-Diluted Shares
Includes: issued shares + option pool (all options, including unissued) + any warrants + SAFE conversions.

## SAFE / Convertible Note Logic

For SAFEs and convertible notes, the agent will:
1. Show conversion at the cap price (if round price > cap price)
2. Show conversion at the discount (if round price < cap * (1 - discount))
3. Flag if terms are unclear and need attorney clarification

## Dilution Table

Shows each stakeholder's % through multiple rounds:

| | Founding | Seed ($500K) | Series A ($3M) |
|--|--|--|--|
| Founder | 100% | 72% | 55% |
| Option Pool | — | 10% | 10% |
| Seed investors | — | 18% | 14% |
| Series A | — | — | 21% |

## Human Cost Equivalent

- Simple founding cap table: $200-400 attorney time
- Multi-round cap table with SAFEs: $500-1,000
- Full capitalization analysis: $800-1,500

## Flags

The agent will flag:
- Option pool > 20% (unusual, may signal investor concern)
- Founder below 50% before Series A (early dilution risk)
- SAFEs without caps (unlimited dilution risk)
- Missing 83(b) election window for founders (must file within 30 days of stock issuance)

## Skill Chains

### Mandatory

- None — cap-table is `advisory` mode (generates planning documents, not legal records).

### Advisory

- `[cap-table]` → `[financial-model]` (embed ownership in projections)
- `[cap-table]` → `[runway]` (shows how much capital remains)
- `[cap-table]` → `[offer-letter]` (check pool availability before making equity offer)
- `[cap-table]` → `[investor-update]` (include cap table summary in board deck)

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (advisory — generates planning docs)
- **T3 (Medium)**: May run without restriction (advisory — generates planning docs)
- **T4 (Probationary)**: May run (advisory — no side effects beyond file generation)
- **Operator**: Override any restriction

## Disclaimer

Cap table outputs are planning tools, not legal documents. Always consult a
securities attorney before issuing equity, options, or convertible instruments.
