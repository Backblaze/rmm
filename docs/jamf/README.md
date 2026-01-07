---

# 2️⃣ Jamf entry doc: `docs/jamf/README.md`

📍 **Location:** `docs/jamf/README.md`

```markdown
# Jamf Pro Integration – Backblaze RMM

This section documents how to integrate **Backblaze Computer Backup**
with **Jamf Pro** using policy-driven automation and `bzcli`.

The Jamf integration is validated in a **Jamf Pro UAT / sandbox environment**
and is intended as a reference implementation for customers and partners.

---

## Scope

The Jamf integration supports:

- Operational actions using `bzcli`
- Policy-based execution
- Optional reporting via Extension Attributes
- Optional automation via Smart Computer Groups

All components are **modular** and can be adopted independently.

---

## Directory Overview

```text
jamf/
└── scripts/
    ├── actions/                # bzcli operational scripts
    ├── configuration/          # future configuration helpers
    ├── extension-attributes/   # optional reporting scripts
    └── install/                # installation helpers

    ## Installation

Backblaze Business v10 can be installed via Jamf using a dedicated install script.

Script: jamf/scripts/install/install-backblaze-business-v10.sh
This script is intended to be executed via a Jamf policy
(scoped to devices where Backblaze is not yet installed).
