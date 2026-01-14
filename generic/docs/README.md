# Generic Backblaze Integration (bzcli)

This folder documents the **platform‑agnostic** Backblaze integration using `bzcli`.
It is intended for IT administrators and MSPs who are **not** using Jamf, Kandji, Addigy, or JumpCloud, or who want a portable reference implementation.

These scripts produce **plain‑text output** suitable for:
- RMM tools
- shell automation
- cron jobs
- exporting to CSV / Excel

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
- `bzcli` available at  
  `/Applications/Backblaze.app/Contents/MacOS/bzcli`

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
