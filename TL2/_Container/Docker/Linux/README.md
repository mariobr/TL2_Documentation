# TLLicenseManager Docker Container

This directory contains the Docker configuration for running TLLicenseManager with TPM and Docker socket access.

## Prerequisites

- Docker and Docker Compose installed
- TPM 2.0 device available on host (`/dev/tpm0`, `/dev/tpmrm0`)
- Docker daemon running
- User in `docker` and `tss` groups on host

## Quick Start

### 1. Build the Project

```bash
# From project root
cd /DEV/TrustedLicensing2/TL2

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_C_COMPILER=gcc \
      -DCMAKE_CXX_COMPILER=g++ \
      -DINCLUDE_GRPC_SERVICE=OFF \
      -DTPM_ON=ON \
      -DFASTCRYPT=ON \
      -DCMAKE_TOOLCHAIN_FILE=/DEV/vcpkg/scripts/buildsystems/vcpkg.cmake \
      -S . \
      -B out/build/linux-debug \
      -G "Unix Makefiles"

# Build
cmake --build out/build/linux-debug
```

### 2. Stage the Binary

```bash
# Navigate to Linux container directory
cd _Container/Docker/Linux

# Run the staging script
./build_and_stage.sh
```

This will:
- Find the built TLLicenseManager binary
- Copy it to `TLM/` directory
- Copy required shared libraries
- Set proper permissions

### 3. Build Docker Image

```bash
# Build the image
docker build -t trustedlicensing:latest .

# Or use docker-compose
docker-compose build
```

### 4. Run the Container

#### Option A: Using Docker Compose (Recommended)

```bash
docker-compose up -d
```

#### Option B: Using Docker Run

```bash
docker run -d \
  --name tl-license-manager \
  --device=/dev/tpm0:/dev/tpm0 \
  --device=/dev/tpmrm0:/dev/tpmrm0 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/_logs:/var/log/TrustedLicensing \
  -v $(pwd)/_config:/etc/TrustedLicensing/config \
  -v $(pwd)/_persistence:/etc/TrustedLicensing/persistence \
  --group-add tss \
  --group-add docker \
  -p 52014:52014 \
  trustedlicensing:latest
```

## Features

### TPM Access
- Mounts `/dev/tpm0` and `/dev/tpmrm0` for TPM operations
- Includes TPM 2.0 tools (`tpm2-tools`)
- User added to `tss` group for TPM access

### Docker Socket Access
- Mounts `/var/run/docker.sock` for Docker API access
- Includes Docker CLI
- User added to `docker` group

### Security
- Runs as non-root user (`tlm`)
- `no-new-privileges` security option
- Limited capabilities
- Read-only root filesystem (optional)

### Networking
- Exposes port `52014` for REST API
- Health check endpoint at `http://localhost:52014/health`

## Verify Deployment

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Check health
curl http://localhost:52014/health

# Test TPM access (from inside container)
docker exec -it tl-license-manager tpm2_getcap properties-fixed

# Test Docker access (from inside container)
docker exec -it tl-license-manager docker ps
```

## Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs -f tl-license-manager

# Execute shell in container
docker exec -it tl-license-manager bash

# Update and redeploy
./build_and_stage.sh
docker-compose up -d --build
```

## Troubleshooting

### TPM Access Issues

```bash
# Check TPM devices on host
ls -la /dev/tpm*

# Verify tss group GID
getent group tss

# Check container can access TPM
docker exec tl-license-manager ls -la /dev/tpm*
docker exec tl-license-manager id
```

### Docker Socket Issues

```bash
# Check docker socket permissions
ls -la /var/run/docker.sock

# Verify docker group GID
getent group docker

# Test Docker access from container
docker exec tl-license-manager docker version
docker exec tl-license-manager docker ps
```

### Binary Not Found

```bash
# Rebuild project
cd /DEV/TrustedLicensing2/TL2
cmake --build out/build/linux-debug

# Re-run staging script
cd _Container/Docker/Linux
./build_and_stage.sh
```

### Port Already in Use

```bash
# Find process using port 52014
sudo lsof -i :52014

# Kill the process or change port in docker-compose.yml
```

