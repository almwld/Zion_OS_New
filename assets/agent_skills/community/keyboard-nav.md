---
name: keyboard-nav
description: Test keyboard navigation and focus management for accessibility compliance. [Maps to P9.]
version: 0.1.0
execution-mode: advisory
argument-hint: <url-or-file-path>
category: governance-compliance
status: candidate
---
# Keyboard Navigation Test Command

Evaluate web content for keyboard accessibility including tab order, focus visibility, keyboard traps, and accessibility of all interactive elements via keyboard alone.

## When to Use
- Ensuring all functionality is keyboard accessible
- When user mentions keyboard accessibility requirements
- Testing custom widgets and complex interactions
- Validating modal dialogs, dropdowns, and dynamic content
- During accessibility regression testing

## Execution

### 1. Load Test Target
Retrieve and prepare the web content for testing:
- If URL: Fetch and parse HTML with JavaScript execution enabled
- If file path: Load local file in test environment
- Initialize keyboard testing automation

### 2. Simulate Keyboard Navigation
Execute comprehensive keyboard testing:
- **Tab Order**: Navigate through all focusable elements in sequence
- **Reverse Tab Order**: Navigate with Shift+Tab to verify bidirectional flow
- **Enter/Space Activation**: Test activation of buttons, links, and controls
- **Arrow Key Navigation**: Test menus, grids, tabs, and custom widgets
- **Escape Key Handling**: Test closing of dialogs, menus, and popups
- **Home/End Keys**: Test navigation to first/last elements in containers
- **Page Up/Down**: Test scrolling behavior where applicable

### 3. Validate Focus Management
Check for proper focus handling:
- **Visible Focus Indicator**: Ensure focus is clearly visible (WCAG 2.4.7)
- **No Focus Loss**: Verify focus doesn't disappear unexpectedly
- **Logical Order**: Confirm tab order follows visual/logical flow
- **No Keyboard Traps**: Ensure users can navigate into and out of all components
- **Modal Focus**: Verify focus is trapped in modals and returned appropriately
- **Skip Links**: Test presence and functionality of skip navigation links

### 4. Identify Accessibility Barriers
Find elements that cannot be used via keyboard:
- Mouse-only event handlers (onclick without keyboard equivalent)
- Custom widgets lacking keyboard support
- Elements with pointer events that block keyboard access
- Dropdowns that require mouse hover to activate
- Date pickers or complex widgets without keyboard alternatives

### 5. Generate Accessibility Report
Document findings with specific examples and remediation guidance.

## Output Format
```
Keyboard Nav Test | <url-or-file-path>
════════════════════════════
Target: <test-target>
Test Time: <timestamp>
Keyboard Tests Performed: <count>

## Summary
- Keyboard Accessible Elements: <count>/<total-interactive>
- Focus Visibility Issues: <count>
- Keyboard Traps Found: <count>
- Mouse-Only Dependencies: <count>
- Overall Keyboard Accessibility Score: <score>/100

## Tab Order Analysis
**Logical Flow**: <assessment> (e.g., "Generally follows visual order with exceptions")
**Tab Stops**: <number> focusable elements found
**First Tab Stop**: <element-description> (should be skip link or header)
**Last Tab Stop**: <element-description> (should be footer or help link)

## Focus Visibility
<if focus-issues>
### Missing or Poor Focus Indicators
1. **Element**: <button class="btn"> (line 45)
   **Issue**: No visible focus indicator when keyboard focused
   **Current**: Relies on browser default (may be insufficient)
   **WCAG**: 2.4.7 Focus Visible
   **Fix**: Add custom focus style: `outline: 2px solid #0066cf;` or similar

2. **Element**: .custom-widget (applied to multiple elements)
   **Issue**: Focus outline removed via CSS (`outline: none;`)
   **Current**: No visible focus indication
   **Fix**: Replace with visible alternative: `outline: 2px solid currentColor;`
<else>
✅ All interactive elements have visible focus indicators
## End If

## Keyboard Traps
<if traps-found>
### Elements Causing Keyboard Traps
1. **Component**: <modal-dialog id="newsletter-popup">
   **Issue**: Focus enters modal but cannot exit with Tab/Shift+Tab
   **Current**: Focus cycles only within modal content
   **WCAG**: 2.1.2 No Keyboard Trap
   **Fix**: Ensure focus returns to trigger element when modal closes
   **Test**: Tab into modal, attempt to tab out, verify focus returns to launcher

2. **Component**: <custom-dropdown>
   **Issue**: Focus enters dropdown menu but Escape doesn't close it
   **Current**: Requires mouse click outside to dismiss
   **Fix**: Add Escape key listener to close dropdown and return focus
<else>
✅ No keyboard traps detected - users can navigate into and out of all components
## End If

## Mouse-Only Dependencies
<if mouse-only-found>
### Functions Requiring Mouse
1. **Element**: <div class="slider"> (line 102)
   **Issue**: Slider only operable via mouse drag
   **Missing**: Arrow key support for increment/decrement
   **WCAG**: 2.1.1 Keyboard
   **Fix**: Add keydown handlers for ArrowLeft/Right, PageUp/Down, Home/End

2. **Element**: <div class="date-picker"> (line 156)
   **Issue**: Calendar requires mouse to select dates
   **Missing**: Keyboard navigation for month/year and date selection
   **Fix**: Implement arrow key navigation, Enter/Space to select date
<else>
✅ All functionality accessible via keyboard alone
## End If

## Custom Widget Assessment
<if custom-widgets-found>
### ARIA Keyboard Support
1. **Widget**: <role="menu"> (line 200)
   **Issue**: Missing arrow key navigation between menu items
   **Current**: Only first item accessible via Tab
   **Required**: Left/Right arrow navigation, Home/End, Escape to close
   **Pattern**: Follow ARIA Authoring Practices Guide for menubar

2. **Widget**: <role="tablist"> (line 250)
   **Issue**: Tabs not activatable via Enter/Space
   **Current**: Focusable but not activatable
   **Required**: Enter/Space to activate associated tabpanel
   **Pattern**: Follow ARIA Authoring Practices Guide for tabs
<else>
✅ Custom widgets follow ARIA keyboard interaction patterns
## End If

## Recommendations
PRIORITY: Ensure all interactive elements have visible focus indicators
SECONDARY: Fix keyboard traps in modals and dropdowns
NEXT: Test with actual assistive technologies or run [a11y-audit]
Estimated remediation effort: <S/M/L>

## Base120 Context
- Primary: **P9** (Cultural Adaptation - ensuring operable interface)
- Related: **DE5** (Finding vital few navigation issues), **IN6** (Verifying keyboard accessibility claims)

## After Completion
Naturally chains to: Fix identified issues, then run `[a11y-audit]` for full verification, or `[commit]` after fixes
