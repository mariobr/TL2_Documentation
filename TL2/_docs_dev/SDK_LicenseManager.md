# SDK-TrustedLicensing - License Manager Distribution Strategy

## Overview

This document outlines the architecture and distribution strategy for shipping TLLicenseManager as part of the SDK-TrustedLicensing SDK.

## Distribution Options Analysis

### Option 1: Source Code Distribution ✅ **RECOMMENDED**

Ship the complete TLLicenseManager source code as part of the SDK, allowing users to compile with their own provider keys and custom locking implementations.

**Structure:**
```
SDK-TrustedLicensing/
├── src/
│   ├── TLLicenseManager/          ← Full source code
│   │   ├── TLCommon/
│   │   ├── TLCrypt/
│   │   ├── TLHardwareInfo/
│   │   ├── TLLicenseService/
│   │   ├── TLTpm/
│   │   ├── TLProtocols/
│   │   └── TLLicenseCommon/
│   └── TLLicenseClient/
├── include/                        ← SDK user configuration
│   ├── TLLicenseProviderKey.h     ← User provides their RSA public key
│   ├── TLLicenseConfig.h          ← Build configuration
│   └── TLCustomLocking.h          ← Custom locking implementation
├── lib/                            ← Pre-compiled libraries (optional)
│   ├── windows/
│   │   ├── x64/
│   │   │   ├── Release/
│   │   │   └── Debug/
│   │   ├── x86/
│   │   └── arm64/
│   └── linux/
│       ├── x86_64/
│       ├── aarch64/
│       └── armv7l/
├── samples/
│   ├── Cpp/
│   │   ├── BasicClient/
│   │   └── CustomLocking/
│   ├── Java/
│   │   └── BasicClient/
│   └── DotNet/
│       └── BasicClient/
├── docs/
├── tools/
│   └── GenerateKeys.ps1
├── CMakeLists.txt
└── README.md
```

**Advantages:**
- ✅ Users can implement CustomLocking (source access required)
- ✅ Users compile with their own RSA provider key (compile-time embedding)
- ✅ Full transparency (important for licensing/security systems)
- ✅ Users can debug and customize
- ✅ Single CMake build for entire SDK
- ✅ Clear what's being compiled
- ✅ Platform independence (users compile for their target)

**Disadvantages:**
- ❌ Exposes implementation details
- ❌ Larger SDK package size
- ❌ Users might modify core code (can be mitigated with documentation)

### Option 2: Pre-compiled Libraries + Headers

Ship pre-built binaries for multiple platforms with only public headers.

**Problem:** Provider key needs to be embedded at **compile-time** for security, making pre-compiled binaries impractical unless runtime key loading is implemented.

### Option 3: Hybrid - Pre-compiled Core + Source Wrapper

Ship TLLicenseManager as pre-compiled library with a thin wrapper layer that users compile with their provider key.

**Structure:**
```
SDK-TrustedLicensing/
├── lib/                           ← Pre-compiled (90% of code)
│   ├── windows/
│   │   └── x64/
│   │       └── TLLicenseManager.lib
│   └── linux/
│       └── x86_64/
│           └── libTLLicenseManager.a
├── src/
│   └── wrapper/                   ← User compiles (10% of code)
│       ├── LicenseProviderConfig.cpp
│       └── CustomLockingImpl.cpp
├── include/
│   ├── TLLicenseProviderKey.h     ← User provides key
│   ├── TLLicenseConfig.h          ← User configures
│   └── TLCustomLocking.h
└── samples/
```

**Wrapper Implementation:**
```cpp
// LicenseProviderConfig.cpp (user compiles this)
#include <TLLicenseProviderKey.h>
#include <TLLicenseManager.h>

namespace TrustedLicensing {
    const char* GetProviderPublicKey() {
        return LicenseProvider::PUBLIC_KEY;
    }
    
    CustomLockImpl* CreateCustomLock() {
#if CUSTOM_LOCKING_ENABLED
        return new MyCustomLock();
#else
        return nullptr;
#endif
    }
}
```

**Advantages:**
- ✅ Protects implementation details
- ✅ Smaller source distribution
- ✅ Faster compilation (core pre-built)

