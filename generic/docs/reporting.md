# Reporting (Generic – bzCLI Telemetry Model)

This document describes the platform-agnostic reporting scripts built on top of the Backblaze `bzcli` command-line interface.

These scripts expose backup telemetry in a deterministic, automation-safe format suitable for:

- Custom RMM platforms
- SIEM ingestion
- Monitoring pipelines
- Compliance dashboards
- Shell-based automation
- CSV / BI exports

All scripts return plain-text output and are safe for scheduled or automated execution.

---

## Available Reporting Scripts

| Script | Purpose | Underlying bzCLI Command |
|--------|---------|--------------------------|
| `client-version.sh` | Returns installed Backblaze client version | `bzcli report -v /client/version` |
| `installed.sh` | Detects installation presence | Binary presence check |
| `status-summary.sh` | Returns backup status summary | `bzcli report -v /backup/status` |
| `last-backup-iso8601.sh` | Returns last successful backup timestamp (ISO8601) | `bzcli report -v /backup/lastbackup` |
| `hguid.sh` | Returns Host GUID identifier | `bzcli report -v /client/hguid` |

Location:

```
generic/scripts/reporting/
```

---

## Execution Requirements

- macOS
- Backblaze Desktop Client v10+
- `bzcli` installed (default path shown below)
- Root execution recommended

Canonical `bzcli` path:

```
/Applications/Backblaze.app/Contents/MacOS/bzcli
```

---

## Usage Examples

Run as root (recommended):

```
sudo bash generic/scripts/reporting/client-version.sh
sudo bash generic/scripts/reporting/status-summary.sh
sudo bash generic/scripts/reporting/last-backup-iso8601.sh
```

Each script:

- Validates `bzcli` availability
- Executes a deterministic `bzcli report` command
- Returns a normalized value
- Uses a non-zero exit code if execution fails

---

## Output Model

All reporting scripts return a single value to stdout.

Example outputs:

Client Version:
```
10.0.0.1016
```

Backup Status:
```
Running
```

Last Backup:
```
2026-02-19T15:42:12Z
```

If data is unavailable, scripts may return:

```
null
```

or exit non-zero depending on condition.

---

## Automation Pattern

Typical monitoring workflow:

1. Collect telemetry via reporting scripts
2. Parse output into monitoring system
3. Apply compliance rules (e.g., stale > 24h)
4. Trigger remediation action if required
5. Re-evaluate state during next telemetry cycle

This pattern enables deterministic monitoring without relying on UI or proprietary dashboards.

---

## Integration Examples

These scripts can be integrated into:

- Custom RMM ingestion frameworks
- Cron-based monitoring checks
- Launchd scheduled jobs
- Enterprise compliance pipelines
- Health score aggregation models

They are intentionally platform-neutral and reusable.

---

## Building Composite Health Models

The scripts in this directory expose primitive telemetry signals.

Composite health or compliance models (e.g., GREEN / YELLOW / RED classification) should be implemented at the RMM or orchestration layer.

Example aggregation pattern:

1. Collect:
   - installation state
   - backup status
   - last backup timestamp
2. Apply organizational compliance thresholds
3. Classify device state
4. Trigger remediation action if required

This keeps the generic layer deterministic and platform-neutral while allowing flexibility at higher integration layers.

---

## Design Principles

- Deterministic output
- Single-responsibility scripts
- No external dependencies
- Vendor-neutral architecture
- Automation-safe formatting

---

## Support Model

These scripts are provided as reference implementations and may require adaptation to align with organizational monitoring standards or infrastructure requirements.