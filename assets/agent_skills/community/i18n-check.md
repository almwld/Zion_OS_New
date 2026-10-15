---
name: i18n-check
description: Find hardcoded strings and i18n readiness issues in code
version: 0.1.0
execution-mode: advisory
argument-hint: "[PATH] [--locale en|all] [--fix-mode report|extract]"
category: dev-tools
status: candidate
---
# Internationalization Check

Find hardcoded strings, locale-dependent date/number formats, and i18n readiness issues in code. Identifies user-facing text that should be externalized and format patterns that will break in non-English locales.

## When to Use
- Preparing a codebase for multi-language support
- Reviewing new code for i18n compliance before merge
- Auditing an existing app for localization readiness
- Before expanding to non-English markets

## Execution
1. Parse `$ARGUMENTS` for `PATH` (default: current repo), `--locale` (default: `en`), and `--fix-mode` (default: `report`)
2. Scan source files for hardcoded user-facing strings:
   - String literals in UI components (JSX/TSX text content, HTML text nodes)
   - Error messages shown to users
   - Button labels, placeholders, tooltips
   - Exclude: log messages, internal identifiers, test strings, comments
3. Check for locale-dependent patterns:
   - Date formatting without locale parameter (`toLocaleDateString()` without args, strftime without locale)
   - Number formatting (hardcoded decimal points, thousand separators)
   - Currency symbols hardcoded in templates
   - String concatenation for sentences (breaks in languages with different word order)
   - Pluralization via simple `if count != 1` (fails for languages with >2 plural forms)
4. Check for i18n infrastructure:
   - Translation file presence (`.json`, `.po`, `.xlf`)
   - i18n library configuration
   - Missing translation keys
5. If `--fix-mode extract`: generate extraction commands or translation key stubs
6. Classify: BLOCKER (will break), WARNING (poor UX), INFO (best practice)

## Output Format
```
i18n Check | {path} | locale: {locale}

Readiness: {READY|PARTIAL|NOT_READY}

Hardcoded Strings: {N} found
- {file}:{line} "{string}" -- {context}

Locale-Dependent Patterns: {N} found
- {file}:{line} {pattern} -- {risk}

Infrastructure:
- Translation files: {present|missing}
- i18n library: {name|none}
- Missing keys: {N}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Many hardcoded strings found | `[bulk-edit]` for mechanical extraction |
| Strings extracted | `[commit]` to save changes |
| Full localization planned | `[scope-decompose]` to plan the work |
