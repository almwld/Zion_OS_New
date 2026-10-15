---
name: financial-model
description: Build a 3-statement financial model (P&L, cash flow, balance sheet) with assumptions labeled, sensitivity table, and investor-ready formatting. Saves to _internal/finance/. Powered by cfo-advisor agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"COMPANY\" [--horizon 3yr|5yr] [--stage pre-seed|seed|series-a] [--focus saas|services|product]"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Financial Model

Generate a complete 3-statement financial model for investor presentations or operational planning.

## When to Use

- Preparing for a fundraise (pre-seed, seed, Series A)
- Annual planning / board presentation
- Hiring plan scenario planning
- Before signing a lease or major commitment
- When a potential investor asks "what do your projections look like?"

## Required Inputs

| Field | Example |
|-------|---------|
| Company | HUMMBL, LLC |
| Business model | SaaS + consulting services |
| Revenue streams | Platform subscription ($3,500/mo), assessments ($7,500 each) |
| Key growth driver | # of clients, # of assessments per quarter |
| COGS | Claude API costs, contractor delivery time |
| Headcount plan | Founder now; +1 technical hire Q3 2026 |
| Known fixed costs | Software subscriptions, legal/accounting |
| Planning horizon | 3 years (monthly Y1, quarterly Y2-3) |
| Starting cash | [actual balance] |

## Model Structure

### Income Statement (P&L)
```
Revenue
  - Recurring (SaaS/subscriptions)
  - One-time (assessments, projects)
  - Total Revenue

COGS
  - Direct delivery costs
  - API/infrastructure
  - Gross Profit / Gross Margin %

Operating Expenses
  - Salaries & benefits
  - Software & tools
  - Marketing & sales
  - G&A (legal, accounting, insurance)
  - Total OpEx

EBITDA
Net Income (Loss)
```

### Cash Flow Statement
- Operating cash flow
- Capex (minimal for software)
- Financing (investor capital)
- Ending cash balance

### Balance Sheet (simplified for early-stage)
- Cash
- AR (accounts receivable)
- Total Assets
- AP + deferred revenue
- Owner equity / invested capital

## Assumptions Page (Required)

Every model must have a clearly separated assumptions section:
```
ASSUMPTION: Monthly churn rate = 5%    [SOURCE: industry benchmark, SaaS Metrics 2024]
ASSUMPTION: Assessment close rate = 30% [SOURCE: founder estimate, no data yet]
ACTUAL: Founding team salary = $0      [SOURCE: confirmed]
```

## Sensitivity Table

The model includes a 3×3 sensitivity table on the top 2 drivers:

| | Churn -2% | Base | Churn +2% |
|---|---|---|---|
| Close rate -10% | | | |
| Base | | | |
| Close rate +10% | | | |

## Human Cost Equivalent

- Basic 3-statement model: $800-1,500 fractional CFO time
- Investor-ready with sensitivity: $1,500-3,000

## Skill Chains

### Mandatory

- None — financial-model is `advisory` mode (generates planning documents, not financial records).

### Advisory

- `[financial-model]` → `[scenario-plan]` (stress-test key assumptions)
- `[financial-model]` → `[investor-update]` (embed in board deck)
- `[financial-model]` → `[runway]` (extract cash runway from model)
- `[financial-model]` → `[pitch]` (financial slides in deck)
- `[financial-model]` → `[docgen]` (export to PDF for data room)

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (advisory — generates planning docs)
- **T3 (Medium)**: May run without restriction (advisory — generates planning docs)
- **T4 (Probationary)**: May run (advisory — no side effects beyond file generation)
- **Operator**: Override any restriction

## Disclaimer

Financial models are planning tools, not financial advice. Always consult a
CPA or financial advisor before making investment or tax decisions.
