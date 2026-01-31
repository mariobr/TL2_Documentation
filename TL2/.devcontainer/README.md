# TrustedLicensing2 Development Container

**Last Updated:** January 25, 2026

This devcontainer provides a complete development environment for building TrustedLicensing2 with all required dependencies, including vcpkg package manager and TPM support.

## Features

- **Base OS**: Ubuntu 24.04
- **Compiler**: GCC 13 / G++ 13
- **Build System**: CMake 3.x + Ninja
- **Package Manager**: vcpkg (pre-installed and configured)
- **TPM Support**: TPM 2.0 tools and libraries
- **Docker CLI**: For container operations (via mounted docker.sock)
- **Development Tools**: GDB, git, vim, nano

## Quick Start

### Prerequisites

- Docker Desktop or Docker Engine
- Visual Studio Code with Remote-Containers extension
- (Optional) TPM device on host system for hardware testing

### Prerequisites

- Docker Engine (28.x or later recommended)
- docker-compose (v2.24+)
- Visual Studio Code with Remote-Containers extension (v0.300+)
- (Optional) TPM device on host system for hardware testing

### Initial Setup (First Time Only)

Since there's a known issue with the Dev Containers extension over Remote-SSH, you need to build the image manually first:

1. **Build the devcontainer image:**
   ```bash
   cd /DEV/TrustedLicensing2/TL2/.devcontainer
   docker-compose build
   ```
   This will take 10-15 minutes on first build.

2. **Verify the image was built:**
   ```bash
   docker images | grep devcontainer
   ```
   You should see: `devcontainer-devcontainer   latest   ...`

### Starting the DevContainer

#### Method 1: VS Code (Recommended)

1. Open the TL2 folder in VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Select "Developer: Reload Window"
4. When prompted, click "Reopen in Container"
5. Wait for the container to start (should be fast since image is pre-built)

The workspace will be available at `/workspaces/TL2` inside the container.

#### Method 2: Manual Container Start + VS Code Attach

If VS Code automatic start has issues, manually start the container:

1. **Start the container:**
   ```bash
   docker run -d --name tl2-dev \
     -v /DEV/TrustedLicensing2/TL2:/workspaces/TL2 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -e VCPKG_ROOT=/home/vscode/vcpkg \
     -e CMAKE_TOOLCHAIN_FILE=/home/vscode/vcpkg/scripts/buildsystems/vcpkg.cmake \
     -e VCPKG_TARGET_TRIPLET=x64-linux \
     -w /workspaces/TL2 \
     devcontainer-devcontainer:latest \
     sleep infinity
   ```

2. **Attach VS Code to the running container:**
   - Press `Ctrl+Shift+P`
   - Select "Dev Containers: Attach to Running Container"
   - Select `tl2-dev` from the list

3. **Open the workspace folder:**
   - Once attached, open folder `/workspaces/TL2`

#### Method 3: Using docker-compose

```bash
cd /DEV/TrustedLicensing2/TL2/.devcontainer
docker-compose up -d
```

Then attach VS Code using Method 2 step 2 above, selecting the `devcontainer-devcontainer-1` container.

### Stopping the DevContainer

Close the VS Code window, then:

```bash
# If started with Method 2:
docker stop tl2-dev
docker rm tl2-dev

# If started with Method 3:
cd /DEV/TrustedLicensing2/TL2/.devcontainer
docker-compose down
```

### Opening the Container

1. Open the TL2 folder in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette: `Remote-Containers: Reopen in Container`
3. Wait for the container to build (first time may take 10-15 minutes)
4. Once ready, vcpkg dependencies will be automatically installed

### Container File Locations

- **Source Code:** `/workspaces/TL2` (mounted from `/DEV/TrustedLicensing2/TL2` on host)
- **vcpkg:** `/home/vscode/vcpkg`
- **Build Output:** `/workspaces/TL2/out/build/linux-debug`

### Building the Project

Once inside the container:

Once inside the container:

```bash
# Install vcpkg dependencies (first time)
cd /workspaces/TL2
vcpkg install --triplet=x64-linux

# Configure with CMake using vcpkg
cmake --preset linux-debug

# Build
cmake --build out/build/linux-debug

# Or use the build script
cd out/build/linux-debug
make -j$(nproc)
```

