# Addigy Integration – Backblaze

This folder contains Addigy-specific scripts and documentation for integrating **Backblaze Computer Backup** using `bzcli` and the Backblaze installer workflow.

This implementation is intended as the Addigy-aligned baseline for enterprise and MSP validation. It reuses the proven Jamf Pro deployment model where possible, while adapting inputs, execution flow, and future policy handling to Addigy.

## Deployment Model

This Addigy integration is intended to support a **centralized Backblaze deployment model** commonly used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account (or Business Group configuration) manages multiple endpoints through Addigy automation policies and scripts.

For environments where each device signs in with its own Backblaze account (a decentralized deployment model), refer to the standard Backblaze deployment documentation on the Backblaze documentation site.

## Integration Model

This Addigy integration follows a layered automation model:

1. **Deployment Layer**  
   Silent installation and Business Group enrollment using Addigy-executed scripts.

2. **Telemetry Layer**  
   Device-state and client-state reporting patterns aligned with `bzcli` output and installer validation.

3. **Segmentation Layer**  
   Addigy-side grouping, scoping, and policy targeting patterns as sandbox validation matures.

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

It provides structured baseline building blocks for deploying and managing Backblaze Computer Backup in Addigy-managed environments.

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
    ├── extension-attributes/
    └── install/
