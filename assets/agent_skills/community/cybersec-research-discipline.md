---
name: cybersec-research-discipline
description: 'Cybersecurity threat research self-checks: IOC defanging before output, curl --fail in monitoring scripts, evidence preservation before rebuild instructions, machine-parseable IOC formats alongside human-readable files, source completeness before declaring IOC extraction done, attribution confidence levels preserved from sources. Run before writing any file containing IOCs, before writing monitoring/fetching scripts, before writing IR/remediation guidance, before claiming SIEM-ready, before declaring IOC collection complete, and before writing threat actor attribution.'
version: 1.0.0
execution-mode: advisory
argument-hint: "[defang | curl | evidence | machine-format | source-complete | attribution | all]"
category: research
status: tested
origin: 2026-09-15 cybersec threat research AAR
---

# [cybersec-research-discipline]

> Six self-checks that prevent the most common cybersecurity research output
> errors. Each originated from a real failure mode in the 2026-09-15 threat
> research session, where a subagent red-team review caught 5 blocking issues
> in the initial deliverables. Run the relevant check before output, not after.

## When to use

- **defang** — before writing any file containing malicious domains, URLs, or
  email addresses. Determines whether IOCs are safe to share.
- **curl** — before writing or shipping any script that fetches URLs (monitoring,
  scraping, polling). Determines whether HTTP errors will be caught.
- **evidence** — before writing IR/remediation guidance that includes "rebuild"
  or "restore" steps. Determines whether forensic evidence preservation is
  mentioned before destruction.
- **machine-format** — before claiming an IOC deliverable is "SIEM-ready" or
  "for SIEM import," or before declaring an IOC deliverable complete.
- **source-complete** — before declaring IOC extraction complete for a threat.
  Determines whether host-side indicators have been collected, not just
  network indicators.
- **attribution** — before writing threat actor attribution in any deliverable.
  Determines whether confidence levels from the source are preserved.
- **all** — run every check; use before finalizing a cybersec research deliverable
  or at session close.

---

## Check 1 — IOC defanging (origin: 2026-09-15 AAR, B1/B2)

Malicious domains, URLs, and email addresses in deliverables must be defanged
before writing. Raw malicious infrastructure in a markdown file becomes
clickable in any rendered viewer (Confluence, Slack, email, GitHub). An
executive or assistant clicking `cloud.shinewrist.net` connects to attacker
infrastructure. The file most likely to be read by non-technical staff is the
one where defanging matters most.

**Defanging rules:**
- Domain: `example.com` → `example[.]com`
- Subdomain: `sub.example.com` → `sub[.]example[.]com`
- URL: `https://example.com/path` → `hxxps://example[.]com/path`
- Email: `user@example.com` → `user[@]example[.]com`
- IP addresses: leave as-is (IPs are not clickable in most viewers)

**Self-check before writing any file with IOCs:**
1. Are all malicious domains defanged with `[.]` notation?
2. Are all malicious URLs using `hxxps://` or `hxxp://` scheme?
3. Are all malicious email addresses using `[@]` notation?
4. If I grep the file for raw malicious domains (without `[.]`), do I get zero
   hits? If not, fix them before writing.

**Red flag**: An executive brief has raw `cloud.shinewrist.net` while the IOC
file has properly defanged `cloud.shinewrist[.]net`. The brief is the file
most likely to be clicked through. This was the single most dangerous issue
in the 2026-09-15 deliverables.

---

## Check 2 — curl safety (origin: 2026-09-15 AAR, B3)

Any script that fetches URLs must use `curl --fail` (or `-f`). Without it,
curl returns exit code 0 for HTTP 404, 500, 503, and rate-limit pages. A
monitoring script that treats HTTP errors as success will silently report
false negatives — every CVE shows "not in KEV" when CISA returns an error page,
every source page shows "no change" when a CAPTCHA replaces the content.

**Self-check before writing or shipping a fetch script:**
1. Does every `curl` invocation include `-f` or `--fail`?
2. Does the script set a User-Agent header? (NVD, Medium, and other sites may
   block or rate-limit requests without one.)
3. Does the script handle the failure case explicitly (error message, skip,
   retry) rather than silently proceeding with empty/error content?
4. If I test the script with a deliberately bad URL, does it report failure
   rather than success?

**Red flag**: A KEV monitoring script without `--fail` reports all CVEs as
"not in KEV" during a CISA outage. A SOC analyst concludes a KEV entry was
removed when it wasn't. This is a silent false-negative in a tool people
rely on for patching decisions.

---

## Check 3 — Evidence preservation (origin: 2026-09-15 AAR, B4)

Any IR/remediation guidance that includes "rebuild" or "restore" steps must
precede those steps with explicit evidence preservation instructions. A
stressed IR team at 3am following a brief literally will rebuild immediately,
destroying volatile evidence (memory, running processes, cron jobs, network
connections) needed for investigation, law enforcement, and insurance.

**Required sequence for any rebuild/restore instruction:**
1. Isolate (network containment, not power-off)
2. **Preserve forensic evidence** (memory capture, disk image, log export)
3. Then rebuild/restore from clean image
4. Rotate credentials and crypto materials
5. Verify remediation

**Self-check before writing "rebuild" in any deliverable:**
1. Does the text say "preserve forensic evidence first" (or equivalent)
   before the rebuild step?
2. Does it specify what to preserve (memory capture, disk image at minimum)?
3. Is the preservation step a separate numbered item, not buried in a
   subordinate clause?

