# Jamf Extension Attributes – Backblaze (Optional)

This document describes optional **Jamf Pro Extension Attributes (EAs)** used to report Backblaze Computer Backup state and metadata via `bzcli`.

These Extension Attributes are **not required** for basic Backblaze operation. They are intended for **visibility, reporting, and automation** during UAT and beyond.

---

## When to use Extension Attributes

Extension Attributes are recommended if you need:

- Inventory visibility into Backblaze status
- Device targeting for remediation workflows
- Operational reporting for IT administrators

They can be safely omitted if Jamf inventory reporting is not required.

---

## Implemented Extension Attributes (Jamf Pro)

The following Extension Attributes are provided and validated in Jamf Pro UAT.

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
