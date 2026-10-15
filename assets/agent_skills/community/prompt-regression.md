---
name: prompt-regression
description: Detect when prompt or system prompt changes break expected outputs by running saved test cases
version: 0.1.0
execution-mode: advisory
argument-hint: "[--prompt-id ID] [--action test|compare|report]"
category: backend-infra
status: candidate
---
# Prompt Regression Testing

Run saved test cases against new prompt versions to detect regressions in output quality, format compliance, and behavioral consistency. Prevents prompt changes from silently breaking expected behavior across different input types.

## When to Use
- After modifying a system prompt and need to verify nothing broke
- Building a regression suite for prompts used in production agents
- Comparing two prompt versions side-by-side on the same test inputs
- Generating a report of prompt stability over time

## Execution
1. Parse `$ARGUMENTS` for `--prompt-id` (optional, defaults to all) and `--action` (default: `test`)
2. Load the prompt version(s) and associated test cases from the prompt registry
3. For `test`: run each test case against the current prompt version, check assertions (format, content keywords, tone, length constraints)
4. For `compare`: run identical inputs through old and new prompt versions, highlight differences in output structure, tone, and content
5. For `report`: generate a stability summary showing pass rates across versions over time
6. Score each test case: PASS (meets all assertions), DRIFT (output changed but acceptable), FAIL (assertion violated)
7. Flag any test cases where output format changed (JSON schema violations, missing fields, etc.)
8. Output summary with regression count and severity

## Output Format
```
Prompt Regression | {prompt-id} | {action}
────────────────────────────────
Prompt version: {current} vs {previous}
Test cases: {N} | Pass: {N} | Drift: {N} | Fail: {N}

| Test Case | v1 Result | v2 Result | Status | Issue |
|-----------|-----------|-----------|--------|-------|
| greeting  | PASS      | PASS      | OK     | --    |
| edge_case | PASS      | FAIL      | REGRESS | Missing JSON field "status" |

Regressions: {N} requiring attention
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Regressions detected | `[prompt-lab]` to iterate on the prompt fix |
| All tests pass | `[decision-log]` to record the prompt change decision |
| Building test suite | `[eval-suite]` for broader LLM evaluation coverage |
| run regression cases against free-tier models | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
