# TLLicenseManager CLI Integration Documentation

## Overview

TLLicenseManager provides a comprehensive command-line interface (CLI) for configuration, debugging, and operational control. The CLI uses the **Argh!** header-only argument parser library with space-separated syntax (`--option value`) for all parameters. Command-line arguments take precedence over configuration file settings, enabling runtime overrides without modifying configuration files.

This document accurately reflects the implementation in [TLLicenseService/sources/src/Main.cpp](../TLLicenseService/sources/src/Main.cpp) and [TLLicenseService/sources/include/MainApp.h](../TLLicenseService/sources/include/MainApp.h).

## Dependencies

### Argh! Argument Parser Library
- **Type:** Header-only library
- **Location:** [TLCommon/sources/include/external/argh.h](../TLCommon/sources/include/external/argh.h)
- **Source:** https://github.com/adishavit/argh
- **License:** MIT
- **Version:** Embedded in codebase
- **Parser Mode:** `PREFER_PARAM_FOR_UNREG_OPTION` (space-separated syntax: `--param value`)
- **Implementation:** `argh::parser cmdl(argc, argv, argh::parser::PREFER_PARAM_FOR_UNREG_OPTION)`

## Available Command-Line Options

### Help & Version

#### Display Help (`-h`, `--help`)
Shows complete usage information including all options, examples, and configuration paths. Exits immediately after displaying help.

```bash
TLLicenseManager --help
TLLicenseManager -h
```

#### Display Version (`-v`, `--version`)
Shows version information, platform, TPM support status, and gRPC availability. Exits immediately after displaying version.

```bash
TLLicenseManager --version
TLLicenseManager -v
```

### Configuration Options

#### Custom Configuration File (`--config <file>`)
Specify an alternate configuration file path. Supports absolute and relative paths.

```bash
# Windows
TLLicenseManager --config C:\custom\TLLicenseManager.json

# Linux
TLLicenseManager --config /etc/tlm/config.json
```

**Logging Output:**
```
[info] CLI: Config file override = /etc/tlm/config.json
```

### Network Port Options

#### REST API Port (`--rest-port <port>`)
Override the REST API server port (default: 52014). Valid range: 1-65535.

```bash
TLLicenseManager --rest-port 8080
```

**Logging Output:**
```
[info] CLI: REST port override = 8080
[info] Config updated: REST.ServerPort = 8080
```

**Configuration Path:** `TrustedLicensing.REST.ServerPort`

#### gRPC Port (`--grpc-port <port>`)
Override the gRPC server port (default: 52013, only available if `GRPC_Service` enabled). Valid range: 1-65535.

```bash
TLLicenseManager --grpc-port 9090
```

**Logging Output:**
```
[info] CLI: gRPC port override = 9090
[info] Config updated: gRPC.ServerPort = 9090
```

**Configuration Path:** `TrustedLicensing.gRPC.ServerPort`

### Logging Options

#### Log Level (`--log-level <level>`)
Set logging verbosity. Valid values: `trace`, `debug`, `info`, `warning`, `error`, `fatal`.

```bash
TLLicenseManager --log-level debug
```

**Logging Output:**
```
[debug] CLI: Log level set to 'debug'
```

**Configuration Path:** `TrustedLicensing.LicenseManager.LogLevel`

### TPM Options

#### Disable TPM (`--no-tpm`)
Disable TPM operations entirely, running in software-only mode. This flag is checked early during initialization.

```bash
TLLicenseManager --no-tpm
```

**Logging Output:**
```
[info] CLI: --no-tpm flag detected, TPM will be disabled
[info] TPM compiled in but disabled (--no-tpm or not available)
```

**Implementation:** Calls `ApplicationState::DisableTPM()` before any TPM operations.

#### TPM Simulator Host (`--tpm-host <host>`)
**Only available in TPM_SIMULATOR builds.** Specify TPM simulator hostname or IP address.

```bash
TLLicenseManager --tpm-host 192.168.1.100
```

**Default:** `192.168.188.55` (defined in `TLCrypt/sources/CMakeLists.txt`)

#### TPM Simulator Port (`--tpm-port <port>`)
**Only available in TPM_SIMULATOR builds.** Specify TPM simulator port.

```bash
TLLicenseManager --tpm-port 2321
```

**Default:** `2321` (defined in `TLCrypt/sources/CMakeLists.txt`)

## Complete Command-Line Syntax

