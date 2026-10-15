---
name: guardrail-design
description: Design input/output guardrails for LLM applications -- content filters, format validators, safety checks.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--type input|output|both] [--app APP_NAME] [--framework nist|owasp|custom]"
category: security
status: candidate
---
# Guardrail Design

Design guardrails that protect LLM applications from misuse, hallucination, and harmful output. Goes beyond agent-specific operating rules (gemini-guardrails.md) to application-level safety.

## When to Use
- Building an LLM-powered feature that faces users
- Designing safety controls for an AI application
- Client engagement requiring AI governance controls
- When user says "guardrail design" or "input filter" or "output filter"

## Guardrail Types

### Input Guardrails
| Guard | What It Catches | Implementation |
|-------|----------------|----------------|
| Prompt injection | Attempts to override system prompt | Pattern matching + LLM classifier |
| PII detection | SSN, credit cards, emails in user input | Regex + entity recognition |
| Topic boundaries | Off-topic requests outside agent scope | Keyword + intent classification |
| Rate limiting | Excessive requests from single user | Token bucket / sliding window |
| Input length | Oversized inputs that waste tokens | Character/token count check |

### Output Guardrails
| Guard | What It Catches | Implementation |
|-------|----------------|----------------|
| Hallucination detection | Claims not grounded in source material | Citation checking + confidence scoring |
| PII leakage | Model revealing training data or user PII | Pattern matching on output |
| Format compliance | Output not matching expected schema | JSON schema validation, regex |
| Toxicity filter | Harmful, biased, or inappropriate content | Classifier or keyword filter |
| Confidence threshold | Low-confidence answers presented as fact | Calibration scoring |
| Cost runaway | Output significantly longer than expected | Token count monitoring |

## Execution

1. **Scope**: What application? What's the threat model?
2. **Risk assessment**: What's the worst that could happen without guardrails?
3. **Select guards**: Choose from the menu above based on risk
4. **Design implementation**: For each guard, specify the check and the action (block, warn, log, fallback)
5. **Test adversarially**: Try to bypass each guardrail
6. **Document**: Output a guardrail specification document

## Output Format

```
Guardrail Design | {app_name}
=============================

## Threat Model Summary
Application: {name}
Users: {who}
Risk level: LOW/MEDIUM/HIGH/CRITICAL
Key threats: {list}

## Input Guardrails
| # | Guard | Risk | Implementation | Action on Trigger | Priority |
|---|-------|------|---------------|-------------------|----------|
| 1 | ... | ... | ... | BLOCK/WARN/LOG | HIGH |

## Output Guardrails
| # | Guard | Risk | Implementation | Action on Trigger | Priority |
|---|-------|------|---------------|-------------------|----------|
| 1 | ... | ... | ... | BLOCK/WARN/LOG | HIGH |

## Bypass Test Plan
| Guard | Test Input | Expected Behavior |
|-------|-----------|-------------------|

## Framework Mapping (if --framework specified)
| Guard | NIST AI RMF | OWASP Top 10 for LLMs |
|-------|------------|----------------------|
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Guardrails designed | `[threat-model]` (deeper threat analysis) |
| For client | `[assessment-report]` (include in deliverable) |
| Production deploy | `[evidence-pack]` (bundle as governance evidence) |
| Guards implemented | `[chaos-test]` (test bypass resistance) |
