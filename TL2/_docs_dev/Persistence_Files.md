# Persistence

## Overview

The persistence layer stores small, encrypted state required for consistent license management across restarts. It provides a stable storage location for cryptographic material and metadata that the service needs to validate and unlock licenses after a reboot or service restart.

---

## Files and Roles

Persistence uses two files that live in the persistence directory:

- `persistence.bin`
  - Encrypted core persistence data.
  - Contains embedded values (such as the vault identifier and key/IV material) at fixed positions.
  - Used to decide if the system is in cold-start or warm-start mode.

- `vault.bin`
  - Encrypted vault payload.
  - Stores the license manager's persisted secrets and related data.

---

## Location

Default locations are platform-specific. On Linux the persistence directory is typically:

```
/etc/asperion/trustedLicensing/persistence/
```

The directory contains `persistence.bin` and `vault.bin`.

---

## Cold Start vs Warm Start

- **Cold Start**
  - Occurs when persistence files do not exist.
  - The service creates the persistence directory and writes fresh `persistence.bin` and `vault.bin`.
  - New AES key and IV values are generated for the vault.

- **Warm Start**
  - Occurs when persistence files already exist.
  - The service reads and decrypts `persistence.bin`, then loads `vault.bin` using the derived key/IV.

---

## Operational Notes

- The service requires elevated privileges to read and write the persistence directory.
- If persistence files are corrupted or were created with different encryption settings, decryption will fail.
- Recovery is done by deleting `persistence.bin` and `vault.bin` to force a cold start.
