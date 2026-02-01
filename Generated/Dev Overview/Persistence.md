# TrustedLicensing Persistence Architecture

**Version:** 1.0  
**Created:** 1 February 2026  
**Last Updated:** 1 February 2026

**Document Purpose:** This document describes the persistence architecture for TrustedLicensing clients, including encrypted file storage, TPM-backed non-volatile storage, secret management, and license model persistence requirements.

---

## Table of Contents

1. [Overview](#overview)
2. [Persistence Files](#persistence-files)
3. [TPM Non-Volatile Storage](#tpm-non-volatile-storage)
4. [Persistence Requirements by License Model](#persistence-requirements-by-license-model)
5. [Initialization Workflow](#initialization-workflow)
6. [Security Architecture](#security-architecture)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)
9. [Related Documents](#related-documents)

---

## 1. Overview

TrustedLicensing clients use multiple persistence mechanisms to securely store secrets, licenses, usage tracking data, and configuration. The persistence architecture provides:

- **Hardware-backed security** through TPM 2.0 integration
- **Encrypted file storage** for secrets and cryptographic keys
- **Cross-platform compatibility** (Windows, Linux, containers)
- **OS independence** with TPM-based storage
- **Tamper detection** through integrity checks

**Persistence Components:**

| Component | Purpose | Security Level | Storage Location |
|-----------|---------|----------------|------------------|
| **persistence.bin** | Encrypted secrets container | AES-256 | Filesystem |
| **vault.bin** | Encrypted key vault | AES-256 | Filesystem |
| **TPM NV Storage** | Hardware-backed secrets | TPM hardware | TPM chip |
| **License Data** | Active licenses | Encrypted | Filesystem/TPM |

---

## 2. Persistence Files

### 2.1. persistence.bin - Core Secret Storage

**Purpose:** Encrypted container for critical secrets and configuration data.

**File Locations:**
- **Windows:** `C:\ProgramData\TrustedLicensing\Persistence\persistence.bin`
- **Linux:** `/var/lib/TrustedLicensing/Persistence/persistence.bin`
- **Container:** `/app/data/persistence.bin` (mounted volume)

#### Structure

**Container Format:**
- **Size:** 15-75 KB (random size for steganographic hiding)
- **Encryption:** AES-256-CBC
- **Key:** Hardcoded `AES_KEY_PERSISTENCE_LOCAL` (source code)
- **Format:** Binary with fixed-position secrets

**Secret Positions:**

| Position | Size | Content | Purpose |
|----------|------|---------|---------|
| 100 | Variable | Vault ID + filename | Vault identification |
| 200 | 32 chars | AES Vault Key | Encrypt vault.bin |
| 250 | 32 chars | AES Vault IV | Encrypt vault.bin |
| 400 | 16 bytes | TPM_AUTH | TPM authorization value |
| 450 | 16 bytes | TPM_SEED | Deterministic key generation seed |

**Security Model:**
- Random container size provides obfuscation
- Fixed positions provide hiding but NOT cryptographic security
- AES encryption protects against casual inspection
- Requires elevated filesystem access

**Source:** [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

### 2.2. vault.bin - Cryptographic Key Storage

**Purpose:** Encrypted storage for RSA key pairs and TPM public key exports.

**File Locations:**
- **Windows:** `C:\ProgramData\TrustedLicensing\Persistence\vault.bin`
- **Linux:** `/var/lib/TrustedLicensing/Persistence/vault.bin`
- **Container:** `/app/data/vault.bin`

#### Contents

**Stored Keys:**
1. **LocalPublicKey** - RSA public key (for non-TPM fallback)
2. **LocalPrivateKey** - RSA private key (encrypted, for non-TPM fallback)
3. **SRK Public** - TPM Storage Root Key public key export

**Encryption:**
- **Algorithm:** AES-256-CBC
- **Key Source:** AES Vault Key from persistence.bin (position 200)
- **IV Source:** AES Vault IV from persistence.bin (position 250)

**Usage:**
- Provides fallback for platforms without TPM support
- Stores TPM public key export for registration with LMS
- Less secure than TPM-based storage (software keys)

**Source:** [TrustedLicensing_Client_Security_Cryptography.md](TrustedLicensing_Client_Security_Cryptography.md)

---

## 3. TPM Non-Volatile Storage

### 3.1. TPM NV Architecture

**Purpose:** Hardware-backed persistent storage within the TPM chip for license data and consistency checks.

**Configuration:**
- **Size per index:** 64 bytes
- **Available slots:** 2101-3000 (899 slots total)
- **Address space:** 0x01000835 - 0x01000BB7
- **Authentication:** PCR-based (no passwords stored)

### 3.2. Security Model (v1.1)

TLLicenseManager v1.1 uses Platform Configuration Register (PCR) values for NVRAM authentication, providing hardware-bound security without password storage vulnerabilities.

**PCR Policy Options:**

| Policy | PCRs Used | Security Level | Flexibility | Use Case |
|--------|-----------|----------------|-------------|----------|
| **FirmwareBoot** (Recommended) | 0, 7 | High | Medium | Production with stable firmware |
| **SecureBoot** | 7 | Medium | High | Frequent firmware updates |
| **BootSequence** | 0, 2, 7 | Maximum | Low | Locked hardware configurations |

**PCR Meanings:**
- **PCR 0:** Firmware/BIOS measurements
- **PCR 2:** Option ROM code
- **PCR 7:** Secure Boot state

### 3.3. Security Benefits

**Hardware Binding:**
1. **No Password Storage** - Eliminates password theft/disclosure risk
2. **Hardware-Bound** - Data access tied to platform boot state
3. **Tamper Evidence** - PCR changes prevent access
4. **Non-Exportable** - Cannot copy NVRAM data to another system
5. **OS Independence** - Survives OS reinstallation

**Access Requirements:**
- TPM's PCR values must match values from when data was written
- Changes to firmware, secure boot, or boot sequence invalidate access
- Requires physical TPM chip (cannot be virtualized securely)

**Migration Notes:**
- Changing `VaultPolicy` requires NVRAM re-initialization
- Firmware updates may require re-initialization (FirmwareBoot/BootSequence policies)
- PCR values must match between write and read operations

**Current Status:** NVRAM functionality is fully implemented and tested but **not currently used in production license flow**.

**Source:** [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

## 4. Persistence Requirements by License Model

Different license models have varying persistence requirements for tracking time, usage, or token consumption.

### 4.1. Models WITHOUT Persistence

**Perpetual License:**
- **Persistence:** Not required
- **Validation:** One-time signature verification
- **Use Case:** Simple perpetual licensing

### 4.2. Time-Based Models (Persistence Required)

**Models:**
- **TimePeriod** - Fixed time range (start/end dates)
- **TimePeriodActivated** - Time period begins at activation
- **TimePeriodToday** - Time period extends from activation to specific future date

**Persistence Needs:**
- Store activation timestamp
- Track expiration dates
- Validate via TPM or persistence layer
- Detect time manipulation

### 4.3. Counter-Based Models (Persistence Required)

**Model:**
- **Counter** - Increment/decrement usage counter

**Persistence Needs:**
- Store current counter value
- Track increment/decrement operations
- Persist counter state across reboots
- Enable batch value passing
- Support counter reset with guaranteed reporting

### 4.4. Token-Based Models (Persistence Required)

**Model:**
- **Token** - Consumption-based licensing with token pools

**Persistence Needs:**
- Store token balance (available tokens)
- Track token consumption
- Support token trading between clients
- Enable token export/import
- Maintain token transaction history

**Token Storage:**
- Tokens are stored in persistence layer
- Token trading requires network communication
- Exportable tokens enable department-to-department transfer

**Source:** [Licensing Models.md](../../TLCloud/LMS/Licensing%20Models.md), [License_Models_and_Features_Analysis.md](License_Models_and_Features_Analysis.md)

---

## 5. Initialization Workflow

### 5.1. First-Time Initialization (Cold Start)

**Phase: Persistence Layer Initialization**

```
PersistenceService::Initialize()
├─ 1. Create persistence directory
│  └─ Windows: C:\ProgramData\TrustedLicensing\Persistence\
│  └─ Linux: /var/lib/TrustedLicensing/Persistence/
│
├─ 2. Environment Detection
│  ├─ Check if running in container (Docker, Kubernetes, Podman, LXC)
│  ├─ Check if running in VM (VMware, Hyper-V, KVM, Xen)
│  └─ Check TPM availability (unless --no-tpm specified)
│
├─ 3. Generate Random Container
│  ├─ Generate random size: 15-75 KB
│  └─ Fill with random binary data
│
├─ 4. Generate Secrets (using TPM hardware RNG)
│  ├─ TPM_AUTH = tpm.Randomize(16)  // Hardware RNG
│  ├─ TPM_SEED = tpm.Randomize(16)  // Hardware RNG
│  ├─ AES_VAULT_KEY = GenerateHex(32)
│  └─ AES_VAULT_IV = GenerateHex(32)
│
├─ 5. Embed Secrets at Fixed Positions
│  ├─ Position 100: Vault ID + filename
│  ├─ Position 200: AES Vault Key
│  ├─ Position 250: AES Vault IV
│  ├─ Position 400: TPM_AUTH
│  └─ Position 450: TPM_SEED
│
├─ 6. Encrypt Container
│  └─ AES-256-CBC with AES_KEY_PERSISTENCE_LOCAL
│
├─ 7. Write persistence.bin
│  └─ Save encrypted container to disk
│
└─ 8. Generate TPM Keys
   ├─ Generate SRK (Storage Root Key) at handle 0x81000835
   ├─ Generate Signature Key at handle 0x81000836
   └─ Persist keys to TPM NV storage
```

### 5.2. Warm Start (Existing Installation)

```
PersistenceService::Initialize()
├─ 1. Read persistence.bin
│
├─ 2. Decrypt with AES_KEY_PERSISTENCE_LOCAL
│
├─ 3. Extract Secrets from Fixed Positions
│  ├─ TPM_AUTH (position 400)
│  ├─ TPM_SEED (position 450)
│  ├─ AES_VAULT_KEY (position 200)
│  └─ AES_VAULT_IV (position 250)
│
├─ 4. Validate Extracted Data
│  ├─ Verify AES keys are hexadecimal
│  ├─ Verify TPM auth/seed exist
│  └─ Verify vault filename valid
│
├─ 5. Create AESCrypt Instance
│  └─ Initialize with AES_VAULT_KEY and AES_VAULT_IV
│
├─ 6. Load TPM Keys
│  ├─ Load SRK from handle 0x81000835
│  ├─ Load Signature Key from handle 0x81000836
│  └─ Set TPM_AUTH authorization value
│
└─ 7. Load or Create vault.bin
   ├─ If exists: decrypt and load keys
   └─ If not exists: generate RSA keys and create vault
```

**Source:** [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

## 6. Security Architecture

### 6.1. Threat Model

**Protected Against:**
- ✅ Offline attacks on persistence.bin (AES-256 encryption)
- ✅ Software key extraction (private keys secured in TPM)
- ✅ License migration to different hardware (TPM binding)
- ✅ Firmware tampering (PCR-based sealing)
- ✅ Unauthorized NVRAM access (PCR hardware-bound)
- ✅ Password storage vulnerabilities (v1.1 eliminated passwords)

**Vulnerabilities:**
- ⚠️ Hardcoded AES key in source code (AES_KEY_PERSISTENCE_LOCAL)
- ⚠️ Fixed positions in persistence.bin (obfuscation only, not cryptographic security)
- ⚠️ TPM_AUTH stored on disk (encrypted but extractable with source access)
- ⚠️ No key rotation mechanism
- ⚠️ TPM replacement = data loss (unless seed is backed up)
- ⚠️ Persistence file portability attack (copying to another system)

### 6.2. Security Layers

**Layer 1: Filesystem Protection**
- Requires elevated privileges to access persistence directory
- File permissions: 600 (owner read/write only)
- Located in protected system directories

**Layer 2: Encryption**
- AES-256-CBC encryption on persistence.bin
- AES-256-CBC encryption on vault.bin
- Cryptographically secure keys

**Layer 3: Obfuscation**
- Random container size (15-75 KB)
- Fixed positions hide secrets in noise
- Not cryptographic security, but adds complexity

**Layer 4: TPM Hardware Binding**
- TPM_AUTH generated by hardware RNG
- TPM_SEED for deterministic key generation
- Private keys never leave TPM hardware
- PCR-based access control for NVRAM

### 6.3. Security Best Practices

**Deployment:**
1. Restrict filesystem access to persistence directory (600 permissions)
2. Enable TPM when available (hardware-backed security)
3. Use FirmwareBoot PCR policy for production systems
4. Monitor for persistence file tampering
5. Implement backup/restore procedures for disaster recovery

**Outstanding Security Issues:**
- **[TODO]** Detect Persistence Move - Prevent copying persistence files between systems
- **[TODO]** Implement key rotation mechanism
- **[TODO]** Add integrity checking for persistence files
- **[TODO]** Implement secure backup mechanism

**Source:** [InfraTodo.md](../../TLCloud/ToDo/InfraTodo.md), [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

## 7. Configuration

### 7.1. Configuration File

**Location:** `TLLicenseManager.json`

**Persistence Configuration:**

```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "Persistence": {
        "DataPath": "/var/lib/tllicensemanager",
        "EnableNVRAM": true,
        "BackupEnabled": true
      },
      "VaultPolicy": "FirmwareBoot"
    }
  }
}
```

**Configuration Options:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `DataPath` | string | Platform-specific | Persistence directory location |
| `EnableNVRAM` | boolean | true | Enable TPM NVRAM storage |
| `BackupEnabled` | boolean | false | Enable automatic backups |
| `VaultPolicy` | string | "FirmwareBoot" | PCR policy for NVRAM access |

### 7.2. Configuration Search Paths

**Search Order:**
1. Command-line: `--config /path/to/config.json`
2. Current directory: `./TLLicenseManager.json`
3. User config (Linux): `~/.config/tllicensemanager/TLLicenseManager.json`
4. User config (Windows): `%APPDATA%\TLLicenseManager\TLLicenseManager.json`
5. System config (Linux): `/etc/tllicensemanager/TLLicenseManager.json`
6. System config (Windows): `C:\ProgramData\TLLicenseManager\TLLicenseManager.json`

### 7.3. Runtime Options

**Command-Line Flags:**
- `--no-tpm` - Disable TPM usage (use software fallback)
- `--config <path>` - Specify configuration file location
- `--data-path <path>` - Override persistence directory

### 7.4. Container Configuration

**Docker Compose:**
```yaml
services:
  tl-license-manager:
    image: trustedlicensing:latest
    devices:
      - /dev/tpmrm0:/dev/tpmrm0  # TPM device
    group_add:
      - 113  # tss group
    volumes:
      - tl-data:/app/data  # For persistence.bin and vault.bin
    cap_add:
      - IPC_LOCK
```

**Kubernetes:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
spec:
  containers:
  - name: app
    image: trustedlicensing:latest
    volumeMounts:
    - name: tpmrm0
      mountPath: /dev/tpmrm0
    - name: data
      mountPath: /app/data
    securityContext:
      supplementalGroups: [113]
  volumes:
  - name: tpmrm0
    hostPath:
      path: /dev/tpmrm0
  - name: data
    persistentVolumeClaim:
      claimName: tl-data
```

**Source:** [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

## 8. Troubleshooting

### 8.1. Common Issues

**Issue: Persistence File Corrupted**

**Symptoms:**
- "Failed to decrypt persistence.bin"
- "Invalid secrets format"
- Startup failures

**Resolution:**
1. Check file integrity: `ls -la persistence.bin`
2. Verify file permissions (should be 600)
3. Check available disk space
4. Review logs for decryption errors
5. **Last resort:** Delete persistence.bin (loses all keys and licenses!)

**Issue: TPM Not Available**

**Symptoms:**
- "TPM device not found"
- "TPM communication failure"

**Resolution:**
1. Check TPM device exists: `ls -la /dev/tpm*`
2. Verify TPM is enabled in BIOS/UEFI
3. Check tss group membership: `groups`
4. Use `--no-tpm` flag for software fallback
5. In containers: verify device mapping in Docker/K8s config

**Issue: NVRAM Access Denied**

**Symptoms:**
- "PCR policy validation failed"
- "NVRAM read failed"

**Resolution:**
1. Verify PCR values haven't changed: firmware update, secure boot change
2. Check VaultPolicy configuration matches initialization
3. Review PCR policy in config: FirmwareBoot, SecureBoot, or BootSequence
4. Re-initialize NVRAM if policy changed (data will be lost)

**Issue: Persistence Move Detected**

**Symptoms:**
- License activation fails after system migration
- Hardware binding validation errors

**Resolution:**
1. Persistence files are hardware-bound (by design)
2. Cannot move persistence.bin between systems
3. Must re-activate licenses on new hardware
4. Contact vendor for license transfer if needed

### 8.2. Performance Characteristics

**Typical Performance (SSD, Modern CPU):**

| Operation | First Boot | Warm Start |
|-----------|-----------|------------|
| Persistence initialization | 200ms | 50ms |
| Persistence load | 50ms | 20ms |
| TPM key generation | 1500ms | - |
| TPM key load | - | 100ms |
| Vault load | 30ms | 10ms |

**Performance Tips:**
- Use SSD for persistence directory
- Enable NVRAM for faster access
- Minimize TPM operations (cached keys)

**Source:** [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md)

---

## 9. Related Documents

### Architecture Documents
- [Client Architecture.md](../../TLCloud/Client/Client%20Architecture.md) - Client topology and storage architecture
- [Crypto Entities.md](../../TLCloud/Architecture/Crypto%20Entities.md) - Cryptographic key infrastructure
- [TrustedLicensing_Client_Security_Cryptography.md](TrustedLicensing_Client_Security_Cryptography.md) - Comprehensive security documentation

### Implementation Documents
- [TLLicenseManager_StartUp.md](../../TL2/_docs_dev/TLLicenseManager_StartUp.md) - Startup sequence and persistence initialization
- [TPM_Requirements.md](../../TLCloud/Client/TPM_Requirements.md) - TPM hardware requirements

### License Model Documents
- [Licensing Models.md](../../TLCloud/LMS/Licensing%20Models.md) - License model types and persistence requirements
- [License_Models_and_Features_Analysis.md](License_Models_and_Features_Analysis.md) - Comprehensive license model analysis

### Diagrams
- [Presistence Init.drawio](../../TLCloud/Draw.IO/Presistence%20Init.drawio) - Visual workflow diagrams for persistence initialization and usage

### TODO Items
- [InfraTodo.md](../../TLCloud/ToDo/InfraTodo.md) - Outstanding persistence security issues

---

<!-- 
REGENERATION PROMPT:

Create a comprehensive documentation of persistence architecture for TrustedLicensing clients covering:

SCOPE:
- Overview of persistence components (persistence.bin, vault.bin, TPM NV storage)
- Detailed structure of persistence.bin with fixed-position secrets
- vault.bin cryptographic key storage architecture
- TPM Non-Volatile storage configuration and PCR policies
- Persistence requirements by license model (time-based, counter-based, token-based)
- Complete initialization workflow (cold start and warm start)
- Security architecture with threat model and vulnerabilities
- Configuration options and deployment scenarios
- Troubleshooting common issues
- Performance characteristics

KEY FILES TO REVIEW:
- TL2/_docs_dev/TLLicenseManager_StartUp.md (primary source for implementation details)
- Generated/Dev Overview/TrustedLicensing_Client_Security_Cryptography.md (security architecture)
- Generated/Dev Overview/License_Models_and_Features_Analysis.md (license model persistence requirements)
- TLCloud/Client/Client Architecture.md (storage architecture)
- TLCloud/Architecture/Crypto Entities.md (key storage)
- TLCloud/LMS/Licensing Models.md (persistence requirements)
- TLCloud/Client/TPM_Requirements.md (hardware requirements)
- TLCloud/Draw.IO/Presistence Init.drawio (visual workflows)
- TLCloud/ToDo/InfraTodo.md (outstanding issues)

STRUCTURE:
1. Overview - Components and security levels table
2. Persistence Files - persistence.bin and vault.bin detailed structure
3. TPM Non-Volatile Storage - PCR policies and security model
4. Persistence Requirements by License Model - Which models need persistence
5. Initialization Workflow - Cold start and warm start sequences
6. Security Architecture - Threat model, security layers, best practices
7. Configuration - JSON config, search paths, container deployment
8. Troubleshooting - Common issues with symptoms and resolutions
9. Related Documents - Cross-references with relative paths

STYLE:
- Professional technical documentation with version control
- Tables for structured data (positions, configurations, performance)
- Code blocks for configuration examples and workflows
- Security indicators: ✅ (protected), ⚠️ (vulnerability)
- Cross-references to source documents with relative paths
- Clear section hierarchy with numbered headings

UPDATE TRIGGERS:
- Changes to persistence file format or structure
- New persistence mechanisms added
- Security model updates
- Performance optimizations
- Configuration option changes
- New license models with persistence requirements

LAST UPDATED: 1 February 2026
-->
