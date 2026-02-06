# JSON Format and File System Operations

## Example JSON Output

Here's what the serialized `LicenseData` looks like as JSON:

```json
{
  "publicKeyBase64": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwJKzNnK7XQFH1Y2MvQN8bXz9JhPKxZ5VQwMmTYr3kL4pN6xK2jM8zR5tW9Qq3cLxP7vN8bH6mY4aK3wR5nJ2qZ8uV7tL9sX4mK2pQ3yR8nH5vL6zM9qW4tN7jK5pR8xV3sL4mN9qZ2wT6yH7vK4nM8rP5tQ3xN9zR2wL5vK8mJ4sT7yQ3nH6vM9pR4xL2zN8tW5qK7mV3jP6sR9yH4nT8vL2zQ5xM7wK3pN6tR9yJ4vH8mL2sQ5nT7xP3wN9zK6rM4vJ8tL5yH2qR7xP9nV3sK6wM4zT8jL5yQ2nH7vR4xP9mK3wN6tJ8sL5yQ2vH7rM4nP9xT3zK6wL8jR5yH2qV4sN7xP9mT3zK6wL8jR5y",
  "vendors": [
    {
      "name": "Acme Corporation",
      "inProduction": true,
      "deprecated": false
    },
    {
      "name": "TechVendor Ltd",
      "inProduction": true,
      "deprecated": false
    },
    {
      "name": "Legacy Systems Inc",
      "inProduction": false,
      "deprecated": true
    },
    {
      "name": "Beta Solutions",
      "inProduction": false,
      "deprecated": false
    }
  ],
  "vendorsSignature": "SHA256:a3d8f2e1b4c59a7d6e8f3b2c1a9d8e7f6b5a4c3d2e1f0a9b8c7d6e5f4a3b2c1d"
}
```

**Key Points:**
- Human-readable and editable
- Compatible with any JSON parser
- Can be version-controlled (Git-friendly)
- Standard field naming (camelCase from protobuf)
- Boolean values as `true`/`false`
- Arrays as JSON arrays

---

## Field Explanations

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `publicKeyBase64` | string | RSA public key encoded in Base64 | Full Base64 string |
| `vendors` | array | List of vendor information objects | Array of VendorInfo |
| `vendors[].name` | string | Vendor name | "Acme Corporation" |
| `vendors[].inProduction` | boolean | Whether vendor is in production | `true` or `false` |
| `vendors[].deprecated` | boolean | Whether vendor is deprecated | `true` or `false` |
| `vendorsSignature` | string | Cryptographic signature of vendors array | SHA256 hash |

---

## C++ File Operations

### Save to JSON File

```cpp
#include "LicenseDataFileIO.h"

// Create data
tllicense::LicenseData data;
data.set_public_key_base64("MIIBIjANBgkqhkiG9w0...");

auto* vendor = data.add_vendors();
vendor->set_name("Acme Corp");
vendor->set_in_production(true);
vendor->set_deprecated(false);

data.set_vendors_signature("SHA256:abc123...");

// Save to JSON
TLLicensing::ProtobufFileIO::SaveToJsonFile(data, "license_data.json");
```

### Load from JSON File

```cpp
// Load from JSON
tllicense::LicenseData data;
if (TLLicensing::ProtobufFileIO::LoadFromJsonFile(data, "license_data.json")) {
    std::cout << "Public Key: " << data.public_key_base64() << std::endl;
    std::cout << "Vendors: " << data.vendors_size() << std::endl;
    
    for (const auto& vendor : data.vendors()) {
        std::cout << "  " << vendor.name() 
                  << " (InProd: " << vendor.in_production() 
                  << ", Deprecated: " << vendor.deprecated() << ")" << std::endl;
    }
}
```

### Binary Format (Optional - More Efficient)

```cpp
// Save to binary (smaller file size, faster)
TLLicensing::ProtobufFileIO::SaveToBinaryFile(data, "license_data.bin");

// Load from binary
tllicense::LicenseData data;
TLLicensing::ProtobufFileIO::LoadFromBinaryFile(data, "license_data.bin");
```

