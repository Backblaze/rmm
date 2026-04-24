# Jamf Pro Actions – Backblaze (Decentralized)

This document describes the **Jamf Pro action scripts** that use `bzcli` to control Backblaze Computer Backup on macOS devices in the **decentralized Jamf deployment model**.

In this model, Backblaze is installed through Jamf Pro, but each device signs in with its own Backblaze account rather than being centrally enrolled into a shared administrative configuration.

These scripts are designed to be used in **Jamf Policies** and do not require user interaction.

---

## Deployment context

This Jamf implementation follows the **decentralized Backblaze deployment model** documented for Jamf Pro on the Backblaze documentation site.

In this model:

- Jamf Pro is responsible for deployment and script execution
- Backblaze account sign-in happens per device or per end user workflow
- `bzcli` is used for post-install operational control
- Optional inventory, extension attributes, and smart groups may still be used for reporting and remediation

This makes the action layer reusable even when enrollment and account association are not centrally managed.

---

## What is included

The Jamf action layer is modular. You may deploy only what you need.

- **Actions (`bzcli`)**
  - Trigger backup now
  - Pause backups
  - Resume backups

- **Optional telemetry and reporting**
  - Backup status summary
  - Last successful backup timestamp
  - Installed state
  - Client version
  - Host GUID (HGUID)

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
    ├── extension-attributes/
    └── install/
```

---

## Getting started

1. Review the decentralized installer documentation
   - `jamf/docs/README.md`
   - `jamf/scripts/install/`

2. Create Jamf policies using the action scripts
   - `jamf/scripts/actions/`

3. Optionally add Extension Attributes for reporting
   - `jamf/scripts/extension-attributes/`

4. Optionally use Smart Groups for staged remediation or operational visibility
   - `jamf/docs/optional-smart-groups.md`

---

## Available actions

### Backup Now

**Script:**
```sh
jamf/scripts/actions/backblaze-backup-now.sh
```

**Description:**
Triggers an immediate Backblaze backup if one is not already running.

**Typical use cases:**
- Manual remediation by IT
- Post-install verification
- User-initiated Self Service action
- Validation after account sign-in

---

### Pause Backup

**Script:**
```sh
jamf/scripts/actions/backblaze-pause-backup.sh
```

**Description:**
Pauses Backblaze backups until they are explicitly resumed.

**Typical use cases:**
- Temporary bandwidth control
- Maintenance windows
- Troubleshooting or test scenarios

---

### Resume Backup

**Script:**
```sh
jamf/scripts/actions/backblaze-resume-backup.sh
```

**Description:**
Resumes Backblaze backups after being paused.

**Typical use cases:**
- End of maintenance window
- Automated remediation
- Recovery after user-side interruption

---

## Jamf policy configuration notes

- No script parameters are required for the standard action scripts
- Scripts should run as **root** in Jamf Pro
- Some `bzcli` operations may work best when a valid console user session exists
- Action logs are typically written to:
  - `/var/log/backblaze_bzcli_action.log`

---

## Error handling

- If `bzcli` is not found, the script exits with a non-zero status
- Exit codes are visible in Jamf policy logs
- Status checks before and after the action help validate expected state transitions
- Logging should be reviewed during UAT to confirm behavior across device states

---

## Notes

- These actions do not perform installation or account creation
- They assume Backblaze is already installed on the device
- They are intended to complement the decentralized Jamf installer workflow
- Organizations may adapt these scripts to match local Jamf policy naming, scoping, and Self Service conventions
