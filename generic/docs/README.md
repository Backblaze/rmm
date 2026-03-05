# Generic Backblaze Integration (bzcli)

This directory provides a **platform‑agnostic reference implementation** for integrating Backblaze Computer Backup using `bzcli`.

It is designed for environments that:

- Use a custom or in‑house RMM platform
- Require portable shell‑based automation
- Integrate backup telemetry into existing monitoring pipelines
- Prefer a vendor‑neutral implementation model

## Deployment Model

The generic integration demonstrates a **centralized Backblaze deployment model**
commonly used in enterprise and RMM-managed environments.

In this model, a single administrative Backblaze account or Business Group
configuration manages multiple endpoints through automation scripts.

Organizations that deploy Backblaze using individual user accounts
(a decentralized deployment model) should refer to the official
Backblaze documentation.

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

## Security Notice

Do not store real Backblaze credentials, tokens, or account identifiers
in scripts or configuration files.

All examples in this repository use placeholders.

Credentials should be securely managed using the secret-management
capabilities of the RMM or automation platform being used.

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
