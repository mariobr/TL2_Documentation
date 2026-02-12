# Persistence Workflow

## Overview

This document describes the complete persistence initialization workflow for the TLLicenseManager, including COLDSTART (first run) and WARMSTART (subsequent runs) paths, with detailed security validations.

## High-Level Flow

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}}}%%
flowchart TD
    start(["<b>Start</b><br/>PersistenceService::Initialize()"])
    start --> determine["<b>1. Determine Startup State</b><br/>DetermineStartupState()<br/>Check filesystem for existing files"]
    
    determine --> setup["<b>2. Setup Files & Encryption</b><br/>SetupPersistenceFiles()<br/>• Create AES encryption<br/>• Initialize PersistenceFile<br/>• Initialize TamperFile"]
    
    setup --> manifests["<b>3. Load License Provider Manifests</b><br/>ManifestLoader::LoadLicenseProviderManifests()<br/>Scan for vendor licenses"]
    
    manifests --> branch{"<b>Startup State?</b>"}
    
    branch -->|COLDSTART| cold["<b>4a. COLDSTART Path</b><br/>InitializeColdstart()"]
    branch -->|WARMSTART| warm["<b>4b. WARMSTART Path</b><br/>InitializeWarmstart()"]
    
    cold --> vault["<b>5. Load Vault & Validate</b><br/>LoadVaultAndValidate()"]
    warm --> vault
    
    vault --> done(["<b>Initialization Complete</b>"])
    
    style start fill:#e1f5e1
    style done fill:#e1f5e1
    style branch fill:#fff4e1
    style cold fill:#ffe1e1
    style warm fill:#e1e5ff
```

## Detailed COLDSTART Flow

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}}}%%
flowchart TD
    coldStart(["<b>COLDSTART</b><br/>InitializeColdstart()"])
    
    coldStart --> secretCheck["<b>SecretStore Validation</b><br/>ValidateColdstartSecretStore()<br/>Check for leftover data"]
    
    secretCheck --> fail1{"Valid?"}
    fail1 -->|No| error1["<b>CRITICAL ERROR</b><br/>PERS_8003<br/>Partial restore detected"]
    fail1 -->|Yes| persist["<b>Create Persistence Data</b><br/>• Generate random core data<br/>• Write version V5<br/>• Write vault filename<br/>• Encrypt and save"]
    
    persist --> vaultKey["<b>Derive Vault Keys</b><br/>CreateGetVaultKey()<br/>KDF from persistence key + salt"]
    
    vaultKey --> done(["<b>Ready for Vault Load</b>"])
    
    style coldStart fill:#ffe1e1
    style error1 fill:#ff0000,color:#fff
    style done fill:#e1f5e1
```

## Detailed WARMSTART Flow

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}}}%%
flowchart TD
    warmStart(["<b>WARMSTART</b><br/>InitializeWarmstart()"])
    
    warmStart --> read["<b>Read Persistence Data</b><br/>• Decrypt persistence.bin<br/>• Extract version<br/>• Extract vault filename<br/>• Extract vault salt"]
    
    read --> vaultKey["<b>Derive Vault Keys</b><br/>CreateGetVaultKey()<br/>KDF from persistence key + salt"]
    
    vaultKey --> done(["<b>Ready for Vault Load & Validation</b>"])
    
    style warmStart fill:#e1e5ff
    style done fill:#e1f5e1
