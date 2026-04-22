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