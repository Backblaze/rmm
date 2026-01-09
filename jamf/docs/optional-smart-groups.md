# Optional Smart Computer Groups

Smart Computer Groups can be created in Jamf Pro using Extension Attributes
to automate targeting and remediation.

⚠️ **Optional Feature**

These groups are provided as a convenience and are not required.

---

## Example Groups

- Backblaze Installed
- Backup Paused
- Backup Not Running

---

## When to Use

Recommended for:
- Large Jamf environments
- Automated remediation workflows
- Self Service targeting

Not required for:
- Small environments
- Manual policy execution
# Optional Smart Computer Groups (Jamf Pro)

This document provides **example Smart Computer Groups** that can be created in **Jamf Pro** using Backblaze Extension Attributes.

⚠️ **Optional Feature**

Smart Computer Groups are **not required** for installing or operating Backblaze. They are provided as **examples only** to demonstrate how Extension Attributes may be used for visibility or automation during UAT.

---

## Purpose

Optional Smart Groups can help Jamf administrators:

- Visualize Backblaze deployment state
- Target devices for remediation policies
- Scope Self Service actions

They are most useful in **large or highly automated Jamf environments**.

---

## Example Smart Groups

The following Smart Groups are examples that can be created using the Extension Attributes documented in `extension-attributes.md`.

### Backblaze Installed

**Criteria:**
- Extension Attribute `Backblaze – Installed` **is** `Installed`

**Use cases:**
- Confirm deployment coverage
- Scope actions or reporting

---

### Backblaze Backup Paused

**Criteria:**
- Extension Attribute `Backblaze – Status Summary` **contains** `Paused`

**Use cases:**
- Identify devices with paused backups
- Trigger resume-backup actions

---

### Backblaze Backup Not Running

**Criteria:**
- Extension Attribute `Backblaze – Status Summary` **is not** `Running`

**Use cases:**
- Detect potential backup issues
- Trigger remediation workflows

---

## When to use Smart Groups

Recommended for:
- Large Jamf deployments
- Automated remediation workflows
- Operational reporting

Not required for:
- Small environments
- Manual Jamf policy execution
- Initial UAT validation

---

## Notes

- Smart Groups depend on Extension Attributes being present and up to date
- Inventory must be refreshed for changes to appear
- Administrators may customize criteria to match internal standards
