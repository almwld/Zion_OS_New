---
name: nda-check
description: Verify NDA/confidentiality status before sharing sensitive info with a client or partner
version: 0.1.0
execution-mode: advisory
argument-hint: "<entity_name> [--check-file PATH]"
category: finance-legal
status: candidate
---
# NDA Check

Verify whether an NDA or confidentiality agreement is in place with a named entity before sharing sensitive information. Checks local records, flags expiration dates, and identifies what categories of information are covered or excluded.

## When to Use
- Before sharing proprietary code, architecture diagrams, or internal docs with a third party
- Before a demo or presentation that includes sensitive implementation details
- When onboarding a new partner or subcontractor who needs access to protected materials
- When unsure whether an existing NDA covers a specific category of information

## Execution
1. Parse `$ARGUMENTS` for entity name and optional file path to check
2. Search `_state/` and local records for NDA/confidentiality agreements with the entity
3. If found: check effective date, expiration, covered categories, and exclusions
4. If `--check-file` provided: assess whether the file contents fall under covered categories
5. Report NDA status: ACTIVE, EXPIRED, NOT_FOUND, or PARTIAL (some categories uncovered)
6. If NOT_FOUND or EXPIRED, recommend next steps (draft NDA, renew, or proceed with caution)

## Output Format
```
NDA Check | <entity_name>
==========================

## Status: ACTIVE / EXPIRED / NOT_FOUND / PARTIAL

## Agreement Details (if found)
- Effective: <date>
- Expires: <date> (<N> days remaining)
- Type: Mutual / One-way
- Covered: <categories>
- Excluded: <categories>

## File Check (if --check-file)
- File: <path>
- Classification: <COVERED / NOT_COVERED / UNCLEAR>
- Reasoning: ...

## Recommendation
- ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| NDA not found, need one drafted | `[legal-check]` for template and terms review |
| Need to bundle protected materials for sharing | `[evidence-pack]` to assemble with proper markings |