```bash
TLLicenseManager [OPTIONS]

Options:
  -h, --help                 Display this help message
  -v, --version              Display version information
  --config <file>            Configuration file path
  --rest-port <port>         REST API port (default: 52014)
  --grpc-port <port>         gRPC port (default: 52013)
  --log-level <level>        Logging: trace|debug|info|warning|error|fatal
  --no-tpm                   Disable TPM operations
  --tpm-host <host>          TPM simulator hostname (TPM_SIMULATOR builds only)
  --tpm-port <port>          TPM simulator port (TPM_SIMULATOR builds only)
```

## Usage Examples

### Basic Usage

```bash
# Run with default configuration
TLLicenseManager

# Display help
TLLicenseManager --help

# Display version
TLLicenseManager --version

# Custom REST port
TLLicenseManager --rest-port 8080

# Debug logging
TLLicenseManager --log-level debug

# Disable TPM (software-only mode)
TLLicenseManager --no-tpm

# Custom configuration file
TLLicenseManager --config /path/to/custom-config.json
```

### Multiple Options

```bash
# REST port + debug logging
TLLicenseManager --rest-port 8080 --log-level debug

# Both REST and gRPC ports
TLLicenseManager --rest-port 9000 --grpc-port 9001

# Custom config with port override
TLLicenseManager --config /etc/tlm/config.json --rest-port 443

# Trace logging without TPM
TLLicenseManager --log-level trace --no-tpm

# All options combined
TLLicenseManager --config ./config.json --rest-port 8080 --grpc-port 8081 --log-level debug --no-tpm
```

### TPM Simulator (Development/Testing)

```bash
# Connect to remote TPM simulator
TLLicenseManager --tpm-host 192.168.1.10 --tpm-port 2321

# Local simulator with custom port
TLLicenseManager --tpm-host localhost --tpm-port 2322
```

## Actual Help Output

From [Main.cpp](../TLLicenseService/sources/src/Main.cpp) `showHelp()` function:

```
TLLicenseManager v0.48 (2026.01.31.1138)
Hardware-bound licensing service with TPM 2.0 support

Usage: TLLicenseManager [OPTIONS]

Options:
  -h, --help                 Display this help message
  -v, --version              Display version information
  --config <file>            Configuration file path
  --rest-port <port>         REST API port (default: 52014)
  --grpc-port <port>         gRPC port (default: 52013)
  --log-level <level>        Logging: trace|debug|info|warning|error|fatal
  --no-tpm                   Disable TPM operations
  --tpm-host <host>          TPM simulator hostname (default: 192.168.188.55)
  --tpm-port <port>          TPM simulator port (default: 2321)

Examples:
  TLLicenseManager --rest-port 8080 --log-level debug
  TLLicenseManager --config /path/to/config.json
  TLLicenseManager --no-tpm

Configuration:
  Default config: C:\ProgramData\TrustedLicensing\Config\TLLicenseManager.json
  Logs directory: C:\ProgramData\TrustedLicensing\Logs\

Note: Requires Administrator (Windows) or root (Linux) privileges for TPM access.
```

## Actual Version Output

From [Main.cpp](../TLLicenseService/sources/src/Main.cpp) `--version` handler:

```
TLLicenseManager version 0.48 (Build 2026.01.31.1138)
Platform: Windows
TPM Support: Enabled
TPM Mode: Hardware
gRPC Support: Disabled
```

**Notes:**
- Build number is automatically generated by [cmake/build_number.cmake](../cmake/build_number.cmake)
- Format: `YYYY.MM.DD.HHMM`
- TPM Mode shows "Simulator" when `TPM_SIMULATOR` is defined, otherwise "Hardware"
- gRPC Support reflects `GRPC_Service` compile-time flag

## Log Output

### Startup Logging

At startup, the version is always logged at `info` level:

```
2026-01-31T14:38:45.123456 [0x00001234] [info] --- Start TLLicenseManager (0.48) [2026.01.31.1138] on Windows
```

**Format:** `YYYY-MM-DDTHH:MM:SS.microseconds [thread_id] [level] message`

### CLI Parameter Logging

When CLI parameters are processed, detailed logging occurs:

```
[debug] Processing command-line arguments...
[info] CLI: --no-tpm flag detected, TPM will be disabled
[info] CLI: REST port override = 8080
[info] CLI: gRPC port override = 9090
[debug] CLI: Log level set to 'debug'
[info] CLI: Config file override = /path/to/config.json
```

### Configuration Override Logging

When configuration is modified by CLI arguments:

```
[debug] Applying CLI overrides to configuration...
[info] Config updated: REST.ServerPort = 8080
[info] Config updated: gRPC.ServerPort = 9090
[info] Config updated: LogLevel = debug
```

### TPM Status Logging

TPM initialization status:

