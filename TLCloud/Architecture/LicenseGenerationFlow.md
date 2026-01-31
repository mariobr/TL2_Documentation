# License Generation Flow Diagram

**Version:** 1.0  
**Created:** 31 January 2026  
**Last Updated:** 31 January 2026  

**Document Purpose:** Visual representation of the end-to-end license generation workflow, from job creation through client activation.

---

## Overview

This diagram illustrates the secure data exchange between the Licensing Service and License Generator, including vendor authentication, payload encryption, package creation, and client-side activation.

---

## License Generation Sequence

```mermaid
sequenceDiagram
    participant LS as Licensing Service
    participant LG as License Generator
    participant Vendor as Vendor System
    participant Client as License Manager (Client)
    
    Note over LS: 1. Create Job
    LS->>LS: Prepare Meta Information<br/>- Vendor Code Public Key<br/>- Payload Signature<br/>- Transport Key (AES encrypted)
    LS->>LS: Prepare Client Activation Data<br/>- Client Key<br/>- Binding Criteria
    LS->>LS: Encrypt Payload with TransportKey<br/>- License templates<br/>- Feature definitions<br/>- Entitlements
    
    LS->>LG: Submit Job
    
    Note over LG: 2. Validate & Process
    LG->>LG: Validate Vendor Signature
    alt Signature Invalid
        LG-->>LS: Reject Job (Audit Log)
    end
    
    LG->>LG: Check Vendor Code Status
    alt Vendor Inactive
        LG-->>LS: Reject Job (Audit Log)
    end
    
    LG->>LG: Decrypt Payload<br/>(using Transport Key)
    LG->>LG: Generate License(s)<br/>- Apply entitlements<br/>- Create license containers<br/>- Prepare activation package
    
    Note over LG: 3. Create Activation Package
    LG->>LG: Build License Container<br/>- Container Guid<br/>- Vendor (Code, Info, Public Key)<br/>- Product (Features, Models, Tokens)
    
    LG->>LG: Build Package<br/>- Package Guid<br/>- Destination Info<br/>- List of Containers
    
    LG->>Vendor: Sign Container with Vendor Key
    Vendor-->>LG: Signed Container
    
    LG->>LG: Sign Package with LMS Key
    LG->>LG: Encrypt Package with<br/>Fingerprint Public Key
    
    Note over LG: 4. Delivery
    LG->>Client: HTTPS Delivery<br/>(Encrypted Package)
    
    Note over Client: 5. Client Activation
    Client->>Client: Validate LMS Signature
    Client->>Client: Decrypt with Private Key<br/>(bound to fingerprint)
    Client->>Client: Validate Container Signature
    Client->>Client: Install License<br/>- Activate features<br/>- Enforce binding criteria
    
    Client-->>LG: Activation Confirmation
```

---

## Process Steps

### 1. Job Creation (Licensing Service)
- Prepares meta information with vendor credentials
- Encrypts payload with ephemeral transport key
- Includes client activation data and binding criteria

### 2. Validation & Processing (License Generator)
- Validates vendor signature and status
- Decrypts payload using transport key
- Generates licenses based on entitlements

### 3. Package Creation
- Builds license containers with vendor and product information
- Signs containers with vendor key
- Signs and encrypts package with client fingerprint

### 4. Secure Delivery
- Transmits encrypted package via HTTPS
- End-to-end encryption ensures confidentiality

### 5. Client Activation
- Validates signatures from LMS and vendor
- Decrypts package with hardware-bound private key
- Installs and enforces license binding

---

## Security Features

- **Vendor Authentication:** Signature validation at every step
- **Payload Encryption:** Transport keys for secure data exchange
- **Hardware Binding:** Fingerprint-based encryption
- **Multi-Signature:** Both vendor and LMS sign critical components
- **Audit Logging:** Failed validations logged for security monitoring

---

## Related Documents

- [LicenseGeneration.md](LicenseGeneration.md) - Detailed workflow documentation
- [Activation.md](../LMS/Activation/Activation.md) - Activation structure and security
- [Crypto Entities.md](Crypto%20Entities.md) - Cryptographic key infrastructure

---

<!--
GENERATION PROMPT:

Create a visual flow diagram for the license generation process including:
- Sequence diagram showing all participants (Licensing Service, License Generator, Vendor, Client)
- Step-by-step workflow from job creation to client activation
- Decision points for validation failures
- Cryptographic operations at each stage
- Security considerations and features

Use Mermaid sequenceDiagram format for clarity and maintainability.

Update timestamp to current date/time: 
[System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Get-Date -Format 'dd MMMM yyyy HH:mm'
-->
