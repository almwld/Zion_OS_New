---
name: testflight-prep
description: Pre-submission checklist for TestFlight/iOS builds.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--app your-app]"
category: dev-tools
status: candidate
---
# TestFlight Prep

Verify all requirements before submitting an iOS build to TestFlight.

## When to Use
- Before any TestFlight submission
- your-app alpha deadline (Apr 2)
- After significant code changes to iOS app

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=testflight-prep] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Xcode project check**: Verify .xcodeproj or .xcworkspace exists and builds
2. **Signing**: Check provisioning profile and certificate validity
3. **Bundle ID**: Verify matches App Store Connect registration
4. **Version/Build**: Bump build number, verify version string
5. **Dependencies**: `pod install` or SPM resolve if applicable
6. **Tests**: Run XCTest suite
7. **Screenshots**: Verify required screenshot sizes exist
8. **Release notes**: Draft TestFlight release notes
9. **Archive**: `xcodebuild archive` succeeds
10. **Export**: Generate .ipa for upload

## Output Format

```
TestFlight Prep | <app-name> v<version> (<build>)
==================================================
| Check | Status | Notes |
|-------|--------|-------|
| Xcode build | PASS/FAIL | ... |
| Signing | PASS/FAIL | ... |
| Bundle ID | PASS/FAIL | ... |
| Tests | PASS/FAIL | N passed, M failed |
| Archive | PASS/FAIL | ... |

Ready for upload: YES/NO
```

## Skill Chains

### Mandatory

None — this skill is a verification checklist; no upstream chain is required before running the checks.

### Advisory

- Before submit → `[ship-check]` (general), then `[testflight-prep]` (iOS-specific)
- After upload → `[send-email]` team-lead with build notes
- Issues found → `[debug-test]`

## Authority

- **T1 (TRUSTED)**: Full access — run verification, archive, export
- **T2 (Active/High)**: Full access — run verification, archive, export
- **T3 (Medium)**: Full access — run verification, archive, export
- **T4 (Probationary)**: May run — checklist verification only (no archive/export)
- **Operator**: Override any restriction