```
[debug] CLI: TPM enabled (no --no-tpm flag)
[info] TPM enabled and will be used
```

Or when disabled:

```
[info] CLI: --no-tpm flag detected, TPM will be disabled
[info] TPM compiled in but disabled (--no-tpm or not available)
```

Or when not compiled in:

```
[warning] TPM not compiled in
```

## Argument Validation

### Valid Flag List

The implementation validates all flags against a whitelist in [Main.cpp](../TLLicenseService/sources/src/Main.cpp):

```cpp
std::vector<std::string> validFlags = {
    "h", "help", "v", "version", "no-tpm",
    "config", "rest-port", "grpc-port", "log-level"
#ifdef TPM_SIMULATOR
    , "tpm-host", "tpm-port"
#endif
};
```

### Unknown Option Handling

If an unknown option is provided:

```bash
TLLicenseManager --invalid-option value
```

**Output:**
```
Error: Unknown option '--invalid-option'

TLLicenseManager v0.48 (2026.01.31.1138)
Hardware-bound licensing service with TPM 2.0 support
...
```

**Exit Code:** `1`

### Log Level Validation

Valid log levels must be one of: `trace`, `debug`, `info`, `warning`, `error`, `fatal`

```bash
TLLicenseManager --log-level invalid
```

**Output:**
```
Error: Invalid log level 'invalid'
Valid levels: trace, debug, info, warning, error, fatal

TLLicenseManager v0.48 (2026.01.31.1138)
...
```

**Exit Code:** `1`

### Port Validation

Ports must be in range 1-65535:

```bash
TLLicenseManager --rest-port 99999
```

**Output:**
```
Error: Invalid REST port '99999' (must be 1-65535)

TLLicenseManager v0.48 (2026.01.31.1138)
...
```

**Exit Code:** `1`

Same validation applies to `--grpc-port`.

## Implementation Architecture

### Main Entry Point Flow

From [Main.cpp](../TLLicenseService/sources/src/Main.cpp):

```
main(argc, argv)
│
├─ 1. Parse arguments with Argh!
│  └─ argh::parser cmdl(argc, argv, PREFER_PARAM_FOR_UNREG_OPTION)
│
├─ 2. Handle immediate-exit options
│  ├─ --help → showHelp() → return 0
│  └─ --version → show version info → return 0
│
├─ 3. Validate all options
│  ├─ Check against validFlags list
│  ├─ Validate log-level values
│  ├─ Validate port ranges (1-65535)
│  └─ Return 1 if validation fails
│
├─ 4. Extract and log CLI parameters
│  ├─ Extract log-level (default: "info")
│  ├─ Initialize logging: TLLogger::InitLogging()
│  ├─ Apply log-level: TLLogger::SetLogLevel()
│  ├─ Log version: "--- Start TLLicenseManager..."
│  ├─ Process --no-tpm flag → ApplicationState::DisableTPM()
│  └─ Log all CLI overrides
│
├─ 5. Check elevation
│  └─ ApplicationState::CheckElevation()
│
├─ 6. Create and run application
│  ├─ LicenseManagerApp lmApp(cmdl)
│  └─ lmApp.run(argc, argv)
│
└─ 7. Cleanup and exit
   └─ Log "Finish TLLicenseManager"
```

### LicenseManagerApp Configuration Override

From [MainApp.h](../TLLicenseService/sources/include/MainApp.h):

```
LicenseManagerApp::main()
│
├─ 1. Load configuration
│  ├─ Create TLConfiguration object
│  └─ Get default config file
│
├─ 2. Apply CLI overrides to configuration
│  ├─ IF cmdl("rest-port")
│  │  ├─ Extract port value
│  │  ├─ pConfig->SetValue("TrustedLicensing.REST.ServerPort", port)
│  │  └─ Log: "Config updated: REST.ServerPort = port"
│  │
│  ├─ IF cmdl("grpc-port")
│  │  ├─ Extract port value
│  │  ├─ pConfig->SetValue("TrustedLicensing.gRPC.ServerPort", port)
│  │  └─ Log: "Config updated: gRPC.ServerPort = port"
│  │
│  └─ IF cmdl("log-level")
│     ├─ Extract log level
│     ├─ pConfig->SetValue("TrustedLicensing.LicenseManager.LogLevel", level)
│     └─ Log: "Config updated: LogLevel = level"
│
├─ 3. Initialize persistence service
│
├─ 4. Log TPM status
│
├─ 5. Start license service
│
├─ 6. Start gRPC server (if enabled)
│
├─ 7. Start REST server
│
└─ 8. Wait for termination request
```

### Configuration Override Mechanism

