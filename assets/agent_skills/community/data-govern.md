---
name: data-govern
description: Implement data governance policies for access control, retention, classification, and compliance mapping
version: 0.1.0
execution-mode: advisory
argument-hint: "[--policy <framework>] [--scope <datasets>]"
category: governance-compliance
status: candidate
---
# data-govern | Data Governance Policy Engine

## When to Use
- Establishing governance for a new data platform or domain
- Mapping datasets to compliance frameworks (GDPR, CCPA, HIPAA)
- Defining access-control, retention, and classification rules
- Preparing for an audit or compliance review

## Execution

### 1. Parse Arguments
- `--policy <framework>`: GDPR, CCPA, HIPAA, or custom policy name
- `--scope <datasets>`: comma-separated dataset identifiers (default all)

### 2. Inventory and Classify
- Load dataset inventory from catalog or direct scan
- Classify each dataset: public, internal, confidential, restricted
- Tag columns with data categories (pii, phi, financial, operational)

### 3. Define Access Policies
- Map roles to datasets and column-level grants
- Apply default deny; enumerate explicit allow rules
- Record break-glass procedures for restricted assets

### 4. Set Retention Rules
- Per framework: define retention periods and deletion triggers
- GDPR: right-to-erasure, data-minimization, purpose limitation
- HIPAA: minimum necessary, audit logs, 6-year retention
- CCPA: consumer deletion requests, opt-out signals

### 5. Compliance Mapping
- For each dataset, map to applicable framework controls
- Record evidence: policy file, access log location, retention config
- Flag gaps where a control is required but not implemented

### 6. Emit Policy Bundle
- Write policies to `_state/govern/policies.<framework>.json`
- Generate compliance matrix to `_state/govern/matrix.<framework>.md`

## Output Format

```
data-govern | policy=GDPR scope=all

## Summary
- Datasets in scope: 42 | Framework: GDPR
- Classified: 42 | Access rules: 18 | Retention rules: 12

## Classification
| Dataset            | Classification | PII Columns | Framework Controls |
|--------------------|----------------|-------------|--------------------|
| public.users       | internal       | email, name | GDPR-3, GDPR-17    |
| api.payments       | restricted     | card_token  | GDPR-5, GDPR-32    |

## Compliance Matrix
| Control   | Description        | Datasets Covered | Status |
|-----------|--------------------|------------------|--------|
| GDPR-3    | Data minimization | 42               | PASS   |
| GDPR-17   | Right to erasure  | 38               | GAP: 4 |

## Verdict
PASS | 42 datasets governed, 1 compliance gap flagged
```

## Skill Chains
- After governing -> `[gdpr-check]` to validate GDPR controls
- After governing -> `[privacy-audit]` to audit privacy posture
- After governing -> `[data-catalog]` to persist classification tags
- Before governing -> `[compliance-calendar]` to align review dates
