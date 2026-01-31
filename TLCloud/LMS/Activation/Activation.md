# License Activation Process

**Version:** 1.0  
**Created:** 31 January 2026  
**Last Updated:** 31 January 2026  

**Document Purpose:** This document describes the license activation input structure, package content, and security mechanisms for deploying licenses to client platforms.

---

## Overview

License activation is the process of securely delivering licenses from the License Management System to client platforms. The activation mechanism ensures vendor authentication, hardware binding, and secure transmission through cryptographic signatures and encryption.

---

## 1. Activation Input Structure

### 1.1 Destination Fingerprint

**Hardware Identification:**
- Unique identifier for target client platform
- Used for hardware-bound license enforcement
- Can be TPM-based (SRK public key) or software-based fingerprint

**Security Purpose:**
- Ensures licenses are bound to specific hardware
- Prevents unauthorized license transfer
- Enables license revocation and management

---

### 1.2 License Container

The License Container encapsulates vendor and product information required for license deployment.

#### Container Components:

**1. Container Guid**
- **Name:** Human-readable container identifier
- **Routing Information:** Network routing and delivery metadata
- **Purpose:** Unique identification and delivery tracking

**2. Vendor Information**
- **Code:** Vendor code identifier (e.g., VENDOR_ROOT)
- **Info:** Vendor metadata and display information
- **Public Key:** Vendor public key for signature verification

**3. Product Information**
- **Features:** List of licensed features and capabilities
- **License Models:** Applicable licensing models (perpetual, subscription, consumption, etc.)
- **Tokens:** Entitlement tokens and feature flags

---

## 2. Package Content Structure

### 2.1 Package Components

**Package Guid:**
- Unique identifier for the activation package
- Used for tracking and audit purposes

**Destination Information:**
- **Target Host:** Hardware fingerprint of destination client
- **List of Containers:** One or more license containers included in package

### 2.2 Package Delivery

- Packages delivered via HTTPS
- Multiple containers can be bundled in single package
- Supports batch activation for multiple products/vendors

---

## 3. Security Architecture

### 3.1 Container Security

**Format:** JSON structure

**Authentication:**
- Digitally signed by Vendor
- Signature verification ensures container integrity
- Prevents tampering with vendor/product information

**Verification Process:**
1. Extract vendor public key from container
2. Verify signature using vendor public key
3. Reject container if signature validation fails

---

### 3.2 Package Security

**Format:** JSON structure

**Authentication:**
- Digitally signed by License Management System (LMS)
- LMS signature ensures package authenticity
- Validates that package originated from trusted LMS

**Confidentiality:**
- Encrypted with Fingerprint Public Key
- Only target client with matching private key can decrypt
- Hardware-bound decryption prevents unauthorized access

**Security Layers:**
1. **LMS Signature** - Authenticates package origin
2. **Fingerprint Encryption** - Ensures destination-specific delivery
3. **Vendor Signature** - Validates container contents
4. **Hardware Binding** - Prevents license portability

---

## 4. Activation Workflow

### 4.1 Server-Side (LMS)

1. Generate license containers with vendor information
2. Sign each container with vendor private key
3. Bundle containers into activation package
4. Sign package with LMS private key
5. Encrypt package with client fingerprint public key
6. Deliver package via HTTPS

### 4.2 Client-Side (TLLicenseManager)

1. Receive encrypted package via HTTPS
2. Verify LMS signature
3. Decrypt package using private key (bound to fingerprint)
4. Extract license containers
5. Verify vendor signature for each container
6. Install licenses and activate features

---

## 5. Security Considerations

### 5.1 Threat Mitigation

- **Man-in-the-Middle:** HTTPS encryption during transmission
- **Tampering:** Multi-level signature verification
- **Unauthorized Access:** Hardware-bound encryption
- **License Portability:** Fingerprint binding prevents transfer
- **Replay Attacks:** Package Guid tracking and audit logging

### 5.2 Best Practices

- Always verify both LMS and vendor signatures
- Use TPM-based fingerprints when available
- Maintain audit logs of all activation attempts
- Implement rate limiting for activation requests
- Use hardware-backed key storage where possible

---

## Related Documents

- [LicenseGeneration.md](../../Architecture/LicenseGeneration.md) - License generation workflow
- [LicenseGenerationFlow.md](../../Architecture/LicenseGenerationFlow.md) - Visual flow diagram
- [Crypto Entities.md](../../Architecture/Crypto%20Entities.md) - Cryptographic key infrastructure

---

<!--
GENERATION PROMPT:

Document the license activation process including:
- Activation input structure (destination fingerprint, license container)
- Package content and structure
- Security mechanisms (signing, encryption, verification)
- Activation workflow (server-side and client-side)
- Security considerations and threat mitigation

Structure:
- Clear numbered sections with descriptive headings
- Detailed component descriptions
- Security architecture with multi-layer protection
- Integration with license generation workflow

Update timestamp to current date/time: 
[System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Get-Date -Format 'dd MMMM yyyy HH:mm'
-->
