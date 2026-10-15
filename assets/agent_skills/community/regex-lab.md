---
name: regex-lab
description: Build, test, and explain regular expressions with sample matching, edge case generation, and performance analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "<pattern_or_description> [--action build|test|explain|optimize]"
category: dev-tools
status: candidate
---
# Regex Lab

Interactive regex workbench for building, testing, explaining, and optimizing regular expressions. Given a pattern or a natural language description, produces a tested regex with match examples, edge cases, and performance characteristics. Supports Python re/regex syntax.

## When to Use
- Building a complex regex and want to verify correctness
- Need to understand what an existing regex does (explain mode)
- Testing a regex against edge cases before deploying
- Optimizing a slow regex (catastrophic backtracking detection)

## Execution
1. **Parse input** -- determine if input is a regex pattern or natural language description.
2. **Build** (if `--action build` or input is description):
   - Convert natural language description to regex pattern
   - Generate the simplest correct pattern
   - Provide named group version if applicable
3. **Test** (if `--action test` or default):
   - Generate positive matches (strings that should match)
   - Generate negative matches (strings that should NOT match)
   - Generate edge cases (empty string, Unicode, very long input, special characters)
   - Run all test cases and report results
4. **Explain** (if `--action explain`):
   - Break down the regex token by token
   - Describe each group, quantifier, and assertion
   - Show the regex as a railroad diagram (ASCII)
5. **Optimize** (if `--action optimize`):
   - Check for catastrophic backtracking patterns
   - Suggest atomic groups or possessive quantifiers where applicable
   - Benchmark against test strings
   - Propose simplified alternatives if possible
6. **Report** -- present results with copy-pasteable pattern.

## Output Format
```
Regex Lab | action: {action}

## Pattern
`{regex pattern}`

## Explanation
{token-by-token breakdown}

## Test Results
| Input | Expected | Actual | Groups |
|-------|----------|--------|--------|

## Edge Cases
| Input | Match? | Notes |
|-------|--------|-------|

## Performance
- Backtracking risk: {none|low|high|catastrophic}
- Optimization notes: {suggestions}

## Copy-Paste
Python: `re.compile(r'{pattern}')`
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Pattern built and tested | `[bulk-edit]` to apply regex across codebase |
| Pattern for log parsing | `[cross-repo-grep]` to search across repos |
| Pattern for log analysis | `[log-analyze]` to apply pattern to log files |