```

## Vault Load & Validation Flow

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}}}%%
flowchart TD
    start(["<b>LoadVaultAndValidate()</b>"])
    
    start --> filename["<b>Validate Vault Filename</b><br/>Must contain 'vault.bin'"]
    filename --> fail1{"Valid?"}
    fail1 -->|No| error1["<b>ERROR</b><br/>Corrupted persistence"]
    
    fail1 -->|Yes| vault["<b>Create & Load Vault</b><br/>CreateAndLoadVault()<br/>• Create Vault instance<br/>• Load vault.bin<br/>• Create PersistenceValidator<br/>• Inject validator into vault"]
    
    vault --> storage["<b>Initialize Storage ID</b><br/>InitializeStorageIdentifier()"]
    
    storage --> branch{"<b>Startup?</b>"}
    
    branch -->|COLDSTART| coldWrite["<b>WRITE: Storage ID</b><br/>Generate & store unique ID<br/>(No validation - first write)"]
    branch -->|WARMSTART| warmRead["<b>READ: Storage ID</b><br/>Verify ID exists"]
    
    coldWrite --> integrate
    warmRead --> integrate["<b>Validate Vault Integrity</b><br/>ValidateVaultIntegrity()<br/>• Read hash from tamper file<br/>• Cross-check SecretStore (no TPM)<br/>• Compare with vault.bin hash"]
    
    integrate --> fail2{"Valid?"}
    fail2 -->|No| error2["<b>CRITICAL ERROR</b><br/>PERS_8003<br/>Tampering detected"]
    
    fail2 -->|Yes| timeCheck["<b>Validate TIME_TAMPER Age</b><br/>ValidateTimeTamperAge()<br/>• Check timestamp not too old<br/>• SecretStore rollback check (no TPM)<br/>Max age: 7 days"]
    
    timeCheck --> fail3{"Valid?"}
    fail3 -->|No| error3["<b>CRITICAL ERROR</b><br/>PERS_8003<br/>Rollback attack detected"]
    
    fail3 -->|Yes| update["<b>Update TIME_TAMPER</b><br/>UpdateTimeTamper()<br/>• StoreTimeTamper() - validated write<br/>• Store in SecretStore (no TPM)"]
    
    update --> done(["<b>Initialization Complete</b>"])
    
    style start fill:#fff4e1
    style error1 fill:#ff0000,color:#fff
    style error2 fill:#ff0000,color:#fff
    style error3 fill:#ff0000,color:#fff
    style done fill:#e1f5e1
    style coldWrite fill:#ffe1e1
    style warmRead fill:#e1e5ff
```

## Vault Write Protection Flow

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}}}%%
flowchart TD
    write(["<b>Vault Write Operation</b><br/>Set() / Delete() / StoreTimeTamper()"])
    
    write --> guard["<b>ValidateBeforeWrite()</b><br/>Internal vault validation"]
    
    guard --> cold{"<b>COLDSTART?</b>"}
    cold -->|Yes| bypass["<b>Bypass Validation</b><br/>Allow first-time writes"]
    
    cold -->|No| hasVal{"<b>Validator<br/>configured?</b>"}
    hasVal -->|No| bypass
    
    hasVal -->|Yes| cache{"<b>Cached<br/>validation?</b><br/>< 60 seconds"}
    cache -->|Yes| cached["<b>Use Cache</b><br/>Skip re-validation"]
    
    cache -->|No| readTime["<b>Read TIME_TAMPER</b><br/>Directly from vault.data_<br/>(no Get() recursion)"]
    
    readTime --> exists{"<b>Exists?</b>"}
    exists -->|No| allow["<b>Allow Write</b><br/>First write scenario"]
    
    exists -->|Yes| validate["<b>ValidateTimeTamperInternal()</b><br/>• Parse timestamp<br/>• Check age (7 days)<br/>• SecretStore rollback check"]
    
    validate --> pass{"<b>Valid?</b>"}
    pass -->|No| block["<b>BLOCK WRITE</b><br/>PERS_8003<br/>Rollback attack detected"]
    pass -->|Yes| updateCache["<b>Update Cache</b><br/>Store validation timestamp"]
    
    bypass --> proceed["<b>Proceed with Write</b><br/>• Update vault.data_<br/>• Encrypt & save vault.bin<br/>• Publish VaultEvent"]
    cached --> proceed
    allow --> proceed
    updateCache --> proceed
    
    proceed --> event["<b>HandleVaultEvent()</b><br/>Event callback handler"]
    
    event --> readOp{"<b>READ<br/>operation?</b>"}
    readOp -->|Yes| skip["<b>Skip Hash Persistence</b><br/>CRITICAL: Prevent TOCTOU attack<br/>READ must NOT overwrite hash"]
    
    readOp -->|No| persist["<b>Persist Vault Hash</b><br/>• Write to tmtmp.bin<br/>• Store in SecretStore (no TPM)"]
    
    persist --> done(["<b>Write Complete</b>"])
    skip --> done
    
    style write fill:#fff4e1
    style block fill:#ff0000,color:#fff
    style done fill:#e1f5e1
    style skip fill:#ffcccc
    style persist fill:#ccffcc
