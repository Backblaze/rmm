# Install (Generic – Reference Implementation)

This document describes how to install or upgrade **Backblaze Computer Backup** on macOS using the generic installer script provided in this repository.

This implementation is designed as a platform-neutral reference model and is suitable for:
- Enterprise IT administrators
- Managed Service Providers (MSPs)
- Custom RMM platforms
- Shell-based automation and orchestration workflows

---

## Script location

```text
generic/scripts/install/install-backblaze.sh
```

---

## Requirements

- macOS
- Root privileges (use `sudo`)
- Network access to download the installer DMG

---

## Inputs

The installer can be configured using **environment variables** (recommended for automation) and/or **CLI flags** (convenient for manual runs).

### Required

- Group ID
- Group Token
- Email

### Optional

- Region
- DMG URL (override)

---

## Install using environment variables (recommended)

```bash
sudo \
  BZ_GROUP_ID="<group_id>" \
  BZ_GROUP_TOKEN="<group_token>" \
  BZ_EMAIL="user@example.com" \
  bash generic/scripts/install/install-backblaze.sh
```

Optional region:

```bash
sudo \
  BZ_GROUP_ID="<group_id>" \
  BZ_GROUP_TOKEN="<group_token>" \
  BZ_EMAIL="user@example.com" \
  BZ_REGION="<region>" \
  bash generic/scripts/install/install-backblaze.sh
```

---

## Install using CLI flags (manual-friendly)

```bash
sudo bash generic/scripts/install/install-backblaze.sh \
  -g "<group_id>" \
  -t "<group_token>" \
  -e "user@example.com"
```

Optional region:

```bash
sudo bash generic/scripts/install/install-backblaze.sh \
  -g "<group_id>" \
  -t "<group_token>" \
  -e "user@example.com" \
  -r "<region>"
```

---

## Install from a Custom DMG URL (Non‑Production / Version Pinning)

By default, the script uses the standard Business Group installer DMG.  
For version pinning, staged rollouts, or non-production validation, override the DMG URL.

Example (Backblaze v10 UAT build):

```bash
sudo \
  BZ_DMG_URL="https://example.com/path/to/backblaze-installer.dmg" \
  BZ_GROUP_ID="<group_id>" \
  BZ_GROUP_TOKEN="<group_token>" \
  BZ_EMAIL="user@example.com" \
  bash generic/scripts/install/install-backblaze.sh
```

Or using flags:

```bash
sudo bash generic/scripts/install/install-backblaze.sh \
  -u "https://example.com/path/to/backblaze-installer.dmg" \
  -g "<group_id>" \
  -t "<group_token>" \
  -e "user@example.com"
```

---

## Verify installation

After installation, confirm the Backblaze service is running:

```bash
pgrep -x bzserv
```

If Backblaze Desktop Client v10+ is installed, you can validate via `bzcli`:

```bash
/Applications/Backblaze.app/Contents/MacOS/bzcli report -v /backup/installation/version
```

---

## Notes

- The script performs an **upgrade** if Backblaze is already installed.
- For production/customer deployments, use the default DMG URL unless a specific version is required.
- For platform-specific guidance (Jamf Pro), refer to the Jamf documentation under `jamf/docs/`.

---

## Security Considerations

- Group Tokens should be treated as sensitive credentials.
- Avoid hardcoding tokens in publicly shared scripts.
- Prefer secure variable injection via RMM secret storage or environment management systems.
- Ensure installer execution is restricted to trusted automation workflows.

---

## Support Model

This installer script is provided as a reference implementation. Organizations may adapt logging, validation, version control, and compliance logic to align with internal security and deployment standards.
