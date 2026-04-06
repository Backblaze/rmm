# Advanced Installer JSON in Addigy (Backblaze v10)

## Overview

Backblaze Desktop v10 supports JSON-based configuration at install time using the advanced installer (`bzinstall_mate`) with the `-cfg` flag.

In the Addigy baseline, this enables IT administrators to pass an enterprise configuration to the installer using either:

- `BZ_INSTALL_CFG_B64` (base64-encoded JSON)
- `BZ_INSTALL_CFG_URL` (JSON downloaded from a URL)

This document describes the intended Addigy-aligned JSON bootstrap model. Live validation in the Addigy sandbox is still pending.

---

## Installer vs. bzCLI responsibilities

| Component | Purpose |
|---|---|
| Installer (`bzinstall_mate -cfg`) | Apply configuration at deployment/install time |
| `bzcli configure --json-file` | Apply configuration post-install and support ongoing management |

---

## Current Addigy baseline

The current Addigy installer baseline supports JSON input through environment variables rather than Jamf script parameters.

Preferred input paths:

- `BZ_INSTALL_CFG_B64`
- `BZ_INSTALL_CFG_URL`

If JSON is supplied, the installer follows the advanced configuration path using:

```bash
bzinstall_mate -cfg /tmp/backblaze_installer_config.json
```

If JSON is not supplied, the installer falls back to explicit environment-variable inputs such as:

- `BZ_GROUP_ID`
- `BZ_GROUP_TOKEN`
- `BZ_EMAIL`
- `BZ_REGION`

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
```

---

## Notes on account workflow

For the current enterprise deployment path, existing-account sign-in should be treated as the expected automated workflow unless future product changes explicitly expand account-creation behavior.

This means:
- user accounts should already exist on the Backblaze side
- users should already be added/invited into the relevant organization/group
- the installer should then proceed using the sign-in/enrollment path

---

## Why JSON is useful

Using advanced installer JSON can help:

- keep installer input structured and reusable
- avoid quoting/escaping issues in command construction
- support centralized deployment patterns more cleanly
- keep the Addigy baseline aligned with the shared v10 installer model

---

## Validation status

At the current stage:
- the JSON bootstrap path is implemented in the Addigy installer baseline
- Addigy sandbox validation is still pending
- final production guidance should be updated once live platform behavior is confirmed