**Disadvantages:**
- ❌ Requires maintaining binaries for multiple platforms/architectures
- ❌ Less flexibility for debugging
- ❌ Requires ABI stability

### Option 4: Binary Distribution with Runtime Key Loading

Ship TLLicenseManager as binary that loads provider key at runtime.

**Not Recommended:** Reduces security as key loading mechanism can be bypassed or intercepted.

## Recommended Implementation: Option 1 (Full Source)

Based on SDK requirements, **Option 1 (Full Source Code Distribution)** is the optimal choice.

### Rationale

1. **CustomLocking Requirement**: Users need to implement custom hardware locking, requiring source code access
2. **Provider Key Security**: Compile-time embedding is more secure than runtime loading
3. **Transparency**: Licensing systems benefit from code transparency and auditability
4. **Platform Flexibility**: Users compile for their specific target platform
5. **SDK Philosophy**: SDKs traditionally ship source code for maximum flexibility

### Architecture

```
SDK-TrustedLicensing/
│
├── CMakeLists.txt                     # Main SDK build configuration
├── CMakePresets.json                  # Pre-configured build presets
├── README.md                          # SDK overview
├── LICENSE                            # SDK license
├── SECURITY.md                        # Security guidelines
├── BUILD.md                           # Build instructions
│
├── include/                           # SDK User Configuration Headers
│   ├── TLLicenseProviderKey.h        # User provides RSA public key here
│   ├── TLLicenseConfig.h             # Build configuration options
│   └── TLCustomLocking.h             # Custom locking implementation
│
├── src/                               # TLLicenseManager Source Code
│   ├── TLCommon/                     # Common utilities
│   ├── TLCrypt/                      # Cryptography (AES, RSA, TPM)
│   ├── TLHardwareInfo/               # Hardware fingerprinting
│   ├── TLLicenseCommon/              # License data structures
│   ├── TLLicenseService/             # Core license service
│   ├── TLLicenseManager/             # Main application
│   ├── TLLicenseClient/              # Client library
│   ├── TLProtocols/                  # REST/gRPC protocols
│   └── TLTpm/                        # TPM 2.0 integration
│
├── lib/                               # Pre-compiled Libraries (Optional)
│   ├── windows/
│   │   ├── x64/
│   │   │   ├── Release/
│   │   │   │   ├── TLLicenseClient.lib
│   │   │   │   └── TLLicenseManager.lib
│   │   │   └── Debug/
│   │   │       ├── TLLicenseClient.lib
│   │   │       └── TLLicenseManager.lib
│   │   ├── x86/
│   │   │   ├── Release/
│   │   │   └── Debug/
│   │   └── arm64/
│   │       ├── Release/
│   │       └── Debug/
│   └── linux/
│       ├── x86_64/
│       │   ├── release/
│       │   │   ├── libTLLicenseClient.a
│       │   │   └── libTLLicenseManager.a
│       │   └── debug/
│       ├── aarch64/
│       │   ├── release/
│       │   └── debug/
│       └── armv7l/
│           ├── release/
│           └── debug/
│
├── samples/                           # Sample Applications
│   ├── Cpp/
│   │   ├── BasicClient/
│   │   │   ├── CMakeLists.txt
│   │   │   ├── main.cpp
│   │   │   └── README.md
│   │   └── CustomLocking/
│   │       ├── CMakeLists.txt
│   │       ├── main.cpp
│   │       ├── MyCustomLock.h
│   │       └── README.md
│   ├── Java/
│   │   └── BasicClient/
│   │       ├── pom.xml
│   │       ├── src/
│   │       │   └── main/
│   │       │       └── java/
│   │       │           └── com/
│   │       │               └── trustedlicensing/
│   │       │                   └── BasicClient.java
│   │       └── README.md
│   └── DotNet/
│       └── BasicClient/
│           ├── BasicClient.csproj
│           ├── Program.cs
│           └── README.md
│
├── docs/                              # Documentation
│   ├── GettingStarted.md
│   ├── APIReference.md
│   ├── CustomLocking.md
│   ├── Deployment.md
│   └── Architecture.md
│
└── tools/                             # Utility Scripts
    ├── GenerateKeys.ps1              # RSA key generation
    ├── GenerateKeys.sh               # Linux version
    └── PackageSDK.ps1                # SDK packaging script
```