The `TLFile::SetValue()` method from [TLFile.cpp](../TLCommon/sources/src/TLFile.cpp):

```cpp
bool TLFile::SetValue(const std::string& pattern, const std::string& value) {
    BOOST_LOG_TRIVIAL(trace) << "TLFile SetValue | Pattern:" << pattern << " Value:" << value;
    
    try {
        // pt.put() creates missing intermediate nodes automatically
        pt.put(pattern, value);
    }
    catch (boost::property_tree::ptree_error& e) {
        BOOST_LOG_TRIVIAL(error) << "TLFile SetValue failed for pattern: " 
                                 << pattern << " Error: " << e.what();
        return false;
    }
    
    return true;
}
```

**Key Features:**
- Uses Boost Property Tree (`boost::property_tree::ptree`)
- Automatically creates missing intermediate nodes
- Supports dot-notation paths: `TrustedLicensing.REST.ServerPort`
- Returns `false` on error, `true` on success

## Configuration Priority Order

Configuration values are resolved in this order (highest to lowest priority):

1. **Command-line arguments** (highest priority)
   - Applied via `SetValue()` to in-memory configuration tree
   - Takes effect immediately
   
2. **Configuration file** (`TLLicenseManager.json`)
   - Loaded at application startup
   - Can be overridden by `--config` option
   
3. **Default values** (hardcoded in application)
   - Used when no config file or CLI override provided

### Example: REST Port Resolution

```bash
# Scenario 1: CLI override provided
TLLicenseManager --rest-port 8080
# Result: Uses 8080 (CLI wins)

# Scenario 2: Config file only
# config.json: "REST.ServerPort": "9000"
TLLicenseManager
# Result: Uses 9000 (from config)

# Scenario 3: Neither provided
TLLicenseManager
# Result: Uses 52014 (default)

# Scenario 4: Both provided
# config.json: "REST.ServerPort": "9000"
TLLicenseManager --rest-port 8080
# Result: Uses 8080 (CLI wins over config)
```

## Configuration File Format

Default location:
- **Windows:** `C:\ProgramData\TrustedLicensing\Config\TLLicenseManager.json`
- **Linux:** `/var/lib/TrustedLicensing/Config/TLLicenseManager.json`

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

**CLI-Configurable Paths:**
- `TrustedLicensing.REST.ServerPort` ← `--rest-port`
- `TrustedLicensing.gRPC.ServerPort` ← `--grpc-port`
- `TrustedLicensing.LicenseManager.LogLevel` ← `--log-level`

## Log Levels

Available log levels (from most to least verbose):

| Level | Description | Use Case | CLI Example |
|-------|-------------|----------|-------------|
| `trace` | Detailed execution flow | Low-level debugging | `--log-level trace` |
| `debug` | Debugging information | Development/troubleshooting | `--log-level debug` |
| `info` | General informational messages | **Default**, production | `--log-level info` |
| `warning` | Warning messages | Production (important events only) | `--log-level warning` |
| `error` | Error messages | Production (errors only) | `--log-level error` |
| `fatal` | Fatal errors | Critical failures only | `--log-level fatal` |

### Console Log Colors

When running in console mode (not as service/daemon):

- **trace** - Dark gray
- **debug** - White  
- **info** - Blue
- **warning** - Yellow
- **error** - Red (fmt::color::red)
- **fatal** - Red

## API Endpoints

### Default Configuration

- **REST API:** `http://localhost:52014`
- **gRPC API:** `localhost:52013` (if `GRPC_Service` enabled)

### With CLI Overrides

```bash
# Change REST port to 8080
TLLicenseManager --rest-port 8080
# REST API now at: http://localhost:8080

# Change both ports
TLLicenseManager --rest-port 8080 --grpc-port 8081
# REST API: http://localhost:8080
# gRPC API: localhost:8081
```

## Platform-Specific Usage

### Windows

#### Interactive Mode
```powershell
# Run as Administrator (required for TPM access)
.\TLLicenseManager.exe --rest-port 8080 --log-level debug

# Check version
.\TLLicenseManager.exe --version

# Run without TPM
.\TLLicenseManager.exe --no-tpm
```

#### Windows Service Mode
```powershell
# Set in configuration file (not via CLI)
# TLLicenseManager.json:
# "application": { "runAsService": true }

# Install as service (separate installer script)
.\InstallTLLicenseManager.ps1
```

**Note:** CLI arguments can be passed when the service starts, configured in service properties.

### Linux

