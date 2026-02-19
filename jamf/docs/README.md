# Jamf Pro Integration – Backblaze

This folder contains Jamf Pro–specific scripts and documentation for integrating **Backblaze Computer Backup** using `bzcli`.

This reference implementation demonstrates enterprise-scale deployment, monitoring, and operational automation using Jamf-native constructs. It can be adapted to fit specific customer environments and policy requirements.

## Intended Audience

This integration is designed for:

- Enterprise IT administrators
- Jamf Pro administrators
- Managed Service Providers (MSPs)
- RMM automation engineers

It provides structured, production-ready building blocks for deploying and managing Backblaze Computer Backup at scale.

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

## Documentation

- **Actions** (backup now / pause / resume): `actions.md`
- **Extension Attributes** (inventory/reporting in Jamf): `extension-attributes.md`
- **Smart Computer Groups** (optional examples): `optional-smart-groups.md`

---

## Scripts

### Install

- `scripts/install/install-backblaze.sh`

Installs (or upgrades) Backblaze Computer Backup and can enroll a device into a Business Group using Jamf script parameters.

### Actions (bzcli)

- `scripts/actions/backup-now.sh`
- `scripts/actions/pause-backup.sh`
- `scripts/actions/resume-backup.sh`

### Extension Attributes (Reporting)

- `scripts/extension-attributes/backblaze-client-version.sh`
- `scripts/extension-attributes/backblaze-installed.sh`
- `scripts/extension-attributes/backblaze-status-summary.sh`
- `scripts/extension-attributes/backblaze-last-backup-iso8601.sh`
- `scripts/extension-attributes/backblaze-hguid.sh`

---

## Notes

- Smart Computer Groups are optional; core functionality works without them.
- Validate in UAT first, then adapt defaults (installer URL/version, scoping, and parameters) for production.
