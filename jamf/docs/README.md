# Jamf Pro Integration – Backblaze (UAT)

This document describes how to integrate **Backblaze Computer Backup** with **Jamf Pro** using the scripts and documentation provided in this repository.

The Jamf integration is currently validated in a **Jamf Pro UAT / sandbox environment** and is intended as a reference implementation for internal testing prior to customer-facing release.

---

## Scope

The Jamf integration supports the following capabilities:

- Installation and upgrade of Backblaze Computer Backup
- Enrollment into a Backblaze Business Group (UAT)
- Operational actions using `bzcli`
- Optional reporting via Extension Attributes
- Optional automation via Smart Computer Groups

All components are **modular** and may be adopted independently.

---

## Repository layout (Jamf)

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

## Installation

Backblaze Business (v10 – UAT) can be installed via Jamf using a dedicated installer script.

**Installer script:**
```
jamf/scripts/install/install-backblaze.sh
```

The installer script is intended to be executed via a Jamf Policy scoped to devices where Backblaze is not yet installed.

During UAT, the installer:
- Requires Business Group enrollment parameters
- Uses an internal Backblaze v10 installer by default

---

## Actions (bzcli)

Operational actions are implemented using `bzcli` and executed through Jamf Policies.

Available actions include:
- Trigger backup now
- Pause backups
- Resume backups

See **`actions.md`** for details.

---

## Extension Attributes (optional)

Optional Extension Attributes provide inventory visibility and reporting within Jamf Pro, including:
- Backblaze client version
- Installation state
- Backup status summary
- Last successful backup timestamp
- Backblaze Host GUID (HGUID)

See **`extension-attributes.md`** for details.

---

## Smart Computer Groups (optional)

Example Smart Computer Groups are provided to demonstrate scoping and automation during UAT.

These groups are **not required** for baseline deployments.

See **`optional-smart-groups.md`** for details.

---

## Notes

- All scripts should be reviewed and adapted to local Jamf standards before deployment.
- Customer-ready defaults and documentation will be finalized after UAT completion.
