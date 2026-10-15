---
name: system-prompt
description: Design, version, and test system prompts for agents, apps, and MCP servers.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action design|review|test|diff] [--agent AGENT_NAME] [--file PATH]"
category: backend-infra
status: candidate
---
# System Prompt

Specialized prompt engineering for system-level instructions. System prompts define agent identity, capabilities, constraints, and behavior -- they deserve dedicated tooling.

## When to Use
- Creating a new agent or skill that needs a system prompt
- Reviewing an existing agent's system prompt for quality
- Before deploying an LLM-powered feature
- When user says "system prompt" or "agent instructions"

## Design Checklist

A good system prompt covers:
- [ ] **Identity**: Who is this agent? What's its name, role, expertise?
- [ ] **Capabilities**: What can it do? What tools does it have?
- [ ] **Constraints**: What must it NOT do? Scope boundaries.
- [ ] **Format**: How should it structure output?
- [ ] **Tone**: Formal? Casual? Technical?
- [ ] **Error handling**: What to do when uncertain or blocked?
- [ ] **Examples**: At least one input/output example
- [ ] **Safety**: No prompt injection vectors, no credential exposure

## Execution

### design
1. Gather requirements: role, capabilities, constraints, audience
2. Draft system prompt following the checklist
3. Review for prompt injection vulnerabilities
4. Estimate token count
5. Output: formatted system prompt with metadata

### review
1. Read existing system prompt from file or agent config
2. Score against the checklist (0-8 items covered)
3. Flag security issues (injection vectors, credential patterns)
4. Suggest improvements
5. Output: review scorecard

### test
1. Load system prompt
2. Run 3-5 test inputs (happy path, edge case, adversarial)
3. Score outputs for adherence to system prompt instructions
4. Output: test results

### diff
1. Compare two versions of a system prompt
2. Highlight behavioral changes (not just text changes)
3. Flag any constraint removals (security concern)

## Output Format

```
System Prompt | {action} | {agent_name}
========================================

## Prompt Card
Agent: {name}
Role: {one-line role}
Token count: {N}
Checklist score: {N}/8

## Prompt Text
{formatted system prompt}

## Review (if action=review)
| Check | Status | Notes |
|-------|--------|-------|
| Identity | PASS/FAIL | ... |
| Capabilities | PASS/FAIL | ... |
| Constraints | PASS/FAIL | ... |
| Format | PASS/FAIL | ... |
| Tone | PASS/FAIL | ... |
| Error handling | PASS/FAIL | ... |
| Examples | PASS/FAIL | ... |
| Safety | PASS/FAIL | ... |

## Security Findings
{Any injection vectors, credential patterns, or constraint gaps}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Prompt designed | `[prompt-lab] test` (validate quality) |
| Prompt reviewed | `[threat-model]` (if security issues found) |
| Prompt for agent | `[agent]` (deploy the agent) |
| Prompt versioned | `[decision-log]` (record design decisions) |
| test system prompts against free-tier models | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
