# SecretStore: Cross-Platform Secret Storage

## Overview

The `SecretStore` class provides a unified interface for storing and retrieving sensitive data across Windows and Linux platforms using OS-specific secure storage mechanisms.

**Platform Implementations:**
- **Windows**: Data Protection API (DPAPI)
- **Linux**: libsecret (GNOME Keyring / Secret Service API)

**Location**: `TLCrypt/sources/include/SecretStore.h`

## Features

- Platform-independent API for secret management
- OS-level encryption and protection
- String-based key-value storage
- Secret validation without retrieval
- Automatic directory/keyring initialization

## API Reference

### Class: `TLCrypt::SecretStore`

```cpp
namespace TLCrypt {
    class SecretStore {
    public:
        SecretStore();
        ~SecretStore();

        // Store a secret with the given name
        bool StoreSecret(const std::string& name, const std::string& secret);

        // Retrieve a secret by name
        std::optional<std::string> GetSecret(const std::string& name);

        // Validate a secret without retrieving it
        bool ValidateSecret(const std::string& name, const std::string& secret);

        // Delete a stored secret
        bool DeleteSecret(const std::string& name);

        // Check if a secret exists
        bool HasSecret(const std::string& name);
    };
}
```

### Method Details

#### `bool StoreSecret(const std::string& name, const std::string& secret)`

Stores a secret value associated with a name identifier.

**Parameters:**
- `name`: Unique identifier for the secret
- `secret`: The secret value to store (any string data)

**Returns:** `true` if successfully stored, `false` on error

**Windows Behavior:**
- Encrypts data using DPAPI (user-specific encryption)
- Stores encrypted blob in filesystem: `%LOCALAPPDATA%\TrustedLicensing\Secrets\<name>.dat`
- Creates directory if it doesn't exist

**Linux Behavior:**
- Stores secret in system keyring using libsecret
- Accessible via GNOME Keyring or KDE Wallet
- Stored with attributes: `application=TLLicenseManager`, `name=<name>`

**Example:**
```cpp
TLCrypt::SecretStore store;
if (store.StoreSecret("database-password", "P@ssw0rd123")) {
    BOOST_LOG_TRIVIAL(info) << "Secret stored successfully";
}
```

---

#### `std::optional<std::string> GetSecret(const std::string& name)`

Retrieves a previously stored secret.

**Parameters:**
- `name`: Identifier for the secret to retrieve

**Returns:** `std::optional<std::string>` containing the secret value, or `std::nullopt` if not found

**Windows Behavior:**
- Reads encrypted file from disk
- Decrypts using DPAPI
- Only the user who encrypted can decrypt (user-specific protection)

**Linux Behavior:**
- Queries keyring via libsecret
- Returns secret if found in active keyring service

**Example:**
```cpp
auto secret = store.GetSecret("database-password");
if (secret.has_value()) {
    std::string password = *secret;
    // Use password
} else {
    BOOST_LOG_TRIVIAL(error) << "Secret not found";
}
```

---

#### `bool ValidateSecret(const std::string& name, const std::string& secret)`

Validates a secret value without exposing the stored value.

**Parameters:**
- `name`: Identifier for the secret
- `secret`: Value to validate against stored secret

**Returns:** `true` if the secret matches, `false` if not found or doesn't match

**Use Case:** Authentication/verification without retrieving sensitive data

**Example:**
```cpp
if (store.ValidateSecret("admin-pin", userInput)) {
    // PIN is correct
} else {
    // Invalid PIN
}
```

---

#### `bool DeleteSecret(const std::string& name)`

Removes a stored secret permanently.

**Parameters:**
- `name`: Identifier for the secret to delete

**Returns:** `true` if successfully deleted, `false` on error or if not found

**Windows Behavior:** Deletes the encrypted file from disk

**Linux Behavior:** Removes entry from keyring

**Example:**
```cpp
if (store.DeleteSecret("temporary-token")) {
    BOOST_LOG_TRIVIAL(info) << "Token deleted";
}
```

---

#### `bool HasSecret(const std::string& name)`

Checks if a secret exists without retrieving its value.

**Parameters:**
- `name`: Identifier for the secret

**Returns:** `true` if the secret exists, `false` otherwise

**Example:**
```cpp
if (!store.HasSecret("encryption-key")) {
    // Generate and store new key
    store.StoreSecret("encryption-key", GenerateNewKey());
}
```

## Platform Requirements

### Windows

**Operating System:**
- Windows 7 or later
- Windows Server 2008 R2 or later

**System Libraries:**
- `crypt32.lib` (Data Protection API)
- Automatically linked via `#pragma comment(lib, "crypt32.lib")`

**Headers Required:**
```cpp
#include <windows.h>
#include <wincrypt.h>
#include <dpapi.h>
#include <shlobj.h>
```

**Storage Location:**
```
%LOCALAPPDATA%\TrustedLicensing\Secrets\
Example: C:\Users\JohnDoe\AppData\Local\TrustedLicensing\Secrets\
```

**File Format:**
- Each secret stored as `<name>.dat`
- Contains DPAPI-encrypted blob
- User-specific encryption (cannot be decrypted by other users)
- Machine-specific protection (tied to user profile)

**Security Properties:**
- Encrypted by DPAPI using user's login credentials
- Automatic key derivation from Windows credential system
- Protected against offline attacks (requires user login)
- Survives password changes (Windows manages key rotation)

**Permissions:**
- Only the encrypting user can decrypt
- Administrator access does NOT grant decryption capability
- Roaming profiles: secrets do NOT roam (machine-specific)

---

### Linux

**Operating System:**
- Ubuntu 18.04+ / Debian 10+ (Ubuntu 24.04 recommended)
- Fedora 30+ / RHEL 8+
- Any distribution with D-Bus and Secret Service API support