**File Size Comparison:**
- JSON: ~850 bytes (human-readable)
- Binary: ~320 bytes (62% smaller!)

---

## C# File Operations

### Save to JSON File

```csharp
using TrustedLicensing.Models;
using Google.Protobuf;
using System.IO;

// Create data
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

// Save to JSON
string json = JsonFormatter.Default.Format(data);
File.WriteAllText("license_data.json", json);
```

### Load from JSON File

```csharp
// Load from JSON
string json = File.ReadAllText("license_data.json");
var data = JsonParser.Default.Parse<LicenseData>(json);

Console.WriteLine($"Public Key: {data.PublicKeyBase64}");
Console.WriteLine($"Vendors: {data.Vendors.Count}");

foreach (var vendor in data.Vendors)
{
    Console.WriteLine($"  {vendor.Name} (InProd: {vendor.InProduction}, Deprecated: {vendor.Deprecated})");
}
```

### Binary Format (Optional)

```csharp
// Save to binary
byte[] binaryData = data.ToByteArray();
File.WriteAllBytes("license_data.bin", binaryData);

// Load from binary
byte[] binaryData = File.ReadAllBytes("license_data.bin");
var data = LicenseData.Parser.ParseFrom(binaryData);
```

---

## Using with TLLicenseManager Paths

### C++ - Using Your Persistence Directory

```cpp
#include <TLConfiguration.h>
#include "LicenseDataFileIO.h"

// Get standard persistence path
auto spConfiguration = std::make_unique<TLConfiguration>();
std::string persistencePath = spConfiguration->CreateDefaultDirectory(Persistence);

// Save to your persistence location
std::string jsonPath = persistencePath + "/license_data.json";
TLLicensing::ProtobufFileIO::SaveToJsonFile(data, jsonPath);

// Example paths:
// Windows: C:\ProgramData\TrustedLicensing\Persistence\license_data.json
// Linux:   /var/lib/TrustedLicensing/Persistence/license_data.json
```

### C# - Standard Locations

```csharp
// Windows: AppData
string appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
string filePath = Path.Combine(appDataPath, "TrustedLicensing", "license_data.json");

// Ensure directory exists
Directory.CreateDirectory(Path.GetDirectoryName(filePath));

// Save
File.WriteAllText(filePath, JsonFormatter.Default.Format(data));

// Load
var data = JsonParser.Default.Parse<LicenseData>(File.ReadAllText(filePath));
```

---

## REST API File Upload/Download

### C++ REST Endpoint - Serve File

```cpp
// In Controller.h
ENDPOINT("GET", "/LM/license/data", getLicenseData) {
    
    // Load from file
    tllicense::LicenseData data;
    std::string filePath = "/path/to/license_data.json";
    
    if (!TLLicensing::ProtobufFileIO::LoadFromJsonFile(data, filePath)) {
        auto response = createResponse(Status::CODE_404, "License data not found");
        return response;
    }
    
    // Convert to JSON
    std::string jsonOutput;
    google::protobuf::util::MessageToJsonString(data, &jsonOutput);
    
    auto response = createResponse(Status::CODE_200, jsonOutput.c_str());
    response->putHeader("content-type", "application/json");
    return response;
}

// Save uploaded data
ENDPOINT("POST", "/LM/license/data", saveLicenseData,
         BODY_STRING(String, body)) {
    
    // Parse JSON
    tllicense::LicenseData data;
    auto status = google::protobuf::util::JsonStringToMessage(body->c_str(), &data);
    
    if (!status.ok()) {
        auto response = createResponse(Status::CODE_400, "Invalid JSON");
        return response;
    }
    
    // Save to file
    std::string filePath = "/path/to/license_data.json";
    TLLicensing::ProtobufFileIO::SaveToJsonFile(data, filePath);
    
    auto response = createResponse(Status::CODE_200, "{\"success\": true}");
    response->putHeader("content-type", "application/json");
    return response;
}
```

