# Persistence and Fingerprint Documentation

## Overview

This document describes the client persistence mechanism and platform fingerprint generation for the TL License Manager system. The fingerprinting system ensures secure license activation and validation across different platform configurations.

---

## Client Persistence

Client persistence relies on a unique security identifier to maintain state across system restarts and ensure secure license management.

### Key Requirements

- A security identifier must be generated and persisted
- Persistence storage varies by platform (TPM NVRAM or file system)
- The security identifier is used as part of the platform fingerprint

---

## Platform Fingerprint

The platform fingerprint is a unique identifier derived from hardware characteristics and security identifiers. It serves as the foundation for license activation and validation.

### Purpose

- **Required for Activation**: The platform fingerprint must be included in the activation package
- **Validation**: Checked during activation to ensure license integrity
- **Security**: Incorporates the persistence security identifier to prevent unauthorized transfers

### Platform-Specific Implementation

#### Windows and Linux

**TPM-Based Fingerprinting**
- Platform fingerprint is derived from the TPM Storage Root Key (SRK)
- Provides hardware-backed security
- Most secure option when TPM is available

**Fallback Mode**
- Platform fingerprint is computed using hash values from hardware components
- Includes the storage location identifier
- Used when TPM is unavailable or not accessible

#### Containerized Docker Environments

**TPM-Based Fingerprinting**
- Platform fingerprint is derived from the TPM Storage Root Key (SRK)
- Requires TPM passthrough to the container

**Fallback Mode**
- **Requirement**: Docker socket (`docker.sock`) must be available
- **Failure Condition**: Service will fail to start without access to the Docker socket
- Platform fingerprint is computed using hash values from the host hardware
- Includes the storage location identifier of the host system

> **Note**: In containerized environments, the fingerprint is based on the host system to ensure consistency across container recreations.

---

## Persistence States

### Cold Start

A cold start occurs when the system initializes persistence for the first time or after persistence data has been cleared.

#### Detection Criteria

**TPM Mode**
- No persistence information exists in TPM NVRAM

**Fallback Mode**
- Persistence folder structure is empty or missing
- No directories or data files present

#### Cold Start Process

1. **Create Persistence Folder Structure**
   - Initialize required directories
   - Prepare storage for `vault.bin` and `persistence.bin`

2. **Generate Security Identifier**
   - Create a unique security identifier for this installation
   - Store securely in the persistence layer

3. **Compute Platform Fingerprint**
   - Generate the platform fingerprint using the appropriate method (TPM or fallback)
   - Associate with the security identifier

### Warm Start

A warm start occurs when the system restarts with existing persistence data.

#### Detection Criteria

**TPM Mode**
- Valid persistence information exists in TPM NVRAM

**Fallback Mode**
- Persistence folder structure contains valid data
- Required files (`vault.bin`, `persistence.bin`) are present

#### Warm Start Process

1. **Load Persistence Data**
   - Read security identifier from storage
   - Validate data integrity

2. **Verify Platform Fingerprint**
   - Recompute the current platform fingerprint
   - Compare with stored fingerprint to detect hardware changes

3. **Resume Operations**
   - Continue with normal license validation and service operation

---

## Exception Handling

> **TODO**: Define specific exception cases and handling procedures for:
> - TPM communication failures
> - Hardware change detection thresholds
> - Migration scenarios
> - Container orchestration edge cases

---

## Security Considerations

- The platform fingerprint should be treated as sensitive information
- Hardware changes may invalidate existing licenses and require reactivation
- In containerized environments, ensure Docker socket access is properly secured
- TPM-based fingerprinting provides the highest level of security and should be preferred when available