#### Interactive Mode
```bash
# Run with sudo (required for TPM access)
sudo ./TLLicenseManager --rest-port 8080 --log-level debug

# Check version (no sudo needed)
./TLLicenseManager --version

# Run without TPM
sudo ./TLLicenseManager --no-tpm
```

#### Daemon Mode
```bash
# Set in configuration file
# TLLicenseManager.json:
# "application": { "runAsDaemon": true }

# Or application auto-detects daemon mode
# (checks if process has controlling terminal)

# Install as systemd service
sudo ./install-tllicensemanager.sh
```

#### Systemd Service

```ini
# /etc/systemd/system/tllicensemanager.service
[Unit]
Description=TLLicenseManager Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/TLLicenseManager --rest-port 8080 --log-level info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable tllicensemanager
sudo systemctl start tllicensemanager

# View logs
sudo journalctl -u tllicensemanager -f
```

### Docker

#### Dockerfile Entry Point

```dockerfile
FROM ubuntu:22.04

# Install application
COPY TLLicenseManager /app/TLLicenseManager
RUN chmod +x /app/TLLicenseManager

# Default command (can be overridden)
CMD ["/app/TLLicenseManager", "--rest-port", "8080", "--log-level", "info"]
```

#### Running with CLI Arguments

```bash
# Override default arguments
docker run -d \
  --name tl-license-manager \
  --device=/dev/tpmrm0 \
  -p 8080:8080 \
  trustedlicensing:latest \
  /app/TLLicenseManager --rest-port 8080 --log-level debug --no-tpm

# Mount custom config
docker run -d \
  --name tl-license-manager \
  --device=/dev/tpmrm0 \
  -v /host/config.json:/app/config/TLLicenseManager.json \
  -p 8080:8080 \
  trustedlicensing:latest \
  /app/TLLicenseManager --config /app/config/TLLicenseManager.json --rest-port 8080

# Check version
docker run --rm trustedlicensing:latest /app/TLLicenseManager --version

# View help
docker run --rm trustedlicensing:latest /app/TLLicenseManager --help
```

#### Docker Compose

```yaml
version: '3.8'

services:
  tl-license-manager:
    image: trustedlicensing:latest
    container_name: tl-license-manager
    command:
      - /app/TLLicenseManager
      - --rest-port
      - "8080"
      - --log-level
      - info
      - --no-tpm
    ports:
      - "8080:8080"
    volumes:
      - ./config:/app/config
    devices:
      - /dev/tpmrm0:/dev/tpmrm0
    restart: unless-stopped
```

### Kubernetes

#### Deployment with CLI Arguments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tl-license-manager
  labels:
    app: tl-license-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tl-license-manager
  template:
    metadata:
      labels:
        app: tl-license-manager
    spec:
      containers:
      - name: tl-license-manager
        image: trustedlicensing:latest
        command: ["/app/TLLicenseManager"]
        args:
          - "--rest-port"
          - "8080"
          - "--grpc-port"
          - "8081"
          - "--log-level"
          - "info"
        ports:
        - containerPort: 8080
          name: rest
        - containerPort: 8081
          name: grpc
        volumeMounts:
        - name: tpmrm0
          mountPath: /dev/tpmrm0
        - name: config
          mountPath: /app/config
      volumes:
      - name: tpmrm0
        hostPath:
          path: /dev/tpmrm0
      - name: config
        configMap:
          name: tl-license-manager-config
---
apiVersion: v1
kind: Service
metadata:
  name: tl-license-manager
spec:
  selector:
    app: tl-license-manager
  ports:
  - name: rest
    port: 8080
    targetPort: 8080
  - name: grpc
    port: 8081
    targetPort: 8081
```

#### ConfigMap for Custom Config

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tl-license-manager-config
data:
  TLLicenseManager.json: |
    {
      "TrustedLicensing": {
        "LicenseManager": {
          "LogLevel": "info"
        },
        "REST": {
          "ServerAddress": "0.0.0.0",
          "ServerPort": "8080"
        },
        "gRPC": {
          "ServerAddress": "0.0.0.0",
          "ServerPort": "8081"
        }
      }
    }
```

## Testing & Verification

### 1. Test Help Output

```bash
TLLicenseManager --help
```

**Expected:**
- Displays complete usage information
- Shows version in header
- Lists all available options
- Shows examples section
- Shows configuration paths
- Exits with code 0

### 2. Test Version Output

```bash
TLLicenseManager --version
```

**Expected:**
- Shows version number (e.g., 0.48)
- Shows build number (e.g., 2026.01.31.1138)
- Shows platform (Windows/Linux)
- Shows TPM support status
- Shows TPM mode (Hardware/Simulator)
- Shows gRPC support status
- Exits with code 0

