---
name: revenue-forecast
description: Project revenue from CRM pipeline, conversion rates, and contract values
version: 0.1.0
execution-mode: advisory
argument-hint: "[period] [scenario]"
category: fleet-ops
status: candidate
---
# [revenue-forecast]

## When to Use
- Monthly or quarterly revenue planning
- Before investor updates or partner conversations
- When evaluating whether to take on new work
- Checking if revenue targets ($5K MRR by Sep) are on track

## Execution

### Data Sources
1. CRM Google Sheet (ID: `1QniOgGd3e7gZXqmknqN1sjXEcYc9NPJCbKJ5lZF4IQM`)
2. `_state/time/log.tsv` -- actual billable hours
3. `_state/expenses/log.tsv` -- cost baseline
4. `$PROJECTS_DIR/your-org/BUSINESS.md` -- canonical rates and service packages

### Steps
1. Read BUSINESS.md for current rate card and service definitions
2. Read CRM data (pipeline tab) for active leads and stages
3. Apply conversion rates by stage:
   - Prospect: 10%, Qualified: 25%, Proposal: 50%, Negotiation: 75%, Closed: 100%
4. Calculate weighted pipeline value
5. Add confirmed recurring revenue (e.g., team lead arrangement, active contracts)
6. Project forward for requested period (default: 3 months)
7. Compare against targets from MEMORY.md ($5K MRR by Sep)

### Scenarios
- **conservative**: 50% of standard conversion rates
- **base**: Standard conversion rates
- **optimistic**: 150% of standard conversion rates

## Output Format

```
Revenue Forecast | Q2 2026 (base scenario)
============================================================
Confirmed Recurring:
  team lead (hummbl-governance)     $3,000/mo    $9,000 total

Weighted Pipeline:
  Lead A (proposal)      $4,500 x 50% = $2,250
  Lead B (qualified)     $2,000 x 25% = $500
  Pipeline total:        $2,750

| Month   | Recurring | Pipeline | Projected | Target |
|---------|-----------|----------|-----------|--------|
| Apr     | $3,000    | $1,000   | $4,000    | $3,000 |
| May     | $3,000    | $1,250   | $4,250    | $4,000 |
| Jun     | $3,000    | $1,500   | $4,500    | $5,000 |

$5K MRR target: ON TRACK (Jun projected: $4,500, gap: $500)
------------------------------------------------------------
Next: [runway] (net position after expenses)
```

## Skill Chains
- After `[revenue-forecast]` -> suggest `[runway]` for net position
- Before `[investor-update]` -> run `[revenue-forecast]` for current numbers
- Pair with `[expense-log] summary` for profit margin view