### User Workflow

```bash
# 1. Extract SDK
unzip SDK-TrustedLicensing-v1.0.0.zip
cd SDK-TrustedLicensing

# 2. Generate Provider Keys
cd tools
./GenerateKeys.ps1 -ProviderName "MyCompany" -KeySize 4096
# Output: keys/provider_private.pem (keep secure!)
#         keys/provider_public.pem (for SDK)

# 3. Configure Provider Key
# Edit include/TLLicenseProviderKey.h
# Paste contents of keys/provider_public.pem

# 4. (Optional) Configure Custom Locking
# Edit include/TLLicenseConfig.h - set CUSTOM_LOCKING_ENABLED 1
# Edit include/TLCustomLocking.h - implement GetCustomHardwareID() and ValidateCustomLock()

# 5. Build SDK
cd ..
cmake --preset windows-release
cmake --build --preset windows-release

# 6. Build Outputs
# bin/TLLicenseManager.exe
# lib/TLLicenseClient.lib
# samples/Cpp/BasicClient/BasicClient.exe

# 7. Run Sample
cd build/windows-release/samples/Cpp/BasicClient
./BasicClient.exe
```

### CMake Build Configuration

**Main CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.19)

project(SDK-TrustedLicensing VERSION 1.0.0)

# Validate provider key is configured
include(cmake/ValidateProviderKey.cmake)

# Build options
option(TPM_ON "Enable TPM 2.0 support" ON)
option(CUSTOM_LOCKING "Enable custom locking" OFF)
option(BUILD_SAMPLES "Build sample applications" ON)
option(BUILD_TESTS "Build unit tests" ON)

# Include SDK configuration
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Build TLLicenseManager components
add_subdirectory(src/TLCommon)
add_subdirectory(src/TLCrypt)
add_subdirectory(src/TLHardwareInfo)
add_subdirectory(src/TLLicenseCommon)
add_subdirectory(src/TLLicenseService)
add_subdirectory(src/TLTpm)
add_subdirectory(src/TLProtocols)

# Build TLLicenseManager executable
add_subdirectory(src/TLLicenseManager)

# Build TLLicenseClient library
add_subdirectory(src/TLLicenseClient)

# Build samples
if(BUILD_SAMPLES)
    add_subdirectory(samples)
endif()

# Build tests
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
```

### Platform-Specific Libraries (Optional)

Pre-compiled libraries can be included as a convenience but are **not required** since users compile from source.

**Directory Structure:**
```
lib/
├── windows/
│   ├── x64/
│   │   ├── Release/
│   │   │   ├── TLLicenseClient.lib
│   │   │   ├── TLLicenseClient.dll
│   │   │   └── TLLicenseClient.pdb
│   │   └── Debug/
│   │       ├── TLLicenseClient.lib
│   │       ├── TLLicenseClient.dll
│   │       └── TLLicenseClient.pdb
│   ├── x86/
│   │   ├── Release/
│   │   └── Debug/
│   └── arm64/
│       ├── Release/
│       └── Debug/
└── linux/
    ├── x86_64/
    │   ├── release/
    │   │   ├── libTLLicenseClient.a
    │   │   └── libTLLicenseClient.so
    │   └── debug/
    │       ├── libTLLicenseClient.a
    │       └── libTLLicenseClient.so
    ├── aarch64/          # ARM 64-bit (Raspberry Pi 4, AWS Graviton)
    │   ├── release/
    │   └── debug/
    └── armv7l/           # ARM 32-bit (Raspberry Pi 3)
        ├── release/
        └── debug/
```

**Use Cases:**
- Quick prototyping without full compilation
- CI/CD pipelines for client applications only
- Languages that need native bindings (Java, .NET)

### Multi-Language Sample Applications

#### C++ Sample (samples/Cpp/BasicClient/)

```cpp
#include <TLLicenseClient.h>
#include <TLLicenseConfig.h>
#include <iostream>

