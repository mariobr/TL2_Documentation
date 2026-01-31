# TLLicenseManager Linux Deployment Scripts

This directory contains bash scripts for deploying and managing the TLLicenseManager service on Linux systems.

## Overview

TLLicenseManager can run as a systemd daemon on Linux systems with full TPM 2.0 support. These scripts automate the deployment, installation, and management of the service.

## Scripts

### 1. copy-build-output.sh

Copies the built TLLicenseManager executable and dependencies from the build directory to the deployment folder.

**Usage:**
```bash
./copy-build-output.sh [release|debug] [--force]
```

**Examples:**
```bash
# Copy release build (default)
./copy-build-output.sh

# Copy debug build
./copy-build-output.sh debug

# Force overwrite existing files
./copy-build-output.sh release --force
```

**Build Configurations:**
- `release` - Copies from `out/build/linux-release/`
- `debug` - Copies from `out/build/linux-debug/`

### 2. install-tllicensemanager.sh

Installs or removes TLLicenseManager as a systemd service with daemon support.

**Usage:**
```bash
sudo ./install-tllicensemanager.sh [OPTIONS]
```

**Options:**
- `--remove` - Remove the service instead of installing
- `--service-path PATH` - Custom path to TLLicenseManager binary
- `--rest-port PORT` - REST API port (default: 52014)
- `--grpc-port PORT` - gRPC port (default: 52013)
- `--skip-firewall` - Skip firewall configuration
- `--help` - Show help message

**Examples:**
```bash
# Install with default settings
sudo ./install-tllicensemanager.sh

# Install with custom ports
sudo ./install-tllicensemanager.sh --rest-port 8080 --grpc-port 8081

# Remove the service
sudo ./install-tllicensemanager.sh --remove

# Install without firewall configuration
sudo ./install-tllicensemanager.sh --skip-firewall
```

## Quick Start

### 1. Build the Project

First, build TLLicenseManager using CMake:

```bash
# Configure
cmake --preset linux-release

# Build
cmake --build out/build/linux-release
```

### 2. Copy Build Output

Copy the built files to the deployment directory:

```bash
cd scripts/Linux
./copy-build-output.sh release
```

### 3. Install the Service

Install TLLicenseManager as a systemd daemon:

```bash
sudo ./install-tllicensemanager.sh
```

The installer will:
- Check for TPM availability
- Create application directories
- Configure systemd service
- Optionally configure firewall rules
- Start the service (if requested)

### 4. Verify Installation

Check service status:

```bash
sudo systemctl status asperionLM
```

View logs:

```bash
sudo journalctl -u asperionLM -f
```

Test REST API:

```bash
curl http://localhost:52014/status
```

## Service Management

The service is installed as `asperionLM` and managed using systemd:

### Start/Stop/Restart

```bash
sudo systemctl start asperionLM
sudo systemctl stop asperionLM
sudo systemctl restart asperionLM
```

### Enable/Disable Auto-Start

```bash
sudo systemctl enable asperionLM   # Start on boot
sudo systemctl disable asperionLM  # Don't start on boot
```

### View Status

```bash
sudo systemctl status asperionLM
```

### View Logs

```bash
# Follow logs in real-time
sudo journalctl -u asperionLM -f

# View last 50 lines
sudo journalctl -u asperionLM -n 50

# View logs since last boot
sudo journalctl -u asperionLM -b
```

## Directory Structure

After installation, the following directories are created:

```
/var/lib/TrustedLicensing/
├── Persistence/    # License and state data
└── Logs/          # Application logs

/etc/TrustedLicensing/
└── Config/        # Configuration files
```

## Daemon Mode

The service runs as a daemon with the following characteristics:

- **Service Type:** `simple` (foreground process managed by systemd)
- **Restart Policy:** Automatic restart on failure (up to 5 times in 5 minutes)
- **Logging:** Logs to systemd journal (viewable with `journalctl`)
- **User:** Runs as root for TPM access
- **Network:** Starts after network is available

The daemon mode is automatically enabled when running as a systemd service. The `application.runAsDaemon` configuration is handled by the Poco ServerApplication framework.

## TPM Support

### TPM Device Access

