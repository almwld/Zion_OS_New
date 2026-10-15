---
name: invoice-generate
description: Generate invoice from hours, rate, and client details with sequence tracking.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "\"CLIENT\" [--hours N] [--rate N] [--period MONTH]"
category: finance-legal
status: candidate
---
# Invoice Generate

Create professional invoices for your organization consulting engagements.

## When to Use
- Monthly billing cycle
- Milestone completion payment
- First your organization invoice (target: Apr 24)
- After `[time-track]` shows billable hours

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=invoice-generate] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Read time log**: Pull hours from `_state/time/log.tsv` for client/period
2. **Get next invoice number**: Read/increment `_state/invoices/sequence.txt`
3. **Calculate totals**: hours × rate, apply any discounts
4. **Generate invoice**:
   - Invoice number (your organization-YYYY-NNN)
   - Bill To (client details)
   - From (Your Company, LLC)
   - Line items (date, description, hours, rate, amount)
   - Subtotal, tax (if applicable), total
   - Payment terms (Net 30)
   - Payment instructions
5. **Output**: Markdown at `_state/invoices/your organization-<YYYY>-<NNN>.md`
6. **Optionally**: Convert to PDF via `[docgen]`

## Output Format

```markdown
# INVOICE
**Your Company, LLC** | $USER_NAME | Atlanta, GA
**Invoice #**: your organization-2026-001
**Date**: <date> | **Due**: <date + 30>

**Bill To**: <client>

| Date | Description | Hours | Rate | Amount |
|------|-------------|-------|------|--------|
| ... | ... | ... | $X | $X,XXX |

**Total Due: $X,XXX**

Payment: Net 30 | ACH/Wire preferred
```

## Skill Chains

### Mandatory (MUST pass before invoice generation)

- **`[time-track]`** MUST verify billable hours for the client/period — no invoicing without verified hours

### Advisory

- **After invoice**: `[send-email]` to client (with `[content-review]` passed), `[payment-track]` (record invoice)
- **Tracking**: `[revenue-forecast]`, `[runway]`
- **PDF**: `[docgen]` (convert to PDF)

## Authority

- **T1 (TRUSTED)**: May generate with `[time-track]` passed
- **T2 (Active/High)**: May generate with `[time-track]` passed; sending requires operator approval
- **T3 (Medium)**: MUST get operator approval AND `[time-track]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill (financial document generation)
- **Operator**: Override any restriction
