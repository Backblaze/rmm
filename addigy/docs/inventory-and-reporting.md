# Jamf Extension Attributes – Backblaze (Optional)

This document describes optional **Jamf Pro Extension Attributes (EAs)** used to report Backblaze Computer Backup state and metadata via `bzcli`.

These Extension Attributes are **not required** for basic Backblaze operation. They are intended for **visibility, reporting, and automation** during UAT and beyond.

## Deployment Context

These Extension Attributes are designed for the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this architecture, a single administrative Backblaze account or Business Group configuration manages multiple endpoints while Jamf provides inventory reporting, policy automation, and device segmentation.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the official Backblaze Jamf documentation on the Backblaze documentation site.

---

## When to use Extension Attributes

Extension Attributes are recommended if you need:

- Inventory visibility into Backblaze status
- Device targeting for remediation workflows
- Operational reporting for IT administrators

They can be safely omitted if Jamf inventory reporting is not required.

---

## Implemented Extension Attributes (Jamf Pro)

## Extension Attribute Design Model

The Extension Attributes follow a structured reporting model aligned with the overall Jamf integration architecture:

1. **Installation State** – Detects presence of the Backblaze client.
2. **Version Reporting** – Exposes installed client version for compliance checks.
3. **Operational Status** – Reports backup runtime state.
4. **Telemetry Timestamping** – Exposes last successful backup time.
5. **Device Identity** – Provides Host GUID (HGUID) for cross-reference.

Together, these attributes enable deterministic device segmentation, automated remediation workflows, and enterprise-level reporting.

---

### Backblaze – Client Version

**Script:**
```
jamf/scripts/extension-attributes/backblaze-client-version.sh
```

**Description:**
Reports the installed Backblaze client version using `bzcli`.

**Example values:**
- `10.0.0.1012`
- `Unknown`

---

### Backblaze – Installed

**Script:**
```
jamf/scripts/extension-attributes/backblaze-installed.sh
```

**Description:**
Reports whether the Backblaze client service (`bzserv`) is running on the device.

**Example values:**
- `Installed`
- `Not Installed`

---

### Backblaze – Status Summary

**Script:**
```
jamf/scripts/extension-attributes/backblaze-status-summary.sh
```

**Description:**
Reports the current Backblaze backup status using `bzcli`.

**Example values:**
- `Running`
- `Paused`
- `Idle`
- `Error`

---

### Backblaze – Last Backup (ISO8601)

**Script:**
```
jamf/scripts/extension-attributes/backblaze-last-backup-iso8601.sh
```

**Description:**
Reports the timestamp of the last successful Backblaze backup in ISO8601 format.

**Example values:**
- `2025-12-22T03:41:10Z`
- `Never`

---

### Backblaze – HGUID

**Script:**
```
jamf/scripts/extension-attributes/backblaze-hguid.sh
```

**Description:**
Reports the Backblaze Host GUID (HGUID) used to uniquely identify the device in Backblaze.

**Example values:**
- `abcd1234efgh5678`
- `Unknown`

---

### (Optional) Backblaze – Health Classification

**Script (if implemented):**
```
jamf/scripts/extension-attributes/backblaze-health-classification.sh
```

**Description:**
Provides a deterministic health classification derived from backup status and last successful backup timestamp.

This attribute is optional but recommended for enterprise compliance enforcement.

**Example values:**
- `Healthy`
- `Warning`
- `Critical`
- `Not Installed`

**Typical evaluation model (example):**
- Healthy → Backup running and last backup < 24 hours
- Warning → Backup paused or last backup 1–7 days
- Critical → Last backup > 7 days or error state

This classification can be used to drive Smart Group scoping and automated remediation policies.

---

These Extension Attributes complement the operational command model documented in the repository CLI reference (`docs/man/backblaze-rmm.md`) and provide the telemetry layer used for device segmentation and remediation workflows.

---

## Jamf Pro configuration notes

- Each Extension Attribute should be created as a **Script** type
- Inventory display type: **String**
- Scripts must run as **root** (default in Jamf)
- Values populate during inventory update (Recon)

---

## Notes

- All Extension Attributes rely on `bzcli` being present on the device
- If `bzcli` is not found, the EA returns a safe fallback value
- These EAs are designed to be lightweight and safe to run frequently
- Health classification logic should remain deterministic and documented.
- Thresholds (24h / 7d / etc.) may be adapted to organizational compliance requirements.
- Extension Attributes are designed for reporting and segmentation only; they do not modify device state.

# Addigy Inventory and Reporting Scripts – Backblaze (Optional)

This document describes optional **Addigy inventory and reporting scripts** used to report Backblaze Computer Backup state and metadata via `bzcli`.

These scripts are **not required** for basic Backblaze operation. They are intended for **visibility, reporting, and automation** during UAT and beyond.

## Deployment Context

These scripts are designed for the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this architecture, a single administrative Backblaze account or Business Group configuration manages multiple endpoints while Addigy provides inventory visibility, script execution, and device segmentation.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the official Backblaze documentation for the Addigy-aligned installer and workflow described in this repository.

---

## When to use these scripts

These inventory and reporting scripts are recommended if you need:

- Visibility into Backblaze installation and runtime state
- Device targeting for remediation workflows
- Operational reporting for IT administrators

They can be safely omitted if Addigy inventory and reporting are not required.

---

## Implemented inventory and reporting scripts

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