The service requires access to TPM devices:
- `/dev/tpm0` - Direct TPM access
- `/dev/tpmrm0` - TPM Resource Manager (preferred)

### TPM Requirements

- TPM 2.0 hardware or firmware TPM
- `tpm2-tools` package (optional, for diagnostics)

Install TPM tools:

```bash
# Ubuntu/Debian
sudo apt install tpm2-tools

# RHEL/CentOS/Fedora
sudo dnf install tpm2-tools
```

### Verify TPM

Check TPM status:

```bash
# Check device files
ls -l /dev/tpm*

# Get TPM capabilities (requires tpm2-tools)
sudo tpm2_getcap properties-fixed
```

### Running Without TPM

If TPM is not available, the service will automatically fall back to `--no-tpm` mode.

## Firewall Configuration

The installer can automatically configure firewall rules for:
- **REST API:** Port 52014 (TCP)
- **gRPC:** Port 52013 (TCP)

### Supported Firewalls

- **UFW** (Ubuntu, Debian)
- **firewalld** (RHEL, CentOS, Fedora)

### Manual Firewall Configuration

#### UFW

```bash
sudo ufw allow 52014/tcp comment "TLLicenseManager REST API"
sudo ufw allow 52013/tcp comment "TLLicenseManager gRPC"
```

#### firewalld

```bash
sudo firewall-cmd --permanent --add-port=52014/tcp
sudo firewall-cmd --permanent --add-port=52013/tcp
sudo firewall-cmd --reload
```

#### iptables

```bash
sudo iptables -A INPUT -p tcp --dport 52014 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 52013 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

## Troubleshooting

### Service Won't Start

Check logs for errors:

```bash
sudo journalctl -u asperionLM -n 100
```

Common issues:
- Missing dependencies (shared libraries)
- TPM device permissions
- Port already in use
- Configuration file errors

### Check Dependencies

Verify all shared libraries are available:

```bash
ldd /path/to/TLLicenseManager
```

### Port Already in Use

Check what's using the port:

```bash
sudo netstat -tulpn | grep 52014
# or
sudo ss -tulpn | grep 52014
```

### TPM Access Issues

Check TPM device permissions:

```bash
ls -l /dev/tpm*
sudo dmesg | grep -i tpm
```

Ensure the service has permission to access TPM devices.

### SELinux Issues (RHEL/CentOS)

If SELinux is enforcing, you may need to adjust policies:

```bash
# Check SELinux status
sestatus

# View denials
sudo ausearch -m avc -ts recent

# Generate and apply policy (if needed)
sudo audit2allow -a -M tllicensemanager
sudo semodule -i tllicensemanager.pp
```

## Uninstallation

Remove the service and optionally clean up data:

```bash
sudo ./install-tllicensemanager.sh --remove
```

The uninstaller will prompt to:
- Remove firewall rules
- Remove application data directories

## Systemd Service Configuration

The service file is created at `/etc/systemd/system/asperionLM.service`:

```ini
[Unit]
Description=asperion Trusted LicenseManager - Hardware-bound licensing service with TPM 2.0 attestation
After=network.target

[Service]
Type=simple
ExecStart=/path/to/TLLicenseManager --rest-port 52014 --grpc-port 52013
Restart=on-failure
RestartSec=10s
StartLimitBurst=5
StartLimitIntervalSec=300
WorkingDirectory=/var/lib/TrustedLicensing
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

## Comparison with Windows Scripts

These Linux scripts provide equivalent functionality to the PowerShell scripts:

| Windows | Linux | Purpose |
|---------|-------|---------|
| `CopyBuildOutput.ps1` | `copy-build-output.sh` | Copy build artifacts |
| `InstallTLLicenseManager.ps1` | `install-tllicensemanager.sh` | Install/remove service |
| Windows Service | systemd Service | Service management |
| TBS (TPM Base Services) | TPM device files | TPM access |
| Windows Firewall | UFW/firewalld | Firewall configuration |

## Support

For issues or questions:
1. Check service status: `sudo systemctl status asperionLM`
2. View logs: `sudo journalctl -u asperionLM -n 100`
3. Verify TPM access: `ls -l /dev/tpm*`
4. Check port availability: `sudo netstat -tulpn | grep 5201`
