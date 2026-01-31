# TLLicenseManager CLI Integration

## Overview

TLLicenseManager now includes command-line interface support using the **Argh!** argument parser library.

## Installation

Argh! is included as a header-only library:
- **Location:** `TLCommon/sources/include/external/argh.h`
- **Source:** https://github.com/adishavit/argh
- **License:** MIT

## Available Command-Line Options

### Help & Version

```bash
# Display help information
TLLicenseManager --help
TLLicenseManager -h

# Display version information
TLLicenseManager --version
TLLicenseManager -v
```

### Configuration Options

```bash
# Specify custom configuration file
TLLicenseManager --config /path/to/config.json

# Override REST API port
TLLicenseManager --rest-port 8080

# Override gRPC port (if GRPC_Service enabled)
TLLicenseManager --grpc-port 9090

# Set logging level
TLLicenseManager --log-level debug

# Note: Use space-separated syntax (--param value), not equals signs
```

### TPM Options

```bash
# Disable TPM operations
TLLicenseManager --no-tpm

# When TPM_SIMULATOR is enabled:
TLLicenseManager --tpm-host 192.168.1.100
TLLicenseManager --tpm-port 2321
```

## Usage Examples

### Basic Usage

```bash
# Run with default configuration
TLLicenseManager

# Run with custom REST port and debug logging
TLLicenseManager --rest-port 8080 --log-level debug

# Run without TPM (software-only mode)
TLLicenseManager --no-tpm

# Use custom configuration file
TLLicenseManager --config C:\custom\config.json
```

### Multiple Options

```bash
# Combine multiple options
TLLicenseManager --rest-port 9000 --grpc-port 9001 --log-level trace

# Custom config + port overrides
TLLicenseManager --config /etc/tlm/config.json --rest-port 443
```

## Help Output

```
TLLicenseManager v0.47 (123)
Hardware-bound licensing service with TPM 2.0 support

Usage: TLLicenseManager [OPTIONS]

Options:
  -h, --help              Display this help message
  -v, --version           Display version information
  --config <file>         Configuration file path
  --rest-port <port>      REST API port (default: 52014)
  --grpc-port <port>      gRPC port (default: 52013)
  --log-level <level>     Logging: trace|debug|info|warning|error|fatal
  --no-tpm                Disable TPM operations
  --tpm-host <host>       TPM simulator hostname (default: 192.168.188.55)
  --tpm-port <port>       TPM simulator port (default: 2321)

Examples:
  TLLicenseManager --rest-port 8080 --log-level debug
  TLLicenseManager --config /path/to/config.json
  TLLicenseManager --no-tpm

Configuration:
  Default config: C:\ProgramData\TrustedLicensing\Config\TLLicenseManager.json
  Logs directory: C:\ProgramData\TrustedLicensing\Logs\

Note: Requires Administrator (Windows) or root (Linux) privileges for TPM access.
```

## Version Output

```
TLLicenseManager version 0.47 (Build 123)
Platform: Windows
TPM Support: Enabled
TPM Mode: Hardware
gRPC Support: Disabled
```

## Log Output

At startup, the version is always logged:
```
2026-01-26T18:23:36.901550 [0x00001430] [info] --- Start TLLicenseManager (0.47) [123] on Windows
```

### Log Colors (Console)
- **trace** - Dark gray
- **debug** - White
- **info** - Blue
- **warning** - Yellow
- **error** - Red
- **fatal** - Red

## Implementation Details

### Code Changes

**Files Modified:**
1. `TLLicenseService/sources/src/Main.cpp` - CLI parsing and help/version handlers
2. `TLLicenseService/sources/include/MainApp.h` - Apply CLI overrides to configuration
3. `TLCommon/sources/include/TLFile.h` - Added `SetValue()` method
4. `TLCommon/sources/src/TLFile.cpp` - Implemented `SetValue()` method
5. `TLCommon/sources/include/external/argh.h` - Added header-only library

### Architecture

```
main(argc, argv)
├─ argh::parser cmdl(argc, argv, PREFER_PARAM_FOR_UNREG_OPTION)
├─ Handle --help → Display help and exit
├─ Handle --version → Display version and exit
├─ Extract CLI parameters
│  ├─ rest-port
│  ├─ grpc-port
│  ├─ log-level
│  ├─ config
│  └─ no-tpm
├─ Pass cmdl to LicenseManagerApp(cmdl)
└─ lmApp.run(argc, argv)

LicenseManagerApp::main()
├─ Load configuration file
├─ Apply CLI overrides
│  ├─ pConfig->SetValue("REST.ServerPort", restPort)
│  ├─ pConfig->SetValue("gRPC.ServerPort", grpcPort)
│  └─ pConfig->SetValue("LicenseManager.LogLevel", logLevel)
└─ Start services with modified configuration
```

### Priority Order

Configuration values are resolved in this order (highest to lowest priority):

1. **Command-line arguments** (highest priority)
2. **Configuration file** (TLLicenseManager.json)
3. **Default values** (hardcoded)

Example:
```bash
# REST port resolution:
# 1. If --rest-port 8080 provided → use 8080
# 2. Else if config has "REST.ServerPort": "9000" → use 9000
# 3. Else use default: 52014
```

