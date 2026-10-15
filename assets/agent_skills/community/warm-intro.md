---
name: warm-intro
description: Draft warm introduction emails with mutual context, reason for connecting, and clear ask
version: 0.1.0
execution-mode: advisory
argument-hint: "<person_a> <person_b> [--context CONTEXT]"
category: sales-marketing
status: candidate
---
# Warm Intro

Draft a warm introduction email connecting two people with shared context, a clear reason for the introduction, and a specific ask. Pulls available context from CRM data to personalize the introduction.

## When to Use
- When connecting a prospect with a team member or partner
- When introducing two contacts who could mutually benefit from knowing each other
- When a client asks for a referral or connection in your network
- When facilitating partnership or collaboration introductions

## Execution
1. Parse `$ARGUMENTS` for both person names and optional context
2. Look up both contacts in CRM data if available
3. Identify mutual interests, complementary skills, or shared connections
4. Draft a double opt-in introduction email (ask both parties before connecting)
5. Include: who each person is, why they should meet, what the specific ask is
6. Keep the email concise (under 150 words for the intro body)

## Output Format
```
Warm Intro | <person_a> <> <person_b>
=======================================

## Context
- <person_a>: <role, company, relevant background>
- <person_b>: <role, company, relevant background>
- Connection reason: <why they should meet>

## Double Opt-In Email (to <person_a>)
Subject: Quick intro — <person_b> at <company>?
Body: ...

## Introduction Email (after opt-in)
Subject: Intro: <person_a> <> <person_b>
Body: ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Need CRM context on the contacts | `[crm]` to look up relationship history |
| Ready to send the email | `[send-email]` to deliver |
