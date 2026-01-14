# Generic Integration

## Reporting (bzCLI)

The Generic integration includes platform‑agnostic reporting scripts powered by **bzCLI**.

These scripts provide:
- Client version
- Install status
- Backup status summary
- Last backup timestamp (ISO8601)
- Host GUID (HGUID)

Documentation:
- `docs/reporting.md` — How reporting works and how to integrate it into any RMM or script

Scripts:
- `scripts/reporting/client-version.sh`
- `scripts/reporting/installed.sh`
- `scripts/reporting/status-summary.sh`
- `scripts/reporting/last-backup-iso8601.sh`
- `scripts/reporting/hguid.sh`