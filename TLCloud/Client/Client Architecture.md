# Trusted Licensing Client Architecture

**Version:** 1.0  
**Created:** 31 January 2026  
**Updated:** 31 January 2026

This document describes the architecture and design principles of the TrustedLicensing client components, including hardware-based security mechanisms, client topologies, storage strategies, identification approaches, and implementation considerations.

---

## Table of Contents

1. [Overview](#overview)
2. [Client Components](#client-components)
3. [Hardware Security](#hardware-security)
4. [Storage Architecture](#storage-architecture)
5. [Secrets Management](#secrets-management)
6. [Client Identification and Trust](#client-identification-and-trust)
7. [Implementation Technologies](#implementation-technologies)
8. [Related Documents](#related-documents)

---

## 1. Overview

The TrustedLicensing client architecture is designed to provide secure, hardware-backed license management for vendor applications. The system supports multiple deployment topologies ranging from full-service daemons to embedded lightweight clients, with a strong emphasis on hardware-based security through Trusted Platform Module (TPM) integration.

**Key Design Principles:**
- **Hardware-backed security**: Primary reliance on TPM 2.0 for trust anchoring and secret storage
- **Flexible deployment**: Support for both service-based (TLLicenseManager) and embedded (TLLicenseClient) scenarios
- **Platform independence**: Cross-platform support for Windows, Linux, and (planned) ARM architectures
- **Network licensing**: Multiple licensing models including Named User, Station, Consumption, and Process-based
- **Offline capability**: Support for disconnected operation scenarios

---

## 2. Client Components

### 2.1. TLLicenseManager (TLLM)

The TLLicenseManager is the primary client component, implemented as a system service or daemon that provides centralized license management capabilities.

**Characteristics:**
- **Deployment model**: Background service/daemon (Trusted License Manager - TLLM)
- **Privileges**: Requires elevated rights for TPM access and system-level operations
- **Communication**: REST API (with planned gRPC migration) for vendor client integration
- **Licensing models**: Supports all network-based (seat) licensing scenarios:
  - **Named User**: OAuth-authenticated user-based licensing with identity claims
  - **Station**: Machine/workstation-based license assignment
  - **Consumption**: Usage-based licensing (login/session tracking)
  - **Process**: Application instance-based licensing

**Architecture benefits:**
- Centralized license management across multiple applications
- Direct TPM access through elevated privileges
- Robust background operation and monitoring
- Support for complex network licensing scenarios

### 2.2. TLLicenseClient

The TLLicenseClient is a lightweight embedded component designed for resource-constrained scenarios where running a full service is not practical.

**Characteristics:**
- **Deployment model**: Embedded library integrated directly into vendor applications
- **Use cases**: Embedded systems, resource-limited environments, simplified deployments
- **TPM access**: Available only through service/daemon or elevation (delegates to TLLicenseManager when needed)
- **Security**: Implements same security mechanisms as TLLicenseManager
- **Communication**: REST API (with planned gRPC migration) to TLLicenseManager for TPM operations
- **Offline support**: Capable of offline license validation and operation

**Architecture benefits:**
- Minimal resource footprint
- Simplified deployment for embedded scenarios
- Direct application integration
- Flexible delegation model for security operations

---

## 3. Hardware Security

### 3.1. TPM-Based Security (Primary)

The TrustedLicensing client leverages Trusted Platform Module (TPM) 2.0 chips as the primary hardware security foundation.

**Supported platforms:**
- **Windows**: Full TPM 2.0 support
- **Linux**: Full TPM 2.0 support
- **ARM**: To be confirmed (planned support)

**TPM capabilities utilized:**
- **Storage Root Keys (SRK)**: Trusted platform public keys for cryptographic operations and key hierarchy
- **HMAC operations**: Hardware-based message authentication for data integrity
- **Non-volatile storage**: Secure persistent storage within TPM hardware for critical secrets and bindings

**Security advantages:**
- Hardware-backed root of trust
- Protection against software-based attacks
- Cryptographic keys never exposed to application memory
- Hardware binding for license portability prevention

### 3.2. Fingerprint-Based Alternative (Fallback)

For systems without TPM support, TrustedLicensing provides fingerprint-based identification as an alternative mechanism.

**Fingerprint options:**
- **Built-in persistence**: Software-based storage (less secure than TPM)
- **Built-in fingerprint**: Standard system identification using hardware characteristics
- **Custom fingerprint**: Vendor-specific identification requiring C++ registered callback

**Licensing requirements:**
> **Important:** A dedicated license feature is required to enable fingerprint-based licensing. This same license feature can also disable TPM usage if needed for specific deployment scenarios.

**Use cases:**
- Virtual machines without TPM pass-through
- Legacy systems without TPM hardware
- Testing and development environments
- Specific vendor requirements for non-TPM deployments

---

## 4. Storage Architecture

The TLLicenseManager must securely store multiple categories of data: secrets, licenses, usage information, configuration, and custom vendor data.

### 4.1. TPM-Based Storage (Recommended)

A fully trusted client configuration relies on TPM 2.0 hardware for secure storage operations.

**Storage mechanisms:**
- **Storage Root Key (SRK)**: Hardware-protected key hierarchy root for encryption/decryption operations
- **Non-volatile (NV) storage**: Secure persistent storage space within the TPM chip for critical secrets

**OS independence advantages:**
- **Cross-platform persistence**: Storage survives OS reinstallation or migration as long as TPM is not reset
- **Hardware binding**: Data remains bound to the physical hardware (TPM chip)
- **Migration scenario**: A PC can be changed from Windows to Linux while maintaining license and trust through TPM capabilities

**Storage resilience:**
- Survives OS upgrades and reinstalls
- Requires explicit TPM reset to clear (administrative action)
- Hardware-level protection against unauthorized access

### 4.2. Software-Based Storage (Fallback)

For fingerprint-based clients or non-TPM scenarios, software-based storage is available with reduced security guarantees.

**Characteristics:**
- Platform-specific secure storage APIs (Windows DPAPI, Linux keyrings, etc.)
- Encryption using derived keys from fingerprint data
- File-based persistence with operating system protection
- Lower security assurance compared to TPM-based storage

---

## 5. Secrets Management

The TLLicenseManager maintains cryptographic keys and secrets for secure communication and configuration management.

**Key types maintained:**
- **Provider public key**: Used to verify information and configurations from the TrustedLicensing platform provider
- **Vendor public key**: Used to verify information and configurations from the software vendor

**Configuration security:**
Encrypted configuration information can be securely delivered to the client from two trusted sources:
- **Provider**: Platform-level configuration and policy enforcement
- **Vendor**: Vendor-specific settings and licensing policies

**Usage:**
Both keys enable secure, authenticated configuration updates without requiring direct network communication. Configurations can be distributed through various channels (files, installation packages, etc.) and verified locally by the client.

For detailed cryptographic key architecture, see [Crypto Entities](../Architecture/Crypto%20Entities.md).

---

## 6. Client Identification and Trust

Establishing mutual trust between the vendor client application and the TLLicenseManager is critical for secure license enforcement.

### 6.1. IAM Integration (OAuth) - Cross-Platform

For OAuth-enabled deployments, Identity and Access Management (IAM) integration provides standardized authentication and trust establishment.

**Configuration:**
- TLLM receives trusted configuration from the vendor specifying the trusted IAM URL
- IAM client information for TLLM is provisioned during installation or configuration
- Vendor client application uses the same IAM realm for authentication

**Trust establishment:**
- **Token-based**: OAuth tokens validate identity and establish trust between client and TLLM
- **Protocol-based**: Standard OAuth 2.0 flows for authentication and authorization

**Benefits:**
- OS-agnostic authentication approach
- Foundation for user-based (claims) licensing with Named User model
- Integration with enterprise identity systems (Azure AD, Keycloak, etc.)
- Standardized security protocols

### 6.2. Windows-Specific Trust

Windows platforms support additional trust mechanisms leveraging platform-specific capabilities.

**Trust establishment methods:**

1. **Diffie-Hellman (TLS) session:**
   - Vendor client knows the vendor public key
   - Client establishes TLS session with TLLM for secure communication
   - Mutual authentication through certificate validation

2. **Vendor secret verification:**
   - TLLM provides a vendor-signed secret to the client
   - Client verifies the secret using the vendor public key
   - Proves TLLM authenticity to the vendor application

3. **Certificate-based identification:**
   - Vendor creates password-protected certificate identifying the vendor client application
   - Certificate used for mutual authentication between client and TLLM
   - Strong cryptographic binding between application and licensing system

### 6.3. Linux-Specific Trust

*(To be documented based on implementation priorities)*

**Planned approaches:**
- Unix domain socket authentication
- SELinux/AppArmor policy integration
- D-Bus authentication mechanisms
- Certificate-based authentication (similar to Windows)

### 6.4. Apple-Specific Trust

*(To be documented based on implementation priorities)*

**Planned approaches:**
- Keychain integration
- Code signing validation
- XPC service authentication
- System Integrity Protection (SIP) considerations

---

## 7. Implementation Technologies

This section outlines the technology stack and libraries being evaluated or used for client implementation.

### 7.1. Graphical User Interface (GUI)

For client configuration tools and license management utilities, the following C++ GUI frameworks are under consideration:

- **[Slint UI](https://slint-ui.com/)**: Modern declarative UI framework for embedded and desktop
- **[wxWidgets](https://www.wxwidgets.org/)**: Cross-platform native GUI framework
- **[Dear ImGui](https://www.dearimgui.com/)**: Immediate-mode GUI for debugging and tools

### 7.2. REST API Implementation

For REST communication between TLLicenseClient and TLLicenseManager:

- **[oatpp](https://oatpp.io/)**: High-performance C++ web framework for REST APIs

**Future migration:** gRPC is planned for improved performance, type safety, and bidirectional streaming capabilities.

### 7.3. Windows Service Implementation

Windows service implementation reference:
- [Microsoft Windows Services Documentation](https://learn.microsoft.com/en-us/windows/win32/services/svccontrol-cpp)

---

## 8. Related Documents

- [TPM Requirements](TPM_Requirements.md) - TPM hardware and software requirements
- [TPM Simulator](TPMSimulator.md) - TPM simulator setup for development
- [Daemon Service](DaemonService.md) - Linux daemon implementation details
- [gRPC](gRPC.md) - gRPC migration planning and implementation
- [Fingerprints](FingerPrints.md) - Fingerprint generation and validation
- [Crypto Entities](../Architecture/Crypto%20Entities.md) - Cryptographic key architecture
- [Client Security and Cryptography](../../Generated/Dev%20Overview/TrustedLicensing_Client_Security_Cryptography.md) - Comprehensive security documentation

---

<!-- 
Generation Prompt:
Create a professional architecture document for TrustedLicensing client components covering:
1. Client topology with TLLicenseManager (service/daemon) and TLLicenseClient (embedded)
2. TPM 2.0 hardware security mechanisms (SRK, HMAC, NV storage) and fingerprint alternatives
3. Network licensing models (Named User, Station, Consumption, Process)
4. Storage architecture (TPM-based vs software-based, OS independence)
5. Secrets management (provider/vendor public keys, encrypted configuration)
6. Client identification and trust establishment (OAuth/IAM, Windows-specific, Linux/Apple)
7. Implementation technologies (GUI frameworks, REST libraries, service implementation)
8. Offline capabilities and resource considerations

Include version control, comprehensive explanations, security considerations, and cross-references to related documents.
-->
