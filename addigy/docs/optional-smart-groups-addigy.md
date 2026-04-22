# Optional Dynamic Groups (Addigy)

This document provides **example dynamic grouping ideas** for **Addigy** using Backblaze inventory and reporting data.

⚠️ **Optional Feature**

Dynamic groups are **not required** to install or operate Backblaze. They are provided as **examples only** to demonstrate how inventory and reporting values may be used for visibility, segmentation, and remediation during UAT or production operations.

## Deployment Context

These grouping examples assume the **centralized Backblaze deployment model** used in enterprise and RMM-managed environments.

In this architecture, Backblaze endpoints are installed and managed through Addigy automation while telemetry is collected using inventory and reporting scripts. Dynamic groups then provide segmentation for reporting, remediation policies, operational workflows, and targeting.

For decentralized deployments where each device signs in with its own Backblaze account, refer to the official Backblaze documentation and the Addigy decentralized installer guidance in this repository.

---

## Purpose

Optional dynamic groups can help Addigy administrators:

- Visualize Backblaze deployment state
- Target devices for remediation policies
- Scope operational actions
- Segment endpoints by health or backup freshness

They are most useful in **large or highly automated Addigy environments**.

---

## Example Dynamic Groups

The following examples are based on the inventory and reporting scripts documented in `inventory-and-reporting.md`.

These groups represent the **segmentation layer** of the Addigy integration architecture and complement the operational action model documented in `actions.md`.

### Backblaze Installed

**Criteria:**
- Inventory value `Backblaze – Installed` **is** `Installed`

**Use cases:**
- Confirm deployment coverage
- Scope actions or reporting

---

### Backblaze Backup Paused

**Criteria:**
- Reporting value `Backblaze – Status Summary` **contains** `Paused`

**Use cases:**
- Identify devices with paused backups
- Target resume-backup actions

---

### Backblaze Backup Not Healthy

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `RED`
- or Reporting value `Backblaze – Health Score` **is** `YELLOW`

**Use cases:**
- Detect backup issues
- Target remediation workflows
- Prioritize operational review

---

## Health-Based Dynamic Groups (Recommended)

If the optional **Backblaze – Health Score** reporting script is implemented, dynamic grouping can be simplified and standardized using deterministic health states.

### Backblaze – GREEN

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `GREEN`

**Use cases:**
- Compliance confirmation
- Healthy device reporting

---

### Backblaze – YELLOW

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `YELLOW`

**Use cases:**
- Early remediation workflows
- Targeted follow-up policies

---

### Backblaze – RED

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `RED`

**Use cases:**
- Automated remediation
- Escalation workflows
- Compliance review

---

### Backblaze – NOT_INSTALLED

**Criteria:**
- Reporting value `Backblaze – Health Score` **is** `NOT_INSTALLED`
- or Inventory value `Backblaze – Installed` **is** `Not Installed`

**Use cases:**
- Deployment gap detection
- Installation policy scoping

---

Using health-based segmentation reduces group complexity and enables a more consistent automation model across large Addigy environments.

---

## When to use Dynamic Groups

Recommended for environments such as:
- Large Addigy deployments
- Automated remediation workflows
- Operational reporting
- Fleet segmentation by backup state

Not required for:
- Small environments
- Manual policy execution
- Initial UAT validation

---

## Notes

- Dynamic groups depend on inventory and reporting data being present and current
- Grouping logic should align with the reporting cadence configured in Addigy
- Administrators may customize criteria to match internal standards
- Health-based groups provide a cleaner segmentation model than raw status-string parsing
- These examples are intended to support visibility and automation, not to prescribe a single Addigy design
