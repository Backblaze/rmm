# Generic Backblaze Integration (bzcli)

This directory provides a **platform‑agnostic reference implementation** for integrating Backblaze Computer Backup using `bzcli`.

It is designed for environments that:

- Use a custom or in‑house RMM platform
- Require portable shell‑based automation
- Integrate backup telemetry into existing monitoring pipelines
- Prefer a vendor‑neutral implementation model

All scripts produce **plain‑text, automation‑safe output** suitable for:

- RMM ingestion
- Shell automation
- Scheduled execution (cron / launchd)
- Export to CSV, Excel, or BI systems

## Intended Audience

This integration is intended for:

- Enterprise IT administrators
- Managed Service Providers (MSPs)
- DevOps and automation engineers
- Security and compliance teams integrating backup telemetry

It provides reusable, production‑ready building blocks for backup deployment, monitoring, and operational control.

---

## Repository layout

```text
generic/
├── README.md
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── install.md
│   └── reporting.md
└── scripts/
    ├── actions/
    │   ├── backup-now.sh
    │   ├── pause-backup.sh
    │   └── resume-backup.sh
    ├── install/
    │   └── install-backblaze.sh
    └── reporting/
        ├── client-version.sh
        ├── installed.sh
        ├── status-summary.sh
        ├── last-backup-iso8601.sh
        └── hguid.sh
```

---

## Documentation

| Topic | File |
|------|------|
| Backup actions | `actions.md` |
| Business Group installation | `install.md` |
| Reporting & monitoring | `reporting.md` |

---

## Requirements

- macOS
- Backblaze Desktop Client v10+
- `bzcli` installed with the Backblaze client (default path shown below)

  ```
  /Applications/Backblaze.app/Contents/MacOS/bzcli
  ```

---

## Output format

All reporting scripts output **plain values** (no Jamf XML, no quotes):

Examples:
```
10.0.0.1016
Running
2025-01-02T03:14:55Z
e5b623168b5e903e9aab0c17
```

This makes them safe for:
- RMM inventory
- CSV export
- Excel / BI pipelines
- shell parsing

---

## Support Model

These scripts are provided as reference implementations and may require adaptation to align with organizational security policies, compliance requirements, or infrastructure standards.
