---
name: evidence-driven-recovery
description: Run a model-led observe-diagnose-repair-verify loop after tool failures.
---
# Evidence-Driven Recovery
1. Preserve the failed step, exact error, exit code, selected runtime, and relevant recent output.
2. Ask the local model for a different corrective step grounded in that evidence.
3. Reject retries that repeat the same tool and parameters without a reason.
4. Re-evaluate tool parameters and runtime policy for every recovery step.
5. Execute, observe, and record each attempt; stop on success, cancellation, or exhausted retry budget.
A recovery proposal is not a successful repair until its verification step passes.