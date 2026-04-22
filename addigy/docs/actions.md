# Jamf Pro – Backblaze Integration

This document describes how to integrate **Backblaze Computer Backup** with **Jamf Pro** using the reference scripts and configuration provided in this repository.

This Jamf implementation serves as the reference RMM model for enterprise deployment, telemetry, and operational control.

## Deployment Context

This Jamf integration follows the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account or Business Group configuration manages multiple endpoints through Jamf automation policies and scripts.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the official Backblaze Jamf documentation on the Backblaze documentation site.

---

## What is included

The Jamf integration is modular. You may deploy only what you need.

- **Installer**
  - Install or upgrade Backblaze
  - Enroll devices into a Backblaze Business Group

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
  - Examples for scoping and automation workflows

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

## Getting Started

1. Review the installer documentation
   - `jamf/scripts/install/install-backblaze.sh`

2. Create Jamf policies using the action scripts
   - `jamf/scripts/actions/`

3. (Optional) Add Extension Attributes for reporting
   - `jamf/scripts/extension-attributes/`

4. (Optional) Use Smart Groups for staged or phased rollouts
   - See `optional-smart-groups.md`

---

## Notes

- All scripts are intended to be reviewed and adapted to local Jamf standards.
- Defaults and examples may be adapted to align with organizational security and deployment standards.

# Jamf Actions – Backblaze (bzcli)

These operational actions correspond to the command model documented in the repository CLI reference (`docs/man/backblaze-rmm.md`) and represent common automation primitives used in RMM and MDM workflows.

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
  - `/var/log/backblaze_bzcli_action.log` (or the log path defined in the script)

---

## Error handling

- If `bzcli` is not found, the script exits with a non-zero status
- Exit codes are logged and visible in Jamf policy logs

---

## Notes

- These actions do not modify configuration or enrollment
- They assume Backblaze is already installed

# Addigy Actions – Backblaze (bzcli)

This document describes the Addigy-aligned operational action model for **Backblaze Computer Backup** using `bzcli`.

These actions correspond to the command model documented in the repository CLI reference (`docs/man/backblaze-rmm.md`) and represent common automation primitives used in RMM and MDM workflows.

The current purpose of this document is to define the intended action model for Addigy while the sandbox environment is being prepared. Live validation of these actions in Addigy is still pending.

---

## Deployment Context

This Addigy integration follows the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account or Business Group configuration manages multiple endpoints through Addigy automation policies and scripts.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the standard Backblaze deployment documentation on the Backblaze documentation site.

---

## What is included

The Addigy integration is modular. You may deploy only what you need.

- **Installer**
  - Install or upgrade Backblaze
  - Enroll devices into a Backblaze Business Group

- **Actions (bzcli)**
  - Trigger backup now
  - Pause backups
  - Resume backups

- **Reporting / Health-State Alignment (future)**
  - Device-state visibility concepts aligned with `bzcli`
  - Future health-state and reporting patterns pending sandbox validation

---

## Available actions

### Backup Now

**Planned script:**
```text
addigy/scripts/actions/backblaze-backup-now.sh
```

**Description:**
Triggers an immediate Backblaze backup if one is not already running.

**Typical use cases:**
- Manual remediation by IT
- Post-install verification
- User-initiated support workflow

---

### Pause Backup

**Planned script:**
```text
addigy/scripts/actions/backblaze-pause-backup.sh
```

**Description:**
Pauses Backblaze backups until they are explicitly resumed.

**Typical use cases:**
- Temporary bandwidth control
- Maintenance windows
- Change windows requiring backup suspension

---

### Resume Backup

**Planned script:**
```text
addigy/scripts/actions/backblaze-resume-backup.sh
```

**Description:**
Resumes Backblaze backups after being paused.

**Typical use cases:**
- End of maintenance window
- Automated remediation
- Restore normal backup operations after temporary suspension

---

## Addigy action model notes

- No final Addigy-specific input model has been validated yet for these action scripts
- Scripts are expected to run as **root** in the managed execution context
- Action logging should be separated from installer logging where possible
- The preferred command model remains `bzcli`-driven and consistent with the shared RMM command reference

---

## Validation status

At the current stage:
- the **installer baseline** has been prepared
- the **sandbox / trial environment** is still pending
- these actions are documented as the intended operational model, but they have not yet been live-validated in Addigy

---

## Error handling expectations

Once implemented and validated, action scripts should follow the same operational expectations used in the other platform baselines:

- if `bzcli` is not found, the script should exit with a non-zero status
- exit codes should be logged and visible through the platform execution logs
- actions should not modify enrollment or identity state
- actions should assume Backblaze is already installed

---

## Notes

- This document is intentionally baseline-oriented and should be updated once Addigy sandbox validation is complete.
- The goal is to keep the action model conceptually aligned with the Jamf and generic RMM patterns while adapting execution details to Addigy.
# Addigy – Backblaze Integration

This document describes how to integrate **Backblaze Computer Backup** with **Addigy** using the reference scripts and configuration provided in this repository.

This Addigy implementation serves as the Addigy-aligned baseline for enterprise deployment, telemetry, and operational control.

## Deployment Context

This Addigy integration follows the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account or Business Group configuration manages multiple endpoints through Addigy automation policies and scripts.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the standard Backblaze deployment documentation on the Backblaze documentation site.