int main() {
    using namespace TrustedLicensing;
    
    // Connect to license manager
    TLLicenseClient client("localhost", 52014);
    
    // Verify license
    auto result = client.VerifyLicense();
    
    if (result.IsValid()) {
        std::cout << "License valid for: " 
                  << result.GetCustomer() << std::endl;
        // Run application
        return 0;
    } else {
        std::cerr << "License error: " 
                  << result.GetError() << std::endl;
        return 1;
    }
}
```

#### Java Sample (samples/Java/BasicClient/)

```java
package com.trustedlicensing;

import com.trustedlicensing.client.LicenseClient;
import com.trustedlicensing.client.LicenseResult;

public class BasicClient {
    public static void main(String[] args) {
        // Load native library
        System.loadLibrary("TLLicenseClient");
        
        // Connect to license manager
        LicenseClient client = new LicenseClient("localhost", 52014);
        
        // Verify license
        LicenseResult result = client.verifyLicense();
        
        if (result.isValid()) {
            System.out.println("License valid for: " + result.getCustomer());
            // Run application
        } else {
            System.err.println("License error: " + result.getError());
            System.exit(1);
        }
    }
}
```

#### .NET Sample (samples/DotNet/BasicClient/)

```csharp
using TrustedLicensing.Client;

namespace BasicClient
{
    class Program
    {
        static void Main(string[] args)
        {
            // Connect to license manager
            var client = new LicenseClient("localhost", 52014);
            
            // Verify license
            var result = client.VerifyLicense();
            
            if (result.IsValid)
            {
                Console.WriteLine($"License valid for: {result.Customer}");
                // Run application
            }
            else
            {
                Console.WriteLine($"License error: {result.Error}");
                Environment.Exit(1);
            }
        }
    }
}
```

### SDK Packaging

SDK can be distributed as:

1. **Source Archive**
   - `SDK-TrustedLicensing-v1.0.0-src.zip`
   - Contains all source code
   - Users compile everything

2. **Binary Archive** (Optional)
   - `SDK-TrustedLicensing-v1.0.0-win-x64.zip`
   - `SDK-TrustedLicensing-v1.0.0-linux-x64.tar.gz`
   - Contains pre-compiled libraries + source
   - Faster for client library integration

3. **Platform-Specific**
   - `SDK-TrustedLicensing-v1.0.0-win-x64.zip`
   - `SDK-TrustedLicensing-v1.0.0-win-x86.zip`
   - `SDK-TrustedLicensing-v1.0.0-win-arm64.zip`
   - `SDK-TrustedLicensing-v1.0.0-linux-x64.tar.gz`
   - `SDK-TrustedLicensing-v1.0.0-linux-aarch64.tar.gz`

### Security Considerations

1. **Provider Key Management**
   - Private key **NEVER** included in SDK
   - Public key embedded at compile-time by user
   - Compile-time validation prevents building without key

2. **Custom Locking**
   - Implementation in user's hands
   - Source code allows security audit
   - No pre-compiled backdoors

3. **Build Validation**
   - CMake validates provider key configured
   - Compile-time assertions check key format
   - Clear error messages guide configuration

## Summary

**Recommended Distribution Method:** Full source code distribution (Option 1)

**Key Benefits:**
- ✅ Supports CustomLocking requirement
- ✅ Secure compile-time key embedding
- ✅ Platform independence
- ✅ Full transparency and auditability
- ✅ Maximum flexibility for users

**User Experience:**
1. Extract SDK
2. Generate provider keys
3. Configure provider key in header file
4. (Optional) Implement custom locking
5. Build with CMake
6. Deploy TLLicenseManager and integrate client library

**Multi-Platform Support:**
- Windows: x64, x86, ARM64
- Linux: x86_64, aarch64, armv7l
- Pre-compiled libraries optional (for convenience)
- All platforms compile from same source

**Multi-Language Support:**
- C++: Native integration
- Java: JNI bindings to TLLicenseClient
- .NET: P/Invoke bindings to TLLicenseClient
- All samples included with SDK
