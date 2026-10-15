---
name: flutter-ci-repair
description: Repair Flutter and GitHub Actions failures with commit-specific verification.
---
# Flutter and CI Repair
1. Tie the failing workflow to its exact head SHA and identify the first failed step.
2. Reproduce locally when possible; run formatting, focused tests, analyzer, then the required build.
3. Fix the root cause and add a regression test where practical.
4. Keep each logical repair in a separate commit and do not edit workflow secrets or signing configuration casually.
5. Re-check the new run for the new SHA; a previous green run does not validate new changes.
Report static analysis, tests, APK build, artifact/signature checks, and device tests separately.