---
name: threat-model
description: Guided STRIDE threat modeling for a component.
version: 0.1.0
execution-mode: advisory
argument-hint: <component name or file path>
status: tested
category: security
providers:
  required: [bash, python]
---
# Threat Model Command

Perform STRIDE threat analysis on a specific component or module.

## Usage

```bash
[threat-model] delegation_token
[threat-model] bus_writer
[threat-model] services/kill_switch_core.py
```

## Execution

### 1. Read the component
Read the source file(s) for the target component. Understand:
- Entry points (public methods, CLI interfaces, API endpoints)
- Data flow (inputs, outputs, storage, external calls)
- Trust boundaries (authenticated vs unauthenticated, internal vs external)
- Dependencies

### 2. Identify assets
What data or capabilities does this component protect?

### 3. STRIDE analysis
For each entry point, evaluate:

| Threat | Question |
|--------|----------|
| **S**poofing | Can an attacker impersonate a legitimate caller? |
| **T**ampering | Can data be modified in transit or at rest? |
| **R**epudiation | Can actions be denied without evidence? |
| **I**nformation Disclosure | Can sensitive data leak? |
| **D**enial of Service | Can the component be made unavailable? |
| **E**levation of Privilege | Can an attacker gain unauthorized capabilities? |

### 4. Rate each threat
- **Likelihood**: Low / Medium / High
- **Impact**: Low / Medium / High / Critical
- **Risk**: Likelihood x Impact

### Likelihood Calibration Examples

Use these concrete examples to calibrate likelihood ratings. The key boundary
cases are Low vs Medium (when mitigations exist) and Medium vs High (when no
mitigation exists).

| Scenario | Likelihood | Why |
|----------|-----------|-----|
| bcrypt password hashing with constant-time compare | **Low** | Strong, well-tested crypto. Timing attack is theoretically possible but practically infeasible against bcrypt's design. |
| HMAC-SHA256 token signing with a strong (32+ byte random) key | **Low** | Cryptographic forgery is computationally infeasible. Attack would require key compromise, not a direct attack on the mechanism. |
| Tampered request fields (price, quantity) with server-side validation | **Medium** | Validation exists but can be bypassed (edge cases, type confusion, race conditions). Attacker only needs to find one bypass, not break crypto. Not Low because validation is application-layer, not cryptographic. |
| Credential stuffing / brute force on login with **no rate limiting** | **High** | No mitigation exists. Automated tools can attempt thousands of logins per second. Attack is trivially executable with publicly available credential lists. |
| JWT forgery with HS256 and weak/default secret | **High** | Known attack vector (e.g., `none` algorithm, weak secret brute-force). No mitigation if secret is weak or algorithm is not pinned. |
| Credential stuffing with rate limiting (100 req/min) + account lockout | **Medium** | Rate limiting slows but does not stop distributed attacks (botnets, IP rotation). Lockout can be abused for DoS. Partial mitigation reduces but does not eliminate. |
| S3 bucket misconfigured as public | **Low** | Requires a specific misconfiguration event (human error). Not a persistent attack surface — either it's misconfigured or it isn't. Likelihood is the chance of the misconfiguration occurring, not the ease of exploitation. |
| Token replay after logout (revoked token still accepted) | **Low** | Requires a specific implementation bug (revocation list not checked). Not a general attack vector — only exploitable if the bug exists. |
| SQL injection on input with parameterized queries | **Low** | Parameterized queries are a strong, well-understood mitigation. Injection is only possible if the parameterization is bypassed (dynamic SQL, string concatenation). |
| SQL injection on input with manual string escaping | **Medium** | Manual escaping is error-prone and can be bypassed with encoding tricks (multibyte, second-order). Partial mitigation that depends on developer discipline. |

**Key calibration rules:**
- **Low** = strong cryptographic mitigation OR requires a specific rare bug/misconfiguration
- **Medium** = application-layer mitigation that can be bypassed OR partial mitigation OR requires effort but is feasible
- **High** = no mitigation exists OR trivially exploitable with public tools OR known attack vector with weak defenses

## Output Format

```
Threat Model | <component>
══════════════════════════

## Component Overview
- File(s): <path(s)>
- Entry points: <list>
- Assets: <what it protects>
- Trust boundary: <where it sits>

## STRIDE Analysis
| # | Threat | Category | Likelihood | Impact | Risk | Existing Mitigation |
|---|--------|----------|------------|--------|------|---------------------|
| 1 | Forged delegation token | Spoofing | Medium | Critical | High | HMAC-SHA256 signing |
| 2 | Bus message injection | Tampering | Low | Medium | Low | flock mutex |
| ... | ... | ... | ... | ... | ... | ... |

## Recommendations
| # | Recommendation | Priority | Effort |
|---|---------------|----------|--------|
| 1 | Add token expiry validation | P0 | S |
| 2 | Rate-limit bus writes | P2 | M |

## Summary
- Total threats identified: N
- High/Critical risk: N
- Already mitigated: N
- Recommendations: N
```

## Constraints

- Always read the actual source code before analyzing -- do not model from memory.
- Be specific about existing mitigations (reference code lines).
- Recommendations must be actionable with estimated effort (S/M/L).
- Do not fabricate vulnerabilities. Base analysis on actual code patterns.
