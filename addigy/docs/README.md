# Jamf Pro Integration – Backblaze

This folder contains Jamf Pro–specific scripts and documentation for integrating **Backblaze Computer Backup** using `bzcli`.

This reference implementation demonstrates enterprise-scale deployment, monitoring, and operational automation using Jamf-native constructs. It can be adapted to fit specific customer environments and policy requirements.

## Deployment Model

This Jamf integration demonstrates a **centralized Backblaze deployment model** commonly used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account (or Business Group configuration) manages multiple endpoints through Jamf automation policies and scripts.

For environments where each device signs in with its own Backblaze account (a decentralized deployment model), refer to the standard Backblaze Jamf documentation on the Backblaze documentation site.

## Integration Model

This Jamf integration follows a layered automation model:

1. **Deployment Layer**  
   Silent installation and Business Group enrollment using Jamf policies.

2. **Telemetry Layer**  
   Inventory data collection via Jamf Extension Attributes powered by `bzcli`.

3. **Segmentation Layer**  
   Dynamic Smart Computer Groups for scoped automation.

4. **Operational Layer**  
   Remote backup control using `bzcli` action scripts.

5. **Compliance Layer (Optional)**  
   Deterministic health classification and automated remediation workflows.

This structure aligns with Jamf-native best practices and supports scalable enterprise deployments.

---

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

## CLI Reference

A Unix-style command reference for operational automation commands used by
RMM and MDM platforms is available in the repository:

`docs/man/backblaze-rmm.md`

This reference documents the operational command model used by the
Backblaze RMM automation layer and complements the Jamf integration scripts.

---

## Scripts

## Script Index

| Script | Phase | Purpose |
|--------|-------|---------|
| install-backblaze.sh | Deployment | Silent installation and Business Group enrollment |
| backup-now.sh | Operations | Trigger immediate backup |
| pause-backup.sh | Operations | Pause backup activity |
| resume-backup.sh | Operations | Resume backup activity |
| backblaze-client-version.sh | Telemetry | Report installed client version |
| backblaze-installed.sh | Telemetry | Detect installation presence |
| backblaze-status-summary.sh | Telemetry | Report backup status summary |
| backblaze-last-backup-iso8601.sh | Telemetry | Report last successful backup timestamp |
| backblaze-hguid.sh | Telemetry | Report Host GUID identifier |

---

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

## Deployment Considerations

- Smart Computer Groups are optional; core functionality works without them.
- Validate the integration in a staged or non-production environment before broad rollout.
- Adjust installer URL/version, scoping, and script parameters to align with organizational security standards.
- Extension Attributes are inventory-driven and do not modify device state.
- Health classification thresholds (if implemented) should align with internal compliance policies.

---

## Support & Scope

This Jamf integration is provided as a reference implementation for enterprise automation scenarios.

Backblaze supports the core client functionality and `bzcli` interface.  
Customization of Jamf policies, Smart Groups, compliance models, and deployment architecture remains the responsibility of the implementing organization.

Organizations are encouraged to adapt logging, validation logic, segmentation strategy, and health classification thresholds to match internal operational and regulatory requirements.
