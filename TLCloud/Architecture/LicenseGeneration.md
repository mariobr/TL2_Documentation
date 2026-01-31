# License Generation Flow

**Version:** 1.0  
**Created:** 31 January 2026  
**Last Updated:** 31 January 2026  

**Document Purpose:** This document describes the end-to-end license generation workflow, from job creation through activation and delivery to the client.

---

## Overview

The license generation process involves secure data exchange between the Licensing Service and License Generator, ensuring vendor authentication, payload encryption, and client-specific binding.

---

## 1. Licensing Service Creates Job

### 1.1 Job Content Structure

#### Meta Information
- **Vendor Code Public Key** - Vendor identity verification
- **Payload Signature** - Ensures data integrity
- **Transport Key** - Session-specific encryption key (encrypted with vendor code AES key)
- **Client Activation Data:**
  - Key - Client identification key
  - Binding Criteria - Hardware/software binding parameters

#### Payload for License Generation
- **Encryption:** All payload data encrypted with TransportKey
- **Content:** License templates, feature definitions, entitlements

---

## 2. License Generator Processes Job

### 2.1 Validation Steps
1. **Vendor Signature Validation** - Verify authenticity of request
2. **Vendor Code Status Check** - Confirm vendor is active and authorized
3. **Payload Decryption** - Decrypt using transport key
4. **License Creation** - Generate license(s) based on validated payload

### 2.2 Security Considerations
- All cryptographic operations use hardware-backed keys where available
- Failed validations result in job rejection with audit logging
- Transport keys are ephemeral and discarded after use

---

## 3. Activation Metadata

See [Activation.md](../LMS/Activation/Activation.md) for detailed activation structure.

### 3.1 Input Structure

**Destination Fingerprint:**
- Target hardware identification
- Platform-specific binding information

**License Container:**
- **Container Guid** - Unique container identifier
  - Name
  - Routing Information
- **Vendor** - Vendor identification
  - Code
  - Info
  - Public Key
- **Product** - Licensed product details
  - Features
  - LicenseModels
  - Tokens

### 3.2 Package Content

**Package Structure:**
- **Package Guid** - Unique package identifier
- **Destination Information:**
  - Target Host
  - List of Containers

### 3.3 Security Structure

**Container Security:**
- Format: JSON structure
- Authentication: Signed by Vendor
- Integrity: Cryptographic signature verification

**Package Security:**
- Format: JSON structure
- Authentication: Signed by LMS
- Confidentiality: Encrypted with Fingerprint Public Key
- End-to-End: Only target client can decrypt

---

## 4. Delivery and Activation

### 4.1 Secure Transmission
- Packages delivered via HTTPS
- Client validates LMS signature
- Client decrypts using private key bound to fingerprint

### 4.2 License Installation
- License Manager validates container signatures
- Features activated based on entitlements
- Binding enforced per activation criteria

---

## Related Documents

- [LicenseGenerationFlow.md](LicenseGenerationFlow.md) - Visual flow diagram of the license generation process
- [Activation.md](../LMS/Activation/Activation.md) - Activation input structure and security
- [Crypto Entities.md](Crypto%20Entities.md) - Cryptographic key infrastructure

---

<!--
GENERATION PROMPT:

Document the end-to-end license generation workflow including:
- Licensing Service job creation process
- License Generator validation and processing steps
- Activation metadata structure (reference Activation.md)
- Security mechanisms (encryption, signing, validation)
- Delivery and activation workflow
- Client-side license installation and binding

Structure:
- Clear numbered sections with descriptive headings
- Security considerations for each step
- Integration with activation and cryptographic entities
- Related document references

IMPORTANT: When updating this document, also update LicenseGenerationFlow.md to reflect any changes to the workflow or process steps.

Update timestamp to current date/time: 
[System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Get-Date -Format 'dd MMMM yyyy HH:mm'
-->



