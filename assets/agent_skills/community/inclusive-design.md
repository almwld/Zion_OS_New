---
name: inclusive-design
description: Apply inclusive design principles and practices for accessible, equitable user experiences. [Maps to P9.]
version: 0.1.0
execution-mode: advisory
argument-hint: <design-spec-or-component-path>
category: dev-tools
status: candidate
---
# Inclusive Design Guidance Command

Provide guidance on applying inclusive design principles to create accessible, equitable user experiences that work for diverse abilities, ages, cultures, and contexts.

## When to Use
- Starting new design projects or redesigns
- When user mentions inclusive or universal design requirements
- Reviewing existing designs for inclusivity gaps
- Developing design systems or component libraries
- Ensuring compliance with accessibility and inclusion standards

## Execution

### 1. Parse Design Input
Accept various forms of design input:
- Design specifications or requirements documents
- Component or UI mockups (describe or reference)
- User stories or accessibility requirements
- Existing codebases to audit for inclusivity
- Style guides or design tokens

### 2. Apply Inclusive Design Principles
Evaluate against core inclusive design dimensions:
- **Equitable Use**: Design is useful and marketable to people with diverse abilities
- **Flexibility in Use**: Accommodates a wide range of individual preferences and abilities
- **Simple and Intuitive**: Easy to understand regardless of user experience or concentration level
- **Perceptible Information**: Communicates necessary information effectively to user
- **Tolerance for Error**: Minimizes hazards and adverse consequences of accidental actions
- **Low Physical Effort**: Can be used efficiently and comfortably with minimum fatigue
- **Size and Space for Approach**: Appropriate size and space provided for approach, reach, manipulation

### 3. Consider Diversity Factors
Address diverse user characteristics:
- **Ability**: Vision, hearing, mobility, cognition, neurodiversity
- **Age**: Children, adults, elderly users
- **Culture**: Language, literacy, cultural norms, symbols
- **Context**: Lighting, noise, connectivity, device constraints
- **Technology**: Assistive tech, bandwidth, device capabilities

### 4. Generate Inclusive Recommendations
Provide specific, actionable guidance for improving inclusivity:
- Design pattern suggestions
- Alternative interaction methods
- Content and language considerations
- Technical implementation approaches
- Testing and validation strategies

## Output Format
```
Inclusive Design | <design-spec-or-component-path>
═════════════════════════════
Target: <design-target>
Analysis Time: <timestamp>
Principles Applied: <list>

## Summary
- Inclusivity Score: <score>/100
- Strengths: <count> areas
- Improvement Areas: <count> areas
- Critical Gaps: <count> requiring attention

## Equitable Use Assessment
<if strengths>
### What Works Well
1. **Feature**: <description>
   **Strength**: Works well for users with varying abilities
   **Example**: <specific-example>
<else>
### Improvement Needed
1. **Aspect**: <description>
   **Gap**: May disadvantage users with certain abilities
   **Impact**: <description-of-impact>
   **Recommendation**: <specific-suggestion>
## End If

## Flexibility in Use
<if strengths>
### Flexible Features
1. **Feature**: <description>
   **Strength**: Accommodates different user preferences
   **Options**: <list-of-options>
<else>
### Rigid Elements
1. **Element**: <description>
   **Issue**: Forces single way of interaction
   **Alternative**: Provide multiple ways to accomplish task
## End If

## Simple and Intuitive
<if clarity-issues>
### Complexity Concerns
1. **Element**: <description>
   **Issue**: May be confusing for users with cognitive load
   **Simplification**: Reduce steps, use familiar conventions
   **Testing**: Verify with users having varying literacy levels
<else>
✅ Design follows conventions for easy understanding
## End If

## Perceptible Information
<if perception-gaps>
### Information Accessibility
1. **Information**: <description>
   **Gap**: Relies solely on <sensory-mode> (color, sound, etc.)
   **Solution**: Provide redundant modes (visual + text + audio)
   **Example**: Add text labels to color-coded status indicators
<else>
✅ Information available through multiple sensory channels
## End If

## Tolerance for Error
<if error-prone>
### Error Prevention
1. **Action**: <description>
   **Risk**: Easy to make mistakes with serious consequences
   **Protection**: Implement undo, confirmation, or constraints
   **Example**: Add "Are you sure?" for destructive actions
<else>
✅ Good error prevention and recovery mechanisms
## End If

## Low Physical Effort
<if effort-concerns>
### Ergonomic Issues
1. **Interaction**: <description>
   **Concern**: Requires sustained pressure or fine motor control
   **Alternative**: Use larger touch targets, reduce required precision
   **Standard**: Follow minimum target size guidelines (44x44 dp)
<else>
✅ Interactions designed for comfortable use
## End If

## Size and Space
<if space-issues>
### Spatial Constraints
1. **Element**: <description>
   **Issue**: Difficult to reach or manipulate for some users
   **Adjustment**: Increase size, improve positioning, provide alternatives
   **Consideration**: One-handed use, left-handed users, assistive devices
<else>
✅ Adequate space provided for approach and use
## End If

## Diversity Considerations
<if diversity-gaps>
### User Diversity
1. **Factor**: <vision/hearing/cognition/culture/etc>
   **Consideration**: <specific-need>
   **Recommendation**: <design-adjustment>
<else>
✅ Design accounts for major user diversity factors
## End If

## Actionable Recommendations
PRIORITY: <most-critical-inclusivity-improvement>
SHORT TERM: <next-steps-within-2-weeks>
LONG TERM: <strategic-inclusivity-improvements>

## Implementation Guidance
- **Testing**: Involve diverse users in usability testing
- **Validation**: Use accessibility tools + real user feedback
- **Documentation**: Record inclusivity decisions in design system
- **Training**: Educate team on inclusive design principles

## Base120 Context
- Primary: **P9** (Cultural Adaptation - designing for human diversity)
- Related: **DE5** (Finding vital few inclusivity improvements), **SY13** (Designing equitable systems)

## After Completion
Naturally chains to: Implement recommendations, then run specific audits ([a11y-audit], [color-contrast], etc.) for validation
