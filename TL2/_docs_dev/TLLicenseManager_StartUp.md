# TLLicenseManager Startup Sequence and TPM Usage

## Overview

TLLicenseManager is a TPM 2.0-backed licensing service that provides hardware-bound license management with cryptographic attestation. The application uses Trusted Platform Module (TPM) for secure key storage, hardware fingerprinting, and optional NVRAM-based persistence. TPM support can be enabled/disabled both at compile-time and runtime.

**Key Features:**
- Hardware-backed cryptographic operations using TPM 2.0
- Deterministic key generation with reproducibility (seed-based)
- Multi-platform support (Windows/Linux, physical/virtual/container)
- REST and optional gRPC API interfaces
- PCR-based NVRAM authentication (no password storage)
- Runtime TPM disabling via `--no-tpm` flag
- Container-aware initialization with Docker/Kubernetes volume tracking

---

## Architecture Components

### Core Modules

| Module | Purpose | Key Classes |
|--------|---------|-------------|
| **TLLicenseService** | Entry point & business logic | `main()`, `LicenseManagerApp`, `LicenseService`, `PersistenceService`, `ApplicationState` |
| **TLCrypt** | TPM operations | `TLTPM_Service`, `TPMService.h` |
| **TLTpm** | Low-level TPM 2.0 | `Tpm2`, `TpmDevice` (Microsoft TSS.C++ wrapper) |
| **TLProtocols** | API interfaces | `RESTService`, `GRPCService` |
| **TLCommon** | Utilities | `TLConfiguration`, `TLLogger` |
| **TLHardwareInfo** | Hardware detection | `TLHardwareService`, `TLFingerPrintService` |

---

## Complete Startup Sequence

### Phase 1: Main Entry Point
**File:** [TLLicenseService/sources/src/Main.cpp](TLLicenseService/sources/src/Main.cpp)

```
main(argc, argv)
├─ Parse command-line arguments
│  └─ argh::parser cmdl(argc, argv, PREFER_PARAM_FOR_UNREG_OPTION)
│     Supports: --help, --version, --config, --rest-port, --grpc-port,
│               --log-level, --no-tpm
│     Simulator (if TPM_SIMULATOR defined): --tpm-host, --tpm-port
│
├─ Handle built-in commands
│  ├─ --help / -h
│  │  └─ Display usage, options, examples, and config paths
│  │     Shows default directories for config and logs
│  │     Exit with code 0
│  │
│  └─ --version / -v
│     └─ Display version info:
│        - Version: APP_VERSION (e.g., "0.47")
│        - Build: BUILD_NUMBER (e.g., "123")
│        - Platform: PLATFORM_DISPLAY (e.g., "Windows" or "Linux")
│        - TPM Support: "Enabled" or "Disabled" (compile-time TPM_ON flag)
│        - TPM Mode: "Hardware" or "Simulator" (compile-time TPM_SIMULATOR flag)
│        - gRPC Support: "Enabled" or "Disabled" (compile-time GRPC_Service flag)
│        Exit with code 0
│
├─ Validate command-line arguments
│  ├─ Check for unknown flags/parameters
│  │  └─ Compare against validFlags list
│  │     If unknown: Display error in red + help, exit with code 1
│  │
│  ├─ Validate log-level values
│  │  └─ Must be: trace|debug|info|warning|error|fatal
│  │     If invalid: Display error + valid options, exit with code 1
│  │
│  └─ Validate port ranges (1-65535)
│     ├─ rest-port: Must be 1-65535
│     └─ grpc-port: Must be 1-65535
│        If invalid: Display error + help, exit with code 1
│
├─ Initialize logging system
│  ├─ TLLogger::InitLogging(LICENSE_SERVER_NAME)
│  │  └─ Sets up file and console logging to default log directory
│  │
│  └─ Apply CLI log level override if specified
│     └─ IF --log-level provided:
│        ├─ TLLogger::SetLogLevel(logLevel)
│        └─ Log: "CLI: Log level set to '{level}'" [debug]
│
├─ Log application version and platform
│  └─ [info] "--- Start TLLicenseManager (version) [build] on platform"
│     Example: "--- Start TLLicenseManager (0.47) [123] on Linux"
│
├─ Log CLI parameters processing
│  └─ [debug] "Processing command-line arguments..."
│
├─ Process --no-tpm flag early (before initialization)
│  ├─ IF --no-tpm provided:
│  │  ├─ ApplicationState::DisableTPM()
│  │  │  └─ Sets tpmDisabledByCLI = true
│  │  │     Sets tpmConnected = false
│  │  │     Adds status: "TPM Connected" = "false (disabled by CLI)"
│  │  │
│  │  └─ Log: "CLI: --no-tpm flag detected, TPM will be disabled" [info]
│  │
│  └─ ELSE:
│     └─ Log: "CLI: TPM enabled (no --no-tpm flag)" [debug]
│
├─ Log all CLI parameter overrides
│  ├─ --rest-port:
│  │  ├─ IF provided: Log "CLI: REST port override = {port}" [info]
│  │  └─ ELSE: Log "CLI: Using default REST port from config" [debug]
│  │
│  ├─ --grpc-port:
│  │  ├─ IF provided: Log "CLI: gRPC port override = {port}" [info]
│  │  └─ ELSE: Log "CLI: Using default gRPC port from config" [debug]
│  │
│  ├─ --log-level:
│  │  ├─ IF provided: Log "CLI: Log level already set to {level}" [debug]
│  │  └─ ELSE: Log "CLI: Using default log level" [debug]
│  │
│  └─ --config:
│     ├─ IF provided: Log "CLI: Config file override = {path}" [info]
│     └─ ELSE: Log "CLI: Using default config file location" [debug]
│
├─ Log configuration paths
│  ├─ Log: "logPath: {path}" [debug]
│  └─ Log: "configPath: {path}" [debug]
│
├─ IF FASTCRYPT defined:
│  └─ Log: "FASTCRYPT" [warning]
│     (Indicates smaller RSA keys for testing - not production-safe)
│
├─ Check elevation status
│  └─ ApplicationState::CheckElevation()
│     └─ TLHardwareService::IsElevated()
│        ├─ Windows: OpenProcessToken() + GetTokenInformation(TokenElevation)
│        └─ Linux: Check if getuid() == 0
│           Stores result in ApplicationState::applicationElevated
│           Adds status: "Elevated" = "true" or "false"
│
└─ Launch POCO ServerApplication
   ├─ Create LicenseManagerApp instance with parsed cmdl
   └─ lmApp.run(argc, argv)
      └─ POCO handles daemon/service setup and calls initialize() + main()
```

**Requirements:**
- ✅ Must run as Administrator (Windows) or root (Linux) for TPM access
- ✅ Without elevation, TPM operations will fail (but app can still start in --no-tpm mode)
- ✅ All CLI parameters validated before initialization begins

**Logging Configuration:**

Log levels (in order of verbosity): **trace** < **debug** < **info** < **warning** < **error** < **fatal**