## API Endpoints

With default configuration:
- **REST API:** http://localhost:52014
- **gRPC API:** localhost:52013 (if enabled)

With CLI overrides:
```bash
TLLicenseManager --rest-port 8080
# REST API now available at: http://localhost:8080
```

## Log Levels

Available log levels (from most to least verbose):
- `trace` - Detailed execution flow
- `debug` - Debugging information
- `info` - General informational messages (default)
- `warning` - Warning messages
- `error` - Error messages
- `fatal` - Fatal errors

Example:
```bash
# Enable trace logging for debugging
TLLicenseManager --log-level trace

# Production: only errors and warnings
TLLicenseManager --log-level warning
```

## Configuration File Format

The `--config` option accepts a JSON configuration file:

```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "LogLevel": "info"
    },
    "gRPC": {
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52013"
    },
    "REST": {
      "ServerAddress": "0.0.0.0",
      "ServerPort": "52014"
    },
    "application": {
      "runAsService": false,
      "runAsDaemon": false
    }
  }
}
```

## Platform-Specific Notes

### Windows

```powershell
# Run as Administrator (required for TPM access)
.\TLLicenseManager.exe --rest-port 8080

# Check version
.\TLLicenseManager.exe --version

# Run as Windows Service (use config file)
# Set "runAsService": true in config.json
```

### Linux

```bash
# Run with sudo (required for TPM access)
sudo ./TLLicenseManager --rest-port 8080

# Check version
./TLLicenseManager --version

# Run as daemon (use config file)
# Set "runAsDaemon": true in config.json
```

### Docker

```bash
# Pass CLI arguments to Docker container
docker run -d \
  --device=/dev/tpmrm0 \
  trustedlicensing:latest \
  /app/TLLicenseManager --rest-port 8080 --log-level debug

# Or use environment variables with config file mounted
docker run -d \
  --device=/dev/tpmrm0 \
  -v /path/to/config.json:/app/config/TLLicenseManager.json \
  trustedlicensing:latest \
  /app/TLLicenseManager --config /app/config/TLLicenseManager.json
```

### Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
spec:
  containers:
  - name: app
    image: trustedlicensing:latest
    command: ["/app/TLLicenseManager"]
    args:
      - "--rest-port"
      - "8080"
      - "--log-level"
      - "info"
    volumeMounts:
    - name: tpmrm0
      mountPath: /dev/tpmrm0
  volumes:
  - name: tpmrm0
    hostPath:
      path: /dev/tpmrm0
```

## Testing

### Verify CLI Integration

```bash
# 1. Test help output
TLLicenseManager --help

# 2. Test version output
TLLicenseManager --version

# 3. Test port override
TLLicenseManager --rest-port 9999 &
curl http://localhost:9999/status

# 4. Test log level
TLLicenseManager --log-level trace
# Check logs for verbose output

# 5. Test multiple options
TLLicenseManager --rest-port 8080 --grpc-port 8081 --log-level debug
```

### Expected Behavior

**Successful start:**
```
2026-01-26T18:23:36.901550 [0x00001430] [info] --- Start TLLicenseManager (0.47) [123] on Windows
CLI override: REST port = 8080
Applied CLI override: REST port = 8080
Persistence initialized successfully
TPM connected
REST server listening on 0.0.0.0:8080
Wait ForTermination Request
```

**Help display (exits immediately):**
```
TLLicenseManager v0.47 (123)
Hardware-bound licensing service with TPM 2.0 support
...
```

## Troubleshooting

### Issue: CLI arguments not recognized

**Problem:**
```bash
TLLicenseManager --rest-port 8080
# Port still uses default 52014
```

**Solution:**
- Check argument spelling: `--rest-port` (not `--restport`)
- Ensure value provided: `--rest-port 8080` (not just `--rest-port`)
- Check logs for "Applied CLI override" messages

### Issue: Configuration file not loaded

**Problem:**
```bash
TLLicenseManager --config /path/to/config.json
# Error: File not found
```

**Solution:**
- Use absolute paths
- Check file permissions
- Verify JSON syntax is valid
- Ensure file extension is `.json`

### Issue: Permission denied on Linux

**Problem:**
```bash
./TLLicenseManager
# Error: TPM requires elevated rights
```

**Solution:**
```bash
# Run with sudo
sudo ./TLLicenseManager --rest-port 8080

# Or add user to tss group
sudo usermod -a -G tss $USER
```

## Future Enhancements

Potential additional CLI options:

1. **Config overrides:**
   ```bash
   TLLicenseManager --set gRPC.Enabled=true
   ```

2. **Startup modes:**
   ```bash
   TLLicenseManager --daemon
   TLLicenseManager --service
   ```

3. **TPM operations:**
   ```bash
   TLLicenseManager --clear-tpm-nvram
   TLLicenseManager --regenerate-keys
   ```

4. **Output formats:**
   ```bash
   TLLicenseManager --version --json
   ```

5. **Dry-run mode:**
   ```bash
   TLLicenseManager --dry-run --check-config
   ```

---

**Document Version:** 1.0  
**Last Updated:** January 26, 2026  
**Maintainer:** TrustedLicensing Team