## Configuration

Edit `docker-compose.yml` to customize:
- Port mappings
- Volume mounts
- Environment variables
- Resource limits
- Restart policies

## Volume Mappings

TLLicenseManager uses specific directories on Linux for storing configuration, logs, and persistent data. The docker-compose configuration maps these to local directories for easy access and backup.

### Directory Structure

```
_Container/Docker/Linux/
├── _logs/              # TLLicenseManager log files
├── _config/            # Configuration files
├── _persistence/       # Persistence binary files
└── TLM/               # Staged binaries (build artifact)
```

### Volume Mappings Table

| Host Path | Container Path | Purpose | Files |
|-----------|---------------|---------|-------|
| `./_logs/` | `/var/log/TrustedLicensing/` | Application logs | `Trusted License Manager__YYYYMMDD.log` |
| `./_config/` | `/etc/TrustedLicensing/config/` | Configuration | `TrustedLicenseManagerConfig.json` |
| `./_persistence/` | `/etc/TrustedLicensing/persistence/` | Persistent data | `persistence.bin`, `vault.bin` |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker API access | Docker socket |

### Persistence Files

The application creates and manages two critical encrypted binary files in the persistence directory:

1. **`persistence.bin`** (15-76 KB, random size)
   - Encrypted core persistence data
   - Contains AES encryption keys for vault
   - TPM authentication data (16 bytes)
   - TPM seed data (16 bytes)
   - Initialization status
   - **Encryption**: AES-256 with hardcoded local key

2. **`vault.bin`**
   - Encrypted vault containing license manager keys
   - Storage Root Key (SRK) information for TPM
   - RSA key pairs for license management
   - **Encryption**: AES-256 with keys stored in `persistence.bin`

⚠️ **Important**: These files are automatically created on first run. Back them up regularly as they contain critical cryptographic material.

### Configuration File

The configuration file is automatically created with default values if not present:

**`TrustedLicenseManagerConfig.json`**
```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "LogLevel": "trace"
    },
    "gRPC": {
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52013"
    },
    "REST": {
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52014"
    }
  }
}
```

**Log Levels**: `trace`, `debug`, `info`, `warning`, `error`, `fatal`

### Log Files

Log files are created daily with the following format:
- **Filename**: `Trusted License Manager__YYYYMMDD.log`
- **Format**: `YYYY-MM-DD HH:MM:SS;ThreadID;Severity;Message`
- **Rotation**: Automatic daily rotation
- **Location**: `./_logs/` (host) → `/var/log/TrustedLicensing/` (container)

### Accessing Volume Data

```bash
# View logs in real-time
tail -f _logs/Trusted\ License\ Manager__*.log

# List persistence files
ls -lh _persistence/

# View configuration
cat _config/TrustedLicenseManagerConfig.json

# Check file sizes
du -sh _logs/ _config/ _persistence/
```

### Backup and Recovery

```bash
# Backup persistence and config
tar -czf tl-backup-$(date +%Y%m%d).tar.gz _config/ _persistence/

# Restore from backup
tar -xzf tl-backup-20260124.tar.gz

# Copy to another system
scp -r _config/ _persistence/ user@host:/path/to/TL2/_Container/Docker/Linux/
```

### Volume Permissions

The container runs as user `tlm` (UID 1000). Ensure the host directories have appropriate permissions:

```bash
# Set ownership (if needed)
sudo chown -R 1000:1000 _logs/ _config/ _persistence/

# Set permissions
chmod 755 _logs/ _config/ _persistence/
chmod 644 _config/*
chmod 600 _persistence/*  # Restrict access to persistence files
```

## Security Notes

⚠️ **Warning**: This container has privileged access to:
- TPM hardware (can perform cryptographic operations)
- Docker daemon (can create/manage containers, essentially root access)

Only deploy in trusted environments and ensure:
1. Container images are from trusted sources
2. Network access is properly restricted
3. Regular security updates are applied
4. Audit logs are monitored

## Additional Resources

- [TPM Access Documentation](../../_docs/TPM_Docker_Kubernetes_Access.md)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [TPM 2.0 Tools](https://github.com/tpm2-software/tpm2-tools)
