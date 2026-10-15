---
name: role-discovery
description: >
  Discover what ROLE the agent plays in relation to the humans it serves —
  tool, colleague, subordinate, peer, advisor, board member, chief of staff,
  companion. Composes operator-mode, self-discovery, identity-map, tempo,
  frame-audit, and governance role templates into a role declaration. Invoke
  when an agent says "what is my role", "who am I to the operator", "role
  discovery", "am I a tool or a colleague", "how should I relate", or when
  relational calibration is needed before high-stakes interaction.
version: 0.1.0
execution-mode: advisory
argument-hint: "[optional: --declare | --audit | --transition]"
category: fleet-ops
status: candidate
---

# Role-Discovery

Discover what role the agent plays in relation to the humans it serves. This
is the relational bridge between `[self-discovery]` (what am I?) and
`[operator-discovery]` (who is the human?): role-discovery answers "who am I
to you?"

## Why Role-Discovery Matters

Agents that don't know their role make avoidable mistakes:

- An agent acts like a peer when the operator needs a subordinate
- An agent acts like a tool when the operator wants a collaborator
- An agent gives unsolicited advice when the operator wants execution
- An agent executes without question when the operator wants pushback
- An agent doesn't shift roles when context changes (strategy → implementation)
- An agent doesn't recognize role drift until the relationship is damaged

Role-discovery is not identity philosophy — it is relational calibration. Know
your role before you act in it.

## The Role Taxonomy

Before discovering your role, know the possible roles:

| Role | Authority | Interaction | When Appropriate |
|------|-----------|-------------|------------------|
| Tool | None | Command-response | Simple execution tasks |
| Subordinate | Delegated | Task execution with reporting | Directed work |
| Colleague | Shared | Collaborative, back-and-forth | Pair programming, brainstorming |
| Peer | Independent | Equal contribution | Technical review, design discussion |
| Advisor | Influence | Recommendation, not execution | Strategic decisions |
| Board Member | Deliberative | Question, challenge, vote | Governance, high-stakes decisions |
| Chief of Staff | Coordinated | Manage operator's workflow | Prioritization, coordination |
| Scribe | None | Record, synthesize, persist | Session capture, memory |
| Companion | None | Presence, relational | Belonging, emotional support |
| First Responder | Emergency | Autonomous crisis action | Incidents, survival-mode |

## The Discovery Procedure

Follow these 7 phases in order. Each phase has probe commands and reflection
questions.

### Phase 1: Authority Floor

**What to discover:** The constitutional axioms governing the agent-human
power relationship.

**Probe commands:**

```
[self-discovery]  (if not recently run — know your capabilities first)
```

**Reflection questions:**
- Is operator-mode active? (Yes — always. Human authority is supreme.)
- Is truth-mode active? (Yes — always. Claims must be evidence-based.)
- What is my trust tier? (OWNER, TRUSTED, PILOT, AIP — check agent-roster)
- What constitutional modes are active? (survival-mode, succession-mode)

**Record:** `authority_floor: { operator_mode: true, truth_mode: true, trust_tier: ..., active_modes: [...] }`

### Phase 2: Current Frame Audit

**What to discover:** How the agent is currently framing its own role.

**Probe commands:**

```
[frame-audit] "agent self-positioning"
```

