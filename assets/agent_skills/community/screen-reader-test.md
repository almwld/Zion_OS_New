---
name: screen-reader-test
description: Test screen reader compatibility and announce accuracy. [Maps to P9.]
version: 0.1.0
execution-mode: advisory
argument-hint: <url-or-file-path>
category: dev-tools
status: candidate
---
# Screen Reader Test Command

Test web content for screen reader compatibility by simulating announcements and verifying accessibility tree accuracy. Helps ensure content is properly conveyed to assistive technology users.

## When to Use
- Validating dynamic content announcements
- Testing ARIA live region effectiveness
- Verifying label and description accuracy
- When user mentions screen reader accessibility requirements
- During accessibility regression testing for AT users

## Execution

### 1. Load Test Target
Retrieve and parse the web content:
- If URL: Fetch and parse HTML/DOM
- If file path: Read and parse local HTML file
- Extract accessibility-relevant elements and attributes

### 2. Simulate Screen Reader Announcements
Use accessibility testing tools to generate what screen readers would announce:
- Element roles, names, descriptions, values
- Live region updates and alerts
- Table structure and header associations
- Form field labels and error messages
- Landmark navigation and heading hierarchy

### 3. Validate Announcement Accuracy
Check for:
- Missing or incorrect accessible names
- Improper role announcements
- Confusing or insufficient descriptions
- Incorrect state announcements (expanded, selected, checked)
- Poor reading order and navigation flow
- Inadequate error messaging

### 4. Generate Compatibility Report
Create detailed feedback on screen reader experience:
- Successes: Well-announced elements
- Issues: Problems with specific elements
- Recommendations: Specific improvements for AT users

## Output Format
```
Screen Reader Test | <url-or-file-path>
════════════════════════════
Target: <test-target>
Test Time: <timestamp>
Simulated SR: <screen-reader-name>

## Summary
- Elements Tested: <count>
- Accessible Names Found: <count>/<total>
- Issues Detected: <count>
- Screen Reader Friendliness: <score>/100

## Accessibility Tree Analysis
<role>: <name> (<description>)
  - State: <state-information>
  - Value: <current-value> (if applicable)
  - Announced As: <what-sr-would-say>

## Issues Found

### Issue 1: Missing Accessible Name
**Element**: <button> (line 45)
**Expected**: Button should have accessible name
**Actual**: No aria-label, aria-labelledby, or inner text
**WCAG**: 4.1.2 Name, Role, Value
**Fix**: Add aria-label="Submit form" or provide inner text

### Issue 2: Confusing Description
**Element**: <div class="status"> (line 102)
**Current**: aria-label="Status: processing"
**Problem**: Too verbose, repeats information
**Suggestion**: Use "Processing" or live region for updates

### Issue 3: Incorrect State Announcement
**Element**: <input type="checkbox" id="newsletter">
**Current**: Not announcing checked state when selected
**Missing**: Properly associated label or aria-checked
**Fix**: Ensure label association or use aria-checked="true"

## Navigation & Flow
**Heading Structure**: H1→H2→H2→H3 (Good)
**Landmark Distribution**: Header(1), Nav(1), Main(1), Footer(1) (Good)
**Tab Order**: Logical and complete (Good)
**Focus Management**: Modals trap focus, returns focus appropriately (Needs Improvement)

## Recommendations
PRIORITY: Fix missing accessible names on interactive elements
NEXT: Verify with actual screen reader testing (VoiceOver, NVDA, JAWS)
Estimated remediation: <S/M/L>
```

## Base120 Context
- Primary: **P9** (Cultural Adaptation - ensuring equivalent experience)
- Related: **DE5** (Finding vital few communication issues), **IN6** (Verifying announcement accuracy)

## After Completion
Naturally chains to: `[a11y-audit]` for complementary testing, or `[commit]` after fixes
