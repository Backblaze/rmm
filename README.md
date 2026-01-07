# Backblaze RMM Integration

This repository contains platform-specific integration scripts and documentation
to enable **Backblaze Computer Backup** automation through popular
**RMM / MDM platforms**.

The integrations are designed to help MSPs and IT administrators:
- Deploy Backblaze via their RMM
- Execute operational actions using `bzcli`
- Monitor backup state (optional)
- Automate remediation workflows

---

## Supported Platforms

| Platform     | Status |
|--------------|--------|
| Jamf Pro     | UAT / In Progress |
| Kandji       | Planned |
| Addigy       | Planned |
| JumpCloud    | Planned |

Each platform is implemented independently to keep scripts and documentation
clear and easy to adapt.

---

## Repository Structure
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