---
name: legal-ai-precedent-watch
description: "Research legal-AI ethics, privilege, confidentiality, hallucination sanctions, court rules, provider API terms, data-use, retention, ZDR, BAA, and workflow risk."
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
---
# Legal AI Precedent Watch

## Objective

Maintain an evidence-first view of legal risk for AI-assisted legal work. Focus on:

- attorney-client privilege and work-product treatment of AI use,
- confidentiality and client-consent duties,
- hallucinated authority and candor sanctions,
- bar ethics opinions and court standing orders,
- provider API terms, data retention, training, subprocessors, and ZDR/BAA availability.

This skill is not legal advice. Produce attorney-ready research notes with source links and uncertainty labels.

## Source Order

1. Primary law: court opinions, orders, docket materials, rules, statutes, regulator materials.
2. Bar/professional guidance: ABA, state bars, court AI guidelines, legal ethics opinions.
3. Provider primary docs: terms, privacy, API data-use, retention, DPA/BAA/ZDR docs.
4. Reputable legal analysis: law firm alerts, legal publishers, bar journals.
5. News/social only for lead generation, never as the final authority.

## Standard Watch Queries

Run fresh web searches before making current claims. Include dates in the brief.

- `"generative AI" attorney client privilege work product court opinion`
- `"Claude" attorney-client privilege "Heppner"`
- `"ChatGPT" sanctions fake cases lawyer`
- `"generative AI" "ethics opinion" lawyers confidentiality`
- `"OpenAI API" data retention "not used to train"`
- `"Anthropic API" "zero data retention" "not train"`
- `"Azure OpenAI" "not used to train"`
- `"Amazon Bedrock" prompts "not used to train"`
- `"Google Vertex AI" generative AI data governance not used to train`

## Review Checklist

For each provider or tool, classify:

- Surface: consumer chat, team/business chat, direct API, cloud-hosted API, local model.
- Training default: no training by default, opt-in training, unclear, or trains by default.
- Retention: standard retention, configurable retention, ZDR available, or unclear.
- Contract controls: DPA, BAA/HIPAA eligibility, subprocessor list, enterprise terms.
- Legal-use controls: logging, redaction, source citation, human review, privilege flags.
- Risk tier:
  - Green: API/enterprise terms, no-training default, retention controlled, lawyer-supervised, no raw client data unless authorized.
  - Yellow: acceptable only for synthetic/redacted/public data or with client consent and documented controls.
  - Red: consumer/free tools, unclear retention/training, public proxy APIs, or no confidentiality commitments.

## Output Format

Use this structure:

```markdown
## Bottom Line

## Current Authorities Checked
| Source | Date checked | Holding / guidance | Relevance |

## Provider Posture
| Provider/API | Training default | Retention/ZDR | Contract controls | HUMMBL recommendation |

## Required HUMMBL Controls

## Open Questions / Needs Counsel Review
```

## HUMMBL Default Rule

For legal/client data, default to local or controlled API paths. Do not treat consumer Claude, ChatGPT, Gemini, or grey-market API proxies as acceptable for confidential legal work. Cloud APIs require provider-primary confirmation of no-training default, retention posture, and contract terms before use in a client matter.