**Red flag**: A brief says "If compromise found: rebuild from clean image,
rotate credentials." An IR team rebuilds, destroying the memory and disk
state that would have identified the attacker's lateral movement. The
investigation is over before it starts. Standard IR doctrine is:
isolate → preserve → rebuild.

---

## Check 4 — Machine-parseable IOC format (origin: 2026-09-15 AAR, S8)

Any IOC deliverable that claims to be "for SIEM import" or "SIEM-ready" must
include a machine-parseable format (CSV at minimum, JSON preferred). A plain-
text IOC list in a code block is not importable — a SOC analyst at 3am cannot
paste it into Splunk, Chronicle, or Elastic without manual parsing.

**Self-check before claiming "SIEM-ready" or finishing an IOC deliverable:**
1. Is there a CSV file with structured columns (type, value, threat,
   description)?
2. Is there a JSON file for programmatic ingestion?
3. Are all IOC values defanged in the machine-parseable files too? (CSV/JSON
   files are often opened in spreadsheet viewers that auto-link URLs.)
4. Can I verify the format with a one-liner? (`python3 -c "import json;
   json.load(open('iocs.json'))"` or `csv.tool iocs.csv | head`)

**Red flag**: A brief's attachment list says "IOCs.md — for SIEM import" but
the file is a markdown table. The analyst opens it, sees a table, and has to
manually extract 100+ indicators into their SIEM. The "SIEM-ready" claim was
false. Always produce CSV+JSON alongside the human-readable file.

---

## Check 5 — Source completeness (origin: 2026-09-15 AAR, S1/S2)

Before declaring IOC extraction complete for a threat, verify that host-side
indicators have been collected, not just network indicators. Network IOCs
(domains, IPs, URLs) are necessary but insufficient — SOC teams hunt for
host-side artifacts at 3am: scheduled task names, cron patterns, user agents,
file extensions, account names, registry keys, mutexes, service names.

**Host-side indicator categories to check before declaring complete:**
- Persistence: scheduled tasks, cron jobs, systemd services, registry Run keys
- Execution: process names, parent-child relationships, command-line patterns
- Filesystem: file paths, file names, file extensions, drop locations
- Accounts: created accounts, modified accounts, group memberships
- Web logs: user agents, request paths, request patterns
- Defense evasion: Defender exclusions, mutex names, masquerade names

**Self-check before declaring IOC extraction complete:**
1. Have I fetched the full primary source (blog body, GitHub IOC repo, PDF
   advisory) — not just the blog summary or search excerpt?
2. Does the IOC file contain at least one host-side indicator (not just
   domains/IPs/hashes)?
3. If the source has a GitHub IOC repo, have I fetched and incorporated it?
4. If the source is a long blog, have I read the full text (not just the
   IOC table at the end)?

**Red flag**: An IOC file has 9 IPs, 7 domains, and 14 hashes but zero
scheduled task names, zero cron patterns, zero user agents, and zero account
names. The SOC team has the network IOCs but not the artifacts they'd actually
hunt for on endpoints. The Volexity GitHub IOC repo and QUIRSO blog full text
had the host-side indicators — they required a second fetch pass.

---

## Check 6 — Attribution confidence (origin: 2026-09-15 AAR, S4)

Threat actor attribution must preserve the source's confidence language.
"Iran MOIS" stated as flat fact is different from "Iran MOIS (NCSC: almost
certainly — high confidence)." Stripping confidence levels turns intelligence
assessments into assertions. A CISO making risk decisions needs to know the
difference between "high confidence" and "low confidence."

**Common confidence levels and their meaning:**
- **High confidence / almost certainly** — multiple independent sources,
  strong evidence, established pattern
- **Moderate confidence / probably** — credible sources, some corroboration,
  gaps remain
- **Low confidence / possibly** — single source, uncorroborated, tenuous

**Self-check before writing attribution in any deliverable:**
1. Does the attribution include the source's confidence qualifier (e.g.,
   "high confidence," "almost certainly," "moderate confidence")?
2. Does it cite the source of the attribution (e.g., "NCSC assesses,"
   "Volexity attributes with high confidence")?
3. If multiple aspects have different confidence levels (e.g., actor
   identification = high, exploit chain sharing = low), are they stated
   separately with their respective levels?
4. If the source explicitly says the attribution should NOT be treated as
   strong evidence (e.g., Babuk ransomware is widely adopted after the 2021
   builder leak), is that caveat included?

**Red flag**: A brief says "Attribution: Iran MOIS" as a flat fact. The NCSC
advisory says "Iran almost certainly uses cyber activity." The confidence
qualifier was stripped. A CISO reads it as confirmed fact rather than a
high-confidence assessment. Always preserve the source's confidence language
verbatim or paraphrased with the qualifier intact.

---

## Quick reference

| Check | Trigger | One-line rule |
|-------|---------|---------------|
| defang | Writing file with IOCs | Defang all domains/URLs/emails before writing |
| curl | Writing fetch script | Always use `curl --fail` + User-Agent |
| evidence | Writing rebuild/restore steps | Preserve forensic evidence before rebuild |
| machine-format | Claiming SIEM-ready | Produce CSV+JSON, not just markdown |
| source-complete | Declaring IOCs done | Fetch full source + GitHub repo; include host-side indicators |
| attribution | Writing actor attribution | Preserve confidence level from source |