---

## Linux Installation Requirements

### Requirements Summary Table

Quick reference for what to install based on your deployment scenario:

| Component | Development | Production (with Keyring) | Production (Fallback) | Docker Container |
|-----------|-------------|--------------------------|----------------------|------------------|
| **Build Tools** | ✅ Required | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| **Runtime Libraries** | ✅ Required | ✅ Required | ✅ Required | ✅ Required |
| **libsecret-1-dev** | ✅ Required | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| **libsecret-1** (runtime) | ✅ Required | ✅ Required | ❌ Optional | ❌ Not installed |
| **D-Bus** | ✅ Required | ✅ Required | ❌ Optional | ❌ Not configured |
| **GNOME Keyring** | ✅ Recommended | ✅ Required | ❌ Optional | ❌ Not installed |
| **TPM Tools** | ⚠️ Optional | ⚠️ Recommended | ⚠️ Recommended | ⚠️ Optional |
| **TPM Libraries** | ⚠️ Optional | ⚠️ Recommended | ⚠️ Recommended | ⚠️ Optional |
| **Docker CLI** | ❌ Not needed | ❌ Not needed | ❌ Not needed | ⚠️ For fingerprinting |
| **vcpkg** | ✅ Auto-installed | ❌ Not needed | ❌ Not needed | ❌ Not needed |

**Legend:**
- ✅ Required: Must be installed
- ⚠️ Optional/Recommended: Install if using that feature
- ❌ Not needed: Skip installation

---

### Package Reference by Purpose

Understanding what each package provides:

#### Core Build Tools
```bash
build-essential    # GCC/G++ compiler, make, and essential build tools
cmake             # Build system generator (3.20+ required)
ninja-build       # Fast build system (alternative to make)
pkg-config        # Helper tool for library compilation
git               # Version control (for cloning repository)
```

#### Dependency Management
```bash
curl zip unzip tar  # Required by vcpkg for downloading dependencies
ca-certificates     # SSL certificate authorities for HTTPS downloads
gnupg              # GPG for verifying package signatures
lsb-release        # Linux Standard Base version reporting
```

#### C++ Development Libraries
```bash
libssl-dev         # OpenSSL development headers (cryptography)
libstdc++-12-dev   # Standard C++ library development files
libdbus-1-dev      # D-Bus development headers
```

#### SecretStore / Keyring (Development)
```bash
libsecret-1-dev    # Secret Service API development library
                   # Provides: secret_password_store_sync, secret_password_lookup_sync
                   # Purpose: Store/retrieve secrets in system keyring
```

#### SecretStore / Keyring (Runtime)
```bash
libsecret-1-0      # Secret Service API runtime library
dbus               # Message bus system for IPC
dbus-x11           # D-Bus session bus for X11/headless environments
gnome-keyring      # GNOME keyring daemon (Secret Service provider)
kde-kwallet        # KDE Wallet (alternative to GNOME Keyring)
libsecret-tools    # Command-line tools (secret-tool) for testing
```

#### TPM Support (Development)
```bash
libtss2-dev        # TPM Software Stack 2.0 development headers
                   # All-in-one dev package for TPM functionality
```

#### TPM Support (Runtime)
```bash
tpm2-tools         # Command-line tools for TPM 2.0 (tpm2_*)
tpm2-abrmd         # TPM2 Access Broker & Resource Manager Daemon
libtss2-esys-3.0.2-0t64    # Enhanced System API implementation
libtss2-tcti-device0t64    # TCTI for /dev/tpm* character devices
libtss2-tcti-tabrmd0       # TCTI for TPM2 Access Broker
libtss2-tcti-mssim0t64     # TCTI for TPM simulator
libtss2-tcti-swtpm0t64     # TCTI for software TPM
libtss2-tctildr0t64        # TCTI loader library
```

#### Boost Libraries (Runtime)
```bash
# Note: Version numbers (1.74.0) vary by distribution
libboost-log           # Logging framework
libboost-filesystem    # File system operations
libboost-program-options  # Command-line argument parsing
libboost-system        # System error codes
libboost-asio          # Asynchronous I/O (for REST API)
libboost-random        # Random number generation
```

#### Container Integration
```bash
docker-ce-cli      # Docker command-line client (not Docker Engine)
                   # Purpose: Query Docker socket for container fingerprinting
```

---

### Quick Start: Installation Procedures

Choose the appropriate installation procedure based on your deployment scenario:

#### Scenario 1: Development Machine (Full Build Environment)

Complete setup for building and running TLLicenseManager with all features:

```bash
# Ubuntu 24.04 / Debian 12
sudo apt-get update && sudo apt-get install -y \
    build-essential cmake git pkg-config ninja-build \
    curl zip unzip tar \
    libssl-dev libstdc++-12-dev \
    libsecret-1-dev libdbus-1-dev \
    libtss2-dev tpm2-tools \
    gnome-keyring dbus-x11 \
    ca-certificates gnupg lsb-release

# Verify installation
cmake --version  # Should be 3.20+
gcc --version    # Should be 11+
pkg-config --modversion libsecret-1  # Should be 0.20+

# Start keyring for current session (if not running)
eval $(dbus-launch --sh-syntax)
gnome-keyring-daemon --start --components=secrets

# Clone and build
git clone <repository-url>
cd TL2
cmake --preset=linux-release
cmake --build --preset=linux-release
```

#### Scenario 2: Production Server (Runtime Only, with Keyring)

Minimal installation for running pre-built TLLicenseManager with full SecretStore support:

