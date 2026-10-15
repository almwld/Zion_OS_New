---
name: ssl-check
description: Check SSL certificate expiry dates, chain validity, and HSTS headers across domains
version: 0.1.0
execution-mode: advisory
argument-hint: "<domain...> [--warn-days 30]"
category: backend-infra
status: candidate
---
# SSL Check

Inspect SSL/TLS certificates for one or more domains, reporting expiry dates, chain validity, protocol versions, and HSTS header presence. Flags certificates expiring within the warning threshold so renewals happen before outages.

## When to Use
- Before a deploy to verify certificates are still valid
- Periodic sweep of all owned domains for expiry risk
- After a certificate renewal to confirm the new cert is live
- Debugging TLS handshake failures or mixed-content warnings

## Execution
1. Parse `$ARGUMENTS` for domain list and `--warn-days` threshold (default: 30).
2. For each domain, run `openssl s_client -connect <domain>:443 -servername <domain>` to fetch the certificate chain.
3. Extract expiry date, issuer, subject, SANs, and protocol version from the certificate.
4. Check for HSTS header via `curl -sI https://<domain>` and report `Strict-Transport-Security` presence and max-age.
5. Flag any certificate expiring within the warning threshold as WARNING; expired certificates as CRITICAL.
6. Summarize chain validity (root CA trust, intermediate completeness).

## Output Format
```
SSL Check | <domain-count> domains

| Domain | Expires | Days Left | Status | Issuer | HSTS |
|--------|---------|-----------|--------|--------|------|
| example.com | 2026-08-15 | 139 | OK | Let's Encrypt | max-age=31536000 |
| api.example.com | 2026-04-05 | 7 | WARNING | DigiCert | missing |

Findings:
- [WARNING] api.example.com expires in 7 days (threshold: 30)
- [OK] Chain valid for example.com (3 certs, root trusted)

Next action: Renew api.example.com certificate before 2026-04-05.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Certificates expiring soon | `[compliance-calendar]` to track renewal deadline |
| Alert threshold breached | `[alert-rule]` to set up automated expiry notifications |
| HSTS missing on production domain | `[security-scan]` for broader hardening review |
