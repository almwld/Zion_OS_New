---
name: travel-itinerary
description: Build a complete trip itinerary with logistics, day-by-day schedule, ground transport, contacts, and pre-trip checklist. Saves to _internal/comms/. Powered by exec-assistant agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"DESTINATION\" \"DATES\" \"PURPOSE\" [--budget economy|business] [--format brief|full]"
category: dev-tools
status: candidate
---
# Travel Itinerary

Generate a complete business travel itinerary — logistics, schedule, contacts, and checklist.

## When to Use

- Attending a conference (Diligent Elevate, ATL AI Week, etc.)
- Client site visit
- Investor meeting trip
- Multi-city business development trip

## Required Inputs

| Field | Example |
|-------|---------|
| Destination | Atlanta, GA → Chicago, IL |
| Dates | April 22-24, 2026 |
| Purpose | Diligent Elevate conference |
| Key meetings | [Name] at [Company] — [purpose] |
| Starting point | Atlanta Hartsfield (ATL) |
| Budget preference | Economy / Business / Unspecified |
| Hotel preference | Near venue / Budget / Brand preference |

## Itinerary Format

```
TRIP: [Destination] | [Dates] | [Purpose]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LOGISTICS
Outbound:  [Flight/Train/Drive — depart time, arrive time, confirmation #]
Hotel:     [Name — address — confirmation # — check-in/out]
Return:    [Flight/Train/Drive — details]

MEETING OBJECTIVES
1. [Primary goal of trip]
2. [Secondary goal]

────────────────────────────────────────
[DATE 1] — [Day of week]
  - [Time]: Arrive / Check-in
  - [Time]: [Meeting] @ [Location] — [goal]
  - [Time]: [Dinner / networking event]
  - Evening: [prep for next day]

[DATE 2] — [Day of week]
  - [Time]: [Meeting 1] @ [Location]
  - [Time]: [Conference session]
  - [Time]: [Lunch meeting] @ [Restaurant]
  - [Time]: [Afternoon meeting]
  - Evening: [optional networking]

[DATE 3] — [Day of week]
  - Morning: [meeting or depart]
  - [Time]: Depart for airport
  - [Time]: Flight home
────────────────────────────────────────

GROUND TRANSPORT
[Day]: Uber from hotel to [venue] — ~[X] min, ~$[Y]
[Day]: [Other transport notes]

KEY CONTACTS ON TRIP
[Name] — [Title, Company] — [Phone] — [purpose of meeting]
[Name] — [Title, Company] — [LinkedIn / email]

PRE-TRIP CHECKLIST
[ ] Confirm all meetings 24 hours before
[ ] Download boarding pass
[ ] Charge all devices
[ ] Pack [specific items for this trip]
[ ] Prep talking points for [key meeting]
[ ] Business cards / QR code for contacts

POST-TRIP ACTIONS
[ ] Send follow-up emails within 24 hours
[ ] Log contacts in CRM
[ ] Expense report
```

## Human Cost Equivalent

- Basic trip itinerary: $100-200 EA time
- Multi-city conference trip: $200-400

## Skill Chains

- `[travel-itinerary]` → `[meeting-prep]` (deep prep for each meeting on the trip)
- `[travel-itinerary]` → `[discovery-call]` (if prospect meetings on the trip)
- After trip → `[meeting-review]` (capture outcomes)
- After trip → `[stakeholder-update]` (report back to investors/board on trip results)
- Expenses → `[expense-log]`
