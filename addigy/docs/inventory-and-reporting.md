# Addigy Inventory and Reporting Scripts – Backblaze (Optional)

This document describes optional **Addigy inventory and reporting scripts** used to report Backblaze Computer Backup state and metadata via `bzcli`.

These scripts are **not required** for basic Backblaze operation. They are intended for **visibility, reporting, and automation** during UAT and beyond.

## Deployment Context

These scripts are designed for the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this architecture, a single administrative Backblaze account or Business Group configuration manages multiple endpoints while Addigy provides inventory visibility, script execution, and device segmentation.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the Addigy installer and workflow documentation included in this repository.

---

## When to use these scripts

These inventory and reporting scripts are recommended if you need:

- Visibility into Backblaze installation and runtime state
- Device targeting for remediation workflows
- Operational reporting for IT administrators

They can be safely omitted if Addigy inventory and reporting are not required.

---

## Reporting model

The scripts follow a structured reporting model aligned with the overall Addigy integration architecture:

1. **Installation State** – Detects presence of the Backblaze client.
2. **Version Reporting** – Exposes installed client version for compliance checks.
3. **Operational Status** – Reports backup runtime state.
4. **Telemetry Timestamping** – Exposes last successful backup time.
5. **Device Identity** – Provides Host GUID (HGUID) for cross-reference.
6. **Health Classification** – Derives a deterministic health state for operational review.

Together, these scripts enable deterministic device segmentation, automated remediation workflows, and operational reporting.

---

## Implemented inventory and reporting scripts

### Backblaze – Client Version

**Script:**
```sh
addigy/scripts/inventory/backblaze-client-version.sh
```

**Description:**
Reports the installed Backblaze client version using `bzcli`.

**Example values:**
- `10.0.0.1012`
- `Unknown`
- `bzcli not found`

---

### Backblaze – Installed

**Script:**
```sh
addigy/scripts/inventory/backblaze-installed.sh
```

**Description:**
Reports whether the Backblaze client appears to be installed.

**Example values:**
- `Installed`
- `Not Installed`

---

### Backblaze – Status Summary

**Script:**
```sh
addigy/scripts/reporting/backblaze-status-summary.sh
```

**Description:**
Reports the current Backblaze backup status using `bzcli`.

**Example values:**
- `Running`
- `Paused`
- `Idle`
- `Error`
- `Unknown`

---

### Backblaze – Last Backup (ISO8601)

**Script:**
```sh
addigy/scripts/reporting/backblaze-last-backup-iso8601.sh
```

**Description:**
Reports the timestamp of the last successful Backblaze backup.

**Example values:**
- `2026-01-16 23:12:14`
- `Never`
- `Unknown`

---

### Backblaze – HGUID

**Script:**
```sh
addigy/scripts/inventory/backblaze-hguid.sh
```

**Description:**
Reports the Backblaze Host GUID (HGUID) used to uniquely identify the device in Backblaze.

**Example values:**
- `abcd1234efgh5678`
- `Unknown`
- `bzcli not found`

---

### Backblaze – Health Score

**Script:**
```sh
addigy/scripts/reporting/backblaze-health-score.sh
```

**Description:**
Provides a deterministic health classification derived from backup status and last successful backup timestamp.

This script is optional but recommended for compliance review, dashboarding, and operational triage.

**Example values:**
- `GREEN`
- `YELLOW`
- `RED`
- `NOT_INSTALLED`

**Typical evaluation model:**
- `GREEN` → Backup active and last backup within 24 hours
- `YELLOW` → Last backup older than 24 hours but less than 7 days
- `RED` → Paused, error, waiting state, invalid backup timestamp, or last backup 7+ days old
- `NOT_INSTALLED` → `bzcli` is not present

---

These scripts complement the operational action model documented elsewhere in the Addigy baseline and provide the telemetry layer used for reporting and remediation workflows.

---

## Addigy configuration notes

- Import or paste each script into the appropriate Addigy policy, inventory, or reporting workflow
- Scripts are intended to run as **root**
- Values should be treated as reporting data, not as direct state mutation
- Inventory and reporting cadence should align with your operational needs

---

## Notes

- All scripts rely on `bzcli` being present on the device
- If `bzcli` is not found, the script returns a safe fallback value
- These scripts are designed to be lightweight and safe to run frequently
- Health classification logic should remain deterministic and documented
- Thresholds such as 24 hours and 7 days may be adapted to organizational requirements
- These scripts are intended for reporting, segmentation, and operational visibility only; they do not modify device state