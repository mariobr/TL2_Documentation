# Protocol Buffers vs oat++ DTOs - Complete Guide

## Overview

This document shows how to use Protocol Buffers with your TLLicenseManager system for data exchange between C++ (TLLicenseManager/Client) and C# (web system).

## Example Data Structure

**Requirements:**
- Public key in base64 format
- Array of vendor information (name, inProduction, deprecated)
- Signature of the vendor array

---

## 1. Protocol Buffers Definition (.proto)

**File:** `TLProtobuf/license_data.proto`

```proto
syntax = "proto3";

package tllicense;

option csharp_namespace = "TrustedLicensing.Models";

message VendorInfo {
  string name = 1;
  bool in_production = 2;
  bool deprecated = 3;
}

message LicenseData {
  string public_key_base64 = 1;
  repeated VendorInfo vendors = 2;
  string vendors_signature = 3;
}
```

---

## 2. Tools for Code Generation

### C++ Code Generation

**Install protobuf compiler:**
```bash
# Windows (vcpkg)
vcpkg install protobuf

# Linux
sudo apt-get install protobuf-compiler libprotobuf-dev
```

**Generate C++ code:**
```bash
protoc --cpp_out=./generated license_data.proto
# Creates: license_data.pb.h and license_data.pb.cc
```

**CMakeLists.txt integration:**
```cmake
find_package(Protobuf REQUIRED)

# Generate protobuf files
file(GLOB PROTO_FILES "${CMAKE_SOURCE_DIR}/TLProtobuf/*.proto")
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILES})

# Add to your target
add_executable(TLLicenseManager ${SOURCES} ${PROTO_SRCS})
target_link_libraries(TLLicenseManager protobuf::libprotobuf)
```

### C# Code Generation

**Install protoc for C#:**
```bash
# Install via NuGet Package Manager or .NET CLI
dotnet add package Google.Protobuf
dotnet add package Grpc.Tools
```

**Generate C# code:**
```bash
protoc --csharp_out=./Generated license_data.proto
# Creates: LicenseData.cs
```

**Or in .csproj (automatic):**
```xml
<ItemGroup>
  <PackageReference Include="Google.Protobuf" Version="3.25.0" />
  <PackageReference Include="Grpc.Tools" Version="2.60.0" PrivateAssets="All" />
  <Protobuf Include="Protos\license_data.proto" GrpcServices="Client" />
</ItemGroup>
```

---

## 3. C++ Usage Examples

### Using Generated Protobuf (Recommended for gRPC + REST)

```cpp
#include "license_data.pb.h"
#include <google/protobuf/util/json_util.h>

// CREATE
tllicense::LicenseData data;
data.set_public_key_base64("MIIBIjANBgkqhkiG9w0...");

auto* vendor = data.add_vendors();
vendor->set_name("Acme Corp");
vendor->set_in_production(true);
vendor->set_deprecated(false);

data.set_vendors_signature("SHA256:abc123...");

// SERIALIZE TO JSON (for REST)
std::string json;
google::protobuf::util::MessageToJsonString(data, &json);

// SERIALIZE TO BINARY (for gRPC)
std::string binary;
data.SerializeToString(&binary);

// PARSE FROM JSON
tllicense::LicenseData parsed;
google::protobuf::util::JsonStringToMessage(json, &parsed);
```

### Using oat++ DTOs (Current REST approach)

```cpp
#include "DTO_LicenseData.h"
#include <oatpp/core/data/mapping/ObjectMapper.hpp>

// CREATE
auto data = LicenseData::createShared();
data->publicKeyBase64 = "MIIBIjANBgkqhkiG9w0...";

data->vendors = oatpp::List<oatpp::Object<VendorInfo>>::createShared();
auto vendor = VendorInfo::createShared();
vendor->name = "Acme Corp";
vendor->inProduction = true;
vendor->deprecated = false;
data->vendors->push_back(vendor);

data->vendorsSignature = "SHA256:abc123...";

// SERIALIZE TO JSON
auto mapper = oatpp::parser::json::mapping::ObjectMapper::createShared();
auto json = mapper->writeToString(data);

// PARSE FROM JSON
auto parsed = mapper->readFromString<oatpp::Object<LicenseData>>(json);
```

### REST Endpoint with Protobuf (in Controller.h)

```cpp
ENDPOINT("POST", "/LM/license/validate", validateLicense,
         BODY_STRING(String, body)) {
    
    // Parse JSON to protobuf
    tllicense::LicenseData request;
    google::protobuf::util::JsonStringToMessage(body->c_str(), &request);
    
    // Validate signature
    bool isValid = spLicenseService->ValidateSignature(
        request.vendors(), 
        request.vendors_signature()
    );
    
    // Create response
    tllicense::ValidationResponse response;
    response.set_valid(isValid);
    response.set_message(isValid ? "Valid" : "Invalid signature");
    
    // Convert back to JSON
    std::string jsonOutput;
    google::protobuf::util::MessageToJsonString(response, &jsonOutput);
    
    auto httpResponse = createResponse(Status::CODE_200, jsonOutput.c_str());
    httpResponse->putHeader("content-type", "application/json");
    return httpResponse;
}
```

---

## 4. C# Usage Examples

### Using Generated Protobuf Classes

