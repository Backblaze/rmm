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

| Platform           | Status           |
|--------------------|------------------|
| **Jamf Pro**       | UAT / In Progress |
| Kandji             | Planned          |
| Addigy             | Planned          |
| JumpCloud          | Planned          |
| Generic (non‑RMM)  | Available        |

> ⚠️ Jamf Pro is currently in **UAT**. Scripts and documentation may change before general availability.

---

## Repository Structure

```text
rmm/
├── README.md
├── jamf/
│   ├── docs/
│   │   ├── README.md
│   │   ├── actions.md
│   │   ├── extension-attributes.md
│   │   └── optional-smart-groups.md
│   └── scripts/
│       ├── actions/
│       ├── configuration/
│       ├── extension-attributes/
│       └── install/
└── generic/
    ├── README.md
    ├── docs/
    │   ├── README.md
    │   ├── actions.md
    │   ├── install.md
    │   └── reporting.md
    └── scripts/
        ├── actions/
        ├── install/
        └── reporting/
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

If you are not using a supported RMM platform, start with the **Generic integration**:

- `generic/README.md`

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

## Known Apple Platform Limitations

The following behaviors are enforced by macOS and **cannot be bypassed by Jamf Pro, PPPC profiles, or any MDM solution**.

### Location Services (Backblaze / bzbmenu)

Backblaze features such as **Locate My Computer** rely on macOS Location Services.

Apple enforces a **two‑layer permission model**:

1. **Global Location Services toggle**
   - Must be enabled manually by the end user.
   - Cannot be enabled silently via MDM.

2. **Per‑application authorization (PPPC / TCC)**
   - Can be pre‑approved via configuration profiles.
   - Persists across reboots, updates, and device wipes once granted.

Because Backblaze uses multiple signed binaries (for example `Backblaze` and `bzbmenu`), **each binary appears separately** in Location Services and must be enabled once by the user.

After this one‑time approval:
- No additional prompts occur
- Permissions persist automatically
- Behavior remains consistent after reboot or reinstall

This is expected macOS behavior and does not indicate a deployment issue.