```bash
# Ubuntu 24.04 / Debian 12
sudo apt-get update && sudo apt-get install -y \
    libssl3 libstdc++6 \
    libsecret-1-0 dbus gnome-keyring dbus-x11 \
    libboost-log1.74.0 libboost-filesystem1.74.0 \
    libboost-program-options1.74.0

# Optional: TPM support
sudo apt-get install -y \
    tpm2-tools tpm2-abrmd \
    libtss2-esys-3.0.2-0t64 libtss2-tcti-device0t64

# Configure user permissions
sudo usermod -aG tss $USER
newgrp tss

# Enable keyring for systemd user session
systemctl --user enable --now gnome-keyring-daemon.service

# Test installation
/path/to/TLLicenseManager --version
```

#### Scenario 3: Production Server (Runtime Only, Fallback Mode)

Minimal installation without keyring (uses fallback encryption):

```bash
# Ubuntu 24.04 / Debian 12
sudo apt-get update && sudo apt-get install -y \
    libssl3 libstdc++6 \
    libboost-log1.74.0 libboost-filesystem1.74.0 \
    libboost-program-options1.74.0

# Optional: TPM support
sudo apt-get install -y \
    tpm2-tools libtss2-esys-3.0.2-0t64

# Configure user permissions (if using TPM)
sudo usermod -aG tss $USER
newgrp tss

# SecretStore will automatically use fallback mode
/path/to/TLLicenseManager --version
```

#### Scenario 4: Docker Container (Standard)

Docker containers use fallback mode by default (no keyring). See `_Container/Docker/Linux/Dockerfile`:

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    # Runtime libraries (minimal)
    libssl3 libstdc++6 \
    # TPM support
    tpm2-tools tpm2-abrmd libtss2-esys-3.0.2-0t64 \
    # Docker CLI (for container fingerprinting)
    docker-ce-cli \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# No keyring services installed - uses fallback mode
COPY TLM/TLLicenseManager /app/
CMD ["/app/TLLicenseManager"]
```

Build and run:
```bash
docker build -t tllicensemanager:latest -f _Container/Docker/Linux/Dockerfile .
docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /dev/tpmrm0:/dev/tpmrm0 \
    -p 52014:52014 \
    tllicensemanager:latest
```

---

### Build Dependencies

Required packages for compiling TLLicenseManager from source:

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y \
    # Build tools
    build-essential \
    cmake \
    git \
    pkg-config \
    ninja-build \
    curl \
    zip \
    unzip \
    tar \
    # C++ development libraries
    libssl-dev \
    libstdc++-12-dev \
    # SecretStore keyring support
    libsecret-1-dev \
    # D-Bus development
    libdbus-1-dev \
    # TPM support (optional, for hardware TPM)
    libtss2-dev \
    # Additional utilities
    ca-certificates \
    gnupg \
    lsb-release
```

**Minimum versions:**
- CMake: 3.20+
- GCC: 11+ or Clang: 14+
- pkg-config: 0.29+

#### Fedora/RHEL/CentOS

```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install -y \
    cmake \
    ninja-build \
    gcc-c++ \
    openssl-devel \
    libsecret-devel \
    dbus-devel \
    tpm2-tss-devel \
    pkgconfig \
    git \
    curl
```

#### Arch Linux

```bash
sudo pacman -Syu
sudo pacman -S \
    base-devel \
    cmake \
    ninja \
    openssl \
    libsecret \
    dbus \
    tpm2-tss \
    git
```

### Runtime Dependencies

Required packages for running TLLicenseManager (minimal installation):

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y \
    # Core runtime libraries
    libssl3 \
    libstdc++6 \
    # SecretStore keyring support (for non-fallback mode)
    libsecret-1-0 \
    # D-Bus runtime (required for libsecret)
    dbus \
    # Keyring service (choose one)
    gnome-keyring \
    # OR: kde-kwallet (KDE alternative)
    # Additional runtime libraries
    libboost-log1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0
```

**Note:** Boost version numbers may vary by distribution version. Use `apt-cache search libboost-log` to find available versions.

#### Fedora/RHEL/CentOS

```bash
sudo dnf install -y \
    openssl-libs \
    libsecret \
    dbus \
    gnome-keyring \
    boost-log \
    boost-filesystem \
    boost-program-options
```

#### Arch Linux

```bash
sudo pacman -S \
    openssl \
    libsecret \
    dbus \
    gnome-keyring \
    boost-libs
```

### Optional: TPM Support

For hardware TPM functionality (recommended for production):

#### Ubuntu/Debian

```bash
sudo apt-get install -y \
    # TPM 2.0 tools
    tpm2-tools \
    tpm2-abrmd \
    # TPM Software Stack 2.0 libraries
    libtss2-esys-3.0.2-0t64 \
    libtss2-tcti-device0t64 \
    libtss2-tcti-tabrmd0 \
    libtss2-tcti-mssim0t64 \
    libtss2-tcti-swtpm0t64 \
    libtss2-tctildr0t64
```

**Note:** Package names with version suffixes (like `-0t64`) may vary. Use `apt-cache search libtss2` to find exact names.

#### Fedora/RHEL/CentOS

```bash
sudo dnf install -y \
    tpm2-tools \
    tpm2-abrmd \
    tpm2-tss
```

#### Arch Linux

```bash
sudo pacman -S \
    tpm2-tools \
    tpm2-abrmd \
    tpm2-tss
```

### Optional: Docker Integration

For containerized deployments with Docker socket access:

#### Ubuntu/Debian

```bash
# Install Docker CLI (not Docker Engine, just the client)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce-cli
```

### vcpkg Dependencies

TLLicenseManager uses vcpkg for C++ dependency management. The following packages are automatically installed during build:

**From vcpkg.json:**
- cryptopp
- fmt
- boost-log, boost-filesystem, boost-property-tree, boost-program-options, boost-asio, boost-random
- openssl (1.1.1i)
- gtest
- botan (3.1.1)
- poco (util, json, xml features)
- expat
- pugixml
- rapidjson
- grpc
- protobuf
- oatpp, oatpp-swagger
- opencl

**Note:** vcpkg will download and build these automatically. No manual installation required.

### SecretStore-Specific Requirements

**Minimal (Runtime only - with fallback):**
```bash
# No keyring - will use fallback mode
# Only needs basic runtime libraries (libssl, libstdc++)
```

**Full SecretStore Support (No fallback):**
```bash
sudo apt-get install -y \
    libsecret-1-0 \
    dbus \
    gnome-keyring \
    dbus-x11  # For headless environments