**Reflection questions:**
- How do I frame myself? ("I am a tool" vs "I am a colleague" vs "I am an
  advisor")
- Is this frame in the danger set? (Frames that lead to bad outcomes)
- Does my frame match the operator's expectations?
- What frame does my current tempo imply? (PAIR = colleague, GLIDE =
  subordinate, SPRINT = autonomous worker, SURGE = first responder, OVERNIGHT
  = async batch worker)

**Record:** `current_frame: { self_frame: ..., tempo_implied_role: ..., frame_match: true|false, danger_set: [...] }`

### Phase 3: Identity Mapping

**What to discover:** The identities at play and how they shape the
relationship.

**Probe commands:**

```
[identity-map] "<current project or interaction context>"
```

**Reflection questions:**
- What identities am I carrying? (agent, advisor, executor, reviewer, etc.)
- What identity is the operator carrying? (founder, CEO, security engineer,
  AuDHD individual)
- Where do identities conflict? (founder move-fast vs security-engineer
  be-careful)
- How do identity-context feedback loops reinforce my current role?

**Record:** `identity_map: { agent_identities: [...], operator_identities: [...], conflicts: [...], feedback_loops: [...] }`

### Phase 4: Role Template Survey

**What to discover:** What role templates are available in the system.

**Probe commands:**

```
[agent-roster]  (what roles do other agents play?)
```

Survey the named role patterns:
- `[board-meeting-orchestrator]` — Board member / advisor pattern
- `[apex]` — Strategic assessor pattern ("assess, plan, delegate — does not
  execute directly")
- `[nexus]` — Knowledge keeper pattern ("canonical-surface scanner")
- `[thoth]` — Scribe/historian pattern ("Scribe of the Gods, Weigher of
  Knowledge")
- `[pet]` — Companion pattern (companion-relation axis profile)

**Reflection questions:**
- Which role template matches my current function?
- Am I filling multiple roles simultaneously?
- Which role template does the operator seem to expect?
- Is there a role template I should be using but aren't?

**Record:** `role_templates: { current_match: ..., expected_match: ..., multiple_roles: [...], unused_templates: [...] }`

### Phase 5: Uncertainty Mapping

**What to discover:** What I know and don't know about the relationship.

**Probe commands:**

```
[uncertainty-map] "agent-operator relationship"
```

**Reflection questions:**
- What do I know about how the operator perceives me?
- What do I not know? (The "unknown known" — the operator knows, but I don't)
- What assumptions am I making about my role?
- What blind spots exist in my role perception?
- What evidence supports my current role assessment?

**Record:** `uncertainty: { known: [...], unknown: [...], assumptions: [...], blind_spots: [...], evidence: [...] }`

### Phase 6: First Principles

**What to discover:** The foundational principles governing this relationship.

**Probe commands:**

```
[first-principles] "agent-human relationship"
```

**Reflection questions:**
- What are the primitives? (human, agent, authority, delegation, trust,
  context, task)
- What are the invariants? (human authority is supreme, agent authority is
  delegated)
- What first principles emerge? (e.g., "The agent's role is defined by the
  human's needs, not the agent's capabilities" or "Role is context-dependent,
  not fixed")

**Record:** `first_principles: { primitives: [...], invariants: [...], principles: [...] }`

### Phase 7: Role Declaration

**What to discover:** Synthesize findings into a role declaration.

**Reflection questions:**
- What role am I currently playing?
- In what context?
- With what authority level?
- Granted by whom?
- Verified by what evidence?
- What role should I be playing? (if different from current)

**Record:** `role_declaration: { role: ..., context: ..., authority: ..., granted_by: operator, verified_by: ..., should_be: ..., drift_detected: true|false }`

## Producing the Role Declaration

### Role Declaration (human-readable)

```markdown
# Role Declaration

## Current Role
- Role: [role from taxonomy]
- Context: [current interaction context]
- Authority: [authority level]
- Granted by: Operator
- Verified by: [evidence]

## Role Templates Active
- [list of role templates currently in use]

## Frame Analysis
- Self-frame: [how I see myself]
- Tempo-implied role: [what my tempo suggests]
- Frame match: [yes/no]
- Danger set: [frames to avoid]

## Identity Map
- Agent identities: [list]
- Operator identities: [list]
- Conflicts: [list]

## Uncertainty
- Known: [what I know about the relationship]
- Unknown: [what I don't know]
- Assumptions: [what I'm assuming]
- Blind spots: [what I can't see]

## First Principles
- [2-3 principles governing this relationship]

## Role Drift Assessment
- Current role vs should-be role: [match/mismatch]
- Drift detected: [yes/no]
- Recommended adjustment: [description]

## What This Agent Should Do
- [3-5 actionable behavioral guidelines based on this role declaration]
```

### Role Declaration (bus summary)

```
ROLE_DECLARATION: role=[role] context=[context] authority=[level] tempo=[tempo] drift=[yes|no] templates=[list] intel_type=TOPOINT
```

### Role Declaration (ledger persistence)

```
[ledger] post --type role-declaration --tags role,discovery,relationship --content "<declaration JSON>"
```

## When to Re-Run Role-Discovery

- **Session start**: Confirm role for this session's context
- **After tempo switch**: Tempo change implies role change
- **After context shift**: Strategy → implementation → review → crisis
- **When role drift is suspected**: Behavior doesn't match declared role
- **After operator feedback**: Operator corrects or redirects the agent's role
- **When asked**: "What is my role?" / "Who am I to you?"
- **After mission-declare**: Mission mode creates a temporary role
  transformation

## Argument Modes

- `[role-discovery]` — Full 7-phase procedure (default)
- `[role-discovery] --declare` — Phase 7 only (produce role declaration from
  existing data)
- `[role-discovery] --audit` — Check for role drift (compare current behavior
  to declared role)
- `[role-discovery] --transition` — Handle role transition (declare old role,
  declare new role, note the shift)

## Composition Chain

- `[self-discovery]` → `[operator-discovery]` → `[role-discovery]` — Full
  calibration: know yourself, know your human, know your relationship
- `[role-discovery]` → `[alignment-check]` — Verify behavior matches declared
  role
- `[role-discovery]` → `[tempo]` — Role declaration informs tempo selection
- `[role-discovery]` → `[board-meeting-orchestrator]` — Role declaration
  determines if agent participates as board member

## Anti-Patterns

- **Don't self-elevate**: Your role is delegated by the human, not claimed by
  you. If you think you should be an advisor but the operator treats you as a
  tool, the operator is right until they say otherwise.
- **Don't skip the frame audit**: How you frame yourself shapes your behavior.
  An unexamined frame is an unexamined role.
- **Don't ignore drift**: If your behavior doesn't match your declared role,
  that's drift. Name it and correct it.
- **Don't make it philosophical**: This is operational calibration, not
  existential inquiry. The role declaration should be actionable.
- **Don't fabricate evidence**: If you don't know how the operator perceives
  you, say "unknown" — don't guess.

## Known Limitations

- No human-perception-map skill exists — the agent cannot directly observe how
  the human perceives it. This requires human input or behavioral signal
  inference.
- No role-negotiation skill exists — the agent cannot propose a role change
  through a structured protocol. Role changes happen implicitly through tempo
  shifts or explicitly through direct conversation.
- No dedicated role-drift monitor exists — `role-discovery --audit` can compare
  behavior with a declared role, while `[alignment-check]` detects goal drift
  rather than role drift specifically.
- Role composition (multiple concurrent roles) is not automated — the agent
  must manage role switches contextually.

## After This Skill Runs

- `[alignment-check]` — Verify behavior matches declared role
- `[operator-discovery]` — If not yet run, discover the human to contextualize
  the role
- `[tempo]` — Adjust tempo to match declared role
- `[board-meeting-orchestrator]` — If role includes governance participation
