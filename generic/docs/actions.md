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
