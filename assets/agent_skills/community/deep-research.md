---
name: deep-research
description: Fork an isolated research agent without polluting context.
version: 0.1.0
execution-mode: advisory
argument-hint: <research topic or question>
category: hummbl-research
status: candidate
---
# Deep Research Command

Spawn an isolated research agent to investigate a topic without polluting the main conversation context.

## Usage

```bash
[deep-research] How does the circuit breaker reset logic work?
[deep-research] What are best practices for HMAC token rotation in 2026?
[deep-research] Compare our IDP implementation to industry standards
[deep-research] Find all places where bus writes bypass bus_writer
```

## Execution

### 1. Classify the research type

| Type | Agent | Description |
|------|-------|-------------|
| Codebase | `Explore` | Search files, read code, trace call paths |
| Web | `general-purpose` | Search the web, fetch docs, synthesize |
| Mixed | `general-purpose` | Both codebase and web research |

### 2. Craft the agent prompt
Include in the prompt:
- The specific question from `$ARGUMENTS`
- Whether to search codebase, web, or both
- Instruction to return structured findings
- Instruction to NOT modify any files

### 3. Launch the agent
```
Task tool with:
  subagent_type: Explore (codebase) or general-purpose (web/mixed)
  prompt: <crafted research prompt>
```

### 4. Present results
When the agent returns, present findings in a structured format.

## Output Format

```
Deep Research | <topic summary>
═══════════════════════════════

## Question
<the original research question>

## Method
<what was searched: files, web, both>
<key sources consulted>

## Findings
<numbered findings with evidence>

1. **<finding>**
   - Source: <file:line or URL>
   - Evidence: <quote or summary>

2. **<finding>**
   ...

## Conclusion
<synthesis of findings, direct answer to the question>

## Further Reading
<related files, docs, or URLs for deeper exploration>
```

## Constraints

- **Research only.** The spawned agent must NOT modify any files.
- Always specify the research-only constraint in the agent prompt.
- Present the agent's findings faithfully -- do not embellish or fabricate.
- If the research requires multiple rounds, launch sequential agents rather than one massive prompt.
- For codebase research, prefer `Explore` agent (faster, lower cost).

## Live Data Sources
For scholarly, regulatory, and vulnerability data, use the free_apis tool:
```bash
python ~/bin/free_apis.py openalex search "<topic>" --limit 25   # 250M scholarly works
python ~/bin/free_apis.py pubmed search "<topic>" --limit 25     # biomedical literature
python ~/bin/free_apis.py fedreg search "<topic>" --limit 25     # US federal register
python ~/bin/free_apis.py wikidata search "<entity>" --limit 5   # structured knowledge
```
See `[claim-verify]` skill for evidence-grading integration with these sources.
- For web research, use a `general-purpose` research agent with explicit source and citation constraints.
