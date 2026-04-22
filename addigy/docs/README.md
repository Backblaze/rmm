# Addigy Integration – Backblaze

This folder contains Addigy-specific scripts, profiles, and documentation for integrating **Backblaze Computer Backup** with Addigy-managed macOS devices.

This implementation is intended as the Addigy-aligned baseline for enterprise and MSP validation. It reuses the broader Backblaze RMM deployment model where it makes sense, while adapting execution flow, script inputs, reporting paths, and operational guidance to Addigy.

## Deployment Model

This Addigy integration is intended to support a **centralized Backblaze deployment model** commonly used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account or Business Group configuration manages multiple endpoints through Addigy policies, scripts, and reporting workflows.

For environments where each device signs in with its own Backblaze account (a decentralized deployment model), refer to the standard Backblaze deployment documentation on the Backblaze documentation site.

## Integration Model

This Addigy integration follows a layered automation model:

1. **Deployment Layer**  
   Silent installation, configuration, and Business Group enrollment using Addigy-executed scripts.

2. **Reporting Layer**  
   Device-state and client-state reporting patterns aligned with `bzcli` output and installer validation.

3. **Segmentation Layer**  
   Addigy-side scoping, policy assignment, and future smart filtering patterns as validation matures.

4. **Operational Layer**  
   Remote backup control using `bzcli` action scripts.

5. **Compliance Layer (Optional)**  
   Deterministic health classification and future remediation workflows where supported by the platform.

This structure is intended to align with Addigy-native automation patterns while keeping the Backblaze deployment flow consistent with the broader RMM architecture.

---

## Intended Audience

This integration is designed for:

- Enterprise IT administrators
- Addigy administrators
- Managed Service Providers (MSPs)
- RMM automation engineers

It provides baseline building blocks for deploying, validating, and operating Backblaze Computer Backup in Addigy-managed environments.

---

## Repository layout (Addigy)

```text
addigy/
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── advanced-installer-json.md
│   ├── extension-attributes.md
│   ├── health-score.md
│   ├── minimal-enterprise-example.json
│   └── optional-smart-groups.md
├── examples/
├── profiles/
└── scripts/
    ├── actions/
    ├── configuration/
    ├── install/
    ├── inventory/
    └── reporting/
```

## What is included

- **Installation scripts** for Addigy-based deployment flows
- **Operational action scripts** for `backup-now`, `pause-backup`, `resume-backup`, and PEK workflows
- **Inventory scripts** for installed state, client version, and HGUID reporting
- **Reporting scripts** for status summary, health score, and last-backup visibility
- **Baseline configuration profiles** copied into the Addigy platform folder for validation and QA
- **Documentation** covering installer inputs, actions, reporting, and optional segmentation patterns

## Current baseline status

The Addigy folder should be treated as an active platform baseline.

At this stage, the repository structure, scripts, and profiles are intended to support:

- functional validation in Addigy UAT
- QA comparison against the established Jamf baseline
- incremental documentation cleanup as Addigy-specific behavior is finalized

Where platform-specific behavior is still evolving, prefer the Addigy scripts and docs in this folder over assumptions carried over from other MDM implementations.
