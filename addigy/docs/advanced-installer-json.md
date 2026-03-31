# Advanced Installer JSON in Jamf (Backblaze v10)

## Overview
Backblaze Desktop v10 supports JSON-based configuration at install time using the advanced installer (`bzinstall_mate`) with the `-cfg` flag.

In Jamf Pro, this enables IT admins to pass an enterprise configuration during deployment, typically as **base64** via script parameters, and apply it during installation.

---

## Installer vs. bzCLI responsibilities

| Component | Purpose |
|---|---|
| Installer (`bzinstall_mate -cfg`) | Apply config at deployment/install time |
| `bzcli configure --json-file` | Apply config post-install and ongoing management |

---

## Minimal enterprise JSON example

```json
{
  "installation": {
    "cmd_param": "-nogui -createaccount_or_signinaccount user@example.com <GROUP_ID> <GROUP_TOKEN> <REGION>"
  },
  "settings": {
    "online_hostname": "managed-mac-hostname",
    "lock_exclusion": true,
    "lock_schedule": true,
    "suppress_notification": true
  }
}
