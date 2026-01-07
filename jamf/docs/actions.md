# Jamf Pro – Backblaze Integration (UAT)

This documentation describes how to integrate **Backblaze Computer Backup** with **Jamf Pro** using scripts and configuration provided in this repository.

This Jamf implementation is currently in **UAT** and intended for internal testing and validation before customer-facing release.

---

## What is included

The Jamf integration is modular. You may deploy only what you need.

- **Installer**
  - Install or upgrade Backblaze
  - Enroll devices into a Backblaze Business Group (UAT)

- **Actions (bzcli)**
  - Trigger backup now
  - Pause backups
  - Resume backups

- **Extension Attributes (optional)**
  - Backblaze client version
  - Installation state
  - Backup status summary
  - Last successful backup timestamp
  - Backblaze Host GUID (HGUID)

- **Smart Groups (optional)**
  - Examples for scoping and automation during UAT

---

## Directory structure

```text
jamf/
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── extension-attributes.md
│   └── optional-smart-groups.md
└── scripts/
    ├── actions/
    ├── configuration/
    ├── extension-attributes/
    └── install/
```

---

## How to start (UAT)

1. Review the installer documentation
   - `jamf/scripts/install/install-backblaze.sh`

2. Create Jamf policies using the action scripts
   - `jamf/scripts/actions/`

3. (Optional) Add Extension Attributes for reporting
   - `jamf/scripts/extension-attributes/`

4. (Optional) Use Smart Groups during UAT
   - See `optional-smart-groups.md`

---

## Notes

- All scripts are intended to be reviewed and adapted to local Jamf standards.
- Customer-ready defaults will be finalized after UAT completes.

# Jamf Actions – Backblaze (bzcli)

This document describes the **Jamf Pro action scripts** that use `bzcli` to control Backblaze Computer Backup on macOS devices.

These scripts are designed to be used in **Jamf Policies** and do not require user interaction.

---

## Available actions

### Backup Now

**Script:**
```
jamf/scripts/actions/backblaze-backup-now.sh
```

**Description:**
Triggers an immediate Backblaze backup if one is not already running.

**Typical use cases:**
- Manual remediation by IT
- Post-install verification
- User-initiated self service action

---

### Pause Backup

**Script:**
```
jamf/scripts/actions/backblaze-pause-backup.sh
```

**Description:**
Pauses Backblaze backups until they are explicitly resumed.

**Typical use cases:**
- Temporary bandwidth control
- Maintenance windows

---

### Resume Backup

**Script:**
```
jamf/scripts/actions/backblaze-resume-backup.sh
```

**Description:**
Resumes Backblaze backups after being paused.

**Typical use cases:**
- End of maintenance window
- Automated remediation

---

## Jamf policy configuration notes

- No script parameters are required
- Scripts must run as **root** (default in Jamf)
- Scripts log to:
  - `/var/log/backblaze_bzcli_action.log`

---

## Error handling

- If `bzcli` is not found, the script exits with a non-zero status
- Exit codes are logged and visible in Jamf policy logs

---

## Notes

- These actions do not modify configuration or enrollment
- They assume Backblaze is already installed
