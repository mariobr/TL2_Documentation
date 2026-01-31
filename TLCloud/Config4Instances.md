# TLConfig4Instances

## 🧩 Purpose

This document explains how to configure **multiple instances** of a .NET application so that each instance can have its own configuration while keeping a shared base configuration.
Environment variables always override values from configuration files.

---

## ⚙️ Configuration Sources and Precedence

Configuration values in .NET are loaded in **the order providers are added**.
Providers added later **override** earlier ones.

**Typical order (lowest → highest precedence):**

1. `appsettings.json`
2. `appsettings.{Environment}.json`
3. Environment variables
4. Command-line arguments

---

## 📁 File Structure Example

```
/MyApp
 ├── appsettings.json
 ├── appsettings.Development.json
 ├── appsettings.Staging.json
 ├── appsettings.Production.json
 └── Program.cs
```

---

## 🧠 appsettings.json (base config)

```json
{
  "MySettings": {
    "ApiUrl": "https://api.default.local",
    "InstanceName": "DefaultInstance",
    "TimeoutSeconds": 30
  }
}
```

---

## 🧩 Instance-specific environment configs

Each instance can override values using environment variables.

### Example (Linux / macOS)

```bash
export MySettings__ApiUrl=https://api.instance1.example
export MySettings__InstanceName=Instance1
export MySettings__TimeoutSeconds=45
dotnet run --environment "Production"
```

### Example (Windows PowerShell)

```powershell
$env:MySettings__ApiUrl = "https://api.instance2.example"
$env:MySettings__InstanceName = "Instance2"
$env:MySettings__TimeoutSeconds = "60"
dotnet run --environment "Production"
```

### Example (Docker Compose)

```yaml
services:
  myapp-instance1:
    image: myapp:latest
    environment:
      - MySettings__ApiUrl=https://api.instance1.example
      - MySettings__InstanceName=Instance1
  myapp-instance2:
    image: myapp:latest
    environment:
      - MySettings__ApiUrl=https://api.instance2.example
      - MySettings__InstanceName=Instance2
```

---

## 🧰 Program.cs Example

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json",
                 optional: true, reloadOnChange: true)
    .AddEnvironmentVariables()
    .AddCommandLine(args);

var config = builder.Configuration;
var app = builder.Build();

var mySettings = config.GetSection("MySettings").Get<MySettings>();
app.MapGet("/config", () => mySettings);

app.Run();

public record MySettings(string ApiUrl, string InstanceName, int TimeoutSeconds);
```

---

## ✅ Summary

| Source                           | Description                              | Override Capability |
| -------------------------------- | ---------------------------------------- | ------------------- |
| `appsettings.json`               | Shared base configuration                | No                  |
| `appsettings.{Environment}.json` | Environment-based overrides              | Yes                 |
| Environment variables            | Per-instance overrides (e.g., in Docker) | ✅ Highest           |
| Command-line args                | Optional runtime overrides               | ✅ Highest           |

---

## 📦 Recommended Pattern

* Keep **common values** in `appsettings.json`.
* Use **per-environment JSON files** for environment-level differences.
* Use **environment variables** for instance-level customization.
* In containerized or cloud deployments, rely primarily on **environment variables** for scalability.

---