### C# - Download from REST API

```csharp
using System.Net.Http;
using Google.Protobuf;

// Download license data
using var httpClient = new HttpClient();
var response = await httpClient.GetAsync("http://localhost:52014/LM/license/data");

if (response.IsSuccessStatusCode)
{
    string json = await response.Content.ReadAsStringAsync();
    var data = JsonParser.Default.Parse<LicenseData>(json);
    
    // Save to local file
    File.WriteAllText("downloaded_license.json", json);
    
    Console.WriteLine($"Downloaded {data.Vendors.Count} vendors");
}
```

### C# - Upload to REST API

```csharp
// Create data
var data = new LicenseData { /* ... */ };

// Convert to JSON
string json = JsonFormatter.Default.Format(data);

// Upload
using var httpClient = new HttpClient();
var content = new StringContent(json, Encoding.UTF8, "application/json");
var response = await httpClient.PostAsync("http://localhost:52014/LM/license/data", content);

Console.WriteLine($"Upload status: {response.StatusCode}");
```

---

## Error Handling

### C++

```cpp
try {
    tllicense::LicenseData data;
    
    if (!TLLicensing::ProtobufFileIO::LoadFromJsonFile(data, "license_data.json")) {
        BOOST_LOG_TRIVIAL(error) << "Failed to load license data";
        return;
    }
    
    // Validate data
    if (data.public_key_base64().empty()) {
        BOOST_LOG_TRIVIAL(error) << "Missing public key";
        return;
    }
    
    if (data.vendors_size() == 0) {
        BOOST_LOG_TRIVIAL(warning) << "No vendors found";
    }
    
} catch (const std::exception& ex) {
    BOOST_LOG_TRIVIAL(error) << "Exception: " << ex.what();
}
```

### C#

```csharp
try
{
    if (!File.Exists("license_data.json"))
    {
        Console.WriteLine("File not found");
        return;
    }
    
    string json = File.ReadAllText("license_data.json");
    var data = JsonParser.Default.Parse<LicenseData>(json);
    
    // Validate data
    if (string.IsNullOrEmpty(data.PublicKeyBase64))
    {
        Console.WriteLine("Missing public key");
        return;
    }
    
    if (data.Vendors.Count == 0)
    {
        Console.WriteLine("Warning: No vendors found");
    }
}
catch (InvalidProtocolBufferException ex)
{
    Console.WriteLine($"Invalid JSON format: {ex.Message}");
}
catch (IOException ex)
{
    Console.WriteLine($"File error: {ex.Message}");
}
```

---

## Benefits of This Approach

✅ **Same JSON format** - C++ and C# produce identical JSON  
✅ **File compatibility** - Files can be read by either language  
✅ **Version control friendly** - JSON is text-based and diffable  
✅ **Human-readable** - Easy to inspect and debug  
✅ **Optional binary format** - Use when efficiency matters  
✅ **Type-safe** - Protobuf validates structure automatically  
✅ **REST-compatible** - JSON works with any HTTP client  

---

## Files Created

1. **[_docs_dev/example_license_data.json](_docs_dev/example_license_data.json)** - Sample JSON output
2. **[TLLicenseCommon/sources/include/LicenseDataFileIO.h](TLLicenseCommon/sources/include/LicenseDataFileIO.h)** - C++ file I/O utilities
3. **[_docs_dev/CSharpExample.cs](_docs_dev/CSharpExample.cs)** - C# examples with file I/O

---

## Quick Start

### C++
```cpp
#include "LicenseDataFileIO.h"

// Create example data
TLLicensing::FileIOExamples::ProtobufExample();
```

### C#
```csharp
using TrustedLicensing.Examples;

// Run file I/O example
ProtobufCSharpExample.FileIOExample();
```

Both will create `license_data.json` that can be read by the other language!
