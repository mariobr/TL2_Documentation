<!--
DOCUMENT GENERATION PROMPT:
"Create a document regarding trusted licensing client and all security cryptologic information. 
Document meta information like in license models and features. 
Store the prompt in the document to be able to update."

TO UPDATE THIS DOCUMENT:
1. Run: .\copy-documents.ps1 (to copy latest files from TL2, TL2_dotnet, TLCloud)
2. Run: .\generate-file-mapping.ps1 (to generate file-mapping.json with source references)
3. Use this prompt:
   "Using the file-mapping.json for source references, analyze all documents in the input folder and update 
   the TrustedLicensing_Client_Security_Cryptography.md with comprehensive information about:
   - Trusted Licensing client architecture (TLLicenseManager and TLLicenseClient)
   - TPM 2.0 integration and hardware security
   - Cryptographic key infrastructure and key hierarchy
   - Encryption, decryption, signing, and verification operations
   - Storage Root Key (SRK) and derived keys
   - License encryption and delivery mechanism
   - Hardware fingerprinting and identification
   - Security mechanisms and threat protection
   - Platform-specific security implementations
   - API security and client authentication
   - Startup sequence and initialization
   - Configuration and deployment security
   
   IMPORTANT: Reference sources using relative paths from originalPath in file-mapping.json.
   Format: **Source:** [filename.md](../Repository/path/to/file.md "Repository/path/to")
   - Link text displays filename only
   - Link target is full relative path
   - Title attribute (hover tooltip) shows directory path
   Do NOT use http:// or https:// links. Use filesystem relative paths only.
   
   Include detailed technical information, code examples, and always cite sources with relative paths.
   Update the timestamp to current date/time in English format with 24h time: 
   [System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Get-Date -Format "dd MMMM yyyy HH:mm""

File mapping: See file-mapping.json for complete source-to-destination mapping
Files analyzed: 56 files from TL2, TL2_dotnet, and TLCloud repositories
Excluded: vcpkg_installed and out directories
-->

# Trusted Licensing 365 - Client Security and Cryptography

**Generated:** 31 January 2026 09:17  
**Last Updated:** 31 January 2026 09:17  
**Source:** Consolidated documentation from TL2, TL2_dotnet, and TLCloud repositories  
**Files Analyzed:** 56 files copied (9 skipped from vcpkg_installed and out directories)

---

## Executive Summary

**Trusted Licensing 365 Client** is a hardware-backed licensing solution built on TPM 2.0 technology, providing cryptographic security for software license management. The client architecture consists of two main components: **TLLicenseManager** (service/daemon) and **TLLicenseClient** (embedded library), both leveraging Trusted Platform Module for secure key storage, hardware fingerprinting, and tamper-resistant license enforcement.

**Key Security Characteristics:**
- Hardware-backed security using TPM 2.0 chips
- Multi-layer cryptographic key hierarchy
- OS-independent license persistence via TPM non-volatile storage
- Hardware fingerprinting with VM rollback detection
- Platform-specific trust mechanisms (Windows/Linux/macOS)
- Support for OAuth/IAM integration and SSO

**Supported Platforms:**
- Windows (with TPM 2.0)
- Linux (with TPM 2.0 or software TPM)
- Container environments (Docker/Kubernetes with TPM passthrough)
- Fallback fingerprint mode for non-TPM environments

---

## Table of Contents

1. [Client Architecture](#1-client-architecture)
2. [TPM 2.0 Hardware Security](#2-tpm-20-hardware-security)
3. [Cryptographic Key Infrastructure](#3-cryptographic-key-infrastructure)
4. [Encryption and Cryptographic Operations](#4-encryption-and-cryptographic-operations)
5. [License Delivery and Storage](#5-license-delivery-and-storage)
6. [Hardware Fingerprinting](#6-hardware-fingerprinting)
7. [Security Mechanisms and Threat Protection](#7-security-mechanisms-and-threat-protection)
8. [Client Authentication and Trust](#8-client-authentication-and-trust)
9. [Startup Sequence and Initialization](#9-startup-sequence-and-initialization)
10. [Platform-Specific Security](#10-platform-specific-security)
11. [API Security](#11-api-security)
12. [Configuration Security](#12-configuration-security)
13. [Deployment and Operational Security](#13-deployment-and-operational-security)
14. [Compliance and Best Practices](#14-compliance-and-best-practices)
15. [Document Sources](#15-document-sources)

---

## 1. Client Architecture

### 1.1 Overview

The Trusted Licensing client ecosystem provides two deployment models to accommodate different security and resource requirements.

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 1.2 TLLicenseManager (Service/Daemon)

**Description:** Full-featured licensing service with TPM integration

**Architecture:**
- Implemented as Windows Service or Linux daemon (Trusted License Manager - TLLM)
- Requires elevated privileges for TPM access
- Communication via REST API (primary) and gRPC (planned)
- Supports network-based licensing

**Network License Models:**
- **Named User:** OAuth-based authenticated user licensing
- **Station:** Device-based licensing
- **Consumption:** Login-based usage tracking
- **Process:** Per-process license checkout

**Key Features:**
- Hardware-backed cryptographic operations via TPM
- Deterministic key generation with reproducibility
- Multi-platform support (Windows/Linux, physical/container)
- REST and optional gRPC API interfaces
- PCR-based boot state attestation
- Configurable logging levels

**Requirements:**
- Windows: Administrator privileges
- Linux: Root or sudo access
- TPM 2.0 hardware or software TPM simulator

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client"), [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 1.3 TLLicenseClient (Embedded Library)

**Description:** Lightweight licensing library for resource-constrained environments

**Use Cases:**
- Embedded systems with limited resources
- IoT devices
- Applications where running a service/daemon is impractical
- Scenarios requiring minimal footprint

**Communication:**
- REST to TLLicenseManager when available
- gRPC support planned
- Can operate in offline mode with cached licenses

**Limitations:**
- TPM access still requires service/daemon or elevation
- Uses same underlying security mechanisms as TLLicenseManager
- Delegates TPM operations to TLLicenseManager when needed

**Offline Capability:**
- Supports offline license validation
- Cached license data in secure storage
- Time-limited offline operation (configurable)

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 1.4 Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Vendor Application                        │
└────────────────┬────────────────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    v                         v
┌─────────────┐         ┌──────────────┐
│TLLicenseClient│ REST  │TLLicenseManager│
│  (Library)   ├────────►  (Service)    │
└─────────────┘         └───────┬───────┘
                                │
                                v
                        ┌───────────────┐
                        │  TPM 2.0 Chip │
                        │  ┌─────────┐  │
                        │  │   SRK   │  │
                        │  ├─────────┤  │
                        │  │NV Storage│ │
                        │  ├─────────┤  │
                        │  │  HMAC   │  │
                        │  └─────────┘  │
                        └───────────────┘
```

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

---

## 2. TPM 2.0 Hardware Security

### 2.1 TPM Overview

**Trusted Platform Module 2.0** provides hardware-backed security primitives for the Trusted Licensing client.

**Core TPM Features Used:**
- **Storage Root Keys (SRK):** Asymmetric keys stored in TPM
- **HMAC Operations:** Hardware-backed message authentication
- **Non-Volatile Storage:** Persistent license data storage
- **Platform Configuration Registers (PCR):** Boot state attestation
- **Hardware Random Number Generator:** Cryptographic randomness

**Benefits:**
- Keys never leave the TPM hardware
- Tamper-resistant key storage
- Hardware-bound licenses
- OS-independent persistence

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 2.2 TPM-Based Storage

**Architecture:**
- Uses Storage Root Key (SRK) as the root of trust
- Non-volatile (NV) space for persistent license data
- TPM 2.0 compliant implementation

**Storage Hierarchy:**
```
TPM 2.0
├── Storage Root Key (SRK) [Persistent Handle: 2101]
│   └── Derived keys for specific operations
├── Signature Key [Persistent Handle: 2102]
│   └── License signing and verification
└── Non-Volatile Storage
    ├── License data
    ├── Configuration secrets
    └── Vendor keys
```

**Benefits:**
- **OS Independence:** Can change OS without losing license trust
- **Hardware Binding:** Licenses bound to specific TPM/hardware
- **Tamper Resistance:** Protected by hardware security
- **Persistence:** Survives OS reinstallation

**Storage Requirements:**
- TPM with at least 2 persistent key handles
- NV storage space for license data (size varies)
- Support for RSA 3072 or ECC operations

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client"), [TPM_Requirements.md](input/TLDocs/Client/TPM_Requirements.md "TLDocs/Client")

### 2.3 TPM Operations

#### Key Generation

**Storage Root Key (SRK) Generation:**
```cpp
// Create persistent SRK at handle 2101
TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);

TPMT_PUBLIC srkTemplate(
    TPM_ALG_ID::SHA256,          // Name algorithm
    TPMA_OBJECT::decrypt |        // Can decrypt
    TPMA_OBJECT::restricted |     // Restricted key
    TPMA_OBJECT::fixedTPM |       // Cannot be exported
    TPMA_OBJECT::fixedParent |    // Parent cannot change
    TPMA_OBJECT::sensitiveDataOrigin | // TPM generated
    TPMA_OBJECT::userWithAuth,    // Auth required
    ByteVec(),                    // No auth policy
    TPMS_RSA_PARMS(              // RSA parameters
        TPMT_SYM_DEF_OBJECT(TPM_ALG_ID::AES, 128, TPM_ALG_ID::CFB),
        TPMS_SCHEME_OAEP(TPM_ALG_ID::SHA256),
        3072,                     // Key size
        0                         // Exponent (default)
    ),
    TPM2B_PUBLIC_KEY_RSA()       // No initial value
);

auto createResult = tpm.CreatePrimary(
    TPM_HANDLE::RH_OWNER,
    TPMS_SENSITIVE_CREATE(),
    srkTemplate,
    ByteVec(),
    TPMS_PCR_SELECTION::GetEmpty()
);

// Make persistent
tpm.EvictControl(
    TPM_HANDLE::RH_OWNER,
    createResult.handle,
    srkHandle
);
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

#### Cryptographic Operations

**RSA Encryption (OAEP with SHA256):**
```cpp
TPMResponseVal<std::string> EncryptSRK(const std::string& payload)
{
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    srkHandle.SetAuth(TPM_AUTH);
    
    TPMS_SCHEME_OAEP scheme(TPM_ALG_ID::SHA256);
    
    ByteVec encrypted = tpm.RSA_Encrypt(
        srkHandle,
        String2ByteVec(payload),
        scheme,
        null  // no label
    );
    
    return ByteVec2String(encrypted);
}
```

**RSA Decryption:**
```cpp
TPMResponseVal<std::string> DecryptSRK(const std::string& ciphertext)
{
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    srkHandle.SetAuth(TPM_AUTH);
    
    TPMS_SCHEME_OAEP scheme(TPM_ALG_ID::SHA256);
    
    ByteVec decrypted = tpm.RSA_Decrypt(
        srkHandle,
        String2ByteVec(ciphertext),
        scheme,
        null
    );
    
    return ByteVec2String(decrypted);
}
```

**Digital Signing (RSASSA with SHA256):**
```cpp
TPMResponseVal<std::string> Sign(const std::string& data)
{
    TPM_HANDLE sigKey = TPM_HANDLE::Persistent(2102);
    sigKey.SetAuth(TPM_AUTH);
    
    TPMT_SIG_SCHEME scheme(TPM_ALG_ID::RSASSA, TPM_ALG_ID::SHA256);
    
    ByteVec digest = SHA256(data);
    
    auto signature = tpm.Sign(
        sigKey,
        digest,
        scheme,
        TPMT_TK_HASHCHECK::NullTicket()
    );
    
    return signature.signature.toBytes();
}
```

**HMAC Operations:**
```cpp
TPMResponseVal<ByteVec> GenerateHMAC(const ByteVec& data)
{
    TPM_HANDLE hmacKey = TPM_HANDLE::Persistent(2103);
    hmacKey.SetAuth(TPM_AUTH);
    
    auto hmacResult = tpm.HMAC(
        hmacKey,
        data,
        TPM_ALG_ID::SHA256
    );
    
    return hmacResult.outHMAC;
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 2.4 Non-Volatile Storage Operations

**Security Model v1.1:**

TLLicenseManager uses **PCR-based authentication** for NVRAM operations, providing hardware-bound security **without password storage**. Access to NVRAM data requires the TPM's Platform Configuration Registers (PCRs) to match the values from when data was written.

**PCR Policy Options:**

| Policy | PCRs Used | Security Level | Flexibility | Use Case |
|--------|-----------|----------------|-------------|----------|
| **FirmwareBoot** (Recommended) | 0, 7 | High | Medium | Production with stable firmware |
| **SecureBoot** | 7 | Medium | High | Frequent firmware updates |
| **BootSequence** | 0, 2, 7 | Maximum | Low | Locked hardware configs |

**PCR Meanings:**
- **PCR 0:** Firmware/BIOS measurements
- **PCR 2:** Option ROM code
- **PCR 7:** Secure Boot state

**Configuration:**

Set the vault policy in `TLLicenseManager.json`:

```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "VaultPolicy": "FirmwareBoot"
    }
  }
}
```

**Write Operation with PCR Policy:**
```cpp
TPMResponse WriteNV(const string& data, int nvSlot, const std::vector<UINT32>& pcrIndices)
{
    TPM_HANDLE nvHandle = TPM_HANDLE::NV(nvSlot);
    
    // 1. Read current PCR values
    TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, pcrIndices);
    auto pcrRead = tpm.PCR_Read({pcrSel});
    
    // 2. Create PCR policy
    PolicyTree policy;
    PolicyPcr pcrPolicy(pcrRead.pcrValues, {pcrSel});
    policy.SetTree({&pcrPolicy});
    ByteVec policyDigest = policy.GetPolicyDigest(TPM_ALG_ID::SHA256);
    
    // 3. Create NV template with PCR policy
    TPMS_NV_PUBLIC nvTemplate(
        nvHandle,
        TPM_ALG_ID::SHA256,      // Name hash algorithm
        TPMA_NV::POLICYREAD |    // Policy-based read
        TPMA_NV::POLICYWRITE |   // Policy-based write
        TPMA_NV::NO_DA,          // No dictionary attack
        policyDigest,            // PCR policy digest
        NV_INDEX_SIZE            // 64 bytes
    );
    
    // 4. Check if NV index exists
    auto nvPub = tpm._AllowErrors().NV_ReadPublic(nvHandle);
    if (!tpm._LastCommandSucceeded()) {
        // Define new index with owner auth (no password)
        tpm.NV_DefineSpace(TPM_RH::OWNER, {}, nvTemplate);
        nvPub = tpm.NV_ReadPublic(nvHandle);
    }
    
    nvHandle.SetName(nvPub.nvName);
    
    // 5. Start policy session
    AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::POLICY, TPM_ALG_ID::SHA256);
    
    // 6. Satisfy PCR policy
    tpm.PolicyPCR(session, pcrRead.pcrValues, {pcrSel});
    
    // 7. Write data
    tpm[session].NV_Write(nvHandle, nvHandle, String2ByteVec(data), 0);
    
    // 8. Cleanup
    tpm.FlushContext(session);
    
    return success;
}
```

**Read Operation with PCR Policy:**
```cpp
TPMResponseVal<string> ReadNV(int nvSlot, const std::vector<UINT32>& pcrIndices)
{
    TPM_HANDLE nvHandle = TPM_HANDLE::NV(nvSlot);
    
    // 1. Read current PCR values
    TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, pcrIndices);
    auto pcrRead = tpm.PCR_Read({pcrSel});
    
    // 2. Get NV handle name
    auto nvPub = tpm.NV_ReadPublic(nvHandle);
    nvHandle.SetName(nvPub.nvName);
    
    // 3. Start policy session
    AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::POLICY, TPM_ALG_ID::SHA256);
    
    // 4. Satisfy PCR policy
    tpm.PolicyPCR(session, pcrRead.pcrValues, {pcrSel});
    
    // 5. Read data
    ByteVec data = tpm[session].NV_Read(nvHandle, nvHandle, NV_INDEX_SIZE, 0);
    
    // 6. Cleanup
    tpm.FlushContext(session);
    
    return ByteVec2String(data);
}
```

**Security Benefits:**

1. **No Password Storage:** Eliminates risk of password theft or disclosure
2. **Hardware-Bound:** Data access tied to platform boot state
3. **Tamper Evidence:** PCR changes from firmware/config modifications prevent access
4. **Non-Exportable:** Cannot copy NVRAM data to another system

**Migration Notes:**

- Changing `VaultPolicy` requires NVRAM re-initialization
- Existing data becomes inaccessible until rewritten with new policy
- Firmware updates may require re-initialization (FirmwareBoot/BootSequence policies)
- PCR values must match between write and read operations

**Note:** NVRAM functionality is fully implemented and tested but not currently used in production license flow.

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 2.5 Platform Configuration Registers (PCR)

**PCR Boot Attestation:**
```cpp
struct BootState
{
    std::map<uint32_t, ByteVec> pcrValues;
    ByteVec quote;
    TPMT_SIGNATURE signature;
};

BootState GetBootAttestation()
{
    BootState state;
    
    // Read PCR values
    std::vector<uint32_t> pcrIndices = {0, 1, 2, 3, 4, 5, 6, 7};
    
    for (auto pcr : pcrIndices)
    {
        auto pcrRead = tpm.PCR_Read(
            TPMS_PCR_SELECTION(TPM_ALG_ID::SHA256, pcr)
        );
        state.pcrValues[pcr] = pcrRead.pcrValues[0];
    }
    
    // Generate quote
    TPM_HANDLE aikHandle = TPM_HANDLE::Persistent(2104);
    TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, pcrIndices);
    
    auto quoteResult = tpm.Quote(
        aikHandle,
        ByteVec(32, 0),  // qualifying data
        TPMT_SIG_SCHEME(TPM_ALG_ID::RSASSA, TPM_ALG_ID::SHA256),
        pcrSel
    );
    
    state.quote = quoteResult.quoted.toBytes();
    state.signature = quoteResult.signature;
    
    return state;
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 2.6 Hardware Random Number Generator

```cpp
ByteVec GetRandomBytes(size_t numBytes)
{
    ByteVec randomData;
    
    // TPM can generate max 32 bytes at a time
    while (randomData.size() < numBytes)
    {
        size_t bytesToGet = std::min(numBytes - randomData.size(), 
                                     size_t(32));
        auto random = tpm.GetRandom(bytesToGet);
        randomData.insert(randomData.end(), 
                         random.randomBytes.begin(), 
                         random.randomBytes.end());
    }
    
    return randomData;
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

---

## 3. Cryptographic Key Infrastructure

### 3.1 Key Hierarchy

The Trusted Licensing system uses a multi-layer key hierarchy for security.

```
┌─────────────────────────────────────────────────────────┐
│                    TPM Hardware                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │   Storage Root Key (SRK) - Asymmetric (RSA 3072) │  │
│  │   [Never leaves TPM, Hardware-bound]              │  │
│  └────────────────┬──────────────────────────────────┘  │
└───────────────────┼──────────────────────────────────────┘
                    │
       ┌────────────┴────────────┐
       │                         │
       v                         v
┌──────────────┐         ┌──────────────┐
│ Derived Keys │         │  Signature   │
│              │         │     Key      │
│ • RSA 3072   │         │  RSA 3072    │
│ • AES 256    │         └──────────────┘
└──────────────┘

External Keys (Not in TPM):
┌─────────────────────────────────────────────────┐
│ Vendor Key (VK) - Asymmetric (RSA 3072)        │
│ • Private: Embedded in client libraries         │
│ • Public: Registered in LMS                     │
└─────────────────────────────────────────────────┘

License Delivery Keys:
┌─────────────────────────────────────────────────┐
│ License Gen Key (LGK) - Symmetric (AES 256)     │
│ • Encrypts license data                         │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│ License Manager Delivery Key (LMDK) - Symmetric│
│ • Encrypts LGK for delivery                     │
└─────────────────────────────────────────────────┘
```

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client"), [TPM_Requirements.md](input/TLDocs/Client/TPM_Requirements.md "TLDocs/Client")

### 3.2 Storage Root Key (SRK)

**Type:** Asymmetric (RSA 3072 or ECC)

**Purpose:**
- Root of trust for License Manager
- Client hardware identifier
- Used as fingerprint in License Management System (LMS)

**Characteristics:**
- **Generation:** Created by TPM hardware
- **Private Key:** Stored in TPM, never exposed or exported
- **Public Key:** Registered in LMS for client identification
- **Persistence:** Stored at persistent handle 2101
- **Authorization:** Protected by TPM auth value

**Key Properties:**
- Fixed to TPM (cannot be duplicated)
- Fixed parent (hierarchy cannot change)
- Restricted usage (specific operations only)
- Decrypt capability
- User authentication required

**Derived Keys from SRK:**

1. **RSA 3072 or ECC Keys:**
   - License Manager to License Generator communication
   - License Manager to License Manager communication
   - Encrypting payload keys

2. **AES 256 Keys:**
   - Communication payload encryption
   - License Manager persistence encryption

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client"), [TPM_Requirements.md](input/TLDocs/Client/TPM_Requirements.md "TLDocs/Client")

### 3.3 Vendor Key (VK)

**Type:** Asymmetric (RSA 3072)

**Purpose:**
- Identifies the software vendor
- Restricts license consumption to authorized vendor clients
- Enables vendor-specific cryptographic operations

**Key Distribution:**
- **Private Key:** Secret, embedded in vendor's client libraries
- **Public Key:** Registered in License Management System (LMS)
- **Delivery:** Encrypted download from LMS to authorized vendors

**Security Model:**
- Only clients with correct vendor private key can decrypt vendor-specific licenses
- Multi-tenant isolation: each vendor has unique key pair
- Revocation support: vendor keys can be rotated or revoked

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

### 3.4 License Generation Keys

#### License Gen Key (LGK)

**Type:** Symmetric (AES 256)

**Purpose:**
- Encrypts license data
- Temporary key generated for each license or license batch

**Lifecycle:**
1. Generated by License Generator
2. Used to encrypt license features and metadata
3. Wrapped using Vendor Key (VK)
4. Delivered to client encrypted with LMDK

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

#### License Manager Delivery Key (LMDK)

**Type:** Symmetric (AES 256)

**Purpose:**
- Encrypts the License Gen Key (LGK) for secure transmission
- Provides additional layer of encryption

**Lifecycle:**
1. Generated for license delivery
2. Encrypts the already VK-wrapped LGK
3. Itself encrypted using Storage Root Key (SRK)
4. Ensures only target License Manager can decrypt

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

### 3.5 Key Wrapping Process

**Multi-Layer Encryption for License Delivery:**

```
┌─────────────────────────────────────────────────────┐
│ Step 1: Encrypt License with LGK                    │
│ License Data → [AES-256-GCM with LGK] → Encrypted   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────┐
│ Step 2: Wrap LGK with Vendor Public Key             │
│ LGK → [RSA-OAEP with VK public] → Wrapped_LGK       │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────┐
│ Step 3: Encrypt Wrapped_LGK with LMDK               │
│ Wrapped_LGK → [AES-256-GCM with LMDK] → Encrypted   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────┐
│ Step 4: Wrap LMDK with SRK Public Key               │
│ LMDK → [RSA-OAEP with SRK public] → Wrapped_LMDK    │
└─────────────────────────────────────────────────────┘

Final Delivery Package:
├── Encrypted License (from Step 1)
├── Wrapped_LGK (from Step 2-3)
└── Wrapped_LMDK (from Step 4)
```

**Decryption Process on Client:**

```
1. Unwrap LMDK using SRK private key in TPM
2. Decrypt Wrapped_LGK using LMDK
3. Unwrap LGK using Vendor private key
4. Decrypt License using LGK
```

**Security Properties:**
- **Vendor Authorization:** Only clients with correct Vendor Key can decrypt
- **Hardware Binding:** Only target TPM/hardware can decrypt (via SRK)
- **End-to-End Confidentiality:** License data encrypted throughout delivery
- **Authenticity:** Cryptographic proof of authorized license generator

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

---

## 4. Encryption and Cryptographic Operations

### 4.1 Supported Algorithms

**Asymmetric Algorithms:**
- RSA 3072 (primary)
- RSA 2048 (legacy support)
- ECC (planned support)

**Symmetric Algorithms:**
- AES-256-GCM (authenticated encryption)
- AES-256-CBC (legacy)
- AES-128-CFB (key wrapping)

**Hash Algorithms:**
- SHA-256 (primary)
- SHA-384
- SHA-512

**Signature Schemes:**
- RSASSA-PKCS1-v1_5 with SHA-256
- RSASSA-PSS with SHA-256 (preferred)

**Key Exchange:**
- RSA-OAEP for key wrapping
- Diffie-Hellman / TLS 1.2+ for session keys

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs"), [Crypto.md](input/TLDocs/Crypto.md "TLDocs")

### 4.2 RSA Operations

#### Public Key Format

**PKCS#1 RSA Public Key:**
```
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEA...
-----END RSA PUBLIC KEY-----
```

**X.509 SubjectPublicKeyInfo:**
```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
```

**Source:** [Crypto.md](input/TLDocs/Crypto.md "TLDocs")

#### Encryption Example (C++)

```cpp
#include "TLCrypt/RSACrypto.h"

// Load public key
RSAPublicKey pubKey = RSACrypto::LoadPublicKey(pemString);

// Encrypt data
std::string plaintext = "Sensitive license data";
std::vector<uint8_t> ciphertext = RSACrypto::Encrypt(
    pubKey, 
    plaintext,
    RSAPadding::OAEP_SHA256
);

// Result is base64 or hex encoded for transmission
std::string encoded = Base64::Encode(ciphertext);
```

#### Decryption Example (C++)

```cpp
// Decrypt using TPM-stored private key
std::vector<uint8_t> ciphertext = Base64::Decode(encoded);

TPMService tpm;
std::string plaintext = tpm.DecryptWithSRK(ciphertext);
```

**Source:** [Crypto.md](input/TLDocs/Crypto.md "TLDocs"), [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 4.3 AES Operations

#### AES-256-GCM Authenticated Encryption

```cpp
#include "TLCrypt/AESCrypto.h"

struct AESGCMResult
{
    std::vector<uint8_t> ciphertext;
    std::vector<uint8_t> nonce;      // 12 bytes
    std::vector<uint8_t> tag;        // 16 bytes authentication tag
};

AESGCMResult EncryptAESGCM(
    const std::vector<uint8_t>& key,      // 32 bytes (256 bits)
    const std::vector<uint8_t>& plaintext,
    const std::vector<uint8_t>& aad)      // Additional authenticated data
{
    AESGCMResult result;
    
    // Generate random nonce
    result.nonce = TPMService::GetRandom(12);
    
    // Encrypt
    AESCrypto::EncryptGCM(
        key,
        result.nonce,
        plaintext,
        aad,
        result.ciphertext,
        result.tag
    );
    
    return result;
}

std::vector<uint8_t> DecryptAESGCM(
    const std::vector<uint8_t>& key,
    const AESGCMResult& encrypted,
    const std::vector<uint8_t>& aad)
{
    std::vector<uint8_t> plaintext;
    
    bool success = AESCrypto::DecryptGCM(
        key,
        encrypted.nonce,
        encrypted.ciphertext,
        aad,
        encrypted.tag,
        plaintext
    );
    
    if (!success)
        throw CryptoException("Authentication failed");
    
    return plaintext;
}
```

**Source:** [Crypto.md](input/TLDocs/Crypto.md "TLDocs")

### 4.4 Digital Signatures

#### Signing

```cpp
std::vector<uint8_t> SignData(const std::string& data)
{
    // Hash the data
    std::vector<uint8_t> hash = SHA256::Hash(data);
    
    // Sign using TPM signature key
    TPMService tpm;
    return tpm.Sign(hash, SignatureScheme::RSASSA_SHA256);
}
```

#### Verification

```cpp
bool VerifySignature(
    const std::string& data,
    const std::vector<uint8_t>& signature,
    const RSAPublicKey& publicKey)
{
    std::vector<uint8_t> hash = SHA256::Hash(data);
    
    return RSACrypto::Verify(
        publicKey,
        hash,
        signature,
        SignatureScheme::RSASSA_SHA256
    );
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 4.5 C#/C++ Cryptographic Interoperability

**Challenge:** Ensuring RSA operations between C++ (client) and C# (server) are compatible

**Key Considerations:**
1. **Padding Scheme:** Must match (OAEP with SHA-256)
2. **Key Format:** PEM format compatibility
3. **Encoding:** Consistent base64/hex encoding

**C# Example (using .NET Cryptography):**

```csharp
using System.Security.Cryptography;

// Load public key from PEM
RSA rsa = RSA.Create();
rsa.ImportFromPem(pemPublicKey);

// Encrypt with OAEP SHA-256
byte[] ciphertext = rsa.Encrypt(
    plaintext, 
    RSAEncryptionPadding.OaepSHA256
);
```

**C++ Example (using Botan or Crypto++):**

```cpp
// Using Botan library
#include <botan/pubkey.h>
#include <botan/rsa.h>

Botan::RSA_PublicKey pubKey = LoadPublicKey(pemString);

Botan::PK_Encryptor_EME encryptor(
    pubKey, 
    rng, 
    "OAEP(SHA-256)"
);

std::vector<uint8_t> ciphertext = encryptor.encrypt(plaintext, rng);
```

**Resources:**
- Crypto++ Library: https://www.cryptopp.com/
- Botan Library: https://botan.randombit.net/
- Interop Guide: https://www.c-sharpcorner.com/forums/rsaencryptionpaddingoaepsha256

**Source:** [Crypto.md](input/TLDocs/Crypto.md "TLDocs")

---

## 5. License Delivery and Storage

### 5.1 License Container Structure

```
License Container
├── Container GUID
├── Name
├── Routing Information
├── Vendor
│   ├── Vendor Code
│   ├── Vendor Info
│   └── Vendor Public Key
└── Product
    ├── Features[]
    │   ├── Feature ID
    │   ├── Feature Type
    │   ├── Seat Count
    │   ├── Expiration
    │   ├── Memory (custom data)
    │   └── Binding (TPM/Fingerprint)
    ├── License Models[]
    │   ├── Model Type
    │   ├── Parameters
    │   └── Restrictions
    └── Tokens[]
        ├── Token ID
        ├── Cryptographic Signature
        └── Validation Data
```

**Source:** [Activation.md](input/TLDocs/LMS/Activation/Activation.md "TLDocs/LMS/Activation")

### 5.2 License Encryption Layers

**Layer 1: Feature Data Encryption**
```
Feature Data → AES-256-GCM(LGK) → Encrypted Feature
```

**Layer 2: LGK Wrapping**
```
LGK → RSA-OAEP(VK_public) → Wrapped LGK
Wrapped LGK → AES-256-GCM(LMDK) → Encrypted LGK Package
```

**Layer 3: LMDK Wrapping**
```
LMDK → RSA-OAEP(SRK_public) → Wrapped LMDK
```

**Final License Package:**
```json
{
  "version": "2.0",
  "containerId": "uuid",
  "vendorId": "vendor-guid",
  "productId": "product-guid",
  "encryptedFeatures": "base64-encrypted-data",
  "wrappedLGK": "base64-wrapped-key",
  "wrappedLMDK": "base64-wrapped-key",
  "signature": "base64-signature",
  "timestamp": "2026-01-28T15:30:00Z"
}
```

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client"), [Activation.md](input/TLDocs/LMS/Activation/Activation.md "TLDocs/LMS/Activation")

### 5.3 TPM-Based License Storage

**Storage Architecture:**

```
TPM Non-Volatile Storage
├── NV Index 0x1500000 (License Data)
│   ├── License Container (encrypted)
│   ├── Feature Cache
│   └── Usage Metrics
├── NV Index 0x1500001 (Configuration)
│   ├── Vendor Keys
│   ├── Server Endpoints
│   └── Client Settings
└── NV Index 0x1500002 (Audit Trail)
    ├── License Activation Events
    ├── Usage History
    └── Revocation List
```

**Persistence Benefits:**
- Survives OS reinstallation
- Protected by TPM hardware
- Can transfer between OS installations on same hardware
- Tamper-resistant storage

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 5.4 Filesystem Fallback Storage

**Location (Windows):**
```
C:\ProgramData\TrustedLicensing\Persistence\
├── licenses\
│   ├── {license-guid}.enc
│   └── cache.dat
├── config\
│   └── settings.enc
└── logs\
    └── audit.log
```

**Location (Linux):**
```
/var/lib/trustedlicensing/
├── licenses/
│   ├── {license-guid}.enc
│   └── cache.dat
├── config/
│   └── settings.enc
└── logs/
    └── audit.log
```

**Security:**
- Files encrypted with keys derived from SRK
- ACLs restrict access to system account
- File integrity verified on load

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

---

## 6. Hardware Fingerprinting

### 6.1 TPM-Based Fingerprinting

**Primary Method:** Storage Root Key (SRK) Public Key Hash

```cpp
std::string GetTPMFingerprint()
{
    TPMService tpm;
    
    // Get SRK public key
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    auto publicKey = tpm.ReadPublic(srkHandle);
    
    // Hash public key to create fingerprint
    ByteVec pubKeyBytes = publicKey.outPublic.toBytes();
    ByteVec hash = SHA256::Hash(pubKeyBytes);
    
    // Return as hex string
    return ByteVec2HexString(hash);
}
```

**Characteristics:**
- Unique per TPM chip
- Deterministic and reproducible
- Hardware-bound
- Cannot be spoofed without physical TPM access

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client"), [FingerPrints.md](input/TLDocs/Client/FingerPrints.md "TLDocs/Client")

### 6.2 Software Fingerprinting Alternative

**Use Case:** Environments without TPM support

**Components Analyzed:**
- CPU ID and features
- MAC addresses (primary network adapter)
- Motherboard serial number
- BIOS/UEFI identifiers
- Storage device serials
- OS installation ID

**Built-in Fingerprint Algorithm:**

```cpp
struct HardwareInfo
{
    std::string cpuId;
    std::string macAddress;
    std::string motherboardSerial;
    std::string biosId;
    std::string storageSerial;
    std::string osInstallId;
};

std::string GenerateFingerprint(const HardwareInfo& hw)
{
    std::string combined = 
        hw.cpuId + "|" +
        hw.macAddress + "|" +
        hw.motherboardSerial + "|" +
        hw.biosId + "|" +
        hw.storageSerial + "|" +
        hw.osInstallId;
    
    // Hash combined string
    return SHA256::HashString(combined);
}
```

**Limitations:**
- Less secure than TPM (can be spoofed)
- Subject to hardware changes
- Stored in standard filesystem (less tamper-resistant)

**License Requirement:**
- Requires special license to enable fingerprint mode
- License can disable TPM requirement

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client"), [FingerPrints.md](input/TLDocs/Client/FingerPrints.md "TLDocs/Client")

### 6.3 Custom Fingerprint Callback

**For Advanced Scenarios:**

Vendors can implement custom fingerprinting logic via C++ callback:

```cpp
// Vendor-defined fingerprint function
typedef std::string (*CustomFingerprintFunc)();

// Register custom fingerprint
TLLicenseManager::RegisterCustomFingerprint(
    [](void) -> std::string {
        // Vendor-specific logic
        std::string dongleId = ReadDongleSerialNumber();
        std::string machineId = GetVendorMachineId();
        
        return SHA256::HashString(dongleId + machineId);
    }
);
```

**Use Cases:**
- Hardware dongles
- Custom security devices
- Proprietary identification methods
- IoT device identifiers

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client"), [FingerPrints.md](input/TLDocs/Client/FingerPrints.md "TLDocs/Client")

### 6.4 Virtual Machine Detection

**Challenges:**
- VM rollback/snapshot restoration
- License state manipulation
- Time-based attack vectors

**Detection Methods:**

1. **Slack Space Analysis:**
   - Detect file system inconsistencies
   - Identify disk snapshot artifacts
   - Reference: https://github.com/OpenSecurityResearch/slacker

2. **Log Analysis:**
   - Check hypervisor logs for rollback events
   - Monitor VM management software logs

3. **Snapshot Detection:**
   - Check for active VM snapshots
   - Verify snapshot timestamps vs. license activation

4. **File System Timestamp Analysis:**
   - Detect temporal inconsistencies
   - Files reverting to older states
   - Missing files that should exist

5. **Network Analysis:**
   - Sudden network reconnections
   - Retransmitted packets indicating rollback

6. **Time Discrepancy:**
   - Compare VM time vs. trusted time source
   - Detect significant time jumps backward

**Anti-Rollback Mechanisms:**

```cpp
class RollbackDetector
{
public:
    bool DetectRollback()
    {
        // Check monotonic counter
        uint64_t currentCounter = ReadTPMCounter();
        uint64_t lastCounter = LoadLastCounterValue();
        
        if (currentCounter < lastCounter)
        {
            // Rollback detected
            LogSecurityEvent("VM rollback detected");
            return true;
        }
        
        // Store new counter
        StoreCounterValue(currentCounter);
        return false;
    }
    
private:
    uint64_t ReadTPMCounter()
    {
        // Use TPM NV counter (monotonic)
        return tpm.NV_ReadCounter(NV_COUNTER_INDEX);
    }
};
```

**Limitations:**
- Not foolproof across all virtualization platforms
- Determined attackers may find workarounds
- Refer to specific hypervisor documentation

**Source:** [FingerPrints.md](input/TLDocs/Client/FingerPrints.md "TLDocs/Client")

---

## 7. Security Mechanisms and Threat Protection

### 7.1 Threat Model

**Protected Against:**
- Unauthorized license duplication
- License tampering and modification
- Software piracy and cracking
- VM snapshot/rollback attacks
- Man-in-the-middle attacks
- Key extraction attempts
- Unauthorized license transfer

**Assumptions:**
- TPM hardware is trusted and not physically compromised
- OS kernel is not compromised
- Physical access to hardware is controlled
- Network communications use TLS 1.2+

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 7.2 Hardware-Backed Security

**TPM Security Features:**
- Keys never leave hardware
- Tamper-resistant key storage
- Hardware random number generation
- Boot integrity measurement (PCR)
- Dictionary attack protection

**Protection Mechanisms:**
```cpp
// Dictionary attack lockout
tpm.DictionaryAttackLockReset(TPM_HANDLE::RH_LOCKOUT);
tpm.DictionaryAttackParameters(
    TPM_HANDLE::RH_LOCKOUT,
    5,      // Max tries before lockout
    300,    // Recovery time (seconds)
    86400   // Lockout duration (seconds)
);
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 7.3 Cryptographic Protections

**Multi-Layer Encryption:**
- License data encrypted with AES-256-GCM
- Keys wrapped with RSA-3072-OAEP
- Authenticated encryption prevents tampering
- Cryptographic signatures verify authenticity

**Key Rotation:**
- Support for periodic vendor key rotation
- License re-encryption with new keys
- Gradual migration without service disruption

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

### 7.4 Anti-Tampering Mechanisms

**Code Integrity:**
- Executable signing (Authenticode on Windows)
- Binary verification before execution
- Checksum validation

**Runtime Protection:**
- Process isolation
- Memory protection
- Anti-debugging techniques (optional)

**Audit Trail:**
```cpp
struct AuditEvent
{
    std::string timestamp;
    std::string eventType;
    std::string description;
    std::string fingerprint;
    std::string signature;  // Signed with TPM key
};

void LogAuditEvent(const std::string& eventType, 
                   const std::string& description)
{
    AuditEvent event;
    event.timestamp = GetUTCTimestamp();
    event.eventType = eventType;
    event.description = description;
    event.fingerprint = GetTPMFingerprint();
    
    // Sign event
    std::string eventData = SerializeEvent(event);
    event.signature = TPMSign(eventData);
    
    // Store in tamper-evident log
    AppendToAuditLog(event);
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 7.5 Network Security

**TLS Requirements:**
- TLS 1.2 minimum (TLS 1.3 preferred)
- Strong cipher suites only
- Certificate validation required
- Perfect forward secrecy

**API Authentication:**
- OAuth 2.0 / OpenID Connect for user-based licenses
- API keys for service-to-service
- Mutual TLS for high-security scenarios

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 7.6 Time-Based Protections

**Trusted Time Sources:**
- NTP time synchronization
- Time attestation from license server
- TPM clock for local time verification

**Anti-Rollback:**
```cpp
bool VerifyTimeNotRolledBack()
{
    // Get TPM time
    auto tpmTime = tpm.ReadClock();
    
    // Compare with stored last known time
    uint64_t lastTime = LoadLastKnownTime();
    
    if (tpmTime.clockInfo.clock < lastTime)
    {
        LogSecurityEvent("Time rollback detected");
        return false;
    }
    
    StoreLastKnownTime(tpmTime.clockInfo.clock);
    return true;
}
```

**Source:** [FingerPrints.md](input/TLDocs/Client/FingerPrints.md "TLDocs/Client")

---

## 8. Client Authentication and Trust

### 8.1 Identification Requirements

The License Manager (TLLM) and vendor client must mutually authenticate.

**TLLM Needs to:**
- Identify the vendor client application
- Verify client has authorized vendor credentials

**Vendor Client Needs to:**
- Trust the TLLM is legitimate
- Verify TLLM has correct vendor configuration

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 8.2 IAM-Based Authentication (OAuth)

**Use Case:** Enterprise environments with identity providers

**Architecture:**
```
┌─────────────┐         ┌──────────┐         ┌─────────────┐
│   Vendor    │         │   TLLM   │         │     IAM     │
│   Client    │         │          │         │  (Keycloak) │
└──────┬──────┘         └────┬─────┘         └──────┬──────┘
       │                     │                       │
       │  1. Request Token   │                       │
       ├────────────────────────────────────────────►│
       │                     │                       │
       │  2. Return Access Token                     │
       │◄────────────────────────────────────────────┤
       │                     │                       │
       │  3. API Call + Token│                       │
       ├────────────────────►│                       │
       │                     │  4. Validate Token    │
       │                     ├──────────────────────►│
       │                     │                       │
       │                     │  5. Token Valid       │
       │                     │◄──────────────────────┤
       │                     │                       │
       │  6. License Response│                       │
       │◄────────────────────┤                       │
```

**Configuration:**

```json
{
  "iam": {
    "enabled": true,
    "provider": "keycloak",
    "authority": "https://auth.example.com/realms/vendor",
    "clientId": "tl-license-manager",
    "clientSecret": "${SECRET}",
    "scopes": ["openid", "profile", "licenses"]
  }
}
```

**Features:**
- Single Sign-On (SSO)
- Named user licensing
- Claims-based feature access
- Multi-factor authentication
- OS agnostic

**Supported Identity Providers:**
- Keycloak
- Microsoft Azure AD / Entra ID
- Okta
- Auth0
- Any OIDC-compliant provider

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 8.3 Windows Platform Trust

**Mechanism:** Diffie-Hellman / TLS + Vendor Secrets

**Process:**

1. **Vendor Client Setup:**
   - Client knows vendor public key (embedded at build time)
   - Client has password-protected certificate identifying vendor

2. **TLLM Setup:**
   - TLLM configured with vendor's trusted public key
   - TLLM has vendor-provided secret for client verification

3. **Mutual Authentication:**

```cpp
// Client side
class VendorClientAuth
{
public:
    bool AuthenticateToLM(const std::string& lmEndpoint)
    {
        // Establish TLS session (Diffie-Hellman key exchange)
        TLSSession session = EstablishTLS(lmEndpoint);
        
        // Request vendor secret from TLLM
        auto response = session.Request("/auth/vendor-challenge");
        
        // Verify secret using vendor public key
        bool secretValid = VerifyVendorSecret(
            response.secret,
            response.signature,
            vendorPublicKey
        );
        
        if (!secretValid)
            return false;
        
        // Provide client certificate
        session.SendClientCertificate(clientCertificate, password);
        
        return session.IsAuthenticated();
    }
    
private:
    RSAPublicKey vendorPublicKey;
    X509Certificate clientCertificate;
    std::string password;
};
```

**Security Properties:**
- Mutual authentication
- TLS provides channel security
- Vendor secret prevents unauthorized TLLM spoofing
- Client certificate prevents unauthorized client access

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 8.4 Linux and macOS Platform Trust

Similar trust mechanisms as Windows:
- TLS-based session establishment
- Vendor key verification
- Client certificate authentication
- Platform-specific certificate stores

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 8.5 Secret Distribution

**TLLM Secrets:**
- Provider public key (for platform trust)
- Vendor public key (for vendor-specific operations)
- Encrypted configuration from provider or vendor

**Distribution Methods:**
```
Vendor Configuration → [Encrypt with Vendor Public Key]
                    → Deliver to TLLM
                    → [Decrypt with Vendor Private Key in TLLM]

Provider Configuration → [Encrypt with Provider Public Key]
                       → Deliver to TLLM
                       → [Decrypt with Provider Private Key in TLLM]
```

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

---

## 9. Startup Sequence and Initialization

### 9.1 Complete Startup Flow

```
main()
├─ Phase 1: Bootstrap
│  ├─ Parse command-line arguments
│  │  └─ argh::parser cmdl(argc, argv, PREFER_PARAM_FOR_UNREG_OPTION)
│  │     Supports: --help, --version, --config, --rest-port, --grpc-port,
│  │               --log-level, --no-tpm, --tpm-host, --tpm-port
│  ├─ Handle built-in commands (--help, --version)
│  ├─ Initialize logging system
│  ├─ Process --no-tpm flag early
│  │  ├─ IF --no-tpm provided:
│  │  │  ├─ ApplicationState::DisableTPM()
│  │  │  └─ Log: "CLI: --no-tpm flag detected, TPM will be disabled"
│  │  └─ ELSE:
│  │     └─ Log: "CLI: TPM enabled (no --no-tpm flag)"
│  ├─ Log all CLI parameter overrides
│  ├─ Check elevation (Admin/root required)
│  └─ Launch POCO ServerApplication
│
├─ Phase 2: Configuration
│  ├─ Load configuration files
│  │  └─ Windows: C:\ProgramData\TrustedLicensing\Config\
│  │     Linux: /etc/trustedlicensing/
│  ├─ Initialize ApplicationState
│  └─ Detect runtime context (Service/Daemon/Console)
│
├─ Phase 3: TPM Initialization
│  ├─ Connect to TPM device
│  │  ├─ Windows: TBS (TPM Base Services)
│  │  ├─ Linux: /dev/tpm0 or /dev/tpmrm0
│  │  └─ Container: Passthrough device
│  ├─ Read TPM capabilities
│  ├─ Check for existing SRK (handle 2101)
│  └─ Generate SRK if not exists
│
├─ Phase 4: Persistence Layer
│  ├─ Initialize PersistenceService
│  ├─ Check TPM NV storage
│  ├─ Load or create persistent data structures
│  └─ Verify data integrity
│
├─ Phase 5: Cryptographic Setup
│  ├─ Load vendor keys
│  ├─ Initialize signature keys (handle 2102)
│  ├─ Setup HMAC keys (handle 2103)
│  └─ Verify key hierarchy
│
├─ Phase 6: License Loading
│  ├─ Read licenses from TPM NV storage
│  ├─ Decrypt license packages
│  ├─ Validate license signatures
│  ├─ Check expiration dates
│  └─ Build license cache
│
├─ Phase 7: Service Initialization
│  ├─ Initialize LicenseService
│  ├─ Setup REST API server (default port: 52014)
│  ├─ Setup gRPC server (default port: 52013, optional)
│  └─ Register API endpoints
│
└─ Phase 8: Runtime
   ├─ Start listening for client requests
   ├─ Background tasks (usage tracking, heartbeat)
   └─ Wait for termination signal
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 9.2 TPM Connection Sequence

```cpp
// Platform-specific TPM device connection
TPMDevice* ConnectTPMDevice()
{
#ifdef _WIN32
    // Windows: Use TBS (TPM Base Services)
    return new TPMDeviceTBS();
#elif defined(__linux__)
    // Linux: Try kernel resource manager first
    if (FileExists("/dev/tpmrm0"))
        return new TPMDeviceLinux("/dev/tpmrm0");
    else if (FileExists("/dev/tpm0"))
        return new TPMDeviceLinux("/dev/tpm0");
    else
        throw TPMException("No TPM device found");
#else
    throw TPMException("Unsupported platform");
#endif
}

// Initialize TPM service
void InitializeTPM()
{
    try {
        // Connect to device
        tpmDevice = ConnectTPMDevice();
        
        // Create TPM2 instance
        tpm = new Tpm2(*tpmDevice);
        
        // Read capabilities
        auto caps = tpm->GetCapability(
            TPM_CAP::TPM_PROPERTIES,
            TPM_PT::MANUFACTURER,
            1
        );
        
        LogInfo("TPM Manufacturer: " + caps.manufacturer);
        LogInfo("TPM Firmware: " + caps.firmwareVersion);
        
        // Verify TPM 2.0
        if (caps.specVersion < 2.0)
            throw TPMException("TPM 2.0 required");
        
    } catch (const std::exception& e) {
        LogError("TPM initialization failed: " + e.what());
        throw;
    }
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 9.3 SRK Generation and Persistence

```cpp
void EnsureSRKExists()
{
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    
    try {
        // Try to read existing SRK
        auto pubKey = tpm->ReadPublic(srkHandle);
        LogInfo("Existing SRK found");
        return;
    } catch (...) {
        // SRK doesn't exist, create it
        LogInfo("Creating new SRK");
    }
    
    // Create SRK template
    TPMT_PUBLIC srkTemplate(
        TPM_ALG_ID::SHA256,
        TPMA_OBJECT::decrypt | 
        TPMA_OBJECT::restricted |
        TPMA_OBJECT::fixedTPM |
        TPMA_OBJECT::fixedParent |
        TPMA_OBJECT::sensitiveDataOrigin |
        TPMA_OBJECT::userWithAuth,
        ByteVec(),
        TPMS_RSA_PARMS(
            TPMT_SYM_DEF_OBJECT(TPM_ALG_ID::AES, 128, TPM_ALG_ID::CFB),
            TPMS_SCHEME_OAEP(TPM_ALG_ID::SHA256),
            3072,  // RSA 3072 bits
            0
        ),
        TPM2B_PUBLIC_KEY_RSA()
    );
    
    // Create primary key
    auto createResult = tpm->CreatePrimary(
        TPM_HANDLE::RH_OWNER,
        TPMS_SENSITIVE_CREATE(),
        srkTemplate,
        ByteVec(),
        TPMS_PCR_SELECTION::GetEmpty()
    );
    
    // Make persistent
    tpm->EvictControl(
        TPM_HANDLE::RH_OWNER,
        createResult.handle,
        srkHandle
    );
    
    // Export public key for registration
    auto pubKey = tpm->ReadPublic(srkHandle);
    std::string pubKeyPEM = ExportPublicKeyPEM(pubKey);
    
    LogInfo("SRK created, public key:");
    LogInfo(pubKeyPEM);
    
    // Store public key for LMS registration
    SavePublicKeyForRegistration(pubKeyPEM);
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 9.4 Configuration Loading

**Configuration File Structure (JSON):**

```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "LogLevel": "info",
      "VaultPolicy": "FirmwareBoot"
    },
    "application": {
      "runAsService": true,
      "runAsDaemon": true,
      "logPath": "C:\\ProgramData\\TrustedLicensing\\Logs"
    },
    "tpm": {
      "enabled": true,
      "simulator": false,
      "simulatorHost": "192.168.188.55",
      "simulatorPort": 2321
    },
    "REST": {
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52014",
      "enableCORS": false,
      "tlsEnabled": false,
      "certificatePath": ""
    },
    "gRPC": {
      "enabled": false,
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52013"
    },
    "licensing": {
      "offlineMode": false,
      "cacheTimeout": 3600,
      "lmsEndpoint": "https://lms.trustedlicensing.com",
      "vendorId": "your-vendor-guid"
    },
    "security": {
      "requireElevation": true,
      "auditEnabled": true,
      "fingerprintFallback": false
    }
  }
}
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 9.5 Command-Line Options

```bash
TLLicenseManager [OPTIONS]

Options:
  --help, -h              Show help message
  --version, -v           Show version information
  --config <path>         Configuration file path
  --rest-port <port>      REST API port (default: 52014)
  --grpc-port <port>      gRPC port (default: 52013)
  --log-level <level>     Log level: trace, debug, info, warning, error
  --no-tpm                Disable TPM usage (use fingerprint fallback)
  --tpm-host <host>       TPM simulator host (for development)
  --tpm-port <port>       TPM simulator port (default: 2321)
  --console               Run in console mode (not as service)
  --install-service       Install as Windows service
  --uninstall-service     Uninstall Windows service
```

**Example Usage:**

```bash
# Run with debug logging
TLLicenseManager --log-level debug

# Use TPM simulator for development
TLLicenseManager --tpm-host 192.168.1.100 --tpm-port 2321

# Custom REST port and multiple options
TLLicenseManager --rest-port 8080 --grpc-port 9090 --log-level trace

# Disable TPM (use software fingerprint)
TLLicenseManager --no-tpm

# Custom config file
TLLicenseManager --config /path/to/config.json

# Install as Windows service
TLLicenseManager --install-service
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

---

## 10. Platform-Specific Security

### 10.1 Windows Security

**Elevation Requirements:**
- Must run as Administrator for TPM access
- Service runs as LocalSystem by default
- Consider dedicated service account if TPM not required

**TPM Access:**
- Uses TBS (TPM Base Services) API
- Requires TCG TSS.NET or native TBS calls
- TPM ownership typically managed by Windows

**File Locations:**
```
C:\Program Files\TrustedLicensing\
├── TLLicenseManager.exe
├── TLCrypt.dll
├── TLTpm.dll
└── config\

C:\ProgramData\TrustedLicensing\
├── Config\
│   └── TLLicenseManager.json
├── Persistence\
│   ├── licenses\
│   └── cache\
└── Logs\
    └── TLLicenseManager.log
```

**Windows Service Installation:**

```powershell
# Install service
New-Service -Name "TLLicenseManager" `
    -BinaryPathName "C:\Program Files\TrustedLicensing\TLLicenseManager.exe" `
    -DisplayName "Trusted Licensing Manager" `
    -Description "Hardware-backed license management service" `
    -StartupType Automatic

# Configure service to run as LocalSystem
sc.exe config TLLicenseManager obj= "LocalSystem"

# Start service
Start-Service TLLicenseManager
```

**Security Best Practices:**
- Run with least privileges (LocalSystem for TPM access)
- Configure firewall rules for trusted networks only
- Keep TPM firmware updated
- Monitor Event Viewer for security events
- Regular backups of C:\ProgramData\TrustedLicensing\Persistence

**Source:** [README.md](input/scripts/Windows/README.md "scripts/Windows")

### 10.2 Linux Security

**Elevation Requirements:**
- Must run as root or with sudo for /dev/tpm0 access
- systemd service runs as root
- Consider TPM Resource Manager (/dev/tpmrm0) for multi-process access

**TPM Access:**
```bash
# Check TPM availability
ls -la /dev/tpm*

# Typical output:
# crw-rw---- 1 tss tss  10, 224 Jan 28 15:30 /dev/tpm0
# crw-rw-rw- 1 tss tss 253,   0 Jan 28 15:30 /dev/tpmrm0

# Grant access to tss group
sudo usermod -a -G tss trustedlicensing
```

**File Locations:**
```
/opt/trustedlicensing/
├── bin/
│   └── TLLicenseManager
├── lib/
│   ├── libTLCrypt.so
│   └── libTLTpm.so
└── config/

/etc/trustedlicensing/
└── TLLicenseManager.json

/var/lib/trustedlicensing/
├── licenses/
├── cache/
└── persistence/

/var/log/trustedlicensing/
└── TLLicenseManager.log
```

**systemd Service:**

```ini
[Unit]
Description=Trusted Licensing Manager
After=network.target

[Service]
Type=simple
ExecStart=/opt/trustedlicensing/bin/TLLicenseManager
Restart=on-failure
RestartSec=10
User=root
Group=root
StandardOutput=journal
StandardError=journal

# Security hardening
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/trustedlicensing /var/log/trustedlicensing
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

**Installation:**

```bash
# Copy service file
sudo cp trustedlicensing.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable trustedlicensing
sudo systemctl start trustedlicensing

# Check status
sudo systemctl status trustedlicensing
```

**Security Best Practices:**
- Use TPM Resource Manager (/dev/tpmrm0) for better multi-process support
- Configure SELinux/AppArmor policies
- Keep TPM firmware and kernel updated
- Monitor journalctl for security events
- Regular backups of /var/lib/trustedlicensing

**Source:** [README.md](input/scripts/Linux/README.md "scripts/Linux")

### 10.3 Container Deployment (Docker/Kubernetes)

**TPM Passthrough in Docker:**

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    libtss2-dev \
    tpm2-tools \
    && rm -rf /var/lib/apt/lists/*

# Copy application
COPY bin/TLLicenseManager /opt/trustedlicensing/
COPY lib/*.so /opt/trustedlicensing/lib/

# Expose REST API port
EXPOSE 52014

# Run as root (required for TPM access)
USER root

ENTRYPOINT ["/opt/trustedlicensing/TLLicenseManager"]
```

**Run with TPM Access:**

```bash
docker run -d \
  --name tl-service \
  --device=/dev/tpm0 \
  --device=/dev/tpmrm0 \
  --group-add $(getent group tss | cut -d: -f3) \
  -p 52014:52014 \
  -v /var/lib/trustedlicensing:/var/lib/trustedlicensing \
  trustedlicensing:latest
```

**Kubernetes Deployment:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
spec:
  containers:
  - name: tl-service
    image: trustedlicensing:latest
    ports:
    - containerPort: 52014
    securityContext:
      privileged: true  # Required for TPM access
    volumeMounts:
    - name: tpm
      mountPath: /dev/tpm0
    - name: tpmrm
      mountPath: /dev/tpmrm0
    - name: persistence
      mountPath: /var/lib/trustedlicensing
  volumes:
  - name: tpm
    hostPath:
      path: /dev/tpm0
  - name: tpmrm
    hostPath:
      path: /dev/tpmrm0
  - name: persistence
    persistentVolumeClaim:
      claimName: tl-persistence
```

**Security Considerations:**
- Container needs privileged access for TPM device
- Use device plugins for better TPM resource management
- Consider node affinity to bind pods to specific hardware
- Volume persistence required for license data
- Network policies for API access control

**Source:** [TPM_Docker_Kubernetes_Access.md](input/_docs/TPM_Docker_Kubernetes_Access.md "_docs"), [README.md](input/_Container/Docker/Linux/README.md "_Container/Docker/Linux")

---

## 11. API Security

### 11.1 REST API Authentication

**Endpoint Security:**

```
GET /api/v1/licenses
Authorization: Bearer <jwt-token>
X-Fingerprint: <hardware-fingerprint>
X-Vendor-Signature: <vendor-signature>
```

**Authentication Methods:**

1. **Bearer Token (OAuth 2.0):**
   ```http
   GET /api/v1/licenses HTTP/1.1
   Host: localhost:52014
   Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

2. **API Key:**
   ```http
   GET /api/v1/licenses HTTP/1.1
   Host: localhost:52014
   X-API-Key: your-api-key-here
   ```

3. **Client Certificate (Mutual TLS):**
   - Client presents X.509 certificate
   - Server validates against trusted CA
   - Certificate CN matches vendor ID

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 11.2 Request Signing

**Prevent Replay Attacks:**

```cpp
struct SignedRequest
{
    std::string method;        // GET, POST, etc.
    std::string path;          // /api/v1/licenses
    std::string body;          // Request body (if POST)
    std::string timestamp;     // ISO 8601
    std::string nonce;         // Random unique value
    std::string signature;     // HMAC or RSA signature
};

std::string SignRequest(const SignedRequest& req, 
                        const std::string& secretKey)
{
    // Construct canonical string
    std::string canonical = 
        req.method + "\n" +
        req.path + "\n" +
        req.timestamp + "\n" +
        req.nonce + "\n" +
        SHA256::HashString(req.body);
    
    // Sign with HMAC-SHA256
    return HMAC_SHA256(secretKey, canonical);
}

bool VerifyRequest(const SignedRequest& req,
                   const std::string& secretKey)
{
    // Check timestamp (prevent replay)
    auto reqTime = ParseISO8601(req.timestamp);
    auto now = std::chrono::system_clock::now();
    auto age = now - reqTime;
    
    if (age > std::chrono::minutes(5))
        return false;  // Request too old
    
    // Verify signature
    std::string expected = SignRequest(req, secretKey);
    return ConstantTimeCompare(expected, req.signature);
}
```

### 11.3 TLS Configuration

**Minimum TLS Version:** 1.2  
**Preferred:** TLS 1.3

**Recommended Cipher Suites:**
```
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
```

**Configuration (POCO Framework):**

```cpp
Poco::Net::Context::Ptr context = new Poco::Net::Context(
    Poco::Net::Context::TLS_SERVER_USE,
    keyFile,
    certificateFile,
    caFile,
    Poco::Net::Context::VERIFY_STRICT,
    9,  // Verification depth
    true,  // Load default CAs
    "ALL:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
);

context->requireMinimumProtocol(Poco::Net::Context::PROTO_TLSV1_2);
```

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 11.4 Rate Limiting

**Prevent Abuse:**

```cpp
class RateLimiter
{
public:
    bool AllowRequest(const std::string& clientId)
    {
        auto now = std::chrono::steady_clock::now();
        auto& bucket = buckets_[clientId];
        
        // Remove old timestamps
        bucket.erase(
            std::remove_if(bucket.begin(), bucket.end(),
                [now](const auto& t) {
                    return now - t > std::chrono::minutes(1);
                }),
            bucket.end()
        );
        
        // Check rate limit (e.g., 60 requests per minute)
        if (bucket.size() >= 60)
            return false;
        
        bucket.push_back(now);
        return true;
    }
    
private:
    std::map<std::string, std::vector<std::chrono::steady_clock::time_point>> buckets_;
};
```

---

## 12. Configuration Security

### 12.1 Secure Configuration Storage

**Sensitive Settings Encryption:**

```cpp
class SecureConfig
{
public:
    void SaveEncryptedConfig(const Config& config)
    {
        // Serialize configuration
        std::string json = config.ToJSON();
        
        // Encrypt with key derived from SRK
        ByteVec key = DeriveKeyFromSRK("config-encryption");
        ByteVec encrypted = AES_GCM_Encrypt(key, json);
        
        // Save to file
        WriteFile(configPath_, encrypted);
    }
    
    Config LoadEncryptedConfig()
    {
        // Read encrypted data
        ByteVec encrypted = ReadFile(configPath_);
        
        // Decrypt
        ByteVec key = DeriveKeyFromSRK("config-encryption");
        std::string json = AES_GCM_Decrypt(key, encrypted);
        
        // Parse and return
        return Config::FromJSON(json);
    }
    
private:
    ByteVec DeriveKeyFromSRK(const std::string& context)
    {
        TPMService tpm;
        
        // Use HMAC with SRK and context
        return tpm.HMAC(
            TPM_HANDLE::Persistent(2101),
            String2ByteVec(context)
        );
    }
};
```

### 12.2 Secrets Management

**Integration with Secret Stores:**

```cpp
// HashiCorp Vault integration
class VaultSecretProvider
{
public:
    std::string GetSecret(const std::string& path)
    {
        // Authenticate to Vault using AppRole
        std::string token = AuthenticateAppRole(roleId_, secretId_);
        
        // Retrieve secret
        auto response = vaultClient_.Get(
            "/v1/secret/data/" + path,
            {{"X-Vault-Token", token}}
        );
        
        return response["data"]["data"]["value"];
    }
    
private:
    std::string roleId_;
    std::string secretId_;
    VaultClient vaultClient_;
};
```

**Environment Variable Substitution:**

```json
{
  "licensing": {
    "lmsEndpoint": "${LMS_ENDPOINT}",
    "vendorId": "${VENDOR_ID}",
    "apiKey": "${API_KEY}"
  }
}
```

**Source:** [Vaults_Architecture.md](input/_vault/Vaults_Architecture.md "_vault")

### 12.3 Configuration Validation

```cpp
class ConfigValidator
{
public:
    void Validate(const Config& config)
    {
        // Validate REST port
        if (config.rest.port < 1024 || config.rest.port > 65535)
            throw ConfigException("Invalid REST port");
        
        // Validate bind address
        if (!IsValidIPAddress(config.rest.bindAddress))
            throw ConfigException("Invalid bind address");
        
        // Validate TLS settings
        if (config.rest.tlsEnabled)
        {
            if (config.rest.certificatePath.empty())
                throw ConfigException("TLS enabled but no certificate");
            
            if (!FileExists(config.rest.certificatePath))
                throw ConfigException("Certificate file not found");
        }
        
        // Validate LMS endpoint
        if (!IsValidURL(config.licensing.lmsEndpoint))
            throw ConfigException("Invalid LMS endpoint");
        
        // Validate vendor ID format (GUID)
        if (!IsValidGUID(config.licensing.vendorId))
            throw ConfigException("Invalid vendor ID format");
    }
};
```

---

## 13. Deployment and Operational Security

### 13.1 Security Checklist

**Pre-Deployment:**
- [ ] TPM firmware updated to latest version
- [ ] Operating system fully patched
- [ ] Firewall rules configured (restrict to trusted networks)
- [ ] TLS certificates obtained and validated
- [ ] Service account configured (if not using LocalSystem/root)
- [ ] Backup strategy established
- [ ] Monitoring and alerting configured

**Post-Deployment:**
- [ ] Verify TPM is detected and functional
- [ ] Test license activation and validation
- [ ] Verify API authentication
- [ ] Check audit logs are being generated
- [ ] Test backup and restore procedures
- [ ] Verify failover/redundancy (if applicable)

**Source:** [README.md](input/scripts/Windows/README.md "scripts/Windows")

### 13.2 Monitoring and Logging

**Security Events to Monitor:**
- Failed authentication attempts
- TPM errors or failures
- License tampering attempts
- VM rollback detection
- Unusual API usage patterns
- Configuration changes
- Service crashes or restarts

**Log Format:**

```json
{
  "timestamp": "2026-01-28T15:30:00.123Z",
  "level": "warning",
  "event": "authentication_failed",
  "source": "REST_API",
  "details": {
    "clientIP": "192.168.1.100",
    "endpoint": "/api/v1/licenses",
    "reason": "invalid_token"
  },
  "fingerprint": "abc123...",
  "signature": "def456..."
}
```

**Integration with SIEM:**
- Syslog output
- Windows Event Log
- JSON structured logging
- Metrics export (Prometheus)

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

### 13.3 Backup and Recovery

**What to Backup:**
- Configuration files
- License data (if not using TPM NV storage exclusively)
- Audit logs
- Vendor keys (encrypted)

**Backup Strategy:**

```bash
# Windows
$backupPath = "\\backup-server\TrustedLicensing\$(Get-Date -Format 'yyyyMMdd')"
robocopy C:\ProgramData\TrustedLicensing\Persistence $backupPath /MIR /Z

# Linux
BACKUP_PATH="/backup/trustedlicensing/$(date +%Y%m%d)"
rsync -avz /var/lib/trustedlicensing/ $BACKUP_PATH/
```

**Recovery:**
- TPM-based licenses: Automatic (stored in TPM NV)
- File-based licenses: Restore from backup
- SRK regeneration: May require re-activation if TPM is cleared

**Source:** [README.md](input/scripts/Windows/README.md "scripts/Windows")

### 13.4 Incident Response

**Security Incident Types:**

1. **TPM Compromise:**
   - Action: Revoke all licenses for affected hardware
   - Generate new SRK
   - Re-activate with new fingerprint

2. **Vendor Key Leak:**
   - Action: Rotate vendor keys
   - Issue new licenses with new keys
   - Revoke old licenses

3. **License Tampering:**
   - Action: Log event, block access
   - Investigate source
   - Re-validate all licenses

4. **API Abuse:**
   - Action: Rate limit or block client
   - Investigate pattern
   - Update firewall rules

**Source:** [TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md "_docs")

---

## 14. Compliance and Best Practices

### 14.1 Security Standards

**Alignment with Standards:**
- **NIST SP 800-147:** BIOS Protection Guidelines (TPM)
- **TCG TPM 2.0 Library Specification:** TPM operations
- **FIPS 140-2:** Cryptographic module validation (TPM hardware)
- **Common Criteria:** EAL 4+ for TPM chips
- **ISO/IEC 27001:** Information security management

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 14.2 Key Management Best Practices

**Key Lifecycle:**
1. **Generation:** Use TPM hardware RNG
2. **Storage:** Keep private keys in TPM
3. **Usage:** Minimize key operations
4. **Rotation:** Regular vendor key rotation
5. **Revocation:** Support for key compromise scenarios
6. **Destruction:** Secure key deletion when decommissioned

**Key Escrow:**
- NOT recommended for SRK (defeats hardware binding)
- Consider for vendor keys (organizational recovery)
- Use multi-party authorization for escrow access

**Source:** [KeyRequired.md](input/TLDocs/Client/KeyRequired.md "TLDocs/Client")

### 14.3 Privacy Considerations

**Data Minimization:**
- Only collect necessary hardware information
- Avoid collecting personally identifiable information (PII)
- Use hashed fingerprints (not raw hardware IDs)

**Data Protection:**
- Encrypt all license data at rest and in transit
- Use TPM-backed encryption keys
- Implement data retention policies

**GDPR Compliance:**
- Hardware fingerprints may be considered personal data
- Provide data access and deletion mechanisms
- Document data processing activities

**Source:** [Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md "TLDocs/Client")

### 14.4 Audit and Compliance Reporting

**Audit Trail Requirements:**
- Tamper-evident logging
- Cryptographic signatures on log entries
- Long-term log retention
- Compliance report generation

```cpp
class ComplianceReporter
{
public:
    Report GenerateComplianceReport(const TimeRange& period)
    {
        Report report;
        
        // License activations
        report.activations = CountActivations(period);
        
        // Security events
        report.securityEvents = GetSecurityEvents(period);
        
        // TPM health
        report.tpmHealth = GetTPMHealthMetrics();
        
        // Key rotations
        report.keyRotations = GetKeyRotationHistory(period);
        
        // Failed access attempts
        report.failedAccess = CountFailedAccess(period);
        
        return report;
    }
};
```

---

## 15. Document Sources

### Core Client Documentation
- [input/TLDocs/Client/Client Architecture.md](input/TLDocs/Client/Client%20Architecture.md) - Client topology and architecture
- [input/TLDocs/Client/KeyRequired.md](input/TLDocs/Client/KeyRequired.md) - Cryptographic key infrastructure
- [input/TLDocs/Client/FingerPrints.md](input/TLDocs/Client/FingerPrints.md) - Fingerprinting and VM detection
- [input/TLDocs/Client/TPM_Requirements.md](input/TLDocs/Client/TPM_Requirements.md) - TPM requirements and derived keys
- [input/TLDocs/Client/DaemonService.md](input/TLDocs/Client/DaemonService.md) - Service/daemon operations
- [input/TLDocs/Client/gRPC.md](input/TLDocs/Client/gRPC.md) - gRPC protocol information

### Cryptography and Security
- [input/TLDocs/Crypto.md](input/TLDocs/Crypto.md) - Cryptographic operations and interoperability
- [input/_docs/TLLicenseManager_StartUp.md](input/_docs/TLLicenseManager_StartUp.md) - Startup sequence and TPM usage

### Deployment and Operations
- [input/scripts/Windows/README.md](input/scripts/Windows/README.md) - Windows deployment scripts
- [input/scripts/Linux/README.md](input/scripts/Linux/README.md) - Linux deployment scripts
- [input/_docs/TPM_Docker_Kubernetes_Access.md](input/_docs/TPM_Docker_Kubernetes_Access.md) - Container deployment
- [input/_Container/Docker/Linux/README.md](input/_Container/Docker/Linux/README.md) - Docker configuration

### Infrastructure and Configuration
- [input/_vault/Vaults_Architecture.md](input/_vault/Vaults_Architecture.md) - HashiCorp Vault integration
- [input/_vault/autounsealDEV/autounseal4dev.md](input/_vault/autounsealDEV/autounseal4dev.md) - Vault auto-unseal

### License Management
- [input/TLDocs/LMS/Activation/Activation.md](input/TLDocs/LMS/Activation/Activation.md) - License activation process
- [input/TLDocs/ServicesDescription.md](input/TLDocs/ServicesDescription.md) - Service architecture

---

**End of Document**

*This document was generated from consolidated source documentation. For updates, follow the regeneration prompt at the beginning of this document.*