### 3. Test Port Override

```bash
# Terminal 1: Start with custom port
TLLicenseManager --rest-port 9999 --log-level debug

# Terminal 2: Test endpoint
curl http://localhost:9999/status
```

**Expected:**
- Logs show: `CLI: REST port override = 9999`
- Logs show: `Config updated: REST.ServerPort = 9999`
- REST API responds on port 9999
- Default port 52014 is not used

### 4. Test Log Level

```bash
TLLicenseManager --log-level trace
```

**Expected:**
- Logs show: `CLI: Log level set to 'trace'`
- Output includes `[trace]` level messages
- Very verbose output with detailed execution flow

### 5. Test Multiple Options

```bash
TLLicenseManager --rest-port 8080 --grpc-port 8081 --log-level debug --no-tpm
```

**Expected:**
- All overrides applied
- Logs show each CLI parameter processed
- REST on 8080, gRPC on 8081
- Debug logging enabled
- TPM disabled

### 6. Test Validation

```bash
# Invalid port
TLLicenseManager --rest-port 99999
# Expected: Error message, help displayed, exit code 1

# Invalid log level
TLLicenseManager --log-level invalid
# Expected: Error with valid levels list, exit code 1

# Unknown option
TLLicenseManager --unknown-option
# Expected: Error message, help displayed, exit code 1
```

### 7. Test Configuration File Override

```bash
# Create custom config
cat > custom-config.json << 'EOF'
{
  "TrustedLicensing": {
    "REST": {
      "ServerPort": "9000"
    }
  }
}
EOF

# Test with custom config
TLLicenseManager --config custom-config.json

# Verify port 9000 is used
curl http://localhost:9000/status
```

### 8. Test TPM Simulator (Development Only)

```bash
# Start TPM simulator on custom port
# (simulator must be built with TPM_SIMULATOR flag)

TLLicenseManager --tpm-host localhost --tpm-port 2322
```

**Expected:**
- Logs show TPM simulator connection
- Application connects to specified host:port

## Troubleshooting

### Issue: CLI arguments not recognized

**Symptoms:**
```bash
TLLicenseManager --rest-port 8080
# Port still uses default 52014
```

**Diagnosis:**
- Check logs for "CLI: REST port override = 8080"
- Check logs for "Config updated: REST.ServerPort = 8080"

**Solutions:**
1. Verify argument spelling: `--rest-port` (not `--restport` or `--rest_port`)
2. Ensure space between option and value: `--rest-port 8080` (not `--rest-port=8080`)
3. Check for typos in option names
4. Verify application version supports the option
5. Check if option requires specific compile-time flags (e.g., `--grpc-port` requires `GRPC_Service`)

### Issue: "Unknown option" error

**Symptoms:**
```bash
TLLicenseManager --rest_port 8080
Error: Unknown option '--rest_port'
```

**Solutions:**
- Use hyphens, not underscores: `--rest-port`
- Check spelling against valid options list
- Use `--help` to see all available options
- Check if option requires specific build configuration

### Issue: "Invalid log level" error

**Symptoms:**
```bash
TLLicenseManager --log-level INFO
Error: Invalid log level 'INFO'
Valid levels: trace, debug, info, warning, error, fatal
```

**Solutions:**
- Use lowercase: `--log-level info` (not `INFO` or `Info`)
- Use exact spelling from valid list
- Valid values: `trace`, `debug`, `info`, `warning`, `error`, `fatal`

### Issue: "Invalid port" error

**Symptoms:**
```bash
TLLicenseManager --rest-port 99999
Error: Invalid REST port '99999' (must be 1-65535)
```

**Solutions:**
- Use port in valid range: 1-65535
- Avoid privileged ports (<1024) unless running with elevation
- Check for port conflicts with other services
- Common ports: 8080, 8443, 9090

### Issue: Configuration file not found

**Symptoms:**
```bash
TLLicenseManager --config /path/to/config.json
# Error loading configuration file
```

**Diagnosis:**
- Check logs for file loading errors
- Verify file exists: `ls -la /path/to/config.json`
- Check file permissions
- Verify JSON syntax

**Solutions:**
1. Use absolute paths: `/full/path/to/config.json`
2. Check file permissions: `chmod 644 config.json`
3. Validate JSON syntax: `jq . config.json`
4. Ensure file extension is `.json`
5. Check for BOM (Byte Order Mark) in file

### Issue: Permission denied on Linux

**Symptoms:**
```bash
./TLLicenseManager
# Error: TPM requires elevated rights
# Application::EXIT_NOPERM
```

