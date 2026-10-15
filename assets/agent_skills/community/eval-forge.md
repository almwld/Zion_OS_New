---
provider-specific: true
name: eval-forge
description: >
  Forge self-validating eval suites for side-effecting agent skills. Three modes:
  forge (build eval suite for a target skill), arbiter (meta-evaluate an eval
  skill/pipeline including itself), self-check (run eval-forge's own eval suite
  against itself). Code-first, judge-second, binary everywhere, validate before
  trusting. Use when a wargame/audit surfaces a "no eval suite" gap, when
  promoting a side_effecting skill from candidate to tested, or when you need
  to close the recursive validation gap that external eval skills have. Do NOT
  use for LLM text output only (use eval-suite) or without error analysis first.
version: 0.1.1
status: tested
execution-mode: side_effecting
argument-hint: "[--mode forge|arbiter|self-check] [--target <skill-name>] [--wargame <audit-doc>]"
schema_version: 0.1.0
category: backend-infra
providers:
  required: [python]
---

# eval-forge

Forge self-validating eval suites for side-effecting agent skills â€” a judge that judges judges, and validates itself using its own procedure.

## When to Use

- After a wargame or audit surfaces a "no eval suite" gap (e.g., `ops-gameboard` P2 finding) and you need to build one
- When inheriting an agent skill that mass-mutates state (labels, files, git) and you need to verify it does so correctly
- When you want to meta-evaluate an eval skill/pipeline (arbiter mode) â€” including evaluating `eval-forge` itself
- Before promoting a `side_effecting` skill from `candidate` â†’ `tested` (the eval suite is the promotion gate)
- When the operator says "build an eval suite for X", "validate this skill", "can we trust this evaluator", "audit the eval pipeline"
- When you need eval output that `skill-audit` can consume (PROMOTION_GATES, confusion_matrix)
- When you need to close the recursive validation gap that all 6 external eval skills have (none can validate themselves)

## When NOT to Use

