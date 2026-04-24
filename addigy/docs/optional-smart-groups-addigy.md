# Optional Smart Groups (Addigy)

This document provides **example Addigy Smart Groups** that can be created using the Backblaze inventory and reporting scripts included in this repository.

⚠️ **Optional Feature**

Smart Groups are **not required** for installing or operating Backblaze. They are provided as **examples only** to demonstrate how inventory and reporting values may be used for visibility or automation during UAT.

## Deployment Context

These Smart Group examples assume the **Backblaze deployment baseline for Addigy** documented in this repository.

In this architecture, Backblaze endpoints are installed and managed through Addigy automation while telemetry is collected using the inventory and reporting scripts included in this repository. Smart Groups then provide segmentation for visibility, remediation workflows, and operational review.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the Addigy decentralized deployment documentation included in this repository.

---

## Purpose

Optional Smart Groups can help Addigy administrators:

- Visualize Backblaze deployment state
- Target devices for remediation workflows
- Organize devices for reporting and operational review

They are most useful in **large or highly automated Addigy environments**.

---

## Example Smart Groups

The following Smart Groups are examples that can be created using the inventory and reporting scripts documented in `inventory-and-reporting.md`.

These Smart Groups represent the **segmentation layer** of the Addigy baseline and complement the operational action model documented in `actions.md`.

### Backblaze Installed

**Criteria:**
- Inventory value `Backblaze – Installed` **is** `Installed`

**Use cases:**
- Confirm deployment coverage
- Scope reporting or follow-up actions

---

### Backblaze Backup Paused

**Criteria:**
- Reporting value `Backblaze – Status Summary` **contains** `Paused`

**Use cases:**
- Identify devices with paused backups
- Target devices for manual review or resume actions

---

### Backblaze Backup Not Running

**Criteria:**
- Reporting value `Backblaze – Status Summary` **does not contain** `Running`

**Use cases:**
- Detect potential backup issues
- Target devices for remediation workflows

---

## Health-Based Smart Groups (Recommended)

If the optional **Health Score** reporting script is implemented, Smart Groups can be simplified and standardized using deterministic health states.

### Backblaze – Healthy

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `GREEN`

**Use cases:**
- Compliance confirmation
- Executive reporting dashboards

---

### Backblaze – Warning

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `YELLOW`

**Use cases:**
- Early remediation workflows
- Targeted operational follow-up

---

### Backblaze – Critical

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `RED`

**Use cases:**
- Automated remediation
- Escalation workflows
- Compliance review

---

### Backblaze – Not Installed

**Criteria:**
- Inventory value `Backblaze – Installed` **is not** `Installed`

**Use cases:**
- Deployment gap detection
- Installation workflow targeting

---

Using health-based segmentation reduces Smart Group complexity and enables a more consistent automation model across large Addigy environments.

---

## When to use Smart Groups

Recommended for environments such as:
- Large Addigy deployments
- Automated remediation workflows
- Operational reporting and device segmentation

Not required for:
- Small environments
- Manual script execution
- Initial UAT validation

---

## Notes

- Smart Groups depend on inventory and reporting values being present and up to date
- Administrators may customize criteria to match internal operational standards
- Health-based Smart Groups provide a cleaner segmentation model than raw status-string parsing
- Smart Groups should remain declarative and inventory-driven
- These examples are optional and intended as a starting point for UAT and production design