```

## Security Validations Summary

### 1. **Vault Integrity Check** (WARMSTART only)
- **When**: After vault load, before any writes
- **What**: Compares vault.bin hash against persisted hash
- **Sources**: 
  - Primary: tmtmp.bin (TamperFile)
  - Fallback: SecretStore (when TPM disabled)
- **Detects**: Vault file tampering, unauthorized modifications

### 2. **TIME_TAMPER Age Validation**
- **When**: 
  - Startup (explicit check)
  - Before every vault write (cached, 60s window)
- **What**: Validates timestamp is not too old (max 7 days)
- **Extra Check**: SecretStore cross-validation for clock rollback detection
- **Detects**: 
  - Outdated backup restorations
  - Rollback attacks
  - Clock manipulation

### 3. **SecretStore Cross-Validation** (TPM disabled only)
- **When**: Both integrity and time validation
- **What**: Compares tamper file data with SecretStore data
- **Detects**:
  - Clock rollback (OS time < SecretStore time)
  - Inconsistencies between storage locations
  - Partial restore attacks

### 4. **COLDSTART SecretStore Validation**
- **When**: COLDSTART initialization
- **What**: Checks for leftover SecretStore data when persistence files missing
- **Detects**:
  - Incomplete cleanup after uninstall
  - Partial backup restoration
  - Tamper attempts via file deletion

### 5. **Write-Time Validation**
- **When**: Every vault write operation
- **What**: Re-validates TIME_TAMPER before allowing write
- **Performance**: 60-second cache to avoid overhead
- **Detects**: Runtime rollback attacks between startup and write operations

## Critical Security Guards

### TOCTOU Protection (Time-of-Check Time-of-Use)
```cpp
// In HandleVaultEvent() - CRITICAL security guard
if (event.Op == VaultOp::Read) {
    return; // Skip hash persistence for READ operations
}
```

**Why Critical**: Without this guard, READ operations would overwrite the legitimate hash BEFORE validation, defeating the integrity check entirely.

**Attack Without Guard**:
1. Attacker modifies vault.bin
2. System loads → READ event → overwrites hash with tampered hash
3. ValidateVaultIntegrity() compares tampered vault vs tampered hash = ✓ PASS (false positive)

**With Guard**:
1. Attacker modifies vault.bin  
2. System loads → READ event → **skipped** (no hash update)
3. ValidateVaultIntegrity() compares tampered vault vs legitimate hash = ✗ FAIL (correct detection)

## File Locations

- **persistence.bin**: Encrypted core data (version, vault filename, salt)
- **vault.bin**: Encrypted vault data (storage ID, TIME_TAMPER, keys)
- **tmtmp.bin**: Tamper detection file (vault hash, operation log)
- **SecretStore**: OS-protected storage (VaultHash, TimeTamper - TPM disabled only)

## Key Methods Reference

| Method | File | Line | Purpose |
|--------|------|------|---------|
| `Initialize()` | PersistenceService.cpp | ~177 | Main entry point |
| `DetermineStartupState()` | PersistenceService.cpp | ~649 | Detect COLD/WARMSTART |
| `SetupPersistenceFiles()` | PersistenceService.cpp | ~694 | Create file handlers |
| `InitializeColdstart()` | PersistenceService.cpp | ~234 | First-run initialization |
| `InitializeWarmstart()` | PersistenceService.cpp | ~294 | Subsequent-run initialization |
| `CreateAndLoadVault()` | PersistenceService.cpp | ~416 | Create vault & validator |
| `ValidateVaultIntegrity()` | PersistenceValidator.cpp | ~27 | Hash integrity check |
| `ValidateTimeTamperAge()` | PersistenceValidator.cpp | ~126 | Timestamp age check |
| `ValidateTimeTamperInternal()` | PersistenceValidator.cpp | ~137 | Internal timestamp validation |
| `ValidateBeforeWrite()` | Vault.cpp | ~226 | Pre-write validation guard |
| `HandleVaultEvent()` | PersistenceService.cpp | ~744 | Event callback with TOCTOU guard |

## Error Codes

- **PERS_8003**: Critical persistence error (tampering, rollback, integrity failure)
- **PERS_8005**: Initialization failure (setup, permissions, exceptions)

## TPM vs No-TPM Differences

| Feature | With TPM | Without TPM (File-Based) |
|---------|----------|--------------------------|
| Vault encryption keys | Hardware-sealed | Software-only |
| SecretStore validation | Skipped (redundant) | Active (cross-validation) |
| Rollback detection | Basic (timestamp age) | Enhanced (SecretStore time check) |
| Hash cross-check | Single source (tmtmp.bin) | Dual source (tmtmp.bin + SecretStore) |
| Security level | High (HW tamper resistance) | Medium (requires multiple checks) |

## Testing Scenarios

1. **COLDSTART Test**: Delete all persistence files, verify clean initialization
2. **WARMSTART Test**: Normal startup, verify integrity checks pass
3. **Tampering Test**: Modify vault.bin, verify PERS_8003 error
4. **Rollback Test**: Restore old backup, verify age check fails
5. **Clock Rollback Test**: Set system clock backwards, verify detection (no TPM)
6. **Partial Restore Test**: Restore files but not SecretStore, verify COLDSTART fails (no TPM)
7. **Performance Test**: Multiple writes within 60s, verify cache usage

