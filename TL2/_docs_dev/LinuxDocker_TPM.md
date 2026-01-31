# Linux Docker TPM Integration Guide

## Overview

This document explains how TLLicenseManager integrates with Trusted Platform Module (TPM) 2.0 hardware in Linux Docker containers. The implementation provides hardware-bound cryptographic operations while running in containerized environments, enabling secure license management with physical hardware attestation.

**Key Capabilities:**
- Direct TPM 2.0 hardware access from containers
- TPM Resource Manager support (`/dev/tpmrm0`)
- Docker socket integration for container awareness
- Secure key generation and storage
- Hardware-bound license fingerprints

---

## Table of Contents

1. [TPM Device Access](#tpm-device-access)
2. [Docker Container Configuration](#docker-container-configuration)
3. [TPM Integration Architecture](#tpm-integration-architecture)
4. [Build and Deployment Process](#build-and-deployment-process)
5. [Security Considerations](#security-considerations)
6. [Troubleshooting](#troubleshooting)

---

## TPM Device Access

### Linux TPM Device Files

Linux exposes TPM 2.0 devices through the `/dev` filesystem:

| Device | Description | Access Mode | Use Case |
|--------|-------------|-------------|----------|
| `/dev/tpm0` | Direct TPM character device | Exclusive access | Legacy applications, direct TPM control |
| `/dev/tpmrm0` | TPM Resource Manager device | Concurrent access | **Recommended** for containers and multi-process |

**Why `/dev/tpmrm0` is Preferred:**

The TPM Resource Manager (`tpmrm0`) provides:
- ✅ **Concurrent Access**: Multiple processes/containers can use TPM simultaneously
- ✅ **Automatic Context Management**: Kernel handles TPM session context saving/loading
- ✅ **Transient Object Cleanup**: Automatically flushes abandoned TPM objects
- ✅ **No Manual Session Management**: Simplifies application code
- ✅ **Better Stability**: Prevents TPM resource exhaustion

### TLLicenseManager TPM Device Priority

**Source:** [TLTpm/src/TpmDevice.cpp](../TLTpm/src/TpmDevice.cpp#L608-L621)

TLLicenseManager attempts to connect to TPM devices in this priority order:

```cpp
bool TpmTbsDevice::Connect()
{
#ifdef __linux__
    // Priority 1: Direct TPM device /dev/tpm0
    int fd = open("/dev/tpm0", O_RDWR);
    if (fd < 0) {
        // Priority 2: Try TPM Access Broker and Resource Manager Daemon (abrmd)
        tctiContext = tctiInitialization("tabrmd", "");
        if (tctiContext == nullptr) {
            // Priority 3: Kernel TPM Resource Manager (PREFERRED)
            fd = open("/dev/tpmrm0", O_RDWR);
            if (fd < 0) {
                printf("Unable to open tpm0, abrmd, or tpmrm0: error %d (%s)\n", 
                       errno, strerror(errno));
                return false;
            }
        }
    }
#endif
    return true;
}
```

**Priority Order:**
1. `/dev/tpm0` - Direct device (exclusive lock)
2. `tabrmd` - TPM Access Broker and Resource Manager Daemon
3. `/dev/tpmrm0` - Kernel Resource Manager (**default in containers**)
4. User-mode TRM - Socket connection (127.0.0.1:2323)

**Container Behavior:**
- In Docker containers, `/dev/tpmrm0` is typically mounted
- Direct `/dev/tpm0` access may be restricted for security
- Resource Manager ensures safe concurrent TPM usage

### Required Kernel Modules

```bash
# Check loaded TPM modules
lsmod | grep tpm

# Expected output:
tpm_tis                16384  0
tpm_tis_core           28672  1 tpm_tis
tpm                    77824  3 tpm_tis,tpm_tis_core,tpm_crb
tpm_crb                16384  0

# Load modules if needed
sudo modprobe tpm_tis
sudo modprobe tpm_crb
```

### TPM Device Permissions

```bash
# Check TPM device permissions
ls -la /dev/tpm*

# Expected output:
crw-rw---- 1 tss  tss  10, 224 Jan 31 10:00 /dev/tpm0
crw-rw---- 1 tss  tss  10, 225 Jan 31 10:00 /dev/tpmrm0

# Verify tss group
getent group tss
# Output: tss:x:113:

# Add user to tss group (if needed)
sudo usermod -aG tss $USER
```

---

## Docker Container Configuration

### Dockerfile Analysis

**Location:** [_Container/Docker/Linux/Dockerfile](../_Container/Docker/Linux/Dockerfile)

The Dockerfile configures a complete environment for TPM-enabled TLLicenseManager:

#### 1. Base Image and Dependencies

```dockerfile
FROM ubuntu:24.04

# Install TPM dependencies
RUN apt-get update && apt-get install -y \
    tpm2-tools \              # TPM 2.0 command-line tools
    tpm2-abrmd \              # TPM Access Broker (optional)
    libtss2-dev \             # TSS2 development headers
    libtss2-esys-3.0.2-0t64 \ # Enhanced System API
    libtss2-tcti-device0t64 \ # Device TCTI (Transport)
    libtss2-tcti-tabrmd0 \    # Broker TCTI
    libtss2-tcti-mssim0t64 \  # Simulator TCTI
    libtss2-tcti-swtpm0t64 \  # Software TPM TCTI
    libtss2-tctildr0t64       # TCTI loader
```

**TPM Software Stack (TSS2) Components:**
- **ESYS**: Enhanced System API - high-level TPM commands
- **TCTI**: TPM Command Transmission Interface - transport layer
  - `device`: Direct device access (`/dev/tpm0`, `/dev/tpmrm0`)
  - `tabrmd`: Access Broker and Resource Manager
  - `mssim`: Microsoft TPM Simulator
  - `swtpm`: Software TPM emulator

#### 2. Docker Socket Access

```dockerfile
# Install Docker CLI for docker.sock access
RUN apt-get install -y docker-ce-cli
```

**Purpose:**
- Query Docker API for container information
- Track mounted volumes and container metadata
- Enable container-aware license management

#### 3. User and Group Configuration

```dockerfile
# Add tss group with correct GID (113 from host)
RUN groupadd -g 113 tss 2>/dev/null || true

# Add docker group (typically GID 999)
RUN groupadd -g 999 docker 2>/dev/null || true

# Create application user (UID 1000)
RUN useradd -m -u 1000 -s /bin/bash tlm && \
    usermod -aG tss tlm && \
    usermod -aG docker tlm
```

**Critical GID Matching:**
- `tss:113` must match host GID for `/dev/tpmrm0` access
- `docker:999` must match host GID for `/var/run/docker.sock` access
- UID 1000 is standard non-root user

**Verify Host GIDs:**
```bash
# Check host tss group
getent group tss
# Expected: tss:x:113:

# Check host docker group
getent group docker
# Expected: docker:x:999: (or similar)
```

#### 4. Directory Structure

```dockerfile
# Create required directories
RUN mkdir -p /var/log/asperion/trustedLicensing \
             /etc/asperion/trustedLicensing/config \
             /etc/asperion/trustedLicensing/persistence && \
    chown -R 1000:1000 /var/log/asperion /etc/asperion
```

**Directory Mapping:**

| Container Path | Purpose | Files |
|----------------|---------|-------|
| `/var/log/asperion/trustedLicensing/` | Application logs | `Trusted License Manager__*.log` |
| `/etc/asperion/trustedLicensing/config/` | Configuration | `TLLicenseManager.json` |
| `/etc/asperion/trustedLicensing/persistence/` | Encrypted keys | `persistence.bin`, `vault.bin` |

#### 5. Security Configuration

```dockerfile
# Run as root for TPM access (TPM requires elevated privileges)
# USER tlm  # Commented out - TPM needs root

# Environment variables
ENV TPM_DEVICE=/dev/tpmrm0
ENV TSS2_TCTI=device:/dev/tpmrm0
ENV TPM2TOOLS_TCTI=device:/dev/tpmrm0
```

**Why Run as Root:**
- TPM device access requires elevated privileges
- Even with `tss` group membership, some TPM operations need root
- Container isolation provides security boundary

**Alternative Approaches:**
```dockerfile
# Option 1: Use capabilities instead of full root
CAP_ADD:
  - SYS_ADMIN
  - IPC_LOCK

# Option 2: Run as tlm user with device permissions
USER tlm
# Requires proper device permissions in docker-compose.yml
```

#### 6. Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:52014/health || exit 1
```

**REST API Health Endpoints:**
- `/health` - Simple health check (200 OK)
- `/status` - Detailed status including TPM connection
- `/fingerprint` - Hardware fingerprint (requires TPM)

---

### Docker Compose Configuration

**Location:** [_Container/Docker/Linux/docker-compose.yml](../_Container/Docker/Linux/docker-compose.yml)

#### Complete Service Definition

```yaml
version: '3.8'

services:
  tl-license-manager:
    build:
      context: .
      dockerfile: Dockerfile
    image: trustedlicensing:latest
    container_name: tl-license-manager
    hostname: tl-license-manager
    
    # TPM Device Passthrough
    devices:
      - /dev/tpm0:/dev/tpm0       # Direct TPM device
      - /dev/tpmrm0:/dev/tpmrm0   # Resource Manager (preferred)
    
    # Privileged mode for TPM hardware access
    privileged: true
    
    # Volume Mounts
    volumes:
      # Docker socket for container introspection
      - /var/run/docker.sock:/var/run/docker.sock
      # Application data (host → container)
      - ./_logs:/var/log/asperion/trustedLicensing
      - ./_config:/etc/asperion/trustedLicensing/config
      - ./_persistence:/etc/asperion/trustedLicensing/persistence
    
    # Group membership (must match host GIDs)
    group_add:
      - "113"  # tss group for TPM access
      - "999"  # docker group for socket access
    
    # Port Exposure
    ports:
      - "52014:52014"  # REST API
    
    # Environment Configuration
    environment:
      - TLM_LOG_LEVEL=INFO
      - TLM_REST_PORT=52014
      - TLM_REST_HOST=0.0.0.0
      - TPM_ENABLED=true
      - DOCKER_HOST=unix:///var/run/docker.sock
      - TPM2TOOLS_TCTI=device:/dev/tpmrm0
      - TSS2_TCTI=device:/dev/tpmrm0
    
    # Security Options
    security_opt:
      - no-new-privileges:true
    
    # Linux Capabilities (alternative to privileged)
    cap_add:
      - SYS_ADMIN  # TPM hardware access
      - IPC_LOCK   # Memory locking for secrets
    
    # Resource Limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
    
    # Restart Policy
    restart: unless-stopped
    
    # Health Check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:52014/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    
    # Logging Configuration
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

#### Key Configuration Elements

##### Device Passthrough

```yaml
devices:
  - /dev/tpm0:/dev/tpm0       # Character device major:minor 10:224
  - /dev/tpmrm0:/dev/tpmrm0   # Character device major:minor 10:225
```

**What Happens:**
1. Docker creates device nodes inside container with same major/minor numbers
2. Container processes can open and use TPM devices
3. Kernel enforces permission checks (requires `tss` group or root)

**Verify Inside Container:**
```bash
docker exec tl-license-manager ls -la /dev/tpm*
# Expected:
# crw-rw---- 1 tss tss 10, 224 Jan 31 10:00 /dev/tpm0
# crw-rw---- 1 tss tss 10, 225 Jan 31 10:00 /dev/tpmrm0
```

##### Privileged Mode

```yaml
privileged: true
```

**Implications:**
- Grants almost all capabilities to container
- Allows access to all host devices
- Disables AppArmor/SELinux confinement
- **Use with caution** - only in trusted environments

**Alternative (More Secure):**
```yaml
privileged: false
cap_add:
  - SYS_ADMIN
  - IPC_LOCK
devices:
  - /dev/tpm0:/dev/tpm0
  - /dev/tpmrm0:/dev/tpmrm0
```

##### Volume Mounts

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - ./_logs:/var/log/asperion/trustedLicensing
  - ./_config:/etc/asperion/trustedLicensing/config
  - ./_persistence:/etc/asperion/trustedLicensing/persistence
```

**Docker Socket Mount:**
- Provides Docker API access from within container
- TLLicenseManager queries container metadata
- Tracks volume mounts and container configuration
- **Security Risk**: Container can control Docker daemon (root access)

**Data Volume Mounts:**
- Host directories mapped to container paths
- Persists data across container restarts
- Allows backup and inspection from host

**Volume Permission Requirements:**
```bash
# Create and set permissions
mkdir -p _logs _config _persistence
sudo chown -R 1000:1000 _logs _config _persistence
chmod 755 _logs _config _persistence
chmod 600 _persistence/*  # Restrict encrypted files
```

##### Group Membership

```yaml
group_add:
  - "113"  # tss
  - "999"  # docker
```

**Purpose:**
- Add container's root user to supplementary groups
- Enables access to group-protected resources
- Must match host GID values

**Verify Configuration:**
```bash
# Check container user groups
docker exec tl-license-manager id

# Expected output:
# uid=0(root) gid=0(root) groups=0(root),113(tss),999(docker)
```

##### Environment Variables

```yaml
environment:
  - TPM2TOOLS_TCTI=device:/dev/tpmrm0
  - TSS2_TCTI=device:/dev/tpmrm0
```

**TCTI (TPM Command Transmission Interface) Configuration:**

| Variable | Purpose | Format |
|----------|---------|--------|
| `TPM2TOOLS_TCTI` | `tpm2-tools` command suite | `device:/dev/tpmrm0` |
| `TSS2_TCTI` | TSS2 library applications | `device:/dev/tpmrm0` |

**Other TCTI Options:**
```bash
# Device (default)
device:/dev/tpmrm0

# Access Broker
tabrmd:bus_name=com.intel.tss2.Tabrmd

# Simulator
mssim:host=localhost,port=2321

# Software TPM
swtpm:path=/tmp/swtpm-sock
```

---

## TPM Integration Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    TLLicenseManager                      │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         LicenseService (Business Logic)        │    │
│  └───────────────────┬────────────────────────────┘    │
│                      │                                   │
│  ┌───────────────────▼────────────────────────────┐    │
│  │              TLTPM_Service                      │    │
│  │  (High-level TPM Operations)                    │    │
│  └───────────────────┬────────────────────────────┘    │
│                      │                                   │
│  ┌───────────────────▼────────────────────────────┐    │
│  │            TpmCpp::Tpm2 Class                   │    │
│  │  (Microsoft TSS.C++ Wrapper)                    │    │
│  └───────────────────┬────────────────────────────┘    │
│                      │                                   │
│  ┌───────────────────▼────────────────────────────┐    │
│  │           TpmTbsDevice (Linux)                  │    │
│  │  Device Priority:                               │    │
│  │  1. /dev/tpm0 (direct)                          │    │
│  │  2. tabrmd (broker)                             │    │
│  │  3. /dev/tpmrm0 (resource manager) ✓            │    │
│  │  4. Socket TRM (127.0.0.1:2323)                 │    │
│  └───────────────────┬────────────────────────────┘    │
│                      │                                   │
└──────────────────────┼───────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │   Kernel TPM Resource Mgr   │
         │       /dev/tpmrm0           │
         └─────────────┬───────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │      TPM 2.0 Hardware       │
         │    (Physical or Virtual)    │
         └─────────────────────────────┘
```

### TPM Operations Flow

#### 1. Initialization (Cold Start)

```
Container Start
    │
    ├─> TLLicenseManager binary executes
    │
    ├─> PersistenceService::Initialize()
    │   ├─> Check for persistence.bin
    │   ├─> NOT FOUND → Cold Start
    │   │
    │   └─> Create TLTPM_Service()
    │       ├─> Select TPM device (/dev/tpmrm0)
    │       ├─> Open device: fd = open("/dev/tpmrm0", O_RDWR)
    │       ├─> Verify TPM connection
    │       └─> Query TPM capabilities
    │
    ├─> Generate Secrets
    │   ├─> spTPM->Randomize(16) → TPM_AUTH
    │   ├─> spTPM->Randomize(16) → TPM_SEED
    │   ├─> AESCrypt::GenerateIV() → Vault Key
    │   └─> AESCrypt::GenerateIV() → Vault IV
    │
    └─> LicenseService::Start()
        │
        ├─> Generate Local RSA Keys (Botan)
        │
        └─> Generate TPM Keys
            ├─> CreatePrimary(TPM_SEED) → Storage Root Key
            │   └─> Deterministic: Same seed = Same key
            │
            ├─> EvictControl() → Persist to handle 0x810003E8
            │   └─> NV slot 1000 (survives reboots)
            │
            ├─> Export SRK public key (PEM format)
            │
            └─> Store in encrypted vault.bin
```

#### 2. Warm Start (Existing Keys)

```
Container Restart
    │
    ├─> TLLicenseManager executes
    │
    ├─> PersistenceService::Initialize()
    │   ├─> Find persistence.bin → Warm Start
    │   ├─> Decrypt persistence.bin
    │   └─> Extract: TPM_AUTH, TPM_SEED, AES Keys
    │
    └─> LicenseService::Start()
        │
        ├─> Find vault.bin
        │
        ├─> Decrypt vault.bin
        │   └─> Load existing keys
        │
        ├─> Connect to TPM
        │   └─> TLTPM_Service() → Open /dev/tpmrm0
        │
        ├─> Access persistent SRK
        │   ├─> Handle: 0x810003E8
        │   ├─> Set auth: TPM_AUTH
        │   └─> Key immediately available (no loading)
        │
        └─> Ready for operations
```

#### 3. TPM Cryptographic Operations

```cpp
// Example: RSA Encryption with SRK
TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(1000);  // 0x810003E8
srkHandle.SetAuth(TPM_AUTH);

// Encrypt data
ByteVec encrypted = tpm.RSA_Encrypt(
    srkHandle,
    String2ByteVec(plaintext),
    TPMS_SCHEME_OAEP(TPM_ALG_ID::SHA256),
    null
);

// Decrypt data
ByteVec decrypted = tpm.RSA_Decrypt(
    srkHandle,
    encrypted,
    TPMS_SCHEME_OAEP(TPM_ALG_ID::SHA256),
    null
);
```

**TPM Operations Used:**
- `TPM2_CreatePrimary` - Generate deterministic primary key
- `TPM2_EvictControl` - Persist key to NV storage
- `TPM2_RSA_Encrypt` - Encrypt data with TPM key
- `TPM2_RSA_Decrypt` - Decrypt data with TPM key
- `TPM2_GetRandom` - Hardware random number generation
- `TPM2_Sign` - Digital signatures
- `TPM2_PCR_Read` - Platform Configuration Registers

---

## Build and Deployment Process

### Build Script Analysis

**Location:** [_Container/Docker/Linux/build_and_stage.sh](../_Container/Docker/Linux/build_and_stage.sh)

#### Script Workflow

```bash
#!/bin/bash
set -e  # Exit on error

# 1. Locate Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/out/build/linux-debug"
STAGING_DIR="${SCRIPT_DIR}/TLM"

# 2. Verify Build Exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found"
    exit 1
fi

# 3. Find TLLicenseManager Binary
TLM_BINARY=$(find "${BUILD_DIR}" -name "TLLicenseManager" -type f -executable)

# 4. Create Staging Directory
mkdir -p "${STAGING_DIR}"

# 5. Copy Binary
cp "${TLM_BINARY}" "${STAGING_DIR}/"

# 6. Copy Shared Libraries (if needed)
LIBS=$(ldd "${TLM_BINARY}" | grep "=> /" | awk '{print $3}' | grep -E "(libtss|libbotan)")
for lib in ${LIBS}; do
    cp "${lib}" "${STAGING_DIR}/lib/"
done

# 7. Set Permissions
chmod +x "${STAGING_DIR}/TLLicenseManager"

# 8. Build Docker Image
docker build -t trustedlicensing:latest .
```

#### Build Process Steps

1. **CMake Configuration**

```bash
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_C_COMPILER=gcc \
      -DCMAKE_CXX_COMPILER=g++ \
      -DINCLUDE_GRPC_SERVICE=OFF \
      -DTPM_ON=ON \
      -DFASTCRYPT=OFF \
      -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake \
      -S . \
      -B out/build/linux-debug \
      -G "Unix Makefiles"
```

**Key CMake Flags:**
- `TPM_ON=ON` - Enable TPM support (required)
- `INCLUDE_GRPC_SERVICE=OFF` - Disable gRPC (optional)
- `FASTCRYPT=OFF` - Production RSA key sizes (ON for testing only)

2. **Build Binary**

```bash
cmake --build out/build/linux-debug --target TLLicenseManager -j$(nproc)
```

3. **Stage for Docker**

```bash
cd _Container/Docker/Linux
./build_and_stage.sh
```

**Staging Output:**
```
TLM/
├── TLLicenseManager          # Main executable
└── lib/                      # Shared libraries (if needed)
    ├── libtss2-esys.so.0
    ├── libtss2-tcti-device.so.0
    └── libbotan-2.so.19
```

4. **Build Docker Image**

```bash
docker build -t trustedlicensing:latest .
```

5. **Deploy Container**

```bash
docker-compose up -d
```

### Complete Deployment Example

```bash
# 1. Build TLLicenseManager
cd /DEV/TL2
cmake -B out/build/linux-debug -DTPM_ON=ON
cmake --build out/build/linux-debug

# 2. Stage and Build Container
cd _Container/Docker/Linux
./build_and_stage.sh

# 3. Start Container
docker-compose up -d

# 4. Verify Deployment
docker-compose ps
docker-compose logs -f

# 5. Test TPM Access
docker exec tl-license-manager tpm2_getcap properties-fixed

# 6. Test REST API
curl http://localhost:52014/status
curl http://localhost:52014/fingerprint
```

---

## Security Considerations

### Threat Model

**Protected Against:**
- ✅ Software key extraction (keys in TPM hardware)
- ✅ Unauthorized container cloning (TPM-bound keys)
- ✅ License migration to different hardware
- ✅ Offline cryptographic attacks
- ✅ Memory dumping (with IPC_LOCK capability)

**Vulnerabilities:**
- ⚠️ **Privileged Container**: Full host device access
- ⚠️ **Docker Socket**: Root-equivalent Docker API access
- ⚠️ **Persistence Files**: Encrypted but keys in same container
- ⚠️ **No Network Isolation**: Direct host network access
- ⚠️ **TPM Replacement**: Key loss without seed backup

### Security Best Practices

#### 1. Minimize Privileges

```yaml
# Instead of privileged: true
privileged: false
cap_add:
  - SYS_ADMIN  # TPM only
cap_drop:
  - ALL
security_opt:
  - no-new-privileges:true
  - apparmor=docker-default
```

#### 2. Read-Only Root Filesystem

```yaml
read_only: true
tmpfs:
  - /tmp
  - /run
volumes:
  - ./_logs:/var/log/asperion/trustedLicensing:rw
```

#### 3. Docker Socket Alternatives

```yaml
# Option 1: Don't mount socket (disable container introspection)
# Remove: - /var/run/docker.sock:/var/run/docker.sock

# Option 2: Use Docker socket proxy (restricts API access)
# https://github.com/Tecnativa/docker-socket-proxy
```

#### 4. Network Isolation

```yaml
networks:
  tl-internal:
    driver: bridge
    internal: true  # No external connectivity

services:
  tl-license-manager:
    networks:
      - tl-internal
```

#### 5. Backup and Recovery

```bash
# Backup persistence data (includes encrypted keys)
tar -czf tl-backup-$(date +%Y%m%d).tar.gz \
    _config/ _persistence/

# Backup with encryption
tar -czf - _config/ _persistence/ | \
    gpg -c > tl-backup-$(date +%Y%m%d).tar.gz.gpg

# Restore
gpg -d tl-backup-20260131.tar.gz.gpg | tar -xzf -
```

#### 6. Audit Logging

```yaml
logging:
  driver: "syslog"
  options:
    syslog-address: "udp://syslog-server:514"
    tag: "tl-license-manager"

# Or JSON with log aggregation
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "10"
    labels: "tpm,license"
```

---

## Troubleshooting

### TPM Access Issues

#### Problem: "Unable to open tpm0, abrmd, or tpmrm0"

**Diagnosis:**
```bash
# Check device exists
ls -la /dev/tpm*

# Check inside container
docker exec tl-license-manager ls -la /dev/tpm*

# Verify kernel modules
lsmod | grep tpm

# Check dmesg for TPM errors
dmesg | grep -i tpm
```

**Solutions:**

1. **Missing Device Files**
```bash
# Load TPM kernel modules
sudo modprobe tpm_tis
sudo modprobe tpm_crb

# Verify devices appeared
ls -la /dev/tpm*
```

2. **Permission Denied**
```bash
# Check tss group membership
docker exec tl-license-manager id

# Verify GID matches
getent group tss  # Should be 113

# Fix docker-compose.yml if needed
group_add:
  - "113"  # Must match host tss GID
```

3. **Device Not Passed Through**
```yaml
# Verify docker-compose.yml
devices:
  - /dev/tpm0:/dev/tpm0
  - /dev/tpmrm0:/dev/tpmrm0  # Required!
```

#### Problem: "TPM_RC::RETRY" or "TPM_RC::TESTING"

**Cause:** TPM is performing self-tests

**Solution:**
```bash
# Wait for self-tests to complete
sleep 5

# Or trigger self-test explicitly
docker exec tl-license-manager tpm2_selftest --fulltest
```

#### Problem: "TPM_RC::LOCKOUT"

**Cause:** Too many failed authorization attempts

**Solution:**
```bash
# Check lockout status
docker exec tl-license-manager tpm2_getcap properties-variable | grep lockout

# Clear lockout (requires platform hierarchy auth)
docker exec tl-license-manager tpm2_clear -c p

# Or wait for timeout (typically 24 hours)
```

### Docker Socket Issues

#### Problem: "Cannot connect to Docker daemon"

**Diagnosis:**
```bash
# Check socket exists in container
docker exec tl-license-manager ls -la /var/run/docker.sock

# Test Docker CLI
docker exec tl-license-manager docker ps
```

**Solutions:**

1. **Socket Not Mounted**
```yaml
# Add to docker-compose.yml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

2. **Permission Denied**
```bash
# Check docker group GID
getent group docker

# Update docker-compose.yml
group_add:
  - "999"  # Match host docker GID
```

3. **SELinux Blocking**
```bash
# Allow container access (Fedora/RHEL)
chcon -Rt svirt_sandbox_file_t /var/run/docker.sock

# Or disable SELinux for testing
sudo setenforce 0
```

### Container Startup Issues

#### Problem: "Container exits immediately"

**Diagnosis:**
```bash
# Check container logs
docker-compose logs tl-license-manager

# Inspect exit code
docker inspect tl-license-manager | grep ExitCode
```

**Common Causes:**

1. **Missing Binary**
```bash
# Verify binary exists in image
docker run --rm trustedlicensing:latest ls -la /app/

# Rebuild if missing
cd _Container/Docker/Linux
./build_and_stage.sh
```

2. **Library Missing**
```bash
# Check dependencies
docker run --rm trustedlicensing:latest ldd /app/TLLicenseManager

# Install missing libraries in Dockerfile
RUN apt-get install -y libmissing.so
```

3. **Configuration Error**
```bash
# Check config file
cat _config/TLLicenseManager.json

# Validate JSON syntax
jq . _config/TLLicenseManager.json
```

### Performance Issues

#### Problem: Slow TPM Operations

**Cause:** Using `/dev/tpm0` instead of `/dev/tpmrm0`

**Solution:**
```bash
# Verify using resource manager
docker exec tl-license-manager cat /proc/self/fd/* 2>&1 | grep tpm

# Should show: /dev/tpmrm0 (not /dev/tpm0)

# Set TCTI environment explicitly
environment:
  - TSS2_TCTI=device:/dev/tpmrm0
```

#### Problem: High CPU Usage

**Cause:** Excessive TPM operations or logging

**Solutions:**

1. **Reduce Log Level**
```bash
# Edit docker-compose.yml
environment:
  - TLM_LOG_LEVEL=WARNING  # Instead of TRACE

# Or use CLI override
command: ["/app/TLLicenseManager", "--log-level", "warning"]
```

2. **Check for TPM Errors**
```bash
# Monitor for retry loops
docker-compose logs -f | grep -i "retry\|error"
```

### Data Persistence Issues

#### Problem: Keys Lost After Restart

**Cause:** Volume mounts not configured

**Solution:**
```yaml
# Verify persistent volumes
volumes:
  - ./_persistence:/etc/asperion/trustedLicensing/persistence

# Check files exist on host
ls -la _persistence/
# Should show: persistence.bin, vault.bin
```

#### Problem: "Permission denied" on persistence files

**Solution:**
```bash
# Fix ownership (container runs as UID 1000)
sudo chown -R 1000:1000 _persistence/

# Fix permissions
chmod 600 _persistence/*.bin
chmod 755 _persistence/
```

---

## Testing and Verification

### Basic TPM Tests

```bash
# 1. Verify TPM device access
docker exec tl-license-manager ls -la /dev/tpm*

# 2. Check TPM capabilities
docker exec tl-license-manager tpm2_getcap properties-fixed

# 3. Test random number generation
docker exec tl-license-manager tpm2_getrandom 16 --hex

# 4. Check PCR values
docker exec tl-license-manager tpm2_pcrread sha256

# 5. List persistent objects
docker exec tl-license-manager tpm2_getcap handles-persistent
```

### TLLicenseManager API Tests

```bash
# 1. Health check
curl http://localhost:52014/health

# 2. Status (includes TPM info)
curl http://localhost:52014/status | jq

# 3. Get fingerprint (requires TPM)
curl http://localhost:52014/fingerprint | jq

# 4. Fallback fingerprint (software)
curl http://localhost:52014/fingerprint/fallback | jq
```

### Docker Integration Tests

```bash
# 1. Verify Docker API access
docker exec tl-license-manager docker version

# 2. List containers (requires socket access)
docker exec tl-license-manager docker ps

# 3. Inspect self
docker exec tl-license-manager docker inspect tl-license-manager
```

### End-to-End Test Script

```bash
#!/bin/bash
set -e

echo "=== TLLicenseManager Docker TPM Integration Test ==="

# 1. Build and deploy
echo "Building and deploying..."
cd _Container/Docker/Linux
./build_and_stage.sh
docker-compose up -d

# 2. Wait for startup
echo "Waiting for service startup..."
sleep 10

# 3. Check container health
echo "Checking container health..."
docker-compose ps | grep -q "healthy" || {
    echo "ERROR: Container not healthy"
    docker-compose logs
    exit 1
}

# 4. Test TPM access
echo "Testing TPM access..."
docker exec tl-license-manager tpm2_getcap properties-fixed > /dev/null || {
    echo "ERROR: TPM access failed"
    exit 1
}

# 5. Test API
echo "Testing REST API..."
STATUS=$(curl -s http://localhost:52014/status)
echo "$STATUS" | jq -e '.tpmConnected == true' > /dev/null || {
    echo "ERROR: TPM not connected"
    echo "$STATUS" | jq
    exit 1
}

# 6. Test fingerprint generation
echo "Testing fingerprint generation..."
FP=$(curl -s http://localhost:52014/fingerprint)
echo "$FP" | jq -e '.fingerprint' > /dev/null || {
    echo "ERROR: Fingerprint generation failed"
    exit 1
}

echo "=== All tests passed! ==="
```

---

## References

### Documentation

- [TLLicenseManager Startup Sequence](TLLicenseManager_StartUp.md)
- [CLI Integration](CLI_Integration.md)
- [Dockerfile](_Container/Docker/Linux/Dockerfile)
- [Docker Compose](_Container/Docker/Linux/docker-compose.yml)

### External Resources

- [TPM 2.0 Specification](https://trustedcomputinggroup.org/resource/tpm-library-specification/)
- [Linux TPM Subsystem](https://www.kernel.org/doc/html/latest/security/tpm/index.html)
- [tpm2-tools Documentation](https://github.com/tpm2-software/tpm2-tools)
- [TSS2 API Specification](https://trustedcomputinggroup.org/resource/tss-system-level-api-and-tpm-command-transmission-interface-specification/)
- [Docker Security](https://docs.docker.com/engine/security/)

### Source Code

- [TLTpm/src/TpmDevice.cpp](../TLTpm/src/TpmDevice.cpp) - TPM device selection logic
- [TLCrypt/sources/src/TPMService.cpp](../TLCrypt/sources/src/TPMService.cpp) - High-level TPM operations
- [TLLicenseService/sources/src/PersistenceService.cpp](../TLLicenseService/sources/src/PersistenceService.cpp) - Persistence layer

---

**Document Version:** 1.0  
**Last Updated:** January 31, 2026  
**Maintainer:** TrustedLicensing Team

---

<!-- 
REGENERATION PROMPT:
Regenerate LinuxDocker_TPM.md documentation for TLLicenseManager TPM integration in Linux Docker containers.

SCOPE:
- TPM 2.0 device access in Linux (/dev/tpm0, /dev/tpmrm0)
- TPM Resource Manager advantages and usage
- Docker container configuration for TPM passthrough
- Dockerfile analysis and dependencies (tpm2-tools, TSS2 libraries)
- Docker Compose configuration (devices, volumes, groups, capabilities)
- Docker socket integration for container awareness
- TPM device selection priority in TpmDevice.cpp
- Build and deployment process (build_and_stage.sh workflow)
- Security considerations (privileged mode, capabilities, isolation)
- Troubleshooting common TPM/Docker issues
- Testing and verification procedures
- Persistent data management (persistence.bin, vault.bin)
- User/group configuration (tss, docker GIDs)
- Environment variables (TCTI configuration)

KEY FILES TO REVIEW:
- _Container/Docker/Linux/Dockerfile (container configuration)
- _Container/Docker/Linux/docker-compose.yml (service definition)
- _Container/Docker/Linux/build_and_stage.sh (build script)
- _Container/Docker/Linux/README.md (deployment guide)
- TLTpm/src/TpmDevice.cpp (TPM device selection, /dev/tpmrm0 priority)
- TLCrypt/sources/src/TPMService.cpp (TPM operations)
- TLLicenseService/sources/src/PersistenceService.cpp (initialization)

UPDATE TRIGGERS:
- Changes to Dockerfile or docker-compose.yml
- New TPM device access methods
- Security configuration updates
- Build process modifications
- Volume mount structure changes
- Permission or group requirements
- New troubleshooting scenarios

LAST UPDATED: January 31, 2026
-->
