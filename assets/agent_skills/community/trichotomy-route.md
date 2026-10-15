---
name: trichotomy-route
description: Route an artifact to the correct tier (_internal/, _between/, _external/) based on authorship and boundary-crossing. Enforces the Internal/Between/External convention.
version: 0.1.0
execution-mode: advisory
argument-hint: "<file-path> [proposed-tier]"
category: dev-tools
status: candidate
---
# [trichotomy-route]

## When to Use

- Before writing any artifact to `_internal/`, `_between/`, or `_external/` — verify the tier is correct
- When you receive an artifact and need to decide where it lives
- During home directory cleanup to verify existing placements
- When citing a source — the tier determines provenance strength (Tier-A primary vs our analysis)

## The Trichotomy

| Tier | Ontology | Authorship | Provenance |
|---|---|---|---|
| `_internal/` | Latent state | We authored (operator or agent on operator's behalf) | Our analysis (NOT Tier-A primary) |
| `_between/` | Governed transformation | Dual authorship / boundary-crossing event | Audit record of a crossing |
| `_external/` | Observable state | External party authored | Tier-A primary source (strongest) |

## Decision tree

```
Who authored this artifact?
|
+-- We did (operator or our agent)
|   |
|   +-- Did an external party also touch it (review, sign, redline)?
|   |   +-- YES -> _between/ (boundary-crossing event)
|   |   +-- NO  -> _internal/ (our latent state)
|
+-- An external party did
|   |
|   +-- Did we transform it (analysis, annotation, review)?
|   |   +-- YES -> _internal/ (we authored the transformation; original goes to _external/)
|   |   +-- NO  -> _external/ (Tier-A primary source)
|
+-- Both parties (signed contract, multi-agent redline, Krineia receipt)
    -> _between/ (governed transformation)
```

## Subdir routing

### `_internal/` subdirs
| Artifact type | Route to |
|---|---|
| AAR, journal entry, governance memo | `_internal/journal/` |
| Peer review WE wrote of others' work | `_internal/reviews/` |
| Research/analysis we authored | `_internal/research/` |
| Stress-test plans, planning docs | `_internal/stress-test/` or `_internal/planning/` |
| Forensic investigation we authored | `_internal/forensics/` |
| Security analysis we authored | `_internal/security/` |
| Backup snapshots | `_internal/backups/` |
| Fleet-level operator work | `_internal/fleet/` |
| Recovery procedures we authored | `_internal/recovery/` |
| Operator task queue state | `_internal/operator-queue/` |

### `_between/` subdirs
| Artifact type | Route to |
|---|---|
| Peer review RECEIVED from another agent | `_between/peer-reviews/<from-agent>/` |
| Multi-agent handoff packet | `_between/handoffs/<from-to>/` |
| Krineia receipt, bus export, ledger snapshot | `_between/receipts/<event>/` |
| Signed contract or SOW mid-negotiation | `_between/contracts/` |
| Multi-agent redline workflow output | `_between/redlines/` |
| Governance audit material | `_between/audit-trail/` |

### `_external/` subdirs
| Artifact type | Route to |
|---|---|
| NIST/ISO/EU AI Act PDF | `_external/regulators/` |
| Vendor RFP response, demo, eval | `_external/vendors/<vendor>/` |
| Inbound arXiv/SSRN paper | `_external/research-papers/` |
| Client-provided document | `_external/clients/<client>/` |
| Partner-provided template | `_external/partners/<partner>/` |
| Public competitor material | `_external/competitors/` |

## Common misroutes (anti-patterns)

1. **Review we received placed in `_internal/reviews/`** — WRONG. Reviews we *received* go to `_between/peer-reviews/`. `_internal/reviews/` is for reviews we *wrote*.
2. **External PDF placed in `_internal/research/`** — WRONG. The PDF goes to `_external/`. Our *analysis* of the PDF goes to `_internal/research/`.
3. **Signed contract placed in `_internal/`** — WRONG. Both parties touched it; goes to `_between/contracts/`.
4. **Multi-agent handoff placed in `_internal/`** — WRONG. Handoffs are boundary-crossing; go to `_between/handoffs/`.
5. **Our analysis of a regulator doc placed in `_external/`** — WRONG. We authored the analysis; goes to `_internal/research/`. The original PDF stays in `_external/regulators/`.

## Provenance implications

Per `claim-honesty-protocol.md`:
- Citing `_external/<source>/<file>` = **Tier-A primary source** (strongest claim)
- Citing `_internal/<file>` = **our analysis** (not primary source)
- Citing `_between/<file>` = **audit record of a boundary-crossing event**

Misrouting an external PDF to `_internal/` weakens its provenance from Tier-A to "our analysis." Misrouting our analysis to `_external/` falsely elevates our voice to primary source. Both are claim-honesty violations.

## Validation

When validating an existing placement, check:
1. Does the file's authorship match the tier's contract? (Read the README.md in each tier dir)
2. Does the file's content match the subdir's purpose? (See tables above)
3. Does the provenance claim in any citing document match the tier's provenance strength?

If any check fails, move the file to the correct tier and update any path references in citing documents.

## Origin

Created 2026-08-09 to enforce the Internal/Between/External trichotomy revived from expired C2/M0 candidate. The convention was aspirational until this skill provided the routing logic. See `_internal/README.md`, `_between/README.md`, `_external/README.md` for the full contract.
