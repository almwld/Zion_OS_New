---
name: legal-check
description: Review code, docs, and configs for license compliance, IP exposure, and legal risks.
version: 0.1.0
execution-mode: advisory
argument-hint: "[licenses | ip-exposure | terms | compliance FRAMEWORK]"
category: governance-compliance
status: candidate
---
# Legal Check

Flag legal risks in code, dependencies, and documentation. Not legal advice -- flags for human review.

## Operations

### licenses
Audit dependency licenses:
```bash
echo "=== Python dependencies ==="
pip list --format=columns 2>/dev/null | head -20
echo "---"
echo "=== License check ==="
pip show $(pip list --format=freeze 2>/dev/null | cut -d= -f1 | head -20) 2>/dev/null | grep -E "^(Name|License):" | paste - - | column -t

echo "=== Node dependencies (if any) ==="
ls package.json 2>/dev/null && npm ls --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v.get(\"version\",\"?\")}') for k,v in d.get('dependencies',{}).items()]" 2>/dev/null || echo "(no node deps)"
```

**License compatibility:**
- MIT, Apache 2.0, BSD: OK for commercial use
- GPL/AGPL: **COPYLEFT** -- requires source disclosure if distributed
- SSPL: **RESTRICTED** -- may require open-sourcing service code
- No license: **UNKNOWN** -- treat as all rights reserved

### ip-exposure
Check for unintentional IP exposure:
- Are proprietary algorithms in public repos?
- Are internal architecture docs committed to public repos?
- Are customer data schemas exposed?
- Is Base120 content (proprietary IP) in the right repos with right licenses?

### terms
Review terms for external services:
- OpenAI/Anthropic API terms (data usage, output ownership)
- Google Cloud terms (data residency, SLA)
- GitHub terms (code ownership, Copilot training opt-out)

### compliance
Check against a specific framework:
- **SOC 2**: Access controls, audit logs, change management
- **GDPR**: Data minimization, consent, right to erasure
- **ISO 42001**: AI management system (Augment Code has this)

## Red Flags
- GPL dependency in our stdlib-only core (would force open-source)
- API keys in git history (legal liability + security)
- Using someone else's copyrighted content in training data
- Trademark issues (configured gateway was forced to rename from "Clawdbot")
- Patent risk in novel algorithms

## Output Format
```
Legal Check | <scope>
══════════════════════

## License Audit
- Compatible: N dependencies
- Copyleft risk: <list>
- Unknown: <list>

## IP Exposure
- <findings>

## Compliance Gaps
- <framework>: <gaps>

## Action Items
- [ ] <specific items for legal review>
```

## Disclaimer
This skill flags potential issues for human/legal review. It is NOT legal advice. Always consult qualified counsel for actual legal decisions.