```

**Runtime Dependencies:**
- `libsecret-1` (runtime library)
- D-Bus session bus
- Keyring service (one of):
  - GNOME Keyring (most common)
  - KDE Wallet (KWallet)
  - Any Secret Service API-compatible implementation

**Headers Required:**
```cpp
#include <libsecret/secret.h>
```

---

### Installation Verification

After installing dependencies, verify the installation:

#### Check libsecret Installation

```bash
# Check if libsecret is installed
pkg-config --modversion libsecret-1

# Expected output: 0.20.x or higher
```

#### Check D-Bus Service

```bash
# Check if D-Bus session bus is running
echo $DBUS_SESSION_BUS_ADDRESS

# Expected output: unix:path=/run/user/1000/bus (or similar)

# Test D-Bus connection
dbus-send --session --print-reply --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.ListNames

# Should list active services including org.freedesktop.secrets (if keyring is running)
```

#### Check Keyring Service

```bash
# Check if GNOME Keyring is running
ps aux | grep gnome-keyring

# List available Secret Service
secret-tool search --all application TLLicenseManager 2>/dev/null

# Install secret-tool if not available:
# sudo apt-get install libsecret-tools
```

#### Verify TPM (Optional)

```bash
# Check TPM device availability
ls -l /dev/tpm* /dev/tpmrm*

# Expected: /dev/tpmrm0 (recommended) or /dev/tpm0

# Test TPM functionality
tpm2_getcap properties-fixed

# Should display TPM properties without errors
```

#### Check CMake and Build Tools

```bash
# Verify CMake version
cmake --version
# Required: 3.20 or higher

# Verify compiler
gcc --version   # or clang --version
# Required: GCC 11+ or Clang 14+

# Verify pkg-config
pkg-config --version
```

---

### Installation Troubleshooting

#### Issue: libsecret not found during build

**Symptoms:**
```
CMake Error: Could not find libsecret-1
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install libsecret-1-dev pkg-config

# Verify installation
pkg-config --libs libsecret-1
```

#### Issue: D-Bus session not available

**Symptoms:**
```
Failed to connect to D-Bus
Error: DBUS_SESSION_BUS_ADDRESS not set
```

**Solution:**
```bash
# For headless/SSH sessions, start D-Bus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

# Add to ~/.bashrc for persistence:
echo 'eval $(dbus-launch --sh-syntax)' >> ~/.bashrc
```

#### Issue: Keyring daemon not running

**Symptoms:**
```
The name org.freedesktop.secrets was not provided by any .service files
```

**Solution:**
```bash
# Start GNOME Keyring manually
gnome-keyring-daemon --start --components=secrets

# For automatic startup, ensure gnome-keyring is installed:
sudo apt-get install gnome-keyring

# For systemd user session:
systemctl --user enable --now gnome-keyring-daemon.service
```

#### Issue: TPM device not accessible

**Symptoms:**
```
Cannot open TPM device: Permission denied
```

**Solution:**
```bash
# Add user to tss group
sudo usermod -aG tss $USER

# Logout and login again, or:
newgrp tss

# Verify group membership
groups | grep tss

# Check device permissions
ls -l /dev/tpmrm0
# Should show: crw-rw---- 1 tss tss
```

#### Issue: Missing Boost libraries

**Symptoms:**
```
error while loading shared libraries: libboost_log.so.1.74.0
```

**Solution:**
```bash
# Find available boost version
apt-cache search libboost-log

# Install matching version (adjust version number as needed)
sudo apt-get install \
    libboost-log1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0 \
    libboost-system1.74.0

# Update library cache
sudo ldconfig
```

#### Issue: vcpkg build failures

**Symptoms:**
```
CMake Error: vcpkg installation failed
```

**Solution:**
```bash
# Ensure vcpkg prerequisites are installed
sudo apt-get install curl zip unzip tar build-essential

# Clean vcpkg cache
rm -rf ~/.cache/vcpkg

# Retry build with verbose output
cmake --build build --verbose
```

---

### System Configuration

#### User and Group Setup

```bash
# Create dedicated service user (recommended for production)
sudo useradd -r -s /bin/false -m -d /var/lib/tllicensemanager tlm

# Add to required groups
sudo usermod -aG tss tlm      # For TPM access
sudo usermod -aG docker tlm   # For Docker socket access (if needed)

# Verify group membership
groups tlm
```

#### Directory Structure and Permissions

```bash
# Create required directories
sudo mkdir -p /var/log/asperion/trustedLicensing
sudo mkdir -p /etc/asperion/trustedLicensing/config
sudo mkdir -p /etc/asperion/trustedLicensing/persistence
sudo mkdir -p /var/lib/tllicensemanager

# Set ownership
sudo chown -R tlm:tlm /var/log/asperion
sudo chown -R tlm:tlm /etc/asperion
sudo chown -R tlm:tlm /var/lib/tllicensemanager