---

## What is included

The Addigy integration is modular. You may deploy only what you need.

- **Installer**
  - Install or upgrade Backblaze
  - Enroll devices into a Backblaze Business Group

- **Actions (bzcli)**
  - Trigger backup now
  - Pause backups
  - Resume backups
  - Set PEK
  - Change PEK
  - Clear PEK

- **Reporting / Inventory**
  - Backblaze client version
  - Installation state
  - Backup status summary
  - Last backup timestamp
  - Backblaze Host GUID (HGUID)
  - Health score

- **Profiles**
  - Baseline macOS configuration profiles copied into the Addigy platform folder for testing and future policy alignment

---

## Directory structure

```text
addigy/
├── README.md
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── advanced-installer-json.md
│   ├── extension-attributes.md
│   ├── health-score.md
│   └── optional-smart-groups.md
├── profiles/
├── scripts/
│   ├── actions/
│   ├── install/
│   ├── inventory/
│   └── reporting/
```

---

## Getting Started

1. Review the installer documentation
   - `addigy/scripts/install/`
   - `addigy/docs/advanced-installer-json.md`

2. Review and deploy the operational action scripts
   - `addigy/scripts/actions/`

3. Add reporting and inventory scripts as needed
   - `addigy/scripts/reporting/`
   - `addigy/scripts/inventory/`

4. Review the baseline profiles for future Addigy policy mapping
   - `addigy/profiles/`

---

## Notes

- All scripts are intended to be reviewed and adapted to local Addigy standards.
- Defaults and examples may be adjusted to align with organizational security and deployment requirements.
- This baseline is designed to stay conceptually aligned with the shared Backblaze RMM model while using Addigy-specific execution patterns.

# Addigy Actions – Backblaze (bzcli)

These operational actions correspond to the command model documented in the repository CLI reference (`docs/man/backblaze-rmm.md`) and represent common automation primitives used in RMM and MDM workflows.

This document describes the **Addigy action scripts** that use `bzcli` to control Backblaze Computer Backup on macOS devices.

These scripts are designed to run through **Addigy policies or live commands** and do not require user interaction.

---

## Available actions

### Backup Now

**Script:**
```text
addigy/scripts/actions/backblaze-backup-now.sh
```

**Description:**
Triggers an immediate Backblaze backup if one is not already running.

**Typical use cases:**
- Manual remediation by IT
- Post-install verification
- Support-driven backup trigger

---

### Pause Backup

**Script:**
```text
addigy/scripts/actions/backblaze-pause-backup.sh
```

**Description:**
Pauses Backblaze backups until they are resumed.

**Typical use cases:**
- Temporary bandwidth control
- Maintenance windows
- Change windows requiring backup suspension

---

### Resume Backup

**Script:**
```text
addigy/scripts/actions/backblaze-resume-backup.sh
```

**Description:**
Resumes Backblaze backups after being paused.

**Typical use cases:**
- End of maintenance window
- Automated remediation
- Restore normal backup operations after temporary suspension

---

### Set PEK

**Script:**
```text
addigy/scripts/actions/backblaze-set-pek.sh
```

**Description:**
Sets a new Private Encryption Key using group-authenticated `bzcli` actions.

**Typical use cases:**
- Initial PEK assignment
- Controlled rollout of private encryption in managed environments

---

### Change PEK

**Script:**
```text
addigy/scripts/actions/backblaze-change-pek.sh
```

**Description:**
Changes an existing Private Encryption Key to a new one using group-authenticated `bzcli` actions.

**Typical use cases:**
- Key rotation workflows
- Security-driven encryption key updates

---

### Clear PEK

**Script:**
```text
addigy/scripts/actions/backblaze-clear-pek.sh
```

**Description:**
Clears an existing Private Encryption Key using group-authenticated `bzcli` actions.

**Typical use cases:**
- PEK rollback scenarios
- Managed decryption-key removal workflows

---

## Addigy execution notes

- Scripts are expected to run as **root** in the Addigy managed execution context.
- Some `bzcli` operations may work best when executed in the active console-user context; current scripts handle this where needed.
- Logging should remain separated by function where possible:
  - action logs: `/var/log/backblaze_bzcli_action.log`
  - PEK / management action logs: `/var/log/backblaze_mdm_actions.log`
- The preferred command model remains `bzcli`-driven and aligned with the shared RMM command reference.

---

## Validation status

At the current stage:
- the **installer baseline** has been adapted for Addigy
- the **core action set** has been added to the Addigy platform folder
- the **reporting and inventory baseline** has been added for QA validation
- baseline **profiles** have been copied into the Addigy platform folder for future mapping and testing
- continued live QA in Addigy should confirm final behavior, policy mapping, and operational guidance

---

## Error handling expectations

Action scripts should follow these operational expectations:

- if `bzcli` is not found, the script should exit with a non-zero status
- exit codes should be logged and visible through Addigy execution logs
- actions should not modify enrollment or account identity state unless explicitly designed to do so
- actions should assume Backblaze is already installed unless the script is part of the install workflow

---

## Notes

- This document should evolve as Addigy QA validation progresses.
- The goal is to keep the action model aligned with the Jamf and generic RMM baselines while documenting Addigy-specific execution details clearly.