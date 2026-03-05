# BACKBLAZE-RMM(1)

## NAME

backblaze-rmm — operational automation commands for Backblaze Computer Backup in RMM/MDM environments

## SYNOPSIS

backblaze-rmm <command> [options]

## DESCRIPTION

backblaze-rmm provides operational automation primitives used by RMM and MDM
platforms (such as Jamf Pro, Kandji, and Addigy) to manage Backblaze Computer
Backup clients in centralized enterprise deployments.

These commands typically wrap common Backblaze client operations using `bzcli`.

## COMMANDS

install
: Install the Backblaze client and optionally enroll the device into a Business Group.

backup-now
: Trigger an immediate backup operation.

pause-backup
: Pause the backup process.

resume-backup
: Resume the backup process.

set-pek
: Configure the Private Encryption Key (PEK).

change-pek
: Rotate the Private Encryption Key (PEK).

clear-pek
: Remove the Private Encryption Key (PEK).

status
: Print a short status summary (typically derived from `bzcli status` and related checks).

license-check
: Validate license/entitlement status (typically `bzcli license check`).

health
: Print a health summary (if available), used for quick triage.

## OPTIONS

-h, --help
: Show help for a command.

--json
: Output machine-readable JSON when supported.

--verbose
: Print additional diagnostic output.

## EXAMPLES

Trigger backup immediately:

    backblaze-rmm backup-now

Pause backups:

    backblaze-rmm pause-backup

Resume backups:

    backblaze-rmm resume-backup

Set a PEK (implementation-specific):

    backblaze-rmm set-pek --pek-env-var BACKBLAZE_PEK

## EXIT STATUS

0
: Command completed successfully.

1
: Command failed.

2
: Invalid arguments or missing prerequisites.

## FILES

/var/log/backblaze_mdm_install.log
: Common install/log location used by Jamf-based scripts.

## SEE ALSO

bzcli(1)

Backblaze documentation:
https://www.backblaze.com/computer-backup/docs/how-to-install-the-backblaze-client-silently-with-jamf-pro-mac
