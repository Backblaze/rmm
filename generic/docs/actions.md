# Actions (Generic)

These scripts map directly to `bzcli action` commands.

## Scripts
- `generic/scripts/actions/backup-now.sh`
- `generic/scripts/actions/pause-backup.sh`
- `generic/scripts/actions/resume-backup.sh`

## Usage
Run as root (recommended):

```
sudo bash generic/scripts/actions/backup-now.sh
sudo bash generic/scripts/actions/pause-backup.sh
sudo bash generic/scripts/actions/resume-backup.sh
```

## Notes
- Scripts use the canonical macOS `bzcli` path:
  `/Applications/Backblaze.app/Contents/MacOS/bzcli`
- Each script returns a non-zero exit code if the action fails.

# Actions (Generic – bzCLI Operational Control)

This document describes the generic, platform-agnostic operational action scripts built on top of the Backblaze `bzcli` command-line interface.

These scripts are designed for environments that:

- Do not use Jamf or other managed RMM platforms
- Use custom automation frameworks
- Require direct shell-based operational control
- Integrate backup state changes into orchestration pipelines

Each script maps directly to a supported `bzcli action` command.

---

## Available Action Scripts

| Script | Purpose | Underlying Command |
|--------|---------|-------------------|
| `backup-now.sh` | Trigger an immediate backup | `bzcli action backup-now` |
| `pause-backup.sh` | Pause backup activity | `bzcli action pause` |
| `resume-backup.sh` | Resume backup activity | `bzcli action resume` |

Location:

```
generic/scripts/actions/
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
sudo bash generic/scripts/actions/backup-now.sh
sudo bash generic/scripts/actions/pause-backup.sh
sudo bash generic/scripts/actions/resume-backup.sh
```

These scripts:

- Validate `bzcli` availability
- Execute the appropriate action
- Return a non-zero exit code if the action fails

---

## Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| `0` | Action executed successfully |
| `>0` | Action failed (see stderr output) |

This makes the scripts suitable for:

- CI/CD pipelines
- Automation frameworks
- Scheduled execution
- Health remediation workflows

---

## Automation Pattern

Typical automation flow:

1. Evaluate backup state (`bzcli report`)
2. Determine compliance condition
3. Trigger operational action (`pause`, `resume`, or `backup-now`)
4. Re-evaluate state during next telemetry cycle

This model enables deterministic operational enforcement without requiring user interaction.

---

## Design Principles

- Idempotent execution
- No external dependencies
- Vendor-neutral implementation
- Automation-safe output
- Compatible with RMM ingestion pipelines

---

## Support Model

These scripts are provided as reference implementations and may require adaptation to align with organizational security policies and infrastructure standards.