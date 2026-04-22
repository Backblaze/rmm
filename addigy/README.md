# Addigy Platform Baseline

This directory contains the Addigy-specific baseline for **Backblaze Computer Backup** deployment and management in enterprise and MSP environments.

The goal of this platform baseline is to reuse the proven Jamf Pro installer and documentation model where possible, while adapting execution details, inputs, and future policy behavior to Addigy.

## Purpose

This folder serves as the Addigy platform entry point in the RMM repository.

It is intended to:
- provide the initial Addigy installer baseline
- organize Addigy-specific documentation and examples
- prepare the repository structure for future Addigy actions, reporting, and configuration work
- support sandbox / UAT validation once vendor access is available

## Current Status

- initial Addigy directory structure has been created
- the installer baseline has been adapted from the Jamf Pro implementation
- Addigy documentation has been initialized
- sandbox / trial credentials are pending from the vendor
- live validation has not started yet

## Directory Layout

```text
addigy/
├── README.md
├── docs/
├── examples/
├── profiles/
└── scripts/
```

## Main Areas

### `docs/`
Addigy-specific documentation for the installer model, action model, health/reporting concepts, and future platform alignment.

### `examples/`
Reserved for sample configuration examples, JSON input examples, and future Addigy-specific test inputs.

### `profiles/`
Reserved for future Addigy-related profile references if required by the platform.

### `scripts/`
Contains the Addigy installer baseline and placeholder folders for future actions, configuration, and reporting work.

## Recommended Entry Point

Start with:

- `docs/README.md`

This document explains the Addigy deployment model, current baseline, and next validation steps in more detail.

## Notes

This is currently a baseline / pre-validation implementation. It is expected to evolve once Addigy sandbox testing begins and platform-specific execution details are confirmed.
# Addigy Platform Baseline

This directory contains the Addigy-specific baseline for **Backblaze Computer Backup** deployment and management in enterprise and MSP environments.

The goal of this platform baseline is to provide an Addigy-aligned starting point for installer execution, operational actions, reporting, and profile references, while keeping the overall repository structure consistent with the other platform implementations in this repository.

## Purpose

This folder serves as the Addigy platform entry point in the RMM repository.

It is intended to:
- provide the initial Addigy installer baseline
- organize Addigy-specific documentation, examples, profiles, and scripts
- prepare the repository structure for Addigy operational actions, reporting, and configuration work
- support QA validation and future platform refinement as Addigy behavior is confirmed

## Current Status

- initial Addigy directory structure has been created
- the installer baseline has been adapted for Addigy execution
- Addigy action, reporting, and inventory scripts have been added
- baseline configuration profiles have been copied into the platform folder for reference and testing
- Addigy documentation has been initialized and still needs final cleanup and alignment
- QA validation is the current next phase

## Directory Layout

```text
addigy/
├── README.md
├── docs/
├── examples/
├── profiles/
└── scripts/
```

## Main Areas

### `docs/`
Addigy-specific documentation for the installer model, operational actions, reporting concepts, health scoring, and future platform alignment.

### `examples/`
Reserved for sample configuration examples, JSON input examples, and future Addigy-specific test inputs.

### `profiles/`
Contains baseline macOS configuration profiles currently being carried for Addigy testing and reference.

### `scripts/`
Contains the Addigy installer baseline plus supporting action, inventory, and reporting scripts.

## Recommended Entry Point

Start with:

- `docs/README.md`

This document explains the Addigy deployment model, current baseline, and next validation steps in more detail.

## Notes

This implementation is still evolving. The current focus is QA validation, documentation cleanup, and confirming Addigy-specific execution details so the platform baseline can move from initial parity work into validated operational guidance.