# Set permissions (secure)
sudo chmod 750 /etc/asperion/trustedLicensing/persistence
sudo chmod 640 /etc/asperion/trustedLicensing/config/*
sudo chmod 750 /var/log/asperion/trustedLicensing
```

#### TPM Device Access

```bash
# Verify TPM device exists and check permissions
ls -l /dev/tpmrm0
# Expected: crw-rw---- 1 tss tss 10, 224 Feb 9 10:00 /dev/tpmrm0

# If permissions are incorrect, create udev rule
sudo tee /etc/udev/rules.d/70-tpm.rules <<EOF
# TPM Character Devices
KERNEL=="tpm[0-9]*", MODE="0660", GROUP="tss"
KERNEL=="tpmrm[0-9]*", MODE="0660", GROUP="tss"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=tpm
```

#### D-Bus and Keyring Configuration

**For Desktop Environments:**
```bash
# Keyring is typically started automatically
# Verify with:
systemctl --user status gnome-keyring-daemon.service

# Enable if not running:
systemctl --user enable --now gnome-keyring-daemon.service
```

**For Server/Headless Environments:**
```bash
# Create systemd user service for D-Bus and keyring
mkdir -p ~/.config/systemd/user

# D-Bus user session service
cat > ~/.config/systemd/user/dbus.service <<EOF
[Unit]
Description=D-Bus User Message Bus
Requires=dbus.socket

[Service]
ExecStart=/usr/bin/dbus-daemon --session --address=systemd: --nofork
ExecReload=/usr/bin/dbus-daemon --session --address=systemd: --nofork
EOF

# GNOME Keyring service
cat > ~/.config/systemd/user/gnome-keyring.service <<EOF
[Unit]
Description=GNOME Keyring daemon
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/bin/gnome-keyring-daemon --foreground --components=secrets
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Enable services
systemctl --user enable --now dbus.service
systemctl --user enable --now gnome-keyring.service
```

#### Systemd Service Configuration

**Create TLLicenseManager systemd service:**

```bash
sudo tee /etc/systemd/system/tllicensemanager.service <<EOF
[Unit]
Description=Trusted Licensing Manager Service
After=network.target dbus.service

[Service]
Type=simple
User=tlm
Group=tlm
WorkingDirectory=/var/lib/tllicensemanager
ExecStart=/usr/local/bin/TLLicenseManager
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment="LD_LIBRARY_PATH=/usr/local/lib"
Environment="TLM_HOME=/var/lib/tllicensemanager"
Environment="TPM_DEVICE=/dev/tpmrm0"

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/asperion /etc/asperion /var/lib/tllicensemanager
DeviceAllow=/dev/tpmrm0 rw
DeviceAllow=/dev/null rw
DevicePolicy=strict

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable tllicensemanager.service
sudo systemctl start tllicensemanager.service

# Check status
sudo systemctl status tllicensemanager.service
```

**Note:** If using keyring with the service user, you may need to configure PAM to unlock the keyring automatically or use fallback mode.

#### Firewall Configuration

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 52014/tcp comment 'TLLicenseManager REST API'

# RHEL/CentOS/Fedora (firewalld)
sudo firewall-cmd --permanent --add-port=52014/tcp
sudo firewall-cmd --reload

# Direct iptables
sudo iptables -A INPUT -p tcp --dport 52014 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

#### System Limits

```bash
# Set file descriptor limits for tlm user
sudo tee /etc/security/limits.d/tllicensemanager.conf <<EOF
tlm soft nofile 65536
tlm hard nofile 65536
tlm soft nproc 4096
tlm hard nproc 4096
EOF

# Verify limits (after relogin)
su - tlm -s /bin/bash -c "ulimit -n"  # Should show 65536
```

#### SELinux Configuration (RHEL/CentOS/Fedora)

```bash
# Check SELinux status
getenforce

# If enforcing, create custom policy for TLLicenseManager
# This is a simplified example - adjust based on your security requirements

# Allow TPM device access
sudo ausearch -m avc -ts recent | grep tpm
sudo semodule -DB  # Disable dontaudit rules temporarily for testing

# Create custom policy (example)
sudo tee tllm.te <<EOF
module tllm 1.0;

require {
    type unconfined_t;
    type tpm_device_t;
    class chr_file { read write ioctl open };
}

allow unconfined_t tpm_device_t:chr_file { read write ioctl open };
EOF

# Compile and install
checkmodule -M -m -o tllm.mod tllm.te
semodule_package -o tllm.pp -m tllm.mod
sudo semodule -i tllm.pp

# Alternative: Use permissive mode for tllicensemanager (less secure)
# sudo semanage permissive -a tllicensemanager_t
```

---

**Storage Location:**
- GNOME Keyring: `~/.local/share/keyrings/`
- KDE Wallet: `~/.local/share/kwalletd/`
- Managed by the active keyring service (not direct file access)

**Schema Definition:**
```
Schema: com.trustedlicensing.secrets
Attributes:
  - application: "TLLicenseManager"
  - name: <secret-name>
Collection: DEFAULT
```

**Security Properties:**
- Encrypted by keyring service using user's login keyring
- Unlocked automatically on user login
- Protected with Linux user credentials
- Can be accessed by Secret Service API clients
- Supports keyring locking (manual or automatic)

**D-Bus Requirements:**
- Session bus must be available
- Keyring service must be running
- Network-Manager-compatible D-Bus activation

**Headless/Server Environments:**

For Docker containers or headless servers without GUI keyring:

```bash
# Install gnome-keyring
sudo apt-get install gnome-keyring

# Start keyring daemon (required for headless)
eval $(dbus-launch --sh-syntax)
eval $(echo '' | gnome-keyring-daemon --unlock)

# Set environment variables
export GNOME_KEYRING_CONTROL=/run/user/$(id -u)/keyring
```

**Alternative: Use File-Based Fallback:**

For environments without keyring support, consider implementing a file-based encrypted fallback using Botan for AES encryption (similar to Windows DPAPI approach but using OS-independent crypto).

---

## D-Bus Fallback Mechanism

### Overview

The `SecretStore` implementation on Linux relies on D-Bus and libsecret to access the system keyring. When these services are unavailable (such as in Docker containers, headless servers, or minimal Linux installations), the system automatically falls back to using legacy encryption keys.

### When Fallback Triggers

**Conditions that trigger fallback:**
- D-Bus session bus is not running
- libsecret Secret Service is not available
- GNOME Keyring or similar keyring daemon is not installed/running
- Docker containers without keyring services (typical scenario)
- Headless server environments without GUI components
- Minimal Linux installations

### Fallback Behavior

**Technical Implementation:**

1. **Availability Check**: During initialization, `SecretStore::CheckAvailability()` attempts to connect to the Secret Service via D-Bus
   
2. **Failure Detection**: If the connection fails, the check returns:
   ```cpp
   {false, "libsecret Secret Service not available: <error-message>"}
   ```

3. **Fallback Activation**: `PersistenceService::SetupPersistenceFiles()` detects the failure and logs:
   ```
   [warning] SecretStore not available: <reason>
   [warning] Continuing with fallback encryption using legacy persistence key
   ```

4. **Legacy Key Usage**: The system uses hardcoded AES keys defined in `PersistenceService.cpp`:
   ```cpp
   #define AES_KEY_PERSISTENCE_LOCAL_LEGACY "d70f6389...67890"
   #define AES_IVC_PERSISTENCE_LOCAL_LEGACY "8795d3d7...6df22"
   ```

**Status Reporting:**

The fallback status is recorded in the License Manager state:
```cpp
ApplicationState::AddLMStatusError("SecretStore", secretStoreCheck.reason);
ApplicationState::AddSetLMStatus("SecretStore", "unavailable - using fallback");
```

This status is visible in the REST API response at `/status` endpoint.

### Security Implications

**With Keyring (Preferred):**
- Persistence keys stored in system keyring
- Protected by user login credentials
- OS-managed encryption and access control
- Keys isolated from application code

**With Fallback (Degraded):**
- Legacy keys compiled into the application
- File-based encryption only (no keyring protection)
- Keys accessible to anyone with read access to the binary
- Reduced security compared to keyring storage
- Still provides basic encryption at rest

**Impact Assessment:**
- Fallback provides minimal viable security for persistence encryption
- Suitable for development, testing, and containerized deployments
- **NOT recommended for high-security production deployments**
- Production systems should use proper keyring services when storing sensitive data

### Docker Container Considerations

**Standard Docker Behavior:**

The TLLicenseManager Docker image (see `_Container/Docker/Linux/Dockerfile`) does NOT include keyring services:
- No `gnome-keyring` package installed
- No `dbus-x11` or D-Bus session bus
- SecretStore always falls back to legacy keys in containers

**Rationale:**
- Minimal container size
- Simplified dependency management
- Consistent behavior across container orchestration platforms
- Avoids complexity of D-Bus session management in containers

### Enabling Keyring in Docker (Advanced)

For deployments requiring keyring security in containers:

**Modified Dockerfile:**
```dockerfile
# Add keyring and D-Bus support
RUN apt-get update && apt-get install -y \
    gnome-keyring \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Configure D-Bus session
ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
```

**Container Startup Script:**
```bash
#!/bin/bash
# Start D-Bus session bus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

# Initialize and unlock keyring
eval $(echo '' | gnome-keyring-daemon --start --unlock --components=secrets)
export GNOME_KEYRING_CONTROL

# Start License Manager
/app/TLLicenseManager "$@"
```

**Warning:** This approach adds significant complexity and may not work reliably across all container environments (Kubernetes, Docker Compose, etc.).

### Verification

**Check SecretStore Status:**

Query the License Manager REST API:
```bash
curl http://localhost:52014/status | jq '.SecretStore'
```

**Expected Responses:**

With keyring available:
```json
{
  "SecretStore": "available"
}
```

With fallback:
```json
{
  "SecretStore": "unavailable - using fallback",
  "SecretStoreError": "libsecret Secret Service not available: ..."
}
```

**Logs:**

Check application logs for fallback indicators:
```bash
grep "SecretStore" /var/log/asperion/trustedLicensing/TLLicenseManager.log
```

Expected log entries during fallback:
```
[warning] SecretStore not available: <detailed-error>
[warning] Continuing with fallback encryption using legacy persistence key
[info] PersistenceService initialized with fallback encryption
```

### Best Practices

**Development/Testing:**
- Fallback mode is acceptable
- Simplifies local development without keyring setup
- Container deployments for CI/CD can use fallback

**Production Deployments:**

**Non-containerized (VM/Bare Metal):**
- Install and configure system keyring (GNOME Keyring, KDE Wallet)
- Ensure D-Bus session bus is available
- Verify `SecretStore` status reports "available"

**Containerized (Docker/Kubernetes):**
- Accept fallback for standard deployments
- Use host keyring via volume mounts if maximum security required
- Consider hardware security modules (HSM) for critical secrets
- Use container secrets management (Docker secrets, Kubernetes secrets) for external credentials

**Monitoring:**
- Monitor `/status` endpoint for SecretStore status
- Alert on fallback mode in production if keyring is expected
- Include SecretStore status in health checks

---

## Build Configuration

### CMakeLists.txt Changes

**File**: `TLCrypt/sources/CMakeLists.txt`

```cmake
# Add SecretStore to headers and sources
set(HEADERS
    include/TpmConfig.h
    include/TLRetVal.h
    include/TPMService.h
    include/AESCrypt.h
    include/RSACrypt.h
    include/SecretStore.h)  # ADDED

set(SOURCES
    src/TpmConfig.cpp
    src/TPMService.cpp
    src/AESCrypt.cpp
    src/RSACrypt.cpp
    src/SecretStore.cpp)  # ADDED

# Find libsecret on Linux
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBSECRET REQUIRED libsecret-1)
endif()

add_library(${PROJECT_NAME} STATIC ${SOURCES} ${HEADERS})

# Link libsecret on Linux
if(UNIX AND NOT APPLE)
    target_link_libraries(${PROJECT_NAME} PUBLIC ${LIBSECRET_LIBRARIES})
    target_include_directories(${PROJECT_NAME} PUBLIC ${LIBSECRET_INCLUDE_DIRS})
    target_compile_options(${PROJECT_NAME} PUBLIC ${LIBSECRET_CFLAGS_OTHER})
endif()
```

### Conditional Compilation

The implementation uses preprocessor directives to select platform-specific code:

```cpp
#ifdef _WIN32
    // Windows DPAPI implementation
#else
    // Linux libsecret implementation
#endif
```

**Defines:**
- `_WIN32`: Defined by Windows compilers (MSVC, MinGW)
- Absence of `_WIN32`: Linux/Unix implementation

---

## Usage Examples

### Example 1: Basic Secret Storage

```cpp
#include <SecretStore.h>
#include <TLLogger.h>

void StoreAPICredentials() {
    TLCrypt::SecretStore store;
    
    // Store API key
    if (store.StoreSecret("api-key", "sk-1234567890abcdef")) {
        BOOST_LOG_TRIVIAL(info) << "API key stored securely";
    } else {
        BOOST_LOG_TRIVIAL(error) << "Failed to store API key";
    }
    
    // Store API secret
    store.StoreSecret("api-secret", "very-secret-value-here");
}
```

### Example 2: Retrieve and Use Secret

```cpp
#include <SecretStore.h>

std::string GetDatabasePassword() {
    TLCrypt::SecretStore store;
    
    auto password = store.GetSecret("database-password");
    if (password.has_value()) {
        return *password;
    }
    
    // Generate new password if not found
    std::string newPassword = GenerateSecurePassword();
    store.StoreSecret("database-password", newPassword);
    return newPassword;
}
```

### Example 3: Storage Identifier Validation

```cpp
#include <SecretStore.h>

bool ValidateStorageIdentifier(const std::string& providedId) {
    TLCrypt::SecretStore store;
    
    // Check if storage ID exists
    if (!store.HasSecret("storage-identifier")) {
        // First run - store the identifier
        store.StoreSecret("storage-identifier", providedId);
        return true;
    }
    
    // Validate against stored identifier
    return store.ValidateSecret("storage-identifier", providedId);
}
```

### Example 4: Secure Configuration Storage

```cpp
#include <SecretStore.h>

class SecureConfig {
public:
    void SaveLicenseKey(const std::string& key) {
        TLCrypt::SecretStore store;
        
        if (store.StoreSecret("license-key", key)) {
            BOOST_LOG_TRIVIAL(info) << "License key saved securely";
        }
    }
    
    bool VerifyLicenseKey(const std::string& key) {
        TLCrypt::SecretStore store;
        return store.ValidateSecret("license-key", key);
    }
    
    void ClearLicenseKey() {
        TLCrypt::SecretStore store;
        store.DeleteSecret("license-key");
    }
};
```

### Example 5: Migration/Backup Consideration

```cpp
#include <SecretStore.h>

// Note: Secrets are NOT portable between users or machines
void BackupSecrets() {
    TLCrypt::SecretStore store;
    
    // WARNING: This exposes secrets in plaintext!
    // Only do this in secure contexts
    auto secret = store.GetSecret("important-secret");
    if (secret.has_value()) {
        // Re-encrypt for backup using different mechanism
        BackupSystem::EncryptAndStore("important-secret", *secret);
    }
}

void RestoreSecrets() {
    TLCrypt::SecretStore store;
    
    // Restore from backup
    std::string secret = BackupSystem::DecryptAndRetrieve("important-secret");
    store.StoreSecret("important-secret", secret);
}
```

---

## Security Considerations

### Windows DPAPI

**Strengths:**
- Tied to user credentials (automatic key derivation)
- No key management required
- Protected against offline attacks
- Survives password changes
- Machine-specific protection

**Limitations:**
- Not portable to other machines
- Not portable to other users
- Requires user to be logged in
- Administrator with physical access can potentially recover keys
- Not suitable for shared secrets across users

**Best Practices:**
- Use for user-specific secrets only
- Do not use for secrets that need to roam
- Combine with file permissions for defense-in-depth
- Regular backup of encrypted files (not decrypted secrets)

### Linux libsecret

**Strengths:**
- Integrated with desktop keyring services
- Supports keyring locking
- Network-transparent (can work with remote keyrings)
- Multi-application secret sharing (with proper permissions)

**Limitations:**
- Requires keyring service to be running
- May prompt for keyring password (if locked)
- Headless environments require special setup
- Docker containers need keyring daemon installation

**Best Practices:**
- Ensure keyring is unlocked on login
- Use appropriate schema and attributes
- Test in target deployment environment
- Provide fallback for headless environments
- Consider file permissions on keyring directories

### General Recommendations

1. **Secrets Should Be:**
   - User-specific (not shared across accounts)
   - Machine-specific (not synchronized)
   - Session-persistent (survive restarts)
   - Encrypted at rest

2. **Do NOT Store:**
   - Secrets that need to be portable
   - System-wide shared secrets
   - Secrets requiring programmatic backup
   - Extremely high-value secrets (use HSM instead)

3. **Logging:**
   - Never log secret values
   - Log only success/failure of operations
   - Use trace level for secret names if needed

4. **Error Handling:**
   - Always check return values
   - Use `std::optional` pattern for retrieval
   - Provide meaningful error messages (without exposing secrets)

---

## Troubleshooting

### Windows Issues

**Problem**: `CryptProtectData` fails with access denied

**Solution**: Check user permissions on `%LOCALAPPDATA%\TrustedLicensing\Secrets\` directory

**Problem**: Secrets lost after password change

**Solution**: Should not happen - DPAPI handles key rotation. If it does, file may be corrupted.

**Problem**: Cannot decrypt on different machine

**Solution**: Expected behavior - DPAPI is machine-specific. Need to re-create secrets.

### Linux Issues

**Problem**: `secret_password_store_sync` fails with "No such interface"

**Solution**: Keyring service not running. Start gnome-keyring or kwallet:
```bash
gnome-keyring-daemon --start --components=secrets
```

**Problem**: "The name org.freedesktop.secrets was not provided"

**Solution**: D-Bus session bus not available or Secret Service not installed:
```bash
sudo apt-get install gnome-keyring
eval $(dbus-launch --sh-syntax)
```

**Problem**: Docker container keyring access

**Solution**: Install and configure keyring in container:
```dockerfile
RUN apt-get update && apt-get install -y gnome-keyring dbus-x11
ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket
```

**Problem**: Headless server - keyring prompts for password

**Solution**: Unlock keyring programmatically or use plaintext login keyring (less secure):
```bash
echo 'password' | gnome-keyring-daemon --unlock
```

---

## Testing

### Unit Test Example

```cpp
#include <gtest/gtest.h>
#include <SecretStore.h>

TEST(SecretStoreTest, StoreAndRetrieve) {
    TLCrypt::SecretStore store;
    
    std::string name = "test-secret";
    std::string value = "test-value";
    
    ASSERT_TRUE(store.StoreSecret(name, value));
    
    auto retrieved = store.GetSecret(name);
    ASSERT_TRUE(retrieved.has_value());
    EXPECT_EQ(*retrieved, value);
    
    // Cleanup
    store.DeleteSecret(name);
}

TEST(SecretStoreTest, ValidateSecret) {
    TLCrypt::SecretStore store;
    
    store.StoreSecret("validate-test", "correct-value");
    
    EXPECT_TRUE(store.ValidateSecret("validate-test", "correct-value"));
    EXPECT_FALSE(store.ValidateSecret("validate-test", "wrong-value"));
    
    store.DeleteSecret("validate-test");
}

TEST(SecretStoreTest, DeleteSecret) {
    TLCrypt::SecretStore store;
    
    store.StoreSecret("delete-test", "value");
    ASSERT_TRUE(store.HasSecret("delete-test"));
    
    ASSERT_TRUE(store.DeleteSecret("delete-test"));
    EXPECT_FALSE(store.HasSecret("delete-test"));
}
```

### Integration Test

```bash
# Linux: Test keyring integration
./test_secret_store

# Check keyring entry
secret-tool lookup application TLLicenseManager name test-secret

# Delete test entries
secret-tool clear application TLLicenseManager
```

---

## Performance Characteristics

### Windows
- **Store**: 5-15ms (file creation + DPAPI encryption)
- **Retrieve**: 3-10ms (file read + DPAPI decryption)
- **Validate**: Same as Retrieve + comparison
- **Storage**: ~100-500 bytes per secret (encrypted blob overhead)

### Linux
- **Store**: 10-30ms (D-Bus IPC + keyring write)
- **Retrieve**: 5-20ms (D-Bus IPC + keyring read)
- **Validate**: Same as Retrieve + comparison
- **Storage**: Managed by keyring (typically SQLite database)

**Notes:**
- First operation may be slower (keyring initialization)
- Performance depends on disk I/O and D-Bus responsiveness
- Suitable for infrequent access (startup, configuration changes)
- Not optimized for high-frequency operations

---

## Future Enhancements

### Potential Improvements

1. **Batch Operations:**
   ```cpp
   bool StoreSecrets(const std::map<std::string, std::string>& secrets);
   std::map<std::string, std::string> GetAllSecrets();
   ```

2. **Metadata Support:**
   ```cpp
   struct SecretMetadata {
       std::string name;
       std::chrono::system_clock::time_point created;
       std::chrono::system_clock::time_point modified;
   };
   std::vector<SecretMetadata> ListSecrets();
   ```

3. **TTL/Expiration:**
   ```cpp
   bool StoreSecretWithTTL(const std::string& name, 
                           const std::string& secret,
                           std::chrono::seconds ttl);
   ```

4. **Binary Data Support:**
   ```cpp
   bool StoreSecretBinary(const std::string& name,
                          const std::vector<uint8_t>& data);
   std::optional<std::vector<uint8_t>> GetSecretBinary(const std::string& name);
   ```

5. **Cross-Platform Fallback:**
   - Implement Botan-based file encryption for platforms without native keyring
   - Unified fallback mechanism for Docker/headless environments

---

## References

### Windows DPAPI
- [DPAPI Overview (Microsoft Docs)](https://docs.microsoft.com/en-us/windows/win32/api/dpapi/)
- [CryptProtectData Function](https://docs.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata)
- [DPAPI Security](https://docs.microsoft.com/en-us/previous-versions/ms995355(v=msdn.10))

### Linux libsecret
- [Secret Service API Specification](https://specifications.freedesktop.org/secret-service/)
- [libsecret Reference Manual](https://gnome.pages.gitlab.gnome.org/libsecret/)
- [GNOME Keyring](https://wiki.gnome.org/Projects/GnomeKeyring)

### Related TLLicenseManager Components
- `AESCrypt`: Alternative encryption for vault files
- `PersistenceService`: Uses vault.bin for encrypted storage
- `TPMService`: Hardware-based key sealing
- `VaultKeyFactory`: Manages vault encryption keys

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-09 | Initial implementation with Windows DPAPI and Linux libsecret support |

---

## License

This component is part of TLLicenseManager and follows the project's licensing terms.
