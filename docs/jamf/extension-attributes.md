# Jamf Extension Attributes (Optional)

Extension Attributes (EAs) can be used to surface Backblaze backup state
inside Jamf Pro inventory records.

⚠️ **Optional Feature**

These attributes are not required for basic operation.

---

## Use Cases

- Reporting backup status
- Targeting devices for remediation
- Visibility for IT administrators

---

## Example Attributes

- Backup running / paused state
- bzcli availability
- Last known backup activity

---

## Recommendation

Use Extension Attributes only if:
- Inventory reporting is required
- Automation decisions depend on device state

Otherwise, these can be safely omitted.