### Using vcpkg

vcpkg is pre-installed at `/home/vscode/vcpkg` and configured in the environment.

```bash
# Check vcpkg version
vcpkg version

# Install a package
vcpkg install <package-name>

# List installed packages
vcpkg list

# Update vcpkg
cd $VCPKG_ROOT
git pull
./bootstrap-vcpkg.sh
```

## Environment Variables

The following environment variables are pre-configured:

- `VCPKG_ROOT=/home/vscode/vcpkg`
- `CMAKE_TOOLCHAIN_FILE=/home/vscode/vcpkg/scripts/buildsystems/vcpkg.cmake`
- `VCPKG_TARGET_TRIPLET=x64-linux`
- `TPM_DEVICE=/dev/tpmrm0`

## Persistent Volumes

vcpkg downloads and built packages are persisted in Docker volumes to speed up subsequent container rebuilds:

- `vcpkg-cache`: Downloaded package sources
- `vcpkg-installed`: Installed packages
- `vcpkg-buildtrees`: Build artifacts
- `vcpkg-packages`: Package binaries

## TPM Access

TPM devices are mounted if available on the host:
- `/dev/tpm0` - TPM character device
- `/dev/tpmrm0` - TPM resource manager

If you don't have TPM hardware, you can disable the device mounts by commenting out the `devices` section in [docker-compose.yml](docker-compose.yml).

## Docker Socket Access

The Docker socket is mounted to enable container operations from within the devcontainer. This is useful for:
- Building Docker images
- Running Docker Compose
- Container testing and deployment

## VS Code Extensions

The following extensions are automatically installed:
- C/C++ Extension Pack
- CMake Tools
- Docker
- GitHub Copilot

## Customization

### Adding More Dependencies

Edit [vcpkg.json](../vcpkg.json) to add more dependencies:

```json
{
  "dependencies": [
    "your-package-name"
  ]
}
```

Then rebuild the container or run:
```bash
vcpkg install
```

### Changing Compiler Version

Edit the Dockerfile to install a different GCC version and update the symbolic links.

### Modifying CMake Settings

Edit [devcontainer.json](devcontainer.json) to change CMake configuration settings.

## Rebuilding the Container Image

If you modify the Dockerfile or need to update dependencies:

```bash
# Stop any running containers
docker stop tl2-dev 2>/dev/null || true
docker rm tl2-dev 2>/dev/null || true

# Rebuild the image
cd /DEV/TrustedLicensing2/TL2/.devcontainer
docker-compose build --no-cache

# Restart VS Code and reopen in container
```

## Troubleshooting

### Known Issues

**VS Code Extension Error: "Cannot read properties of undefined"**
- This is a known issue with Dev Containers extension v0.437.0 over Remote-SSH
- Workaround: Use the manual container start method (Method 2 above)
- The image builds and runs fine; it's only the VS Code extension's auto-start that has issues

### Container Build Fails

- Check Docker daemon is running
- Ensure sufficient disk space
- Try: `Docker: Clean up containers` from VS Code command palette

### vcpkg Installation Fails

- Check internet connectivity
- Verify git is working: `git --version`
- Manually bootstrap: `cd $VCPKG_ROOT && ./bootstrap-vcpkg.sh`

### TPM Access Denied

- Ensure your user is in the `tss` group on the host
- Check TPM device permissions: `ls -l /dev/tpm*`
- May need to run container with elevated privileges

### Build Errors

- Ensure all vcpkg dependencies are installed: `vcpkg install`
- Check CMake configuration: `cmake --preset linux-debug`
- Verify compiler version: `g++ --version`

## Rebuilding the Container

If you modify the Dockerfile or docker-compose.yml:

1. Command Palette: `Remote-Containers: Rebuild Container`
2. Or from terminal: `docker-compose build --no-cache`

## Notes

- The container runs as user `vscode` (UID 1000) for better file permission compatibility
- Workspace is mounted at `/workspaces/TL2`
- Build output goes to `/workspaces/TL2/out/build/`
- The old installation scripts (`installDEV.sh`, `installVCPKG.sh`) are no longer used, as all setup is done in the Dockerfile