Console output colors:
- **trace** - Dark gray (most verbose, internal state changes)
- **debug** - White (detailed diagnostics)
- **info** - Blue (normal operations)
- **warning** - Yellow (potential issues)
- **error** - Red (failures that don't stop execution)
- **fatal** - Red (critical failures)

Command-line examples:
```bash
# Set log level at startup (space-separated syntax)
TLLicenseManager --log-level error

# Multiple options (REST port + verbose logging)
TLLicenseManager --rest-port 8080 --log-level debug

# Disable TPM operations (software-only mode)
TLLicenseManager --no-tpm

# Use custom config file
TLLicenseManager --config /path/to/config.json

# Simulator mode (if compiled with TPM_SIMULATOR)
TLLicenseManager --tpm-host 192.168.1.10 --tpm-port 2321
```

---

### Phase 2: Application Initialization
**File:** [TLLicenseService/sources/include/MainApp.h](TLLicenseService/sources/include/MainApp.h#L53)

```
LicenseManagerApp::initialize(Application& self)
├─ Load configuration files
│  └─ loadConfiguration()
│     └─ POCO searches for TLLicenseManager.json in:
│        - Current directory
│        - Default config directory (platform-specific)
│        - Path specified by --config CLI argument
│
├─ ServerApplication::initialize(self)
│  └─ Base class initialization (POCO framework)
│
├─ ApplicationState::Initialize()
│  ├─ Create JSON status document
│  │  └─ rapidjson::Document with "LMSTATUS" root object
│  │
│  ├─ Record start time
│  │  └─ std::chrono::system_clock::now()
│  │
│  ├─ Store LM version
│  │  └─ "LMVersion" = BUILD_NUMBER
│  │
│  ├─ Store log path
│  │  └─ "LogPath" = TLConfiguration::GetDefaultDirectory(Logs)
│  │
│  └─ Set isInitialized = true
│
├─ Add platform info to status
│  └─ AddSetLMStatus("Compiled for", PLATFORM_DISPLAY)
│     Examples: "Windows", "Linux", "Linux (ARM)"
│
├─ Detect runtime context
│  ├─ Windows:
│  │  └─ IF config.getBool("application.runAsService", false):
│  │     └─ status = "Running As Service"
│  │
│  ├─ Linux:
│  │  ├─ IF config.getBool("application.runAsDaemon", false):
│  │  │  └─ status = "Running As Daemon"
│  │  │
│  │  └─ ELSE:
│  │     └─ ApplicationState::IsRunningAsDaemon()
│  │        └─ Auto-detect daemon mode using multi-factor check:
│  │           ├─ Factor 1: !isatty(STDIN_FILENO) - No controlling terminal
│  │           ├─ Factor 2: getppid() == 1 - Parent is init/systemd
│  │           ├─ Factor 3: getsid(0) == getpid() - Is session leader
│  │           │
│  │           └─ IF 2+ factors true:
│  │              └─ detectedDaemon = true
│  │                 status = "Running As Daemon (detected)"
│  │
│  └─ Default (interactive):
│     └─ status = "Interactive Console"
│
├─ Log runtime context
│  └─ [debug] "{status}"
│     Examples:
│     - "Interactive Console"
│     - "Running As Service" (Windows)
│     - "Running As Daemon" (Linux configured)
│     - "Running As Daemon (detected)" (Linux auto-detected)
│
└─ Store runtime context in ApplicationState
   └─ AddSetLMStatus("RuntimeContext", status)
```

**Runtime Context Detection Details:**

| Platform | Method | Indicators | Example |
|----------|--------|-----------|---------|
| **Windows Interactive** | User launch | N/A | Double-click .exe, PowerShell |
| **Windows Service** | Config flag | `application.runAsService` = true | `sc start TLLicenseManager` |
| **Linux Interactive** | User launch | Terminal attached | `./TLLicenseManager` |
| **Linux Daemon (Config)** | Config flag | `application.runAsDaemon` = true | Systemd with config |
| **Linux Daemon (Detected)** | Auto-detection | 2+ of: no TTY, parent=init, session leader | Systemd, supervisord |

---

### Phase 2.5: Environment Detection (Pre-Persistence)
**File:** [TLLicenseService/sources/include/MainApp.h](TLLicenseService/sources/include/MainApp.h#L122)

This phase occurs in `LicenseManagerApp::main()` **before** persistence initialization.

```
LicenseManagerApp::main()
├─ Create service instances
│  ├─ spPersistence = std::make_shared<PersistenceService>()
│  └─ spLicenseService = std::make_shared<TLLicensing::LicenseSerivce>()
│
├─ ApplicationState::CheckContainer()
│  └─ Detect containerization (Linux only):
│     Methods:
│     ├─ Method 1: Check /.dockerenv file exists → "Docker"
│     ├─ Method 2: Check /run/.containerenv exists → "Podman"
│     └─ Method 3: Parse /proc/1/cgroup for patterns:
│        - "docker" → "Docker"
│        - "kubepods" → "Kubernetes"
│        - "containerd" → "Containerd"
│        - "lxc" → "LXC"
│     │
│     └─ IF container detected AND Docker socket available:
│        ├─ Connect to /var/run/docker.sock
│        ├─ Read hostname from /etc/hostname → Container ID
│        ├─ GET /containers/{id}/json
│        └─ Extract and store in ApplicationState:
│           - ContainerID (short hash)
│           - ContainerName (e.g., "/tl-service")
│           - ContainerImage (e.g., "trustedlicensing:latest")
│           - ContainerStatus (e.g., "running")
│           - VolumeMountCount
│           - VolumeMount0_Name, _Type, _Source, _Destination, _ReadWrite
│           - VolumeMount1_... (for each mount)
│     │
│     Logs:
│     - [debug] "Containerized => true/false"
│     - [debug] "ContainerEnvironment => {type}"
│     - [debug] "Container ID: {id}"
│     - [debug] "Volume Mount 0: /app/data <- host_path [bind]"
│
├─ [trace] "Virtual Machine Status Check"
│  └─ ApplicationState::CheckVirtualMachine()
│     └─ TLHardwareService::GetVMState()
│        Detects virtualization via:
│        - Windows: WMI queries (Win32_ComputerSystem)
│        - Linux: /sys/class/dmi/id/* files, cpuid checks
│        Possible values: VMware, Hyper-V, KVM, Xen, VirtualBox, None
│        Stored in ApplicationState status
│
└─ ApplicationState::CheckTPM()
   ├─ IF tpmDisabledByCLI (--no-tpm flag was used):
   │  └─ Skip TPM check entirely
   │     Status: "TPM Connected" = "false (disabled by CLI)"
   │     No error logged (intentional)
   │
   ├─ ELSE IF TPM_ON (compiled with TPM support):
   │  ├─ Status: "TPM available" = "in binary"
   │  ├─ Create TLTPM_Service instance to test connection
   │  ├─ IF TPM connection succeeds:
   │  │  └─ Status: "TPM Connected" = "true"
   │  │     tpmConnected = true
   │  │
   │  └─ IF TPM connection fails:
   │     ├─ tpmConnected = false
   │     ├─ Status: "TPM Connected" = "false"
   │     └─ No error logged (will be handled by PersistenceService)
   │
   └─ ELSE (!TPM_ON - compiled without TPM):
      ├─ Status: "TPM available" = "binary unavailable"
      ├─ Status: "TPM Connected" = "false (not compiled in)"
      └─ No logging at this stage
```

**After Environment Detection:**
```
└─ spPersistence->Initialize()
   IF fails:
   └─ return Application::EXIT_CANTCREAT

├─ Log TPM final status
│  IF TPM_ON:
│  ├─ IF TPMConnected():
│  │  └─ [info] "TPM enabled and will be used"
│  └─ ELSE:
│     └─ [info] "TPM compiled in but disabled (--no-tpm or not available)"
│  ELSE:
│  └─ [warning] "TPM not compiled in"
│
└─ spLicenseService->Start(spPersistence)
```

---

### Phase 3: Persistence Layer Initialization

> **Important**: Environment detection (Container, VM, TPM checks) now occurs in MainApp **BEFORE** PersistenceService::Initialize().
> See Phase 2 Application Initialization for those checks. The flow is:
> 1. MainApp calls ApplicationState::CheckContainer()
> 2. MainApp calls ApplicationState::CheckVirtualMachine()  
> 3. MainApp calls ApplicationState::CheckTPM()
> 4. MainApp calls spPersistence->Initialize()

**File:** [TLLicenseService/sources/src/PersistenceService.cpp](TLLicenseService/sources/src/PersistenceService.cpp#L58)

```
PersistenceService::Initialize()
├─ [trace] "PersistenceService::Initialize"
│
├─ 1. Create persistence directory
│  └─ spConfiguration->CreateDefaultDirectory(TLDirectory::Persistence)
│     Platform-specific paths:
│     - Windows: C:\ProgramData\TrustedLicensing\Persistence\
│     - Linux: /var/lib/TrustedLicensing/Persistence/
│
├─ 2. TPM Availability Check (Logging Only - Already Determined in MainApp)
│  ├─ IF TPM_ON (compiled with TPM support):
│  │  └─ IF !ApplicationState::RunningInContainer() AND !ApplicationState::TPMConnected():
│  │     └─ [warning] "PersistenceService - TPM not available (may be disabled or missing)"
│  │        Note: This is informational - TPM detection already completed in MainApp
│  │
│  └─ ELSE (!TPM_ON - compiled without TPM):
│     └─ [info] "PersistenceService - TPM not compiled in binary"
│
├─ 3. Persistence File Management
│  ├─ Check if persistence.bin exists
│  │  └─ PersistenceFileName = "{PersistenceDir}/persistence.bin"
│  │
│  ├─ tmpVaultFileName = PERSISTENCE_VAULT_FILE ("vault.bin")
│  │
│  ├─ IF NOT EXISTS (First-time initialization - Cold Start):
│  │  ├─ PersistenceFileWritten = true
│  │  │
│  │  ├─ CreateRandomString(15KB-75KB)
│  │  │  └─ boost::mt19937 RNG with random_device seed
│  │  │     Generate random bytes (0-255) into std::vector<char>
│  │  │     Purpose: Steganographic container for secret hiding
│  │  │     Size randomized to prevent fingerprinting
│  │  │     Log: [trace] "PersistenceService core size init: {size} kByte"
│  │  │
│  │  ├─ Generate and embed secrets at fixed positions:
│  │  │  ├─ Position 100 (variable length): Vault ID + filename
│  │  │  │  ├─ vaultID = AESCrypt::GenerateIV() (32 hex chars)
│  │  │  │  └─ persistenceValutValue = "{vaultID}.vault.bin"
│  │  │  │     Example: "a3b2c4d5...f9.vault.bin"
│  │  │  │     WriteValue(PERSISTENCE_WAS_INITIALIZED_POS, persistenceValutValue)
│  │  │  │
│  │  │  ├─ Position 200 (64 hex chars): AES Vault Key
│  │  │  │  ├─ aesKeyGen = AESCrypt::GenerateIV()
│  │  │  │  └─ WriteValue(AES_KEY_PERSISTENCE_VAULT_POS, aesKeyGen)
│  │  │  │
│  │  │  └─ Position 250 (64 hex chars): AES Vault IV
│  │  │     ├─ aesIVCGen = AESCrypt::GenerateIV()
│  │  │     └─ WriteValue(AES_IVC_PERSISTENCE_VAULT_POS, aesIVCGen)
│  │  │
│  │  └─ Note: WritePersistenceCoreFile() called later after validation
│  │
│  └─ ELSE (Warm start - File exists):
│     ├─ PersistenceFileWritten = false
│     │
│     └─ ReadPersistenceCoreFile()
│        ├─ Read ciphertext from persistence.bin
│        │  Log: [trace] "Read {PersistenceFileName}"
│        ├─ cipher = TLCommon::Files::ReadFile(PersistenceFileName)
│        ├─ AES-decrypt: decrypt = spAEShc->AESDecrypt(cipher)
│        │  Using hardcoded key/IV:
│        │  - Key: AES_KEY_PERSISTENCE_LOCAL
│        │  - IV:  AES_IVC_PERSISTENCE_LOCAL
│        └─ Store plaintext in PersistenceCoreData (in-memory)
│
├─ 4. Extract Secrets from Memory
│  ├─ Calculate vault filename length
│  │  └─ length = AES_IV_LENGTH * 2 + tmpVaultFileName.length() + 1
│  │
│  ├─ VaultFileName = ReadValue(PERSISTENCE_WAS_INITIALIZED_POS, length)
│  │  └─ Extract: "{hexID}.vault.bin"
│  │
│  ├─ AESGenKey = ReadValue(AES_KEY_PERSISTENCE_VAULT_POS, AES_IV_LENGTH * AES_FACTOR)
│  │  └─ 32 bytes as 64 hex characters (AES_IV_LENGTH=32, AES_FACTOR=2)
│  │
│  └─ AESGenIV = ReadValue(AES_IVC_PERSISTENCE_VAULT_POS, AES_IV_LENGTH * AES_FACTOR)
│     └─ 32 bytes as 64 hex characters
│
└─ 5. Validation
   ├─ Verify AES keys are valid hexadecimal
   │  └─ TLCommon::Conversion::isHexadecimal(AESGenKey)
   │     TLCommon::Conversion::isHexadecimal(AESGenIV)
   │     IF invalid:
   │     - [error] "PersistenceService - key initializatin failure!"
   │     - ApplicationState::AddLMStatusError("PersistenceService", "key initializatin failure")
   │     - retval = false
   │
   ├─ Verify vault filename valid
   │  └─ IF !VaultFileName.find(PERSISTENCE_VAULT_FILE):
   │     - [error] "PersistenceService - vault initializatin failure!"
   │     - ApplicationState::AddLMStatusError("PersistenceService", "vault initializatin failure")
   │     - retval = false
   │
   ├─ IF all validations pass (retval == true):
   │  ├─ [info] "PersistenceService - initialized!"
   │  ├─ ApplicationState::AddSetLMStatus("PersistenceService", "initialized")
   │  │
   │  └─ Create AESCrypt instance for vault operations
   │     └─ spAESvault = std::make_unique<AESCrypt>(AESGenKey, AESGenIV)
   │
   └─ return retval (true if success, false if validation failed)
```

**Exception Handling:**
```cpp
try {
    // All initialization steps above...
} catch (const std::exception& e) {
    BOOST_LOG_TRIVIAL(error) << "PersistenceService::Initialize " << e.what();
    return false;
}
│  │     └─ TLCommon::Files::SaveData(persistence.bin, encrypted)
│  │
│  └─ ELSE (Warm start):
│     ├─ PersistenceFileWritten = false
│     │
│     └─ ReadPersistenceCoreFile()
│        ├─ Read ciphertext from persistence.bin
│        ├─ AES-decrypt with hardcoded key/IV
│        └─ Store plaintext in PersistenceCoreData (in-memory)
│
├─ 4. Extract Secrets from Memory
│  ├─ VaultFileName = ReadValue(position 100, variable length)
│  │  └─ Extract: "{hexID}.vault.bin"
│  │
│  ├─ AESGenKey = ReadValue(position 200, 64 chars)
│  │  └─ 32 bytes as 64 hex characters
│  │
│  └─ AESGenIV = ReadValue(position 250, 64 chars)
│     └─ 32 bytes as 64 hex characters
│
└─ 5. Validation
   ├─ Verify AES keys are valid hexadecimal
   │  └─ TLCommon::Conversion::isHexadecimal(AESGenKey)
   │     TLCommon::Conversion::isHexadecimal(AESGenIV)
   │     IF invalid:
   │     - [error] "PersistenceService - key initialization failure!"
   │     - AddLMStatusError("PersistenceService", "key initialization failure")
   │     - retval = false
   │
   ├─ Verify vault filename valid
   │  └─ IF !VaultFileName.find("vault.bin"):
   │     - [error] "PersistenceService - vault initialization failure!"
   │     - AddLMStatusError("PersistenceService", "vault initialization failure")
   │     - retval = false
   │
   ├─ Create AESCrypt instance for vault operations
   │  └─ spAESvault = std::make_unique<AESCrypt>(AESGenKey, AESGenIV)
   │
   └─ IF all validations pass:
      ├─ [info] "PersistenceService - initialized!"
      ├─ AddSetLMStatus("PersistenceService", "initialized")
      └─ return true
```

**Security Model:**
- **Random container (15-75 KB)**: Provides steganographic hiding of secrets
- **Fixed positions**: Implementation detail (obfuscation, not security)
- **AES encryption**: Hardcoded key protects persistence.bin at rest
- **Filesystem permissions**: Requires elevated access to read/write
- **Vault keys**: AESGenKey/AESGenIV are software-generated but encrypted

**Purpose of Secrets:**
| Secret | Purpose | Source |
|--------|---------|--------|
| **VaultFileName** | Identifies vault.bin | Software RNG |
| **AESGenKey** | Encrypts vault.bin | Software RNG |
| **AESGenIV** | Vault encryption IV | Software RNG |

**File Dependencies:**
```
persistence.bin (encrypted)
    └─ Contains: VaultFileName, AESGenKey, AESGenIV
       └─ Used to decrypt ─┐
                            ↓
                      vault.bin (encrypted)
                          └─ Contains: LocalPublicKey, LocalPrivateKey, SRK (public)
```

---

### Phase 4: TPM Initialization
**File:** [TLCrypt/sources/src/TPMService.cpp](TLCrypt/sources/src/TPMService.cpp#L12)

```
TLTPM_Service::Constructor()
├─ Initialize TPM status
│  └─ tpmStatus = std::make_unique<TPMStatus>()
│     Fields: IsConnected (bool), Message (string)
│
├─ 1. Check Elevation
│  └─ isElevated = TLHardwareService::IsElevated()
│     ├─ Windows: OpenProcessToken() + GetTokenInformation(TokenElevation)
│     └─ Linux: getuid() == 0
│        IF not elevated:
│        - [error] "TPM requires elevated rights"
│        - Return early (device = nullptr, IsConnected = false)
│
├─ 2. Select TPM Device
│  ├─ IF TPM_SIMULATOR (compile-time flag):
│  │  ├─ Read environment or defaults:
│  │  │  - hostname = TPM_DEVICE (default: "localhost")
│  │  │  - port = TPM_PORT (default: "2321")
│  │  │
│  │  ├─ device = new TpmTcpDevice(hostname, port)
│  │  │  └─ TCP socket connection to MS TPM Simulator
│  │  │
│  │  └─ [trace] "TPM_SIMULATOR START {hostname}:{port}"
│  │
│  └─ ELSE (Production hardware TPM):
│     ├─ device = new TpmTbsDevice()
│     │  └─ Platform-specific device access:
│     │     ├─ Windows: TBS (TPM Base Services) API
│     │     │  └─ Uses Tbsi.dll: Tbsi_Context_Create()
│     │     │     Provides kernel-level TPM resource management
│     │     │
│     │     └─ Linux: Device access priority (tries in order):
│     │        1. /dev/tpm0 - Direct character device
│     │        2. TCTI abrmd - Resource manager daemon (socket)
│     │        3. /dev/tpmrm0 - Kernel resource manager (PREFERRED)
│     │        4. User-mode TRM - Socket 127.0.0.1:2323
│     │
│     └─ [trace] "TPM Start"
│
├─ 3. Connect to TPM
│  ├─ [trace] "Connect to TPM"
│  │
│  ├─ IF !device->Connect():
│  │  ├─ device = nullptr
│  │  ├─ tpmStatus->IsConnected = false
│  │  ├─ tpmStatus->Message = "Could not connect to TPM."
│  │  └─ [debug] "Could not connect to TPM."
│  │     Return early (TPM not available)
│  │
│  └─ ELSE (connection successful):
│     ├─ tpmStatus->Message = "TPM device found."
│     ├─ tpmStatus->IsConnected = true
│     └─ [debug] "TPM device found."
│
├─ 4. Configure TPM Context
│  ├─ tpm._SetDevice(*device)
│  │  └─ Associate Tpm2 object with device
│  │
│  └─ IF IsUsingSimulator:
│     ├─ device->PowerCycle()
│     │  └─ Send TPM power commands (simulator only)
│     │
│     └─ tpm.Startup(TPM_SU::CLEAR)
│        └─ TPM2_Startup command
│           Note: NOT called for hardware TPM (already started by platform)
│
└─ 5. Initialize TPM Capabilities
   └─ TpmConfig::Init(tpm)
      ├─ [trace] "Init TPM"
      │
      ├─ Query implemented algorithms
      │  └─ tpm.GetCapability(TPM_CAP::ALGS, ...)
      │     Returns: List of TPM_ALG_ID values
      │     Examples: RSA, AES, SHA256, HMAC, ECC
      │
      ├─ Filter hash algorithms
      │  └─ For each algorithm with TPMA_ALGORITHM::hash attribute
      │     Store available hash functions
      │
      └─ Query implemented commands
         └─ tpm.GetCapability(TPM_CAP::COMMANDS, ...)
            Returns: Bitmap of supported TPM 2.0 commands
            Used for feature detection (e.g., NV_Certify available?)
```

**Platform-Specific Behavior:**

| Platform | Device Path | Access Method | Sessions | Resource Manager | Notes |
|----------|-------------|---------------|----------|------------------|-------|
| **Windows** | TBS API | Tbsi.dll | HMAC sessions used | Built-in (TBS) | Always available |
| **Linux /dev/tpm0** | Direct char device | open() + read/write | Optional | None | Root only, single process |
| **Linux /dev/tpmrm0** | Kernel RM | open() + read/write | Optional | Kernel (v4.12+) | **PREFERRED** - concurrent access |
| **Linux abrmd** | TCTI daemon | D-Bus/socket | Optional | Userspace daemon | Legacy, being phased out |
| **Simulator** | TCP socket | localhost:2321 | Full control | None | Development/testing only |
| **Container** | Host passthrough | Same as host | Depends on host | Host's manager | Sees host PCR values |

**Linux Resource Manager Benefits:**
- ✅ Multiple processes can access TPM simultaneously
- ✅ Automatic session management and context swapping
- ✅ Transient object cleanup (prevents handle exhaustion)
- ✅ No explicit session creation needed for most operations
- ⚠️ Not available on kernels < 4.12 (requires fallback to /dev/tpm0)

**TPM Connection Error Handling:**
```cpp
try {
    if (!device || !device->Connect()) {
        device = nullptr;
        tpmStatus->IsConnected = false;
        tpmStatus->Message = "Could not connect to TPM.";
        BOOST_LOG_TRIVIAL(debug) << tpmStatus->Message;
    } else {
        tpmStatus->Message = "TPM device found.";
        tpmStatus->IsConnected = true;
        // Continue with initialization...
    }
} catch (const std::exception& ex) {
    BOOST_LOG_TRIVIAL(error) << ex.what();
    // TPM initialization failed, but app continues (software-only mode)
}
```

**Destructor Cleanup:**
```cpp
TLTPM_Service::~TLTPM_Service()
{
    // Flush all transient handles (persistent handles remain)
    for (const auto& mapHandle : tpmKeyHandles) {
        tpm._AllowErrors().FlushContext(mapHandle.second);
        auto rc = EnumToStr(tpm._GetLastResponseCode());
    }
    
    if (device) {
        device->Close();
        delete device;
    }
    
    BOOST_LOG_TRIVIAL(trace) << "TPM closed";
}
```

---

### Phase 5: Key Generation
**File:** [TLLicenseService/sources/src/LicenseService.cpp](TLLicenseService/sources/src/LicenseService.cpp#L12)

```
LicenseService::Constructor
├─ [trace] "LicenseService::LicenseService()"
│
├─ Initialize configuration
│  └─ spConfiguration = std::make_unique<TLConfiguration>()
│
├─ Conditional TPM Service Creation
│  ├─ IF ApplicationState::TPMConnected():
│  │  ├─ [debug] "Initializing TPM service"
│  │  └─ spTPMService = std::make_unique<TLTPM_Service>()
│  │     └─ Creates TPM connection (see Phase 4)
│  │
│  └─ ELSE:
│     ├─ [debug] "TPM service not initialized (TPM disabled or not connected)"
│     └─ spTPMService = nullptr
│        Purpose: Prevents TPM access attempts when:
│        - --no-tpm flag was used
│        - TPM not available in container
│        - TPM hardware missing/disabled
│
└─ Set vault file path
   └─ vaultFileName = "{PersistenceDir}/vault.bin"

LicenseService::Start(spPersistence)
├─ [trace] "LicenseService::Start"
│
├─ Store persistence service reference
│  └─ spPersistence = persistence
│
├─ Get persistence data
│  └─ persistenceData = spPersistence->GetPersistenceData()
│     Fields: PersistenceFileWritten
│
├─ Create JSON object mapper
│  └─ jsonObjectMapper = TLCommon::Serialization::CreateObjectMapper()
│     (oatpp JSON serialization)
│
├─ Check if vault.bin exists
│  │
│  ├─ IF vault.bin EXISTS (Warm start):
│  │  ├─ [debug] "{vaultFileName} found"
│  │  │
│  │  ├─ Read and decrypt vault
│  │  │  └─ vaultData = spPersistence->ReadVaultFile()
│  │  │     └─ AES decrypt with AESGenKey/AESGenIV
│  │  │
│  │  ├─ Deserialize JSON
│  │  │  └─ wrapperlicenseManagerKeys = 
│  │  │        jsonObjectMapper->readFromString<LicenseManagerKeys>(vaultData)
│  │  │
│  │  └─ Validate SRK (if TPM connected)
│  │     └─ IF ApplicationState::TPMConnected():
│  │        └─ IF wrapperlicenseManagerKeys->SRK == nullptr:
│  │           ├─ [error] "No Storage Root Key"
│  │           ├─ AddLMStatusError("LicenseService", "No Storage Root Key")
│  │           └─ return (fatal error)
│  │
│  └─ ELSE vault.bin NOT EXISTS (Cold start / First-time initialization):
│     │
│     ├─ Validate persistence state
│     │  └─ IF !persistenceData.PersistenceFileWritten:
│     │     ├─ [error] "LicenseService::Start Inconsistent data"
│     │     ├─ AddLMStatusError("LicenseService", "Inconsistent data")
│     │     └─ return (fatal error)
│     │
│     ├─ [debug] "{vaultFileName} not found"
│     ├─ [debug] "Generate Keys"
│     │
│     ├─ 1. Generate Local RSA Keys (Software)
│     │  ├─ localKeys = RSACrypt::GenerateKeys()
│     │  │  └─ Uses Botan library:
│     │  │     ├─ Algorithm: RSA
│     │  │     ├─ Key size: 2048 bits (production)
│     │  │     │           1024 bits (if FASTCRYPT defined - testing only)
│     │  │     ├─ Public exponent: 65537
│     │  │     └─ Format: PEM (PKCS#8 for private, X.509 SubjectPublicKeyInfo for public)
│     │  │
│     │  ├─ IF localKeys.HasError():
│     │  │  ├─ [error] "LicenseService::Start Failed to generate keys: {error}"
│     │  │  ├─ AddLMStatusError("LicenseService", "Failed to generate keys")
│     │  │  └─ return
│     │  │
│     │  ├─ [debug] "Keys generated successfully"
│     │  ├─ [debug] "Public key length: {length}"
│     │  └─ [debug] "Private key length: {length}"
│     │
│     ├─ Validate key generation
│     │  └─ IF localKeys.publicKeyPEM.empty() OR localKeys.privateKeyPEM.empty():
│     │     ├─ [error] "LicenseService::Start Generated keys are empty"
│     │     ├─ AddLMStatusError("LicenseService", "Generated keys are empty")
│     │     └─ return
│     │
│     ├─ Create DTO for key storage
│     │  └─ dto_LicenseManagerKeys = LicenseManagerKeys::createShared()
│     │     └─ dto_LicenseManagerKeys->LocalPublicKey = localKeys.publicKeyPEM
│     │        dto_LicenseManagerKeys->LocalPrivateKey = localKeys.privateKeyPEM
│     │
│     ├─ 2. Generate TPM Keys (Hardware-bound)
│     │  └─ IF ApplicationState::IsElevated():
│     │     │
│     │     └─ IF ApplicationState::TPMConnected():
│     │        │
│     │        ├─ Ensure TPM service exists
│     │        │  └─ IF !spTPMService:
│     │        │     ├─ [debug] "Initializing TPM service for key generation"
│     │        │     └─ spTPMService = std::make_unique<TLTPM_Service>()
│     │        │
│     │        ├─ Generate temporary TPM auth and seed
│     │        │  ├─ tpmAuth = spTPMService->Randomize(16).templateValue
│     │        │  │  └─ Uses TPM hardware RNG for cryptographically secure random bytes
│     │        │  │
│     │        │  └─ tpmSeed = spTPMService->Randomize(16).templateValue
│     │        │     └─ Uses TPM hardware RNG for cryptographically secure random bytes
│     │        │     Note: Generated fresh each time, not persisted
│     │        │
│     │        ├─ Create Storage Root Key (SRK)
│     │        │  ├─ Call: tpmSRK = spTPMService->InitStorageRootKey(
│     │        │  │           auth: tpmAuth,
│     │        │  │           seed: tpmSeed,
│     │        │  │           persistence: PERSISTENCE_SRK_EVICT  (value: 1000)
│     │        │  │        )
│     │        │  │
│     │        │  ├─ Inside InitStorageRootKey():
│     │        │  │  ├─ Create SRK template:
│     │        │  │  │  └─ TPMT_PUBLIC(
│     │        │  │  │       nameAlg: SHA256,
│     │        │  │  │       objectAttributes:
│     │        │  │  │         decrypt | fixedParent | fixedTPM |
│     │        │  │  │         sensitiveDataOrigin | userWithAuth,
│     │        │  │  │       authPolicy: null (uses auth value, not policy),
│     │        │  │  │       parameters: TPMS_RSA_PARMS(
│     │        │  │  │         symmetric: null,
│     │        │  │  │         scheme: OAEP-SHA256,
│     │        │  │  │         keyBits: 2048,
│     │        │  │  │         exponent: 65537
│     │        │  │  │       ),
│     │        │  │  │       unique: TPM2B_PUBLIC_KEY_RSA(seed)
│     │        │  │  │     )
│     │        │  │  │
│     │        │  │  ├─ Create sensitive area:
│     │        │  │  │  └─ TPMS_SENSITIVE_CREATE(auth, null)
│     │        │  │  │
│     │        │  │  ├─ [trace] "Create StorageRootKey"
│     │        │  │  │
│     │        │  │  ├─ Generate primary key:
│     │        │  │  │  └─ rsaKey = tpm._AllowErrors().CreatePrimary(
│     │        │  │  │       hierarchy: TPM_RH::OWNER,
│     │        │  │  │       inSensitive: sensCreate,
│     │        │  │  │       inPublic: srkTemplate,
│     │        │  │  │       outsideInfo: null,
│     │        │  │  │       creationPCR: null
│     │        │  │  │     )
│     │        │  │  │     └─ Returns: handle, outPublic, ...
│     │        │  │  │        **Note**: Fresh random seed generates unique keys each time
│     │        │  │  │
│     │        │  │  ├─ Check for errors:
│     │        │  │  │  └─ IF !tpm._LastCommandSucceeded():
│     │        │  │  │     ├─ [error] "Code: {TPMRC}"
│     │        │  │  │     ├─ [error] "TPMError {message}"
│     │        │  │  │     └─ return error
│     │        │  │  │
│     │        │  │  ├─ Set handle auth:
│     │        │  │  │  └─ rsaKey.handle.SetAuth(tpmAuth)
│     │        │  │  │
│     │        │  │  ├─ Store in memory maps:
│     │        │  │  │  ├─ tpmKeyHandles["SRK"] = rsaKey.handle
│     │        │  │  │  └─ publicKeys["SRK"] = rsaKey.outPublic
│     │        │  │  │
│     │        │  │  ├─ Make key persistent:
│     │        │  │  │  ├─ persistentHandle = TPM_HANDLE::Persistent(1000)
│     │        │  │  │  │  └─ Converts slot number to TPM handle:
│     │        │  │  │  │     0x81000000 + 1000 = 0x810003E8
│     │        │  │  │  │
│     │        │  │  │  ├─ Delete any existing key at this slot:
│     │        │  │  │  │  └─ tpm._AllowErrors().EvictControl(
│     │        │  │  │  │       TPM_RH::OWNER, persistentHandle, persistentHandle)
│     │        │  │  │  │
│     │        │  │  │  ├─ persistentHandle.SetAuth(tpmAuth)
│     │        │  │  │  │
│     │        │  │  │  └─ Persist the new key:
│     │        │  │  │     └─ tpm.EvictControl(
│     │        │  │  │          TPM_RH::OWNER, rsaKey.handle, persistentHandle)
│     │        │  │  │        └─ Key now survives reboots at handle 0x810003E8
│     │        │  │  │
│     │        │  │  └─ return success
│     │        │  │
│     │        │  ├─ IF tpmSRK.Success():
│     │        │  │  ├─ Export public key as PEM:
│     │        │  │  │  └─ dto_LicenseManagerKeys->SRK = 
│     │        │  │  │        spTPMService->CreatePublicKeyPEM("StorageRootKey")
│     │        │  │  │     └─ Uses Botan to convert TPM public key to X.509 PEM format
│     │        │  │  │
│     │        │  │  └─ Note: Private key NEVER leaves TPM chip
│     │        │  │
│     │        │  └─ ELSE (SRK creation failed):
│     │        │     ├─ [error] "LicenseService::Start tpmSRK: {error}"
│     │        │     └─ AddLMStatusError("LicenseService tpmSRK: ", error)
│     │        │
│     │        └─ ELSE (TPM not connected):
│     │           └─ [debug] "LicenseService::Start TPM not connected"
│     │
│     │     └─ ELSE (not elevated):
│     │        ├─ [debug] "LicenseService::Start not elevated"
│     │        └─ AddLMStatusError("LicenseService", "not elevated")
│     │
│     ├─ 3. Serialize and encrypt vault
│     │  ├─ vaultData = jsonObjectMapper->writeToString(dto_LicenseManagerKeys)
│     │  │  └─ JSON format:
│     │  │     {
│     │  │       "LocalPublicKey": "-----BEGIN PUBLIC KEY-----\n...",
│     │  │       "LocalPrivateKey": "-----BEGIN PRIVATE KEY-----\n...",
│     │  │       "SRK": "-----BEGIN PUBLIC KEY-----\n..."  (if TPM connected)
│     │  │     }
│     │  │
│     │  ├─ Write encrypted vault:
│     │  │  └─ spPersistence->WriteVaultFile(vaultData)
│     │  │     └─ AES-256 encrypt with AESGenKey/AESGenIV from persistence.bin
│     │  │
│     │  └─ Write persistence file:
│     │     └─ spPersistence->WritePersistenceCoreFile()
│     │        (Re-encrypt persistence.bin with any updates)
│     │
│     └─ 4. Load keys back into memory:
│        └─ wrapperlicenseManagerKeys = 
│              jsonObjectMapper->readFromString<LicenseManagerKeys>(vaultData)
│
└─ 5. Generate Hardware Fingerprints
   ├─ Get fingerprint keys:
   │  └─ keys = GetFingerPrintKeys()
   │     └─ Returns JSON:
   │        {
   │          "LocalPublicKey": "...",
   │          "SRK": "..."  (if wrapperlicenseManagerKeys->SRK != nullptr)
   │        }
   │
   ├─ Create fingerprint service:
   │  └─ spFingerPrintService = std::make_unique<TLFingerPrintService>(keys)
   │     └─ Collects hardware identifiers:
   │        - CPU ID (via cpuid instruction)
   │        - Motherboard serial
   │        - MAC addresses
   │        - Disk serial numbers
   │
   ├─ Generate Fallback fingerprint (always):
   │  └─ ApplicationState::StoreFingerPrint(
   │       FingerPrintType::Fallback,
   │       spFingerPrintService->GetFingerPrint(Fallback)
   │     )
   │     └─ Combines: SHA256(HardwareIDs + LocalPublicKey)
   │        Purpose: Software-based hardware binding (no TPM required)
   │
   └─ Generate TPM fingerprint (if TPM connected):
      └─ IF ApplicationState::TPMConnected():
         └─ ApplicationState::StoreFingerPrint(
              FingerPrintType::TPM,
              spFingerPrintService->GetFingerPrint(TPM)
            )
            └─ Combines: SHA256(HardwareIDs + SRK_PublicKey)
               Purpose: Hardware-backed binding (TPM required)
```

**Key Characteristics:**

| Key Type | Storage Location | Private Key Location | Reproducible | Use Case | Handle |
|----------|-----------------|---------------------|--------------|----------|--------|
| **Local RSA** | vault.bin (AES encrypted) | File on disk | ❌ No (random generation) | Software crypto operations | N/A |
| **SRK** | TPM NV 0x810003E8 | Inside TPM chip | ❌ No (unique per cold start) | Encryption/Decryption | Persistent slot 1000 |

**TPM Key Generation:**
The TPM SRK is generated using `TPM2_CreatePrimary` with fresh random values on each cold start:
- Fresh `auth` + `seed` generated from TPM hardware RNG
- Creates **unique key pair** for each initialization
- Private key never exposed outside TPM
- Public key exported as PEM for fingerprinting
- Keys stored in persistent TPM storage (survives reboots)

---

### Phase 6: Service Startup
**File:** [TLLicenseService/sources/include/MainApp.h](TLLicenseService/sources/include/MainApp.h#L91)

```
LicenseManagerApp::main(const std::vector<std::string>& args)
├─ Create configuration
│  ├─ spConfiguration = std::make_unique<TLConfiguration>()
│  └─ pConfig = spConfiguration->GetDefaultConfigurationFile(LICENSE_SERVER_NAME)
│
├─ Apply CLI overrides to configuration
│  ├─ [debug] "Applying CLI overrides to configuration..."
│  │
│  ├─ IF cmdl("rest-port"):
│  │  ├─ Extract port: cmdl("rest-port") >> restPort
│  │  ├─ pConfig->SetValue("TrustedLicensing.REST.ServerPort", restPort)
│  │  └─ [info] "Config updated: REST.ServerPort = {port}"
│  │
│  ├─ IF cmdl("grpc-port"):
│  │  ├─ Extract port: cmdl("grpc-port") >> grpcPort
│  │  ├─ pConfig->SetValue("TrustedLicensing.gRPC.ServerPort", grpcPort)
│  │  └─ [info] "Config updated: gRPC.ServerPort = {port}"
│  │
│  └─ IF cmdl("log-level"):
│     ├─ Extract level: cmdl("log-level") >> logLevel
│     ├─ pConfig->SetValue("TrustedLicensing.LicenseManager.LogLevel", logLevel)
│     └─ [info] "Config updated: LogLevel = {level}"
│
├─ Create service instances
│  ├─ spPersistence = std::make_shared<PersistenceService>()
│  └─ spLicenseService = std::make_shared<LicenseService>()
│
├─ 1. Initialize Persistence Layer
│  ├─ IF !spPersistence->Initialize():
│  │  └─ return Application::EXIT_CANTCREAT
│  │     (Fatal error - cannot create required directories/files)
│  │
│  └─ (See Phase 3 for full initialization details)
│
├─ 1a. Log TPM Status After Initialization
│  ├─ #if TPM_ON (compile-time check)
│  │  ├─ IF ApplicationState::TPMConnected():
│  │  │  └─ [info] "TPM enabled and will be used"
│  │  │
│  │  └─ ELSE:
│  │     └─ [info] "TPM compiled in but disabled (--no-tpm or not available)"
│  │
│  └─ #else (TPM_ON not defined)
│     └─ [warning] "TPM not compiled in"
│
├─ 2. Start License Service
│  └─ spLicenseService->Start(spPersistence)
│     └─ (See Phase 5 for full key generation and loading)
│
├─ 3. Start gRPC Service [if GRPC_Service enabled]
│  ├─ #if GRPC_Service
│  │  ├─ configServerPort = pConfig->GetValue("TrustedLicensing.gRPC.ServerPort")
│  │  │  └─ Default: "52013"
│  │  │
│  │  ├─ grpcService = std::make_unique<GRPCService>()
│  │  │
│  │  └─ std::jthread grpcServer([&grpcService, &grpcServiceFinishedSuccess] {
│  │     ├─ [debug] "start gRPC"
│  │     │
│  │     ├─ std::jthread startServer([&grpcService, &success] {
│  │     │  ├─ success = grpcService->Run()
│  │     │  │  └─ GRPCService::Run():
│  │     │  │     ├─ grpc::ServerBuilder builder
│  │     │  │     ├─ builder.AddListeningPort("{port}", credentials)
│  │     │  │     ├─ builder.RegisterService(&service_)
│  │     │  │     ├─ server = builder.BuildAndStart()
│  │     │  │     └─ HandleRpcs() - Async RPC event loop
│  │     │  │        Blocks until ShutDown() called
│  │     │  │
│  │     │  └─ [debug] "gRPC Run finished => success: {success}"
│  │     │  })
│  │     │
│  │     └─ (Thread runs until shutdown requested)
│  │     })
│  │
│  └─ #endif
│
├─ 4. Start REST API Service (Always enabled)
│  ├─ restService = std::make_unique<RESTService>(spLicenseService)
│  │  └─ Passes LicenseService reference for controllers
│  │
│  └─ std::jthread restServer([&restService](std::stop_token serverToken) {
│     ├─ [debug] "start REST"
│     │
│     ├─ restReq = restService->Start(serverToken)
│     │  └─ RESTService::Start():
│     │     ├─ oatpp::base::Environment::init()
│     │     │  └─ Initialize oatpp framework
│     │     │
│     │     ├─ Create RESTComponent
│     │     │  └─ Configure router, object mapper, connection provider
│     │     │
│     │     ├─ Create StatusController(spLicenseService)
│     │     │  └─ Endpoints:
│     │     │     - GET /status - Application status JSON
│     │     │     - GET /fingerprint - Hardware fingerprints
│     │     │     - POST /license - License operations
│     │     │     - GET /health - Health check
│     │     │
│     │     ├─ Create connection provider
│     │     │  └─ oatpp::network::tcp::server::ConnectionProvider
│     │     │     (Default port: 52014)
│     │     │
│     │     └─ oatpp::network::Server::run()
│     │        └─ Blocks until stop requested
│     │           Listens for HTTP requests on configured port
│     │
│     ├─ IF !restReq.Success:
│     │  ├─ [error] "{restReq.ErrorMessage}"
│     │  │
│     │  └─ #if Windows
│     │     └─ [info] "restart hns service"
│     │        (Windows-specific network service hint)
│     │
│     └─ ELSE:
│        └─ [debug] "REST finished"
│     })
│
├─ 5. Wait for Termination Signal
│  ├─ [debug] "Wait ForTermination Request"
│  │
│  └─ waitForTerminationRequest()
│     └─ POCO ServerApplication method
│        Blocks until:
│        - SIGTERM received (systemd stop)
│        - SIGINT received (Ctrl+C)
│        - Windows service stop signal
│        - POCO Application::terminate() called
│
├─ Termination received
│  └─ [debug] "Termination Request Received"
│
└─ 6. Graceful Shutdown
   ├─ #if GRPC_Service
   │  └─ IF grpcServiceFinishedSuccess:
   │     └─ grpcService->ShutDown()
   │        └─ server->Shutdown()
   │           └─ Stops accepting new RPCs
   │              Waits for in-flight RPCs to complete
   │
   ├─ Stop REST server
   │  └─ restServer.request_stop()
   │     └─ Signals stop_token → breaks server loop
   │        oatpp server stops accepting connections
   │
   ├─ Thread cleanup (automatic)
   │  └─ std::jthread destructors wait for threads to finish
   │
   ├─ [debug] "Application exit"
   │
   └─ return Application::EXIT_OK
      (Triggers LicenseService destructor)
      (Triggers TLTPM_Service destructor if exists)
         └─ Flushes transient TPM handles
            Closes TPM device connection
```

**Service Architecture:**

| Service | Protocol | Default Port | Required | Purpose |
|---------|----------|--------------|----------|----------|
| **REST API** | HTTP | 52014 | ✅ Yes | Primary interface for license operations, status, fingerprints |
| **gRPC** | gRPC/HTTP2 | 52013 | ❌ Optional | High-performance RPC interface (compile-time flag) |

**Shutdown Behavior:**
- Graceful: Waits for in-flight requests to complete
- Signal-based: Responds to SIGTERM, SIGINT
- Thread-safe: Uses std::jthread with stop_token
- Resource cleanup: TPM handles flushed, connections closed
- No data loss: Vault and persistence files already written during startup

---

## TPM Usage Details

### TPM Operations

#### 1. Persistent Key Storage

**Handle Allocation:**
```
NV Handle Range: 0x81000000 - 0x81FFFFFF (persistent)
Application Range: 2101 - 3000

SRK:           0x81000835 (2101)
Signature Key: 0x81000836 (2102)
```

**Persistence Operations:**
```cpp
// Create and persist
auto rsaKey = tpm.CreatePrimary(TPM_RH::OWNER, sensCreate, template, null, seed);
TPM_HANDLE persistHandle = TPM_HANDLE::Persistent(2101);
tpm.EvictControl(TPM_RH::OWNER, rsaKey.handle, persistHandle);

// Load on restart
TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
srkHandle.SetAuth(TPM_AUTH);
// Key is immediately available, no loading needed
```

**Benefits:**
- ✅ Survives reboots
- ✅ No need to reload key material
- ✅ Private key never leaves TPM
- ✅ Fast access

#### 2. Cryptographic Operations

**Encryption (RSA-OAEP):**
```cpp
TPMResponseVal<std::string> EncryptSRK(const std::string& payload)
{
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    srkHandle.SetAuth(TPM_AUTH);
    
    TPMS_SCHEME_OAEP scheme(TPM_ALG_ID::SHA256);
    
    ByteVec encrypted = tpm.RSA_Encrypt(
        srkHandle,
        String2ByteVec(payload),
        scheme,
        null  // no label
    );
    
    return ByteVec2String(encrypted);
}
```

**Decryption:**
```cpp
TPMResponseVal<std::string> DecryptSRK(const std::string& ciphertext)
{
    TPM_HANDLE srkHandle = TPM_HANDLE::Persistent(2101);
    srkHandle.SetAuth(TPM_AUTH);
    
    TPMS_SCHEME_OAEP scheme(TPM_ALG_ID::SHA256);
    
    ByteVec decrypted = tpm.RSA_Decrypt(
        srkHandle,
        String2ByteVec(ciphertext),
        scheme,
        null
    );
    
    return ByteVec2String(decrypted);
}
```

**Signing:**
```cpp
TPMResponseVal<std::string> Sign(const std::string& data)
{
    TPM_HANDLE sigKey = TPM_HANDLE::Persistent(2102);
    sigKey.SetAuth(TPM_AUTH);
    
    TPMT_SIG_SCHEME scheme(TPM_ALG_ID::RSASSA, TPM_ALG_ID::SHA256);
    
    ByteVec digest = SHA256(data);
    
    auto signature = tpm.Sign(
        sigKey,
        digest,
        scheme,
        TPMT_TK_HASHCHECK::NullTicket()
    );
    
    return signature.signature.toBytes();
}
```

#### 3. NVRAM Operations

**Configuration:**
- Size per index: 64 bytes
- Available slots: 2101-3000 (899 slots)
- Address space: 0x01000835 - 0x01000BB7
- **Authentication:** PCR-based hardware binding (no passwords stored)

**Security Model:**

TLLicenseManager v1.1 uses PCR-based authentication for NVRAM operations, providing hardware-bound security without password storage. Access to NVRAM data requires the TPM's Platform Configuration Registers (PCRs) to match the values from when data was written.

**PCR Policy Options:**

| Policy | PCRs Used | Security Level | Flexibility | Use Case |
|--------|-----------|----------------|-------------|----------|
| **FirmwareBoot** (Recommended) | 0, 7 | High | Medium | Production with stable firmware |
| **SecureBoot** | 7 | Medium | High | Frequent firmware updates |
| **BootSequence** | 0, 2, 7 | Maximum | Low | Locked hardware configs |

**PCR Meanings:**
- **PCR 0:** Firmware/BIOS measurements
- **PCR 2:** Option ROM code
- **PCR 7:** Secure Boot state

**Configuration:**

Set the vault policy in `TLLicenseManager.json`:

```json
{
  "TrustedLicensing": {
    "LicenseManager": {
      "VaultPolicy": "FirmwareBoot"
    }
  }
}
```

**Write Operation:**
```cpp
TPMResponse WriteNV(const string& data, int nvSlot, const std::vector<UINT32>& pcrIndices)
{
    TPM_HANDLE nvHandle = TPM_HANDLE::NV(nvSlot);
    
    // 1. Read current PCR values
    TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, pcrIndices);
    auto pcrRead = tpm.PCR_Read({pcrSel});
    
    // 2. Create PCR policy
    PolicyTree policy;
    PolicyPcr pcrPolicy(pcrRead.pcrValues, {pcrSel});
    policy.SetTree({&pcrPolicy});
    ByteVec policyDigest = policy.GetPolicyDigest(TPM_ALG_ID::SHA256);
    
    // 3. Create NV template with PCR policy
    TPMS_NV_PUBLIC nvTemplate(
        nvHandle,
        TPM_ALG_ID::SHA256,      // Name hash algorithm
        TPMA_NV::POLICYREAD |    // Policy-based read
        TPMA_NV::POLICYWRITE |   // Policy-based write
        TPMA_NV::NO_DA,          // No dictionary attack
        policyDigest,            // PCR policy digest
        NV_INDEX_SIZE            // 64 bytes
    );
    
    // 4. Check if NV index exists
    auto nvPub = tpm._AllowErrors().NV_ReadPublic(nvHandle);
    if (!tpm._LastCommandSucceeded()) {
        // Define new index with owner auth (no password)
        tpm.NV_DefineSpace(TPM_RH::OWNER, {}, nvTemplate);
        nvPub = tpm.NV_ReadPublic(nvHandle);
    }
    
    nvHandle.SetName(nvPub.nvName);
    
    // 5. Start policy session
    AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::POLICY, TPM_ALG_ID::SHA256);
    
    // 6. Satisfy PCR policy
    tpm.PolicyPCR(session, pcrRead.pcrValues, {pcrSel});
    
    // 7. Write data
    tpm[session].NV_Write(nvHandle, nvHandle, String2ByteVec(data), 0);
    
    // 8. Cleanup
    tpm.FlushContext(session);
    
    return success;
}
```

**Read Operation:**
```cpp
TPMResponseVal<string> ReadNV(int nvSlot, const std::vector<UINT32>& pcrIndices)
{
    TPM_HANDLE nvHandle = TPM_HANDLE::NV(nvSlot);
    
    // 1. Read current PCR values
    TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, pcrIndices);
    auto pcrRead = tpm.PCR_Read({pcrSel});
    
    // 2. Get NV handle name
    auto nvPub = tpm.NV_ReadPublic(nvHandle);
    nvHandle.SetName(nvPub.nvName);
    
    // 3. Start policy session
    AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::POLICY, TPM_ALG_ID::SHA256);
    
    // 4. Satisfy PCR policy
    tpm.PolicyPCR(session, pcrRead.pcrValues, {pcrSel});
    
    // 5. Read data
    ByteVec data = tpm[session].NV_Read(nvHandle, nvHandle, NV_INDEX_SIZE, 0);
    
    // 6. Cleanup
    tpm.FlushContext(session);
    
    return ByteVec2String(data);
}
```

**Security Benefits:**

1. **No Password Storage:** Eliminates risk of password theft or disclosure
2. **Hardware-Bound:** Data access tied to platform boot state
3. **Tamper Evidence:** PCR changes from firmware/config modifications prevent access
4. **Non-Exportable:** Cannot copy NVRAM data to another system

**Migration Notes:**

- Changing `VaultPolicy` requires NVRAM re-initialization
- Existing data becomes inaccessible until rewritten with new policy
- Firmware updates may require re-initialization (FirmwareBoot/BootSequence policies)
- PCR values must match between write and read operations

**Note:** NVRAM functionality is fully implemented and tested but not currently used in production license flow.

#### 4. Hardware RNG

```cpp
TPMResponseVal<ByteVec> Randomize(UINT16 length)
{
    ByteVec random = tpm.GetRandom(length);
    return random;
}
```

**Used for:**
- TPM_AUTH generation (16 bytes)
- TPM_SEED generation (16 bytes)
- Nonce generation for quotes/challenges
- Cryptographic key material

**Quality:** Hardware-based true random number generator (TRNG)

---

## Advanced TPM Features

### PCR-Based Sealing (Not Yet Implemented)

**Concept:** Seal secrets to specific boot states

**Recommended PCRs:**
- **PCR 0:** Firmware code (BIOS/UEFI)
- **PCR 7:** Secure Boot state

**Implementation Example:**
```cpp
// Read current PCR values
TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, {0, 7});
auto pcrRead = tpm.PCR_Read({pcrSel});

// Create policy
PolicyTree policy;
policy.PolicyPCR(TPM_ALG_ID::SHA256, {0, 7});

// Seal password to PCRs
TPMS_SENSITIVE_CREATE sensCreate(null, nvAuth);
TPMT_PUBLIC sealTemplate(
    TPM_ALG_ID::SHA256,
    TPMA_OBJECT::fixedTPM | TPMA_OBJECT::fixedParent,
    policy.GetPolicyDigest(),
    TPMS_NULL_SYM_CIPHER_PARMS(),
    TPM2B_DIGEST()
);

auto sealed = tpm.Create(srkHandle, sensCreate, sealTemplate, null, {pcrSel});

// Unseal (only works if PCRs match)
AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::POLICY, TPM_ALG_ID::SHA256);
tpm.PolicyPCR(session, pcrRead.pcrValues, pcrSel);
ByteVec unsealed = tpm[session].Unseal(sealedHandle);
```

**Benefits:**
- ✅ Password only accessible in trusted boot state
- ✅ Prevents offline attacks on persistence.bin
- ✅ Detects firmware tampering
- ⚠️ Requires re-sealing after firmware updates

### TPM Attestation (Remote Verification)

**Quote Generation:**
```cpp
ByteVec nonce = tpm.GetRandom(20);  // Freshness challenge
TPMS_PCR_SELECTION pcrSel(TPM_ALG_ID::SHA256, {0, 7});
TPM_HANDLE sigKey = TPM_HANDLE::Persistent(2102);

auto quote = tpm.Quote(
    sigKey,
    nonce,
    TPMT_SIG_SCHEME(TPM_ALG_ID::RSASSA, TPM_ALG_ID::SHA256),
    {pcrSel}
);

// Quote contains:
// - PCR values (boot state)
// - TPM signature (proves authenticity)
// - Clock/reset counters (anti-replay)
```

**Use Cases:**
- Remote license server verifies client boot state
- Prove TPM operations are from real hardware
- Detect VM/emulator attempts

---

## Platform-Specific Details

### Linux Support

**Device Access Priority:**
1. `/dev/tpm0` - Direct kernel driver
2. TCTI abrmd - Resource manager daemon
3. `/dev/tpmrm0` - Kernel resource manager (recommended)
4. Socket TRM - User-mode resource manager

**Resource Manager Benefits:**
- ✅ Concurrent access from multiple processes
- ✅ Automatic session management
- ✅ Context swapping
- ✅ Transient object cleanup

**Code Differences:**
```cpp
#if Windows
    AUTH_SESSION session = tpm.StartAuthSession(TPM_SE::HMAC, TPM_ALG_ID::SHA1);
    tpm[session].NV_DefineSpace(TPM_RH::OWNER, nvAuth, nvTemplate);
#endif

#if LINUX
    tpm.NV_DefineSpace(TPM_RH::OWNER, nvAuth, nvTemplate);
    // No explicit session needed with resource manager
#endif
```

### Container Support

**Docker Configuration:**
```yaml
services:
  tl-license-manager:
    image: trustedlicensing:latest
    devices:
      - /dev/tpmrm0:/dev/tpmrm0  # Preferred
    group_add:
      - 113  # tss group (check with: getent group tss)
    volumes:
      - tl-data:/app/data  # For persistence.bin and vault.bin
    cap_add:
      - IPC_LOCK  # Optional, for some TPM operations
```

**Kubernetes Configuration:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
spec:
  containers:
  - name: app
    image: trustedlicensing:latest
    volumeMounts:
    - name: tpmrm0
      mountPath: /dev/tpmrm0
    securityContext:
      supplementalGroups: [113]
  volumes:
  - name: tpmrm0
    hostPath:
      path: /dev/tpmrm0
      type: CharDevice
  nodeSelector:
    tpm-enabled: "true"
```

**PCR Behavior in Containers:**
- Container sees **host PCR values**
- PCR 0: Host firmware (not container-specific)
- PCR 7: Host Secure Boot state
- ✅ Good for licensing: binds to physical host
- ❌ Cannot measure container-specific state via PCRs

---

## Security Architecture

### Threat Model

**Protected Against:**
- ✅ Software key extraction (private keys in TPM)
- ✅ Offline brute force (requires TPM interaction)
- ✅ License migration to different hardware
- ✅ Firmware tampering (with PCR sealing)
- ✅ Unauthorized NVRAM access (PCR hardware-bound, no passwords)
- ✅ Password storage vulnerabilities (v1.1: eliminated passwords entirely)

**Vulnerabilities:**
- ⚠️ Hardcoded AES key in source code
- ⚠️ Fixed positions in persistence.bin (obfuscation only)
- ⚠️ TPM_AUTH stored on disk (encrypted but extractable)
- ⚠️ No key rotation mechanism
- ⚠️ TPM replacement = key loss (unless seed is backed up)

### Defense in Depth

**Layer 1: Filesystem**
- Elevated privileges required
- Application-specific directory
- File permissions

**Layer 2: Encryption**
- AES-256 encryption of persistence.bin
- AES-256 encryption of vault.bin
- Keys derived from TPM RNG

**Layer 3: Steganography**
- Secrets hidden in 15-75 KB random data
- Fixed positions are implementation detail
- Appears as random noise

**Layer 4: TPM Hardware**
- Private keys never leave chip
- Hardware-bound operations
- Cryptographic attestation

**Layer 5: PCR Sealing (Future)**
- Boot state verification
- Firmware integrity
- Anti-tampering

---

## Troubleshooting

### Common Issues

**1. TPM Not Found**
```
Error: "Could not connect to TPM"
```

**Solutions:**
- Linux: Check `/dev/tpm0` or `/dev/tpmrm0` exists
- Linux: Check user in `tss` group: `groups $USER`
- Linux: Load TPM modules: `sudo modprobe tpm_tis`
- Windows: Enable TPM in BIOS
- Container: Verify device passthrough

**2. Elevation Required**
```
Error: "TPM requires elevated rights"
```

**Solutions:**
- Windows: Run as Administrator
- Linux: Run with `sudo` or as root
- Container: Check capabilities and security context

**3. Persistence File Corrupted**
```
Error: "key initialization failure"
```

**Solutions:**
- Check file permissions on persistence.bin
- Verify disk space available
- Delete persistence.bin to re-initialize (loses keys!)
- Restore from backup if available

**4. TPM Lockout**
```
Error: TPM_RC::LOCKOUT
```

**Solutions:**
```cpp
tpm.Clear(TPM_RH::LOCKOUT);  // Clear lockout
// Or wait for lockout timeout (TPM-specific)
```

**5. Container TPM Access Denied**
```
Error: "Permission denied" on /dev/tpmrm0
```

**Solutions:**
- Add `--group-add tss` to docker run
- Check host TPM device permissions
- Verify `supplementalGroups` in Kubernetes
- Use device plugin for production

---

## Configuration Reference

### Command-Line Arguments

| Argument | Type | Description | Example |
|----------|------|-------------|---------|
| **-h, --help** | Flag | Display help with usage, options, and examples | `--help` |
| **-v, --version** | Flag | Show version, build, platform, TPM/gRPC support | `--version` |
| **--config** | Value | Override config file path | `--config /etc/tl.json` |
| **--rest-port** | Value | Override REST API port (default: 52014) | `--rest-port 8080` |
| **--grpc-port** | Value | Override gRPC port (default: 52013) | `--grpc-port 50051` |
| **--log-level** | Value | Set log level: trace\|debug\|info\|warning\|error\|fatal | `--log-level debug` |
| **--no-tpm** | Flag | Disable TPM operations (run software-only mode) | `--no-tpm` |
| **--tpm-host** | Value | TPM simulator hostname (simulator builds only) | `--tpm-host 192.168.1.10` |
| **--tpm-port** | Value | TPM simulator port (simulator builds only) | `--tpm-port 2321` |

**Validation:**
- Unknown flags/parameters → error and display help
- Invalid log level → error with valid options list
- Invalid port (< 1 or > 65535) → error

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `TPM_DEVICE` | Simulator hostname | localhost |
| `TPM_PORT` | Simulator port | 2321 |

### Compile-Time Flags

| Flag | Effect | Default |
|------|--------|---------|
| `TPM_ON` | Enable TPM operations | ON |
| `TPM_SIMULATOR` | Use simulator instead of hardware | OFF |
| `FASTCRYPT` | Use smaller RSA keys (testing) | OFF |
| `GRPC_Service` | Enable gRPC API | OFF |

### Persistence Locations

| File | Location | Purpose |
|------|----------|---------|
| `persistence.bin` | `{AppData}/Persistence/` | Encrypted secrets container |
| `vault.bin` | `{AppData}/Persistence/` | Encrypted key vault |
| `TLLicenseManager.json` | `{AppData}/Config/` | Configuration |
| `logs/` | `{AppData}/Logs/` | Application logs |

**Default Paths:**
- Windows: `C:\ProgramData\TrustedLicensing\`
- Linux: `/var/lib/TrustedLicensing/`

---

## Performance Characteristics

### Startup Times (Typical)

| Phase | Cold Start | Warm Start |
|-------|-----------|------------|
| Logging init | 10ms | 10ms |
| Persistence load | 50ms | 20ms |
| TPM connect | 200ms | 100ms |
| Key generation | 2000ms | - |
| Key loading | - | 50ms |
| Service start | 100ms | 100ms |
| **Total** | **~2.4s** | **~280ms** |

### TPM Operation Latencies

| Operation | Typical | Notes |
|-----------|---------|-------|
| GetRandom(16) | 5-10ms | Hardware RNG |
| CreatePrimary | 500-1000ms | RSA key generation |
| RSA_Encrypt | 10-20ms | 2048-bit |
| RSA_Decrypt | 50-100ms | Private key operation |
| NV_Write | 50-100ms | Flash write latency |
| NV_Read | 10-20ms | Fast read |
| PCR_Read | 5-10ms | Always fast |

**Note:** Times vary by TPM manufacturer and version.

---

## Future Enhancements

### Planned Features

1. **PCR-Based Sealing**
   - Seal TPM_AUTH to boot state
   - Eliminate password storage on disk
   - Automatic re-sealing on firmware updates

2. **Remote Attestation**
   - TPM Quote generation
   - Remote license server verification
   - Certificate-based attestation

3. **Key Rotation**
   - Periodic key regeneration
   - Migration to new TPM
   - Backup/restore procedures

4. **Enhanced NVRAM Usage**
   - Store activation tokens
   - License expiration counters
   - Tamper-detection flags

5. **Policy-Based Authorization**
   - Replace passwords with TPM policies
   - Multi-factor authorization
   - Time-based access control

---

## References

### TPM 2.0 Specification
- [TPM 2.0 Library Specification](https://trustedcomputinggroup.org/resource/tpm-library-specification/)
- [TPM 2.0 Key File Format](https://www.hansenpartnership.com/draft-bottomley-tpm2-keys.html)

### Platform Resources
- Windows: [TBS Documentation](https://docs.microsoft.com/en-us/windows/win32/tbs/tpm-base-services-portal)
- Linux: [Linux TPM Subsystem](https://www.kernel.org/doc/html/latest/security/tpm/index.html)
- Container: [Intel TPM Device Plugin](https://github.com/intel/intel-device-plugins-for-kubernetes)

### Internal Documentation
- [TPM_Docker_Kubernetes_Access.md](TPM_Docker_Kubernetes_Access.md) - Container deployment guide
- [CMakeLists.txt](../CMakeLists.txt) - Build configuration
- [vcpkg.json](../vcpkg.json) - Dependencies

---

## Appendix: File Locations

```
TL2/
├─ TLLicenseManager/           # Executable wrapper
│  └─ sources/src/CustomFingerPrint.cpp
│
├─ TLLicenseService/           # Business logic
│  ├─ sources/src/Main.cpp     # Entry point
│  ├─ sources/include/MainApp.h # POCO ServerApplication
│  ├─ sources/src/LicenseService.cpp
│  ├─ sources/src/PersistenceService.cpp
│  └─ sources/src/ApplicationState.cpp
│
├─ TLCrypt/                    # TPM operations
│  └─ sources/
│     ├─ include/TPMService.h
│     └─ src/TPMService.cpp
│
├─ TLTpm/                      # Low-level TPM 2.0
│  └─ src/
│     ├─ include/Tpm2.h
│     ├─ include/TpmDevice.h
│     ├─ Tpm2.cpp
│     └─ TpmDevice.cpp
│
└─ _docs/
   ├─ TPM_Docker_Kubernetes_Access.md
   └─ TLLicenseManager_StartUp.md (this file)
```

---

**Document Version:** 1.3  
**Last Updated:** January 31, 2026  
**Maintainer:** TrustedLicensing Team

---

## Recent Changes

### v1.3 - January 31, 2026
- ✅ **Complete regeneration based on current codebase**
- ✅ Comprehensive code review and validation against actual implementation
- ✅ Added detailed Phase 1-6 startup flows with line-by-line code paths
- ✅ Documented actual TPM persistent handle values (0x810003E8 for SRK at slot 1000)
- ✅ Clarified deterministic key generation mechanics (seed-based reproducibility)
- ✅ Added container volume tracking via Docker socket API
- ✅ Documented multi-factor daemon detection on Linux
- ✅ Enhanced persistence layer with steganographic container details
- ✅ Added detailed TPM device selection priority and resource manager behavior
- ✅ Included full LicenseService constructor and key generation flow
- ✅ Documented conditional TPM service instantiation based on --no-tpm flag
- ✅ Added comprehensive error handling and validation steps
- ✅ Included actual code snippets from implementation
- ✅ Fixed all file path references to use workspace-relative markdown links
- ✅ Clarified that SRK uses slot 1000 (not 2101 from test code)

### v1.2 - January 31, 2026
- ✅ Documentation review and validation against current codebase
- ✅ Verified all code samples match actual implementation
- ✅ Confirmed TPM initialization flows and error handling
- ✅ Updated date to current

### v1.1 - January 28, 2026

#### Enhanced CLI Interface
- ✨ Added `--help` with detailed usage, examples, and config paths
- ✨ Added `--version` with platform and feature detection
- ✅ Comprehensive argument validation with helpful error messages
- ✅ TPM simulator options: `--tpm-host` and `--tpm-port`

#### TPM Management
- ✨ **New `--no-tpm` flag**: Runtime TPM disabling without recompilation
- ✅ Conditional TPM service instantiation (prevents access when disabled)
- ✅ Enhanced TPM status logging after initialization
- ✅ Better error handling for TPM unavailability in containers

#### Configuration
- ✅ CLI arguments now directly update runtime configuration
- ✅ Port overrides (`--rest-port`, `--grpc-port`) applied before service start
- ✅ Log level changes applied to config object

#### Linux Improvements
- ✨ **Daemon auto-detection**: Automatically detects systemd/init execution
- ✅ Multi-factor daemon detection: terminal, parent process, session leader
- ✅ Distinguishes between configured daemon vs. detected daemon

#### Logging
- ✅ Detailed CLI parameter logging on startup
- ✅ Each override logged individually with context
- ✅ "Using default" messages when no override provided

---

<!-- 
REGENERATION PROMPT:
Create a markdown in _docs about TLLicenseManager startup sequence and details about TPM usage. 
Call it TLLicenseManager_StartUp.md

⚠️ CRITICAL: ALWAYS verify documentation against actual source code before regenerating.
Use grep_search, read_file, and semantic_search to validate all flows, constants, and behavior.

REGENERATION STEPS:
1. Read and analyze the source files listed below
2. Verify all code flows, constant values, and error messages match implementation
3. Check for any recent changes to initialization sequences
4. Validate log messages against actual BOOST_LOG_TRIVIAL calls
5. Confirm all file paths and line numbers are current
6. Update "LAST UPDATED" date to current date
7. Document any behavioral changes discovered during code review

SCOPE:
- Complete startup sequence from main() through service initialization
- Persistence layer initialization and secret storage architecture
- TPM connection and key generation (SRK, signature keys)
- TPM operations: persistent storage, cryptographic ops, NVRAM, hardware RNG
- Platform-specific details (Windows/Linux/Container)
- Security architecture and threat model
- Troubleshooting common issues
- Performance characteristics
- Future enhancements

KEY FILES TO REVIEW (ALWAYS CHECK THESE):
- TLLicenseService/sources/src/Main.cpp (entry point)
- TLLicenseService/sources/include/MainApp.h (POCO app lifecycle & main())
- TLLicenseService/sources/src/PersistenceService.cpp (secret storage)
- TLLicenseService/sources/include/PersistenceService.h (persistence interface)
- TLLicenseService/sources/src/LicenseService.cpp (key generation)
- TLLicenseService/sources/src/ApplicationState.cpp (state management)
- TLCrypt/sources/src/TPMService.cpp (TPM operations)
- TLCrypt/sources/include/TPMService.h (TPM interface)
- TLTpm/src/TpmDevice.cpp (platform-specific device access)
- TLTpm/src/include/Tpm2.h (TPM 2.0 commands)
- _docs_dev/TPM_Docker_Kubernetes_Access.md (container deployment)

VERIFICATION CHECKLIST:
□ All #define constants match source code
□ All log messages match actual BOOST_LOG_TRIVIAL calls
□ Function call sequences verified with grep_search
□ Error handling flows match try/catch blocks
□ CLI arguments match argh parser implementation
□ ApplicationState method calls occur in correct order
□ File paths and line numbers are accurate
□ TPM auth/seed handling matches current implementation
□ Persistence positions and lengths are correct
□ All code snippets compile and are accurate

UPDATE TRIGGERS:
- Changes to startup sequence or initialization flow
- New TPM operations added
- Persistence format changes (positions, encryption, storage)
- Security model updates
- Platform support additions
- Configuration changes
- CLI argument additions/changes
- ApplicationState method signature changes

LAST UPDATED: February 1, 2026
-->