**Solutions:**
```bash
# Option 1: Run with sudo
sudo ./TLLicenseManager --rest-port 8080

# Option 2: Add user to tss group (for TPM access)
sudo usermod -a -G tss $USER
# Logout and login again

# Option 3: Run without TPM
./TLLicenseManager --no-tpm

# Option 4: Set capabilities (careful!)
sudo setcap cap_sys_admin=ep ./TLLicenseManager
```

### Issue: Port already in use

**Symptoms:**
```bash
TLLicenseManager
# Error: Address already in use
# REST server failed to start
```

**Diagnosis:**
```bash
# Check what's using the port
# Windows:
netstat -ano | findstr :52014

# Linux:
sudo lsof -i :52014
sudo netstat -tlnp | grep 52014
```

**Solutions:**
1. Use different port: `--rest-port 8080`
2. Stop conflicting service
3. Check if another TLLicenseManager instance is running
4. Wait for port to be released (TIME_WAIT state)

### Issue: gRPC options not available

**Symptoms:**
```bash
TLLicenseManager --grpc-port 8081
Error: Unknown option '--grpc-port'
```

**Cause:**
- Application built without `GRPC_Service` flag
- gRPC support not compiled in

**Solutions:**
1. Rebuild with gRPC support enabled
2. Remove `--grpc-port` option
3. Check build configuration: `TLLicenseManager --version` shows "gRPC Support: Disabled"

### Issue: TPM simulator options not available

**Symptoms:**
```bash
TLLicenseManager --tpm-host localhost
Error: Unknown option '--tpm-host'
```

**Cause:**
- Application built without `TPM_SIMULATOR` flag
- Using hardware TPM build

**Solutions:**
1. Use development build with TPM simulator support
2. Remove `--tpm-host` and `--tpm-port` options
3. Use `--no-tpm` to disable TPM operations

### Issue: Log file permissions error

**Symptoms:**
```bash
# Logs not being written
# Permission denied errors in console
```

**Solutions:**
```bash
# Windows: Check ProgramData permissions
icacls "C:\ProgramData\TrustedLicensing\Logs"

# Linux: Check /var/lib permissions
sudo chown -R root:root /var/lib/TrustedLicensing
sudo chmod -R 755 /var/lib/TrustedLicensing/Logs
```

### Issue: Docker container exits immediately

**Symptoms:**
```bash
docker run trustedlicensing:latest --help
# Container starts and exits
# No output captured
```

**Solutions:**
```bash
# Use --rm to see output
docker run --rm trustedlicensing:latest /app/TLLicenseManager --help

# Check container logs
docker logs <container-id>

# Run interactively
docker run -it --rm trustedlicensing:latest /bin/bash
/app/TLLicenseManager --help
```

## Error Messages Reference

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `Error: Unknown option '--xyz'` | Invalid or misspelled option | Check spelling, use `--help` |
| `Error: Invalid log level 'XYZ'` | Invalid log level value | Use: trace, debug, info, warning, error, fatal |
| `Error: Invalid REST port 'N'` | Port out of range (1-65535) | Use valid port number |
| `Error: Invalid gRPC port 'N'` | Port out of range (1-65535) | Use valid port number |
| `Elevation required` | Missing admin/root privileges | Run with sudo/admin rights |
| `Address already in use` | Port conflict | Change port or stop conflicting service |
| `File not found` | Config file doesn't exist | Check path, use absolute path |
| `TPM not available` | TPM device not accessible | Check /dev/tpmrm0, use --no-tpm, or check permissions |

## Best Practices

### Development

```bash
# Use trace logging for debugging
TLLicenseManager --log-level trace --no-tpm

# Use custom config for testing
TLLicenseManager --config ./test-config.json --rest-port 9999

# Test without TPM
TLLicenseManager --no-tpm --rest-port 8080 --log-level debug
```

### Production

```bash
# Minimal logging for performance
TLLicenseManager --log-level warning

# Use standard ports (from config file)
TLLicenseManager

# Use config file for all settings (no CLI overrides)
TLLicenseManager --config /etc/tlm/production.json
```

### Testing/Staging

```bash
# Balance logging and performance
TLLicenseManager --log-level info

# Use non-standard ports to avoid conflicts
TLLicenseManager --rest-port 8080 --grpc-port 8081

# Clearly identify environment in config
TLLicenseManager --config /etc/tlm/staging.json
```

### Container Deployments