```csharp
using TrustedLicensing.Models;
using Google.Protobuf;

// CREATE
var data = new LicenseData
{
    PublicKeyBase64 = "MIIBIjANBgkqhkiG9w0...",
    VendorsSignature = "SHA256:abc123..."
};

data.Vendors.Add(new VendorInfo
{
    Name = "Acme Corp",
    InProduction = true,
    Deprecated = false
});

// SERIALIZE TO JSON (for REST)
string json = JsonFormatter.Default.Format(data);

// SERIALIZE TO BINARY (for gRPC)
byte[] binary = data.ToByteArray();

// PARSE FROM JSON
var parsed = JsonParser.Default.Parse<LicenseData>(json);

// PARSE FROM BINARY
var parsedBinary = LicenseData.Parser.ParseFrom(binary);
```

### REST API Call from C#

```csharp
using System.Net.Http;

var data = new LicenseData { /* ... */ };

// Convert to JSON
string jsonContent = JsonFormatter.Default.Format(data);

using var httpClient = new HttpClient();
var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

var response = await httpClient.PostAsync(
    "http://localhost:52014/LM/license/validate",
    content
);

if (response.IsSuccessStatusCode)
{
    string responseJson = await response.Content.ReadAsStringAsync();
    var result = JsonParser.Default.Parse<ValidationResponse>(responseJson);
    Console.WriteLine($"Valid: {result.Valid}");
}
```

### gRPC Call from C#

```csharp
using Grpc.Net.Client;

// Create channel
var channel = GrpcChannel.ForAddress("http://localhost:52013");
var client = new LicenseService.LicenseServiceClient(channel);

// Make gRPC call
var request = new LicenseDataRequest { LicenseId = "12345" };
var response = await client.GetLicenseDataAsync(request);

Console.WriteLine($"Public Key: {response.PublicKeyBase64}");
Console.WriteLine($"Vendors: {response.Vendors.Count}");
```

---

## 5. JSON Output Comparison

### Protobuf-generated JSON:
```json
{
  "publicKeyBase64": "MIIBIjANBgkqhkiG9w0...",
  "vendors": [
    {
      "name": "Acme Corp",
      "inProduction": true,
      "deprecated": false
    }
  ],
  "vendorsSignature": "SHA256:abc123..."
}
```

### oat++ DTO JSON:
```json
{
  "publicKeyBase64": "MIIBIjANBgkqhkiG9w0...",
  "vendors": [
    {
      "name": "Acme Corp",
      "inProduction": true,
      "deprecated": false
    }
  ],
  "vendorsSignature": "SHA256:abc123..."
}
```

**Both produce identical JSON!** The difference is in the tooling and binary serialization.

---

## 6. Comparison Table

| Feature | Protocol Buffers | oat++ DTOs |
|---------|-----------------|------------|
| **JSON Support** | ✅ Yes | ✅ Yes |
| **Binary Format** | ✅ Yes (efficient) | ❌ No |
| **gRPC Support** | ✅ Native | ❌ Not designed for it |
| **C++ Generation** | ✅ protoc compiler | ✅ Macros/codegen |
| **C# Generation** | ✅ protoc compiler | ❌ Manual classes needed |
| **Schema Evolution** | ✅ Built-in versioning | ⚠️ Manual handling |
| **Type Safety** | ✅ Strong | ✅ Strong |
| **Performance** | ⭐⭐⭐⭐⭐ (binary) | ⭐⭐⭐⭐ (JSON only) |
| **Learning Curve** | Medium | Low (if know oat++) |

---

## 7. Recommended Approach

**For TLLicenseManager ↔ C# Web System:**

1. **Define once in .proto files**
   - Single source of truth
   - Generate code for both C++ and C#

2. **REST Endpoints (HTTP/JSON)**
   - Use protobuf messages internally
   - Serialize to/from JSON for HTTP transport
   - Compatible with any REST client

3. **gRPC Endpoints (Optional)**
   - Use protobuf binary format
   - More efficient for high-volume communication
   - Type-safe contracts

4. **Internal C++ Logic**
   - Can mix oat++ DTOs and protobuf messages
   - Convert between them as needed
   - See `LicenseDataExample.h` for converter utilities

---

## 8. Required Dependencies

### C++ (vcpkg.json)
```json
{
  "dependencies": [
    "protobuf",
    "grpc",
    "oatpp"
  ]
}
```

### C# (NuGet)
```bash
dotnet add package Google.Protobuf
dotnet add package Grpc.Net.Client  # if using gRPC
dotnet add package Grpc.Tools        # for code generation
```

---

## 9. Files Created in This Example

- `TLProtobuf/license_data.proto` - Protocol buffer definition
- `TLLicenseCommon/sources/include/DTO_LicenseData.h` - oat++ DTOs
- `TLLicenseCommon/sources/include/LicenseDataExample.h` - C++ examples
- `_docs_dev/CSharpExample.cs` - C# examples

---

## 10. Next Steps

1. Review the example files
2. Choose your approach (Protobuf recommended for C#↔C++)
3. Update your CMakeLists.txt to generate protobuf code
4. Implement converters between oat++ DTOs and protobuf (if needed)
5. Test REST endpoints with JSON
6. Optionally add gRPC for performance-critical paths