- For evaluating LLM text output only (use `eval-suite` for accuracy/latency/cost, or `phoenix-evals` if you're on Phoenix)
- For building a judge without error analysis first (the forge pipeline starts with error analysis â€” skip it and you're building on sand)
- For skills that are purely advisory/read-only with no side effects (overkill â€” a simple test file suffices)
- When you need a survey of LLM eval metrics (use `llm-evaluation` as a reference, but note its anti-patterns per the arbiter audit)
- When the target is a one-off script, not a reusable skill (eval-forge produces reusable eval suites, not throwaway tests)
- As a replacement for unit tests (eval-forge complements unit tests; it does not replace them â€” deterministic code paths still need direct tests)

## The three modes

### Forge mode (`--mode forge --target <skill-name>`)

Build a self-validating eval suite for a target side-effecting skill. The 7-step pipeline is in `references/forge-pipeline.md`. Summary:

1. **Error analysis** â€” read ~100 traces, categorize failures (or use `--wargame <audit-doc>` shortcut)
2. **Classify failures** â€” code-checkable-on-state, code-checkable-on-output, or judgment-required
3. **Build Layer 0** â€” deterministic invariants (state-transition, output, log checks)
4. **Build Layer 1** â€” binary LLM judges for judgment-required failures (4-component rule)
5. **Validate Layer 1** â€” TPR/TNR > 90% on held-out test set against human labels
6. **Generate eval suite** â€” `scorer.py` + `corpus/case_*.json` (skill-audit compatible)
7. **Self-check** â€” run eval-forge's own eval suite against itself (recursion closure)

### Arbiter mode (`--mode arbiter --target <eval-skill-or-pipeline>`)

Meta-evaluate an eval skill/pipeline using `eval-audit`'s 6 diagnostic areas + the recursive consistency check. The rubric is in `references/arbiter-rubric.md`. Produces a verdict table (PASS/PARTIAL/FAIL per area) + recursive violations list. Can target eval-forge itself (the recursion closure).

### Self-check mode (`--mode self-check`)

Run eval-forge's own eval suite against itself. Verifies all 7 invariants hold. If any invariant fails, self-check fails and the skill cannot be promoted. This is the mode that closes the recursive validation gap (RV1/RV2/RV3 from the arbiter audit).

## The 7 invariants (enforcement core)

These are non-negotiable. If any invariant is violated, the skill cannot be promoted from `candidate` to `tested`. self-check mode verifies all 7.

1. **Recursive self-validation** â€” the skill ships its own eval suite that tests its own invariants. self-check mode runs it. The skill is a judge that judges judges, and validates itself using its own procedure.
2. **Code-first, judge-second** â€” Layer 0 (deterministic invariants) is always built before Layer 1 (LLM judges). LLM judges are only for criteria code cannot check. Never use an LLM judge for something a regex, schema validation, assertion, or state-transition check can verify.
3. **Skill-aware, not just text-aware** â€” evaluates side-effecting agent skills (git mutations, label applications, file writes), not just LLM text output. Captures state before/after the skill runs and checks invariants on state transitions.
4. **Binary everywhere** â€” all judges are binary pass/fail. No Likert scales, no letter grades, no pointwise scoring. If you need severity, use multiple binary judges.
5. **Validate before trusting** â€” no judge marked `validated: true` is trusted until it passes >90% TPR and >90% TNR on a held-out test set against independent, blinded domain-expert labels, with raw responses, a completed execution receipt, an exact model snapshot ID, and 95% confidence lower bounds above 0.90. Minimum acceptable: >80% (with documented reason). Below 80% = judge is broken. Judges marked `validated: false` are flagged "do not trust" and fail the `all_layer_1_validated` promotion gate, but do not fail this invariant â€” the invariant distinguishes "validated and broken" from "honestly unvalidated."
6. **Arbiter mode is first-class** â€” the skill can meta-evaluate other eval skills/pipelines, including itself. The arbiter rubric is `eval-audit`'s 6 diagnostic areas + the recursive consistency check.
7. **Test-set-backed validation (anti-fabrication)** â€” every Layer 1 judge marked `validated: true` must have a test set file at `eval/test_sets/<judge_name>.jsonl` that backs its TPR/TNR numbers. The self-check recomputes tp/fp/tn/fn from the file and verifies they match the asserted counts and TPR/TNR (within 0.01). Minimum: â‰¥30 examples with â‰¥10 positive AND â‰¥10 negative. This invariant exists because asserted TPR/TNR without a test set file is fabrication â€” the exact recursive violation (RV2/RV3) eval-forge was built to close. Origin: 2026-08-22 hardening â€” eval-forge's own dogfood judges had asserted TPR/TNR with no test set files; the self-check passed because it checked *presence* of numbers, not *measurement*.

## Skill Chains

- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers side-effecting agent skills only. For LLM text use `eval-suite`, for CLI tools use `cli-harness`, for Python functions use `benchmark`.

| Position | Skill | Why |
|---|---|---|
| **Upstream** | `spectrum-wargame` (or any wargame/audit) | Wargame findings (P1/P2/P3) become eval cases via `--wargame` |
| **Upstream** | `skill-audit` | skill-audit identifies missing eval suites; eval-forge builds them |
| **Core** | `eval-forge` | Builds the eval suite, validates it, self-checks |
| **Downstream** | `skill-audit` | eval-forge output (scorer.py + corpus/) is consumed by skill-audit PROMOTION_GATES |
| **Downstream** | `apex-nexus evals/` | eval-forge produces golden-fixture-compatible output for the fleet eval runner |
| **Pair** | `error-analysis` (external) | Forge mode Step 1 incorporates error-analysis methodology with attribution |
| **Pair** | `validate-evaluator` (external) | Forge mode Step 5 uses TPR/TNR per validate-evaluator with attribution |

### Mandatory

- For forge mode, begin with error analysis (or the `--wargame` shortcut),
  build Layer 0 before any Layer 1 judges, and run self-check before handing
  the suite to `skill-audit` for promotion gating.

## Authority

**Trust tiers:**
- **T1/T2 (operator/trusted):** Unrestricted. Can run forge, arbiter, and self-check modes.
- **T3 (probationary-trusted):** Arbiter mode unrestricted (read-only). Forge mode requires operator approval before writing the eval suite to disk. Self-check mode unrestricted (runs against eval-forge's own suite, no external side effects).
- **T4 (probationary):** Arbiter mode on existing eval pipelines only (read-only). Forge mode blocked â€” T4 cannot build eval suites for side-effecting skills without operator escalation. Self-check mode permitted (read-only verification of eval-forge itself).

**Operator override:** Operator can escalate any tier to any mode. T4 with operator approval can run forge mode for a specific target skill.

**Rationale:** 93% of `side_effecting` skills in the fleet have `## Authority` (154/165). eval-forge is `side_effecting` (forge mode writes scorer.py + corpus/). Arbiter and self-check modes are read-only and safe for lower tiers.

## Output

### Forge mode output

```json
{
  "mode": "forge",
  "target_skill": "<skill-name>",
  "timestamp": "<ISO 8601>",
  "failure_catalog": [{"category": "...", "definition": "...", "classification": "code-checkable-on-state|code-checkable-on-output|judgment-required"}],
  "layer_0_invariants": [{"name": "...", "type": "state-transition|output-check|log-check", "passes": N, "fails": N}],
  "layer_1_judges": [{"name": "...", "failure_mode": "...", "why_code_cannot_check": "...", "tpr": N, "tnr": N, "validated": bool, "test_set_size": N}],
  "promotion_gates": {"all_layer_0_pass": bool, "all_layer_1_validated": bool, "all_layer_1_tpr_gt_90": bool, "all_layer_1_tnr_gt_90": bool, "all_layer_1_provenance_valid": bool, "self_check_pass": bool},
  "confusion_matrix": {"<judge_name>": {"tp": N, "fp": N, "tn": N, "fn": N, "tpr": N, "tnr": N}},
  "files_written": ["eval/scorer.py", "eval/corpus/case_*.json"]
}
```

### Arbiter mode output

```json
{
  "mode": "arbiter",
  "target": "<eval-skill-or-pipeline>",
  "timestamp": "<ISO 8601>",
  "verdicts": {"error_analysis": "PASS|PARTIAL|FAIL", "evaluator_design": "...", "judge_validation": "...", "human_review": "...", "labeled_data": "...", "pipeline_hygiene": "...", "recursive_consistency": "..."},
  "recursive_violations": [{"id": "RVN", "severity": "HIGH", "finding": "..."}],
  "overall": "STRONG|MEDIUM|WEAK"
}
```

### Self-check mode output

```json
{
  "mode": "self-check",
  "target": "eval-forge",
  "timestamp": "<ISO 8601>",
  "invariant_checks": [{"invariant": "...", "passes": bool, "evidence": "..."}],
  "self_check_pass": bool,
  "can_promote": bool
}
```

## Constraints

- DO NOT build Layer 1 judges before Layer 0 invariants. Code-first is enforced, not suggested.
- DO NOT use an LLM judge for a criterion that a regex, schema, assertion, or state-transition check can verify.
- DO NOT use Likert scales, letter grades, or pointwise scoring. Binary pass/fail only.
- DO NOT trust a judge until it passes >90% TPR and >90% TNR on a held-out test set against human labels.
- DO NOT skip error analysis. The forge pipeline starts with error analysis (or a wargame shortcut).
- DO NOT use dev/test examples as few-shot examples. This is data leakage.
- DO NOT report dev set performance as final accuracy. Dev numbers are optimistic; the test set gives the unbiased estimate.
- DO NOT report point estimates without confidence intervals. A corrected rate of 85% could be 78-92%.
- DO NOT ship eval-forge without self-check passing. If self-check fails, the skill is broken and cannot be promoted.
- DO NOT run forge mode without operator approval if you are T3 or T4. See ## Authority.
- DO NOT skip SKILL_INVOKE on entry. Post a SKILL_INVOKE as the first action after skill activation.
- DO NOT reinvent error-analysis or validate-evaluator. Incorporate with attribution. The forge pipeline builds on them, not around them.

## What this skill is NOT

- **NOT a replacement for unit tests.** eval-forge complements unit tests for deterministic code paths. It evaluates skills as systems, not functions.
- **NOT an LLM text evaluator.** For LLM text output only, use `eval-suite` or `phoenix-evals`. eval-forge is for side-effecting agent skills.
- **NOT an observability platform.** No tracing, dashboards, or production monitoring. Use Phoenix/Langsmith/Braintrust for that.
- **NOT a metric survey.** Does not list BLEU/ROUGE/BERTScore. Those are surface-overlap metrics that `eval-audit` flags. eval-forge uses binary evaluators grounded in specific failure modes.
- **NOT a replacement for the hamelsmu trio.** Incorporates error-analysis, write-judge-prompt, and validate-evaluator with attribution. Unifies the pipeline; does not replace the methodology skills it builds on.
- **NOT a one-off audit.** Arbiter mode is reusable. Any eval skill/pipeline can be arbiter-evaluated, including eval-forge itself.

## References

- `references/forge-pipeline.md` â€” detailed 7-step forge pipeline with error-analysis and validate-evaluator attribution
- `references/arbiter-rubric.md` â€” 6 diagnostic areas + recursive consistency check (from the arbiter audit)
- `references/code-first-invariants.md` â€” Layer 0 check patterns (state-transition, output, log)
- `references/skill-aware-eval.md` â€” before/after state capture, invariant checking on state transitions
- `references/anti-patterns.md` â€” what eval-forge is NOT (encoded anti-patterns from the arbiter audit)

## Eval suite

- `eval/scorer.py` â€” self-check scorer (PROMOTION_GATES, confusion_matrix, --target, --self-check flags)
- `eval/self_check.py` â€” runs scorer.py against eval-forge itself
- `eval/corpus/case_01_recursive_self_validation.json` through `case_08_arbiter_on_eval_forge.json` â€” 8 golden fixtures

## Lifecycle and deprecation

**Creation:** `candidate` (initial) â†’ `tested` (after dogfood plan) â†’ `stable` (after 3 engagements) â†’ `canonical` (if adopted as fleet standard)

**Deprecation:** If superseded, add `DEPRECATED <date>` to description and `status: retired` to frontmatter. Strip body to a redirect. See `gameboard-ops` for the deprecation anti-pattern (P5 from the wargame â€” deprecation header is a note, not a gate).

**Re-validation:** Re-run self-check and arbiter-on-self after any change to the 7 invariants, the forge pipeline, or the arbiter rubric.

## Layer 1 judges: validation pending

The earlier validation claim is withdrawn. Three judgment-based dogfood judges remain (`labeling_accuracy`, `graph_completeness`, and `contact_dedup_accuracy`), and all are marked `validated: false`. `generated_skill_quality` was reclassified as Layer 0 because every checked convention is deterministic. The required judge list is executable in `eval/layer_1_judges.json`; a missing or empty list fails promotion closed.

**Validation methodology** (per `references/forge-pipeline.md` Step 5 and `write-judge-prompt` 4-component rule):
1. Built 35-45 realistic traces per judge (5 train + 30-40 test) with ~40% clear pass, ~30% clear fail, ~30% borderline. Total: 167 traces (147 test + 20 train across 4 judges).
2. Labels created by AI agents (claude-code, gpt-5.6-sol, gpt-codex-5.6-sol) — NOT independent human operator ground truth. Label provenance is documented in each `_labels.json` file. This is a known limitation: validation is AI-judging-AI, not AI-judging-human.
3. Built LLM judge prompts with 4 components: task/criterion, pass/fail definitions, 3 few-shot examples from TRAIN split only (test leakage fixed 2026-08-22: gc_test_05 was previously used as Example 3 in graph_completeness, replaced with gc_train_05).
4. Stored predictions were attributed to an LLM judge run, but no raw model responses, API receipts, or execution logs were preserved. The claimed run cannot be independently verified.
5. Computed TPR/TNR by comparing judge predictions to labels. Wilson 95% lower bounds computed.

**Observed AI-assisted point estimates (unvalidated):**

| Judge | Skill | TPR | TNR | Test n | Pos | Neg | Wilson TPR lower | Wilson TNR lower |
|---|---|---|---|---|---|---|---|---|
| labeling_accuracy | ops-gameboard | 1.00 | 1.00 | 34 | 23 | 11 | 0.857 | 0.741 |
| graph_completeness | graphify | 1.00 | 1.00 | 28 | 18 | 10 | 0.824 | 0.722 |
| contact_dedup_accuracy | crm | 1.00 | 1.00 | 32 | 22 | 10 | 0.851 | 0.722 |

**What this means:**
- `self_check_pass: true` — the seven invariants and fail-closed machinery hold when unvalidated judges are represented honestly
- `can_promote: false` — independent human labels, raw responses, execution receipts, exact model snapshots, adequate test size, and confidence support are missing
- Layer 0 checks remain separate from the unvalidated Layer 1 evidence
- **Wilson CI warning**: all Wilson 95% lower bounds are BELOW 0.90 (range: 0.717–0.883). The point estimates pass the >90% gate, but the confidence intervals do not support a >90% population claim at 95% confidence. This is documented honestly — the test sets are too small (30-42 examples) to statistically confirm >90% TPR/TNR. Larger test sets needed for statistically significant validation.

**Honest limitations (peer review 2026-08-22):**
- Labels are AI-generated, not independent human operator ground truth. Validation is AI-judging-AI.
- Labeling was not blinded — labelers may have seen judge predictions.
- No raw model responses, API receipts, or execution logs preserved. Predictions cannot be independently verified.
- A dev/test split was added retrospectively, so the test set was not run exactly once as an untouched final measurement.
- Wilson 95% lower bounds all below 0.90 — point estimates pass but CIs do not support >90% population claim.
- `generated_skill_quality` was reclassified to Layer 0 because it checks deterministic conventions.
- Perfect scores (TPR=1.0, TNR=1.0) could be an artifact of AI-judging-AI with non-blinded labels, not necessarily well-calibrated judges. Operator review required.

**Artifacts per judge:**
- `eval/traces/<judge_name>_traces.json` — the traces (train + test)
- `eval/traces/<judge_name>_labels.json` — AI-assisted labels (NOT operator ground truth; provenance documented in file)
- `eval/traces/<judge_name>_predictions.json` — LLM judge predictions (no raw responses preserved)
- `eval/judge_prompts/<judge_name>.md` — the 4-component judge prompt (few-shot from train split only)
- `eval/test_sets/<judge_name>.jsonl` — held-out rows with AI-assisted labels and stored predictions; not independent human ground truth

## Version history

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-08-22 | Initial build. 6 invariants, 3 modes (forge/arbiter/self-check), 7-step forge pipeline, 8-case eval suite. Built on the arbiter audit of 6 external eval skills. Closes the recursive validation gap (RV1/RV2/RV3). |
| 0.1.0 | 2026-08-22 | Promoted from `candidate` to `tested` after dogfood: forge mode built eval suite for `ops-gameboard` that catches all 7 wargame findings (P1-P7). Self-check passed (6/6 invariants), arbiter-on-self passed (7/7 STRONG), skill-audit passed. |
| 0.1.0 | 2026-08-22 | Three additional dogfood runs: forge mode built eval suites for `graphify` (6 findings), `crm` (6 findings), and `skill-create` (6 findings). All 3 eval suites catch their findings (24/25 effective coverage; 1 N/A self-referential case). eval-forge proven to generalize across 4 different side-effect profiles and 4 different domains. |
| 0.1.0 | 2026-08-22 | **Hardening: Invariant 7 added (test-set-backed validation / anti-fabrication).** Origin: dogfood Layer 1 judges had asserted TPR/TNR with `validated: true` but no test set files â€” the exact recursive violation (RV2/RV3) eval-forge was built to close. The original self-check passed because Invariant 5 checked *presence* of TPR/TNR numbers, not *measurement* against a real test set. Invariant 7 closes this gap by requiring `eval/test_sets/<judge_name>.jsonl` for every `validated: true` judge, with recomputed counts and TPR/TNR matching the asserted values (within 0.01), minimum 30 examples, minimum 10 positive AND 10 negative. Invariant 5 refined to distinguish "validated and broken" (fails invariant) from "honestly unvalidated" (fails promotion gate, not invariant). All 5 dogfood Layer 1 judges marked `validated: false` with TPR/TNR set to 0.0 â€” honest state. Self-check still passes (7/7 invariants); `can_promote` now correctly returns false (Layer 1 gate fails). Unit test `test_invariant_7.py` (8 tests) verifies the invariant catches fabricated judges, mismatched counts, too-small test sets, and unbalanced test sets. Status remains `stable` for Layer 0; Layer 1 promotion gated until real test sets are built. |
| 0.1.0 | 2026-08-22 | **Attempted Layer 1 validation (reversed).** Stored predictions agreed perfectly with AI-assisted labels, but independent ground truth, execution provenance, and confidence support were missing. Peer review reversed the promotion claim and required remediation. |
| 0.1.0 | 2026-08-23 | **Fail-closed remediation.** Added a non-empty required Layer 1 manifest and executable gates for independent/blinded human labels, raw responses, completed execution receipts, exact model snapshots, disjoint train/dev/test splits, minimum class balance, matching confusion counts, and 95% Wilson lower bounds. Marked all three judgment-based judges unvalidated, restored `can_promote: false`, and returned status to `candidate`. |
