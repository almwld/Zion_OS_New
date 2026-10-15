---
name: payment-track
description: Track invoice payments, aging, outstanding balances, and payment history per client
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action record|aging|outstanding|history] [--client NAME]"
category: finance-legal
status: candidate
---
# Payment Track

Track the lifecycle of invoices from issuance to payment. Monitor aging buckets (30/60/90 days), outstanding balances, and payment history per client. Reads from and writes to the payment ledger at `_state/billing/payments.jsonl`.

## When to Use
- Recording a payment received against an outstanding invoice
- Checking which invoices are overdue and by how long
- Reviewing outstanding balances before a client meeting or follow-up
- Generating a payment history summary for tax prep or runway calculations

## Execution
1. Parse `$ARGUMENTS` for action (default: `outstanding`) and optional client filter.
2. Read the payment ledger at `_state/billing/payments.jsonl`. If it does not exist, report empty state.
3. Cross-reference with invoice records at `_state/billing/invoices.jsonl` if available.
4. Execute the requested action:
   - **record**: Append a payment entry (invoice_id, amount, date, method) to the ledger.
   - **aging**: Bucket all unpaid invoices into current, 30-day, 60-day, 90-day+ categories.
   - **outstanding**: List all unpaid invoices with amounts, clients, and days overdue.
   - **history**: Show payment timeline for a specific client or all clients.
5. Calculate summary statistics: total outstanding, total received this month, average days to payment.
6. Flag any invoices approaching or past the 90-day mark for escalation.

## Output Format
```
Payment Track | action | client_filter

## Summary
- Total outstanding: $X,XXX
- Invoices overdue: N
- Average days to payment: N days

## Aging Buckets
| Bucket | Count | Total |
|--------|-------|-------|
| Current (< 30d) | N | $X,XXX |
| 30-60 days | N | $X,XXX |
| 60-90 days | N | $X,XXX |
| 90+ days | N | $X,XXX |

## Details
{Action-specific details: invoice list, payment record confirmation, or history}

## Alerts
- {any 90+ day invoices or large outstanding balances}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains

### Mandatory

- None — payment-track is `advisory` mode (read-only tracking). The `record` action
  appends to a ledger but does not modify financial documents.

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Finding overdue invoices | `[invoice-generate]` to re-send or create follow-up invoice |
| Reviewing total outstanding | `[runway]` to update cash flow projections |
| Identifying 90+ day aging | `[follow-up]` to draft collection emails (with `[content-review]`) |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only tracking + ledger append)
- **T3 (Medium)**: May run without restriction (read-only tracking + ledger append)
- **T4 (Probationary)**: May run (read-only tracking; `record` action requires operator approval)
- **Operator**: Override any restriction
