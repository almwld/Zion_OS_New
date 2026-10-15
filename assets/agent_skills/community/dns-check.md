---
name: dns-check
description: Verify DNS records (A, AAAA, MX, SPF, DKIM, DMARC, CNAME) and propagation status
version: 0.1.0
execution-mode: advisory
argument-hint: "<domain> [--records A|MX|SPF|DKIM|all]"
category: backend-infra
status: candidate
---
# DNS Check

Query and verify DNS records for a domain, covering A, AAAA, MX, SPF, DKIM, DMARC, and CNAME records. Reports misconfigurations, missing email authentication records, and propagation issues that could affect deliverability or availability.

## When to Use
- Debugging email deliverability issues (SPF/DKIM/DMARC)
- Verifying DNS propagation after record changes
- Auditing domain configuration for security (DNSSEC, CAA)
- Pre-launch domain readiness check

## Execution
1. Parse `$ARGUMENTS` for domain and `--records` filter (default: all).
2. Query A and AAAA records via `nslookup` or `dig` to verify IP resolution.
3. Query MX records and verify mail server reachability.
4. Check TXT records for SPF (`v=spf1`), DKIM (`_domainkey`), and DMARC (`_dmarc`).
5. Query CNAME records if the domain is a subdomain.
6. Optionally check against multiple DNS resolvers (Google 8.8.8.8, Cloudflare 1.1.1.1) to verify propagation consistency.
7. Flag missing or misconfigured records.

## Output Format
```
DNS Check | <domain>

| Record | Type | Value | Status |
|--------|------|-------|--------|
| @ | A | 93.184.216.34 | OK |
| @ | AAAA | 2606:2800:220:1:... | OK |
| @ | MX | mail.example.com (pri 10) | OK |
| @ | TXT (SPF) | v=spf1 include:_spf.google.com ~all | OK |
| _dmarc | TXT (DMARC) | v=DMARC1; p=reject; rua=... | OK |
| default._domainkey | TXT (DKIM) | -- | MISSING |

Findings:
- [WARNING] DKIM record not found for selector 'default'
- [OK] SPF record valid, includes Google Workspace

Next action: Add DKIM TXT record for selector 'default' at your DNS provider.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Email records misconfigured | `[send-email]` to test deliverability after fix |
| Domain not resolving | `[uptime-check]` to verify endpoint availability |
| Multiple domains to audit | `[bulk-edit]` to batch DNS fixes across configs |
