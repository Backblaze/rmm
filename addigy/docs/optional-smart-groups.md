# Optional Smart Computer Groups (Jamf Pro)

This document provides **example Smart Computer Groups** that can be created in **Jamf Pro** using Backblaze Extension Attributes.

⚠️ **Optional Feature**

Smart Computer Groups are **not required** for installing or operating Backblaze. They are provided as **examples only** to demonstrate how Extension Attributes may be used for visibility or automation during UAT.

## Deployment Context

These Smart Computer Group examples assume the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this architecture, Backblaze endpoints are installed and managed through Jamf automation while telemetry is collected using Extension Attributes. Smart Computer Groups then provide segmentation for reporting, remediation policies, and operational workflows.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the official Backblaze Jamf documentation on the Backblaze documentation site.

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

These Smart Groups represent the **segmentation layer** of the Jamf integration architecture and complement the operational command model documented in the CLI reference (`docs/man/backblaze-rmm.md`).

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

## Health-Based Smart Groups (Recommended for Enterprise)

If the optional **Health Classification** Extension Attribute is implemented, Smart Groups can be simplified and standardized using deterministic health states.

### Backblaze – Healthy

**Criteria:**
- Extension Attribute `Backblaze – Health Classification` **is** `Healthy`

**Use cases:**
- Compliance confirmation
- Executive reporting dashboards

---

### Backblaze – Warning

**Criteria:**
- Extension Attribute `Backblaze – Health Classification` **is** `Warning`

**Use cases:**
- Early remediation workflows
- Targeted follow-up policies

---

### Backblaze – Critical

**Criteria:**
- Extension Attribute `Backblaze – Health Classification` **is** `Critical`

**Use cases:**
- Automated remediation
- Escalation workflows
- Compliance enforcement

---

### Backblaze – Not Installed

**Criteria:**
- Extension Attribute `Backblaze – Installed` **is not** `Installed`

**Use cases:**
- Deployment gap detection
- Installation policy scoping

---

Using health-based segmentation reduces Smart Group complexity and enables consistent automation models across large Jamf environments.

---

## When to use Smart Groups

Recommended for enterprise environments such as:
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
- Health-based Smart Groups provide a cleaner segmentation model than status-string parsing.
- Organizations may align Smart Groups with internal compliance policies.
- Smart Groups should remain declarative and inventory-driven.
