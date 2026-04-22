# Backblaze Health Score (Jamf)

## Overview

The Backblaze Health Score Extension Attribute provides a deterministic
backup compliance classification for managed macOS devices.

This score enables:

- Visual fleet segmentation
- Smart Group automation
- Policy-driven remediation
- Executive-level reporting

The Health Score is optimized for Jamf-native automation workflows.

---

## Output Values

The Extension Attribute returns one of the following values:

| Value           | Meaning                                  |
|----------------|------------------------------------------|
| GREEN          | Backup is healthy and recent             |
| YELLOW         | Backup is slightly stale (warning state) |
| RED            | Backup is non-compliant or unhealthy     |
| NOT_INSTALLED  | Backblaze client not detected            |

---

## Classification Logic

### GREEN
- Backup status indicates active/backing up
- Last successful backup ≤ 24 hours

### YELLOW
- Last successful backup > 24 hours and < 7 days

### RED
- Backup paused
- Error state
- Waiting state
- No valid last backup timestamp
- Last backup ≥ 7 days

### NOT_INSTALLED
- `bzcli` binary not found on system

---

## Smart Group Recommendations

Create Smart Computer Groups in Jamf using the following criteria:

**Criteria Example:**

Extension Attribute  
Backblaze – Health Score  
is  
RED

Recommended Smart Groups:

- Backblaze – Health: RED (Critical)
- Backblaze – Health: YELLOW (Warning)
- Backblaze – Health: GREEN (Healthy)
- Backblaze – Not Installed

---

## Operational Use Cases

### Automated Remediation
Scope a policy to:
- Health Score = RED
- Trigger Backup Now or Resume Backup

### Reporting
Filter Jamf inventory by:
- Health Score

### Compliance Monitoring
Segment devices requiring investigation.

---

## Design Principles

- Deterministic classification
- Jamf-native implementation
- No external dependencies
- Safe fallback (unknown states default to RED)

---

## Health Score Automation Flow

The following diagram illustrates how the Health Score integrates with Jamf workflows:

```
Device
   │
   ▼
bzcli telemetry
   │
   ▼
Extension Attribute (Health Score)
   │
   ▼
Jamf Inventory Update (recon)
   │
   ▼
Smart Computer Groups (GREEN / YELLOW / RED / NOT_INSTALLED)
   │
   ▼
Jamf Policies (Remediation / Reporting)
```

This flow demonstrates how telemetry becomes actionable segmentation and policy-driven automation within Jamf.
---

## Notes

- Extension Attribute runs during inventory recon.
- Ensure `jamf recon` is executed after installation.
- Health thresholds (24h / 7d) may be adapted for enterprise policy.
