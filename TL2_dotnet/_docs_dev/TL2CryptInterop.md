# TL2 Cryptographic Interoperability Library

**Document Version:** 1.0  
**Created:** 02. February 2026  
**Last Updated:** 02. February 2026  

## Table of Contents

- [Overview](#overview)
- [Purpose](#purpose)
- [Cryptographic Algorithms](#cryptographic-algorithms)
  - [1. AES (Advanced Encryption Standard)](#1-aes-advanced-encryption-standard)
  - [2. RSA (Rivest–Shamir–Adleman)](#2-rsa-rivestshamiradleman)
  - [3. Hash Algorithms](#3-hash-algorithms)
- [Supporting Components](#supporting-components)
  - [ASN.1 Key Parser](#asn1-key-parser)
  - [ASN.1 Key Builder](#asn1-key-builder)
  - [BigInteger Implementation](#biginteger-implementation)
  - [Utility Classes](#utility-classes)
- [Interoperability Architecture](#interoperability-architecture)
  - [Data Exchange Flow](#data-exchange-flow)
  - [File-Based Data Exchange](#file-based-data-exchange)
- [Test Suite](#test-suite)
- [Configuration](#configuration)
- [Security Considerations](#security-considerations)
  - [Algorithm Strength](#algorithm-strength)
  - [Best Practices Implemented](#best-practices-implemented)
  - [Known Limitations](#known-limitations)
- [Usage Examples](#usage-examples)
- [Dependencies](#dependencies)
- [Known Vulnerabilities and Contradictions](#known-vulnerabilities-and-contradictions)
  - [Critical Security Vulnerabilities](#critical-security-vulnerabilities)
  - [Documentation Contradictions](#documentation-contradictions)
  - [Security Recommendations by Priority](#security-recommendations-by-priority)
  - [Testing Considerations](#testing-considerations)
- [Future Enhancements](#future-enhancements)
- [License & Credits](#license--credits)
- [Regeneration Prompt](#regeneration-prompt)

## Overview

The **CSCPPInterop** project is a C#/.NET cryptographic interoperability library designed to facilitate secure data exchange between C# and C++ applications. It provides implementations of industry-standard cryptographic algorithms and utilities for key management, encryption, decryption, and digital signatures.

## Purpose

This library enables:
- Cross-platform cryptographic operations between C# and C++ codebases
- Secure data encryption and decryption
- Digital signature creation and verification
- Key import/export in standard formats (PEM, ASN.1)
- Testing cryptographic compatibility between .NET and C++ implementations

## Cryptographic Algorithms

### 1. AES (Advanced Encryption Standard)

**File:** [AESInterop.cs](../CSCPPInterop/AESInterop.cs)

**Configuration:**
- **Key Size:** 128-bit
- **Mode:** CBC (Cipher Block Chaining)
- **Padding:** PKCS7
- **Encoding:** Base64 for ciphertext, Hexadecimal for keys/IV

**Key Features:**
- Symmetric encryption/decryption
- Automatic key and IV generation
- Support for interoperability with C++ OpenSSL implementations

**Classes:**
- `AESCrypt` - Main AES encryption/decryption class

**Methods:**
- `Encrypt(string plainText)` - Encrypts plaintext, generates key and IV
- `Decrypt(string cipher)` - Decrypts Base64-encoded ciphertext

### 2. RSA (Rivest–Shamir–Adleman)

**File:** [RSAInterop.cs](../CSCPPInterop/RSAInterop.cs)

**Configuration:**
- **Key Size:** 2048-bit (FASTCRYPT mode) or 4096-bit (default)
- **Padding (Encryption):** OAEP with SHA-256
- **Padding (Signature):** PKCS1 with SHA-256
- **Hash Algorithm:** SHA-256

**Key Features:**
- Asymmetric encryption/decryption
- Digital signature generation and verification
- PEM format key import/export
- PKCS#8 private key format
- Subject Public Key Info format

**Classes:**
- `RSAInterop` - Main RSA operations class

**Methods:**
- `LoadKeyFromCPPEncryptDecrypt()` - Imports keys from C++ and decrypts data
- `ExportKeyEncryptDecrypt()` - Exports keys and performs encryption
- `VerifyCPPSignature()` - Verifies digital signatures from C++

**Key Formats Supported:**
- PEM (Privacy Enhanced Mail) format
- ASN.1/DER format (via parser)
- PKCS#8 for private keys
- X.509 SubjectPublicKeyInfo for public keys

### 3. Hash Algorithms

**Usage:** SHA-256 (via RSA signature operations)
- Used for digital signatures
- HMAC operations in RSA-OAEP padding

## Supporting Components

### ASN.1 Key Parser

**File:** [AsnKeyParser.cs](../CSCPPInterop/AsnKeyParser.cs)

**Purpose:** Parses ASN.1/DER encoded RSA keys for interoperability with C++ libraries

**Key Features:**
- BER (Basic Encoding Rules) parsing
- RSA public/private key extraction
- DSA key support
- OID (Object Identifier) validation

### ASN.1 Key Builder

**File:** [AsnKeyBuilder.cs](../CSCPPInterop/AsnKeyBuilder.cs)

**Purpose:** Constructs ASN.1/DER encoded key structures

### BigInteger Implementation

**File:** [BigInteger.cs](../CSCPPInterop/BigInteger.cs)

**Purpose:** Custom arbitrary-precision integer arithmetic for cryptographic operations

**Features:**
- Large integer arithmetic (+, -, *, /, %)
- Primality testing (Fermat, Rabin-Miller, Solovay-Strassen, Lucas)
- Modular exponentiation with Barrett reduction
- Inverse modulo operations
- Pseudo-prime and co-prime generation

### Utility Classes

#### Base64 Encoder/Decoder
**File:** [Base64.cs](../CSCPPInterop/Base64.cs)
- UTF-8 to Base64 encoding
- Base64 to UTF-8 decoding

#### Conversion Utilities
**File:** [Conversion.cs](../CSCPPInterop/Conversion.cs)
- Hexadecimal string to byte array conversion
- Byte array to hexadecimal string conversion
- Used for key and IV representation

#### RSA Key Exporter
**File:** [RSAExporter.cs](../CSCPPInterop/RSAExporter.cs)
- Legacy RSA key export utilities

## Interoperability Architecture

### Data Exchange Flow

```
C++ Application                    C# Application
     |                                  |
     | 1. Generate Keys/Encrypt         |
     |--------------------------------->|
     | (Save to shared files)           |
     |                                  |
     |                                  | 2. Read & Decrypt
     |                                  | (Verify signature)
     |                                  |
     | 3. Read C# output                |
     |<---------------------------------|
     | (Verify/Decrypt)                 | 4. Encrypt & Save
```

### File-Based Data Exchange

**Test Data Manager:** [RSATestData.cs](../CSCPPInterop/RSATestData.cs)

**Purpose:** Manages file-based data exchange between C# and C++ implementations

**Data Types Exchanged:**
- **RSA Keys:** Public/private keys in PEM and ASN.1 formats
- **AES Keys:** Symmetric keys and initialization vectors
- **Encrypted Data:** Ciphertext from both implementations
- **Signatures:** Digital signatures for verification
- **Test Messages:** Plaintext inputs for testing

**File Location:**
- Windows: `C:\ProgramData\asperion\trustedLicensing\persistenceTest\`
- Linux: `/mnt/d/DEV/TrustedLicensing2/persistenceTest/`
- Configurable via `RSATestKeyPath` environment variable

## Test Suite

**File:** [CPPInterOpTests.cs](../CSCPPInterop/CPPInterOpTests.cs)

### Test Methods

1. **`AESDecryptCPP()`**
   - Decrypts AES-encrypted data from C++
   - Validates plaintext recovery

2. **`AESEncryptForCPP()`**
   - Encrypts data for C++ consumption
   - Exports key, IV, and ciphertext

3. **`RSAFromCPP()`**
   - Imports RSA keys from C++
   - Decrypts RSA-encrypted data

4. **`RSAForCPP()`**
   - Exports RSA keys for C++
   - Encrypts data for C++ decryption

5. **`RSASignatureFromCPP()`**
   - Verifies digital signatures created by C++

## Configuration

### Compilation Flags

**FASTCRYPT:** When defined, uses 2048-bit RSA keys instead of 4096-bit
```xml
<DefineConstants>$(DefineConstants);FASTCRYPT</DefineConstants>
```

### Target Framework

- .NET 10.0 (as configured in [CSCPPInterop.csproj](../CSCPPInterop/CSCPPInterop.csproj))

## Security Considerations

### Algorithm Strength

| Algorithm | Configuration | Security Level |
|-----------|--------------|----------------|
| AES-128 | CBC mode, PKCS7 padding | Strong |
| RSA-4096 | OAEP-SHA256 padding | Very Strong |
| RSA-2048 | OAEP-SHA256 padding | Strong (FASTCRYPT) |
| SHA-256 | For signatures | Strong |

### Best Practices Implemented

1. **Key Generation:** Uses cryptographically secure random number generators
2. **Padding Schemes:** 
   - OAEP for RSA encryption (prevents chosen-ciphertext attacks)
   - PKCS7 for AES (standard block cipher padding)
3. **Signature Verification:** SHA-256 with PKCS1 padding
4. **Key Storage:** File-based exchange with appropriate permissions

### Known Limitations

- File-based key exchange should be replaced with secure key exchange protocols in production
- CBC mode is susceptible to padding oracle attacks if not implemented carefully
- Consider using authenticated encryption modes (GCM) for AES in production environments

## Usage Examples

### AES Encryption/Decryption

```csharp
// Encrypt
var aes = new AESCrypt();
var cipher = aes.Encrypt("Sensitive data");
Console.WriteLine($"Key: {aes.AESKey}");
Console.WriteLine($"IV: {aes.IV}");
Console.WriteLine($"Cipher: {cipher}");

// Decrypt
var aes2 = new AESCrypt(aes.AESKey, aes.IV);
var plaintext = aes2.Decrypt(cipher);
```

### RSA Signature Verification

```csharp
using var rsa = RSA.Create(4096);
rsa.ImportFromPem(publicKeyPEM);

var message = Encoding.UTF8.GetBytes("Message to verify");
var signature = Convert.FromBase64String(signatureBase64);

bool isValid = rsa.VerifyData(
    message, 
    signature, 
    HashAlgorithmName.SHA256, 
    RSASignaturePadding.Pkcs1
);
```

## Dependencies

- **System.Security.Cryptography** - Core cryptographic primitives
- **.NET 10.0 SDK** - Target framework

## Known Vulnerabilities and Contradictions

### Critical Security Vulnerabilities

#### 1. **Insecure Text Encoding in AES** 🔴
**Location:** [AESInterop.cs](../CSCPPInterop/AESInterop.cs#L29)

```csharp
byte[] clearBytes = Encoding.Default.GetBytes(plainText);
```

**Issue:** Uses `Encoding.Default` (platform-dependent) instead of `Encoding.UTF8`
- **Risk:** Data corruption across platforms, encoding inconsistencies between C# and C++
- **Impact:** Critical - Could result in decryption failures or data corruption
- **Recommended Fix:** Replace with `Encoding.UTF8.GetBytes(plainText)`

#### 2. **File-Based Key Storage Without Access Controls** 🔴
**Location:** [RSATestData.cs](../CSCPPInterop/RSATestData.cs#L58-L62)

**Issues:**
- Stores private keys, ciphertext, and signatures in plain text files
- No file permission checks or encryption at rest
- No access control validation
- Shared directory (`C:\ProgramData\asperion\trustedLicensing\persistenceTest\`) accessible to all processes

**Risk Level:** CRITICAL
- Private keys exposed on filesystem without protection
- Any process with read access can steal cryptographic keys
- No audit trail for key access

**Recommended Fixes:**
- Encrypt keys at rest using DPAPI (Windows) or keyring (Linux)
- Implement file permission validation (restrict to current user)
- Add access logging for security auditing
- Use Windows Credential Manager or equivalent secure storage

#### 3. **No Error Handling for Cryptographic Operations** ⚠️
**Location:** [CPPInterOpTests.cs](../CSCPPInterop/CPPInterOpTests.cs)

```csharp
catch (Exception)
{
    return false;  // Silently fails without logging
}
```

**Issue:** Swallows all exceptions without logging
- **Risk:** Makes debugging impossible, hides security issues
- **Impact:** High - Cannot detect or respond to cryptographic failures
- **Recommended Fix:** Implement structured logging with security event tracking

#### 4. **Missing Key Validation** ⚠️
**Location:** [AESInterop.cs](../CSCPPInterop/AESInterop.cs) - Decrypt method

**Issues:**
- No validation that `AESKey` and `IV` are set before decryption
- Could throw null reference exceptions if keys not initialized
- No validation of key/IV format or length

**Recommended Fixes:**
```csharp
if (string.IsNullOrEmpty(AESKey) || string.IsNullOrEmpty(IV))
    throw new InvalidOperationException("AES key and IV must be set before decryption");
```

#### 5. **Potential Directory Traversal** ⚠️
**Location:** [RSATestData.cs](../CSCPPInterop/RSATestData.cs) - SaveFile/ReadFile methods

```csharp
var filePath = $"{path}{fileName}";
```

**Issue:** No validation of `fileName` parameter
- **Risk:** Directory traversal attack if attacker controls filename (e.g., `../../../sensitive.txt`)
- **Recommended Fix:** Validate filename contains no path separators or use `Path.GetFileName()`

#### 6. **CBC Mode Without Authentication** ⚠️
**Location:** [AESInterop.cs](../CSCPPInterop/AESInterop.cs)

**Issue:** AES-CBC without HMAC is vulnerable to padding oracle attacks
- No message authentication code (MAC) to verify integrity
- Attacker can modify ciphertext without detection
- Susceptible to bit-flipping attacks

**Risk Level:** HIGH
- **Recommended Fix:** Use AES-GCM (authenticated encryption mode) instead of CBC
- Alternative: Implement Encrypt-then-MAC with HMAC-SHA256

#### 7. **Exception Information Leakage** ⚠️
**Location:** [RSAInterop.cs](../CSCPPInterop/RSAInterop.cs)

```csharp
Console.WriteLine($"CryptographicException {e.Message}");
```

**Risk:** Leaks cryptographic error details that could aid attackers
- Timing attack information
- Key format validation details
- Padding validation results

**Recommended Fix:** Log to secure audit log, return generic error to caller

#### 8. **No Key Lifecycle Management** ⚠️
**Issue:** Keys are generated but never destroyed/cleared from memory
- Key material remains in memory after use
- No secure key disposal with `Array.Clear()` on key bytes
- Vulnerable to memory dumping attacks

**Recommended Fix:**
```csharp
try {
    // Use key
} finally {
    if (keyBytes != null) Array.Clear(keyBytes, 0, keyBytes.Length);
}
```

### Documentation Contradictions

#### 1. **Hash Algorithm Description - HMAC vs MGF1**
**Documentation States:**
> "HMAC operations in RSA-OAEP padding"

**Reality:** RSA-OAEP uses MGF1 (Mask Generation Function 1), not HMAC
- MGF1 is based on a hash function (SHA-256) but is not HMAC
- This is a technical inaccuracy in cryptographic terminology

**Correction:** Should state "MGF1 with SHA-256 for mask generation in OAEP"

#### 2. **Encoding Inconsistency**
**Documentation Claims:**
> "Encoding: Base64 for ciphertext, Hexadecimal for keys/IV"

**Reality:** Code uses `Encoding.Default` for plaintext conversion, which is:
- Platform-dependent (Windows-1252 on Windows, varies on Linux)
- Neither UTF-8 nor explicitly defined
- Inconsistent with stated encoding scheme

**Correction:** Documentation should specify UTF-8 encoding for text, and code should be fixed accordingly

### Security Recommendations by Priority

#### Immediate (Critical) - Fix Before Production

1. ✅ Change `Encoding.Default` to `Encoding.UTF8` in AES implementation
2. ✅ Implement file permissions and encryption for key storage
3. ✅ Add proper error logging without information leakage
4. ✅ Add input validation for filenames (prevent directory traversal)

#### High Priority - Security Improvements

5. ✅ Replace AES-CBC with AES-GCM (authenticated encryption)
6. ✅ Add key validation checks before cryptographic operations
7. ✅ Implement secure key disposal (clear sensitive data from memory)
8. ✅ Add file access control checks and validation
9. ✅ Implement proper exception handling with security logging

#### Medium Priority - Best Practices

10. Fix documentation inaccuracies (HMAC/MGF1, encoding schemes)
11. Add comprehensive security audit logging
12. Implement key rotation mechanisms
13. Add unit tests for error conditions and edge cases
14. Consider hardware security module (HSM) integration for production

#### Low Priority - Enhancements

15. Add certificate-based authentication
16. Implement secure key derivation functions (PBKDF2, Argon2)
17. Add support for ECC and modern algorithms
18. Implement rate limiting for cryptographic operations

### Testing Considerations

**Current State:** This is a TEST/INTEROP library, not production-ready
- Designed for testing C#/C++ cryptographic compatibility
- File-based exchange is intentional for testing purposes
- Should NOT be used in production without significant security hardening

**Production Readiness Checklist:**
- [ ] Replace file-based key exchange with secure protocols
- [ ] Implement proper key management system
- [ ] Add comprehensive error handling and logging
- [ ] Enable FIPS 140-2 compliance if required
- [ ] Perform security audit and penetration testing
- [ ] Implement secure memory handling
- [ ] Add rate limiting and DOS protection
- [ ] Document threat model and security assumptions

## Future Enhancements

1. Support for additional algorithms (ECC, ChaCha20-Poly1305)
2. Secure key exchange protocols (ECDH, X25519)
3. Certificate-based authentication
4. Hardware security module (HSM) integration
5. Authenticated encryption modes (AES-GCM)
6. Key derivation functions (PBKDF2, Argon2)

## License & Credits

- **BigInteger Class:** Version 1.03, Copyright (c) 2002 Chew Keong TAN
- Project namespace: `TrustedLicensing.Crypt` and `CSCPPInterop`

---

**Document Version:** 1.0  
**Created:** 02. February 2026  
**Last Updated:** 02. February 2026  

## Regeneration Prompt

To regenerate or update this documentation, use the following prompt:

```
Analyze the CSCPPInterop project and create a markdown in folder _docs_dev called TL2CryptInterop.md and explain and list algos used. Include:
- Document version (1.0) and dates in format "dd. Month yyyy" (e.g., "02. February 2026") using Get-Date from OS
- Table of contents with all major sections and subsections
- Overview and purpose
- All cryptographic algorithms with configurations (AES-CBC, RSA, SHA-256)
- Supporting components (ASN.1 parsers, BigInteger, utilities)
- Interoperability architecture and file-based data exchange
- Test suite description with test methods
- Security considerations and algorithm strength table
- Known vulnerabilities and contradictions section with:
  * Critical security vulnerabilities (encoding issues, file storage, error handling, key validation, directory traversal, CBC mode, exception leakage, key lifecycle)
  * Documentation contradictions (HMAC vs MGF1, encoding inconsistencies)
  * Security recommendations prioritized by urgency
  * Testing considerations and production readiness checklist
- Usage examples (AES encryption/decryption, RSA signature verification)
- Dependencies and future enhancements
- License & Credits
- Add regeneration prompt at the end
```
