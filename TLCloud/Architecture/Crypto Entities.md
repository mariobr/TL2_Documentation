# Cryptographic Entities and Key Management

**Document Purpose:** This document describes cryptographic key usage and storage for entities involved in secure data exchange workflows within the TrustedLicensing 365 platform, with particular emphasis on secure asset generation (e.g., license generation).

---

## Table of Contents

1. [License Management System (Backend)](#license-management-system-backend)
   - [Provider](#provider)
   - [Vendor](#vendor)
2. [Licensing Client (Enforcement)](#licensing-client-enforcement)
   - [Vendor Client](#vendor-client)

---

## License Management System (Backend)

### Provider

The **Provider** is the platform operator that hosts the system infrastructure and provides services for vendors and their customers. The Provider serves as the infrastructure layer enabling multi-tenant vendor operations.

#### Cryptographic Keys

**Provider Key**

- **Algorithm:** RSA asymmetric key pair (public/private)
- **Purpose:** Sign payloads during data exchange between vendor and vendor client
- **Usage:** Platform-level authentication and data integrity verification
- **Storage Location:** VendorBoard (secure key vault)

**Security Characteristics:**
- Private key never leaves Provider infrastructure
- Public key distributed to vendors for signature verification
- Used for platform-level trust establishment

---

### Vendor

The **Vendor** defines licensing schemes for their customers by leveraging the License Management System (LMS). Each vendor operates as an independent tenant and can serve multiple vendor clients, differentiated by vendor codes.

**Multi-Tenancy Characteristics:**
- Vendors are independent tenants from the Provider's perspective
- Public exposure limited to LMS web URL
- No requirement to reveal vendor identity (contractual relationship with Provider)
- Vendor can create products and services using multiple vendor codes
- Licenses generated with different vendor codes are isolated but can coexist in the same infrastructure

#### Cryptographic Keys

**Vendor Codes** *(also known as Vendor Secrets)*

- **Algorithm:** 
  - RSA asymmetric key pair (public/private)
  - AES symmetric key
- **Purpose:** Vendor-specific generation of licenses and client assets (e.g., license managers)
- **Storage Location:** VendorBoard (secure key vault)

**Vendor Code Management:**
- Vendors can provision multiple vendor codes as required
- Use case: Separate business units or product lines within vendor organization
- Default vendor code: `VENDOR_ROOT` (recommended for testing and development)
- Vendor code information is transmitted to client during license activation

**Security Considerations:**
- Each vendor code creates an isolated trust boundary
- Compromised vendor code affects only licenses generated with that specific code
- Enables granular security and organizational separation

---

## Licensing Client (Enforcement)

### Vendor Client

The **Vendor Client** consists of applications that consume licenses using SDKs provided by the vendor. These clients leverage vendor codes and cryptographic keys generated on the client platform to enforce licensing policies.

#### Cryptographic Keys

**Storage Root Key (SRK)** *(also known as TPM Key)*

- **Algorithm:** RSA asymmetric key pair
- **Public Key Availability:** Public key exported and registered with LMS
- **Private Key Storage:** Secured within client's Trusted Platform Module (TPM)
- **Storage Location:** TPM hardware (Hardware Security Module)
- **Purpose:** 
  - Secure asset transfer to client platforms
  - Multi-layer cryptographic operations
  - Hardware-based license binding

**Security Characteristics:**
- **Private key never exposed:** Stored permanently within TPM hardware
- **Hardware-backed security:** Protected by TPM security guarantees
- **Tamper-resistant:** TPM provides cryptographic attestation
- **Device binding:** Licenses cryptographically bound to specific hardware

---

**Client Public Key** *(also known as Local Public Key)*

- **Algorithm:** RSA asymmetric key pair (public/private)
- **Purpose:** Fallback mechanism for platforms without TPM support
- **Storage Location:** Local persistence vault (software-based)

**Fallback Mechanism:**
- Used on platforms lacking TPM 2.0 hardware support
- Provides functional licensing with reduced security compared to TPM
- Requires dedicated license enablement from vendor
- Suitable for development, testing, and non-critical deployments

**Security Trade-offs:**
- Less secure than TPM-based approach
- Private key stored in software (vulnerable to extraction)
- No hardware attestation capabilities
- Should be used only when TPM is unavailable

---

## Key Hierarchy Summary

```
Platform Level:
└── Provider Key (RSA) → Platform authentication and trust

Vendor Level:
└── Vendor Code Keys (RSA + AES) → License generation and vendor isolation

Client Level:
├── Storage Root Key (SRK) → Hardware-backed security (TPM)
└── Client Public Key → Software fallback (no TPM)
```

---

## Security Best Practices

1. **Provider Keys:** Never distribute private keys; maintain strict access control to VendorBoard
2. **Vendor Codes:** Use separate vendor codes for production and testing environments
3. **TPM Keys:** Prefer TPM-based licensing for production deployments
4. **Fallback Keys:** Use software-based keys only when TPM is unavailable; clearly document security implications

---

**Document Version:** 1.0  
**Last Updated:** January 31, 2026