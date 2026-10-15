---
name: operating-agreement
description: Draft a complete LLC Operating Agreement. Single-member or multi-member. Georgia default, multi-state supported. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"ENTITY_NAME\" \"MEMBER_NAME\" [--state GA] [--ein EIN] [--address \"ADDRESS\"]"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# Operating Agreement

Generate a complete, attorney-ready LLC Operating Agreement.

## When to Use
- Forming a new LLC and need the foundational governance document
- Bank account application requiring OA
- Enterprise client procurement asks for OA
- Adding a second member (triggers full rewrite)

## Required Inputs

| Field | Example | Required |
|-------|---------|----------|
| Entity name | HUMMBL, LLC | Yes |
| Member name(s) | Reuben P. Bowlby | Yes |
| State of formation | Georgia | Yes |
| Principal address | 526 Briarhill Ln NE, Atlanta GA 30324 | Yes |
| EIN | 41-5361118 | Recommended |
| State control # | 25204758 | Recommended |
| Effective date | 10/15/2025 | Yes |
| Business purpose | AI software and consulting | Yes |
| Tax treatment | Disregarded entity / S-corp / C-corp | Defaults to disregarded |

## Execution

1. **Collect inputs** — gather all required fields; if run without arguments, ask for each
2. **Detect structure** — single-member (simpler) vs multi-member (requires membership %, vesting, drag-along)
3. **Select jurisdiction** — apply correct statutory references for the state
4. **Draft 11 articles**:
   - I: Formation (name, registered agent, address, term)
   - II: Purpose
   - III: Membership (interests, admission of new members)
   - IV: Capital Contributions
   - V: Allocations and Distributions
   - VI: Management (member-managed default)
   - VII: Tax Matters (EIN, default classification, election options)
   - VIII: Liability and Indemnification
   - IX: Transfer of Membership Interest
   - X: Dissolution
   - XI: Miscellaneous (governing law, amendments, severability)
5. **Attach signature block** — member(s) with date line
6. **Attach governance receipt**
7. **Save** to `_internal/legal/<entity-slug>-operating-agreement-<date>.md`

## Output

- Full operating agreement (~150-200 lines)
- Governance receipt with cost saved
- Note any provisions requiring attorney review (unusual purpose, multi-member complexity, IP concerns)

## Human Cost Equivalent

| Structure | Attorney hours | Cost range |
|-----------|---------------|-----------|
| Single-member | 2-4 hours | $600-2,000 |
| Multi-member (2-3) | 4-8 hours | $1,200-4,000 |
| Multi-member with vesting | 6-12 hours | $1,800-6,000 |

## Known HUMMBL Entity

If generating for HUMMBL, LLC, pre-fill from memory:
- Entity: HUMMBL, LLC
- Member: Reuben P. Bowlby
- State: Georgia
- EIN: 41-5361118
- Control #: 25204758
- Address: 526 Briarhill Ln NE, Atlanta GA 30324
- Effective: 10/15/2025
- Purpose: AI software development, AI governance consulting, and related technology and advisory services

## Skill Chains
- Before OA → confirm entity is registered with state
- After OA → `[service-agreement]` (ready to take clients), `[nda-draft]` (client confidentiality)
- OA signed → store copy in `_internal/legal/` + update `project_hummbl_entity.md` in memory
- Need PDF → `[docgen]` to export