```bash
# Use environment-specific configs
docker run -v ./config-prod.json:/app/config.json \
  trustedlicensing:latest \
  /app/TLLicenseManager --config /app/config.json

# Override ports for container networking
docker run -p 8080:8080 \
  trustedlicensing:latest \
  /app/TLLicenseManager --rest-port 8080

# Use log level from environment
docker run -e LOG_LEVEL=info \
  trustedlicensing:latest \
  /app/TLLicenseManager --log-level ${LOG_LEVEL}
```

## Future Enhancements

Potential additional CLI options for future versions:

### 1. Generic Configuration Override
```bash
# Set any configuration value via CLI
TLLicenseManager --set TrustedLicensing.gRPC.Enabled=true
TLLicenseManager --set TrustedLicensing.REST.ServerAddress=0.0.0.0
```

### 2. Startup Mode Selection
```bash
# Force service mode (Windows)
TLLicenseManager --service

# Force daemon mode (Linux)
TLLicenseManager --daemon

# Interactive mode (override config)
TLLicenseManager --interactive
```

### 3. TPM Management Operations
```bash
# Clear TPM NVRAM
TLLicenseManager --tpm-clear-nvram

# Regenerate TPM keys
TLLicenseManager --tpm-regenerate-keys

# Show TPM status and exit
TLLicenseManager --tpm-status
```

### 4. Output Format Options
```bash
# JSON output for automation
TLLicenseManager --version --json
TLLicenseManager --status --json

# Machine-readable format
TLLicenseManager --version --format json
```

### 5. Validation & Dry-Run
```bash
# Validate configuration without starting
TLLicenseManager --validate-config

# Check configuration and exit
TLLicenseManager --check-config --dry-run

# Test TPM connection without starting service
TLLicenseManager --test-tpm
```

### 6. Logging Enhancements
```bash
# Log to specific file
TLLicenseManager --log-file /var/log/tlm-custom.log

# Multiple log destinations
TLLicenseManager --log-console --log-file /var/log/tlm.log --log-syslog

# Structured logging
TLLicenseManager --log-format json
```

### 7. Debug & Diagnostic Options
```bash
# Enable performance profiling
TLLicenseManager --profile

# Enable debug HTTP endpoints
TLLicenseManager --enable-debug-endpoints

# Verbose startup diagnostics
TLLicenseManager --diagnose
```

### 8. Security Options
```bash
# Enable TLS for REST API
TLLicenseManager --rest-tls --rest-cert /path/to/cert.pem

# Enable authentication
TLLicenseManager --enable-auth --auth-config /path/to/auth.json
```

---

## Changelog

### Version 2.0 (January 31, 2026)
- **MAJOR:** Complete regeneration based on actual codebase
- Updated to reflect actual implementation in Main.cpp and MainApp.h
- Added comprehensive validation logic documentation
- Added detailed error messages and troubleshooting
- Updated version to 0.48 and build number format (YYYY.MM.DD.HHMM)
- Added actual logging output examples
- Added TPM status logging details
- Documented configuration override mechanism (SetValue)
- Added platform-specific deployment examples (Windows, Linux, Docker, Kubernetes)
- Added testing and verification procedures
- Added comprehensive troubleshooting section
- Added best practices for different environments
- Added future enhancement suggestions
- Added error messages reference table

### Version 1.0 (January 26, 2026)
- Initial documentation
- Basic CLI options and usage

---

**Document Version:** 2.0  
**Last Updated:** January 31, 2026  
**Application Version:** 0.48  
**Maintainer:** TrustedLicensing Team

<!--
REGENERATION PROMPT:
Regenerate CLI_Integration.md documentation for TLLicenseManager command-line interface.

SCOPE:
- Complete CLI argument parsing and validation
- All supported command-line options (--help, --version, --config, --rest-port, --grpc-port, --log-level, --no-tpm, --tpm-host, --tpm-port)
- Help and version output formats
- Configuration override mechanism
- Priority order (CLI > Config File > Defaults)
- Platform-specific usage (Windows/Linux/Docker/Kubernetes)
- Log levels and output formatting
- Error handling and validation
- Troubleshooting common issues
- Usage examples and best practices

KEY FILES TO REVIEW:
- TLLicenseService/sources/src/Main.cpp (CLI parsing, help, version, validation)
- TLLicenseService/sources/include/MainApp.h (CLI overrides application)
- TLCommon/sources/include/external/argh.h (Argh! parser library)
- TLCommon/sources/include/TLFile.h (SetValue for config overrides)
- TLCommon/sources/src/TLFile.cpp (Implementation)

UPDATE TRIGGERS:
- New CLI options added
- Changes to help or version output
- Validation logic changes
- Configuration override mechanism changes
- New platforms or deployment methods
- Error handling improvements

LAST UPDATED: January 31, 2026
-->
