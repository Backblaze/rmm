# Backblaze RMM Integration

This repository contains **platform-specific integration scripts and documentation** to enable **Backblaze Computer Backup** automation through popular **RMM / MDM platforms**.

The goal is to provide IT administrators and MSPs with clear, copy‑paste‑ready building blocks that can be adapted to their environment.

## What this repo provides

Depending on the platform, integrations may include:

- Silent installation and upgrade of Backblaze Computer Backup
- Optional Business Group enrollment
- Operational actions using `bzcli` (backup now, pause, resume)
- Inventory and reporting via Extension Attributes (optional)
- Examples for automation and remediation workflows

Each platform implementation is **self‑contained** to keep scripts and documentation easy to understand and reuse.

---

## Supported Platforms

| Platform     | Status |
|--------------|--------|
| **Jamf Pro** | UAT / In Progress |
| Kandji       | Planned |
| Addigy       | Planned |
| JumpCloud    | Planned |

> ⚠️ Jamf Pro is currently in **UAT**. Scripts and documentation may change before general availability.

---

## Repository Structure

```text
rmm/
├── README.md
└── jamf/
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

### Platform layout philosophy

- Each platform lives under its own top‑level folder (e.g. `jamf/`).
- Documentation (`docs/`) lives next to the scripts it describes.
- Scripts are grouped by function (install, actions, reporting).
- Optional features are clearly marked and not required for baseline deployments.

---

## Getting started

If you are using **Jamf Pro**, start here:

- `jamf/docs/README.md`

That document explains:

- How to deploy the installer script
- How to configure optional `bzcli` actions
- How to add Extension Attributes (optional)
- How to use Smart Groups during UAT (optional)

---

## Notes

- This repository is intended as a **reference implementation**.
- Administrators should review and adapt scripts to meet their internal security and operational requirements.
- Customer‑facing defaults will be finalized after UAT.