# TLLicenseManager Windows Deployment Scripts

This directory contains PowerShell scripts for deploying and managing the TLLicenseManager service on Windows systems.

## Overview

TLLicenseManager runs as a Windows Service on Windows systems with full TPM 2.0 support via the TBS (TPM Base Services) API. These scripts automate the deployment, installation, and management of the service.

## Scripts

### 1. CopyBuildOutput.ps1

Copies the built TLLicenseManager.exe and dependencies from the build directory to the deployment folder.

**Usage:**
```powershell
.\CopyBuildOutput.ps1 [-Configuration <Release|Debug>] [-Force]
```

**Parameters:**
- `-Configuration` - Build configuration to copy (Release or Debug). Default: Debug
- `-Force` - Overwrite existing files without prompting

**Examples:**
```powershell
# Copy Release build (default)
.\CopyBuildOutput.ps1

# Copy Debug build
.\CopyBuildOutput.ps1 -Configuration Debug

# Force overwrite existing files
.\CopyBuildOutput.ps1 -Force
```

**Build Configurations:**
- `Release` - Copies from `out\build\win64-release\`
- `Debug` - Copies from `out\build\win64-debug\`

### 2. InstallTLLicenseManager.ps1

Installs or removes TLLicenseManager as a Windows Service with TPM 2.0 support.

**Usage:**
```powershell
.\InstallTLLicenseManager.ps1 [-Remove] [-ServicePath <Path>] [-RestPort <Port>] [-GrpcPort <Port>] [-SkipFirewall]
```

**Parameters:**
- `-Remove` - Remove the service instead of installing
- `-ServicePath` - Custom path to TLLicenseManager.exe
- `-RestPort` - REST API port (default: 52014)
- `-GrpcPort` - gRPC port (default: 52013)
- `-SkipFirewall` - Skip Windows Firewall configuration

**Examples:**
```powershell
# Install with default settings
.\InstallTLLicenseManager.ps1

# Install with custom ports
.\InstallTLicenseManager.ps1 -RestPort 8080 -GrpcPort 8081

# Remove the service
.\InstallTLLicenseManager.ps1 -Remove

# Install without firewall configuration
.\InstallTLLicenseManager.ps1 -SkipFirewall

# Install with custom executable path
.\InstallTLLicenseManager.ps1 -ServicePath "C:\MyPath\TLLicenseManager.exe"
```

## Quick Start

### 1. Build the Project

First, build TLLicenseManager using CMake or Visual Studio:

**Using CMake:**
```powershell
# Configure
cmake --preset win64-release

# Build
cmake --build out\build\win64-release --config Release
```

**Using Visual Studio:**
- Open the solution in Visual Studio
- Select Release configuration
- Build → Build Solution

### 2. Copy Build Output

Open PowerShell as Administrator and run:

```powershell
cd scripts\Windows
.\CopyBuildOutput.ps1 -Configuration Release
```

The script will copy files to `scripts\Windows\TLLicenseManager\`

### 3. Install the Service

Install TLLicenseManager as a Windows Service:

```powershell
.\InstallTLLicenseManager.ps1
```

The installer will:
- Check for Administrator privileges (auto-elevates if needed)
- Verify TPM 2.0 availability
- Check/start TPM Base Services (TBS)
- Create application directories
- Register Windows Service
- Configure service recovery options
- Optionally configure Windows Firewall rules
- Start the service (if requested)

### 4. Verify Installation

Check service status:

```powershell
Get-Service -Name asperionLM
```

View service details:

```powershell
Get-Service -Name asperionLM | Format-List *
```

Test REST API:

```powershell
Invoke-WebRequest -Uri http://localhost:52014/status
```

## Service Management

The service is installed as `asperionLM` and managed using standard Windows Service commands:

### Start/Stop/Restart

```powershell
# Start service
Start-Service -Name asperionLM

# Stop service
Stop-Service -Name asperionLM

# Restart service
Restart-Service -Name asperionLM
```

### Service Control Manager (sc.exe)

```cmd
# Start service
sc start asperionLM

# Stop service
sc stop asperionLM

# Query service status
sc query asperionLM

# View service configuration
sc qc asperionLM
```

### Services MMC

You can also manage the service through the Windows Services management console:

```powershell
# Open Services console
services.msc
```

Look for **"asperion Trusted LicenseManager"** in the list.

### View Service Logs

Service events are logged to Windows Event Viewer:

```powershell
# Open Event Viewer
eventvwr.msc
```

Navigate to: **Windows Logs → Application** and filter for source **asperionLM**

Or use PowerShell:

```powershell
# View recent service events
Get-EventLog -LogName Application -Source asperionLM -Newest 50

# Or with newer cmdlet
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='asperionLM'} -MaxEvents 50
```

## Directory Structure

After installation, the following directories are created:

```
C:\ProgramData\TrustedLicensing\
├── Config\        # Configuration files
├── Persistence\   # License and state data
└── Logs\         # Application logs
```

**Permissions:**
- Full control for SYSTEM and Administrators
- Located in ProgramData for proper service access

## Windows Service Configuration

The service runs with the following configuration:

- **Service Name:** `asperionLM`
- **Display Name:** asperion Trusted LicenseManager
- **Startup Type:** Automatic
- **Account:** Local System
- **Dependencies:** TPM Base Services (TBS)
- **Recovery:** Automatic restart on failure (up to 3 times)

### Service Recovery Options

The installer configures automatic recovery:
- **First failure:** Restart after 60 seconds
- **Second failure:** Restart after 120 seconds
- **Subsequent failures:** Restart after 300 seconds
- **Reset fail count:** After 24 hours

## TPM 2.0 Support

### TPM Base Services (TBS)

The service depends on TPM Base Services for TPM access:

**Check TBS status:**
```powershell
Get-Service -Name TBS
```

**Start TBS if needed:**
```powershell
Start-Service -Name TBS
```

### Verify TPM

Check TPM status using PowerShell:

```powershell
# Get TPM information
Get-Tpm

# Check if TPM is ready
$tpm = Get-Tpm
$tpm.TpmReady
$tpm.TpmPresent
$tpm.TpmEnabled
```

Using `tpm.msc`:

```powershell
# Open TPM Management console
tpm.msc
```

### TPM Requirements

- TPM 2.0 hardware or firmware TPM (fTPM)
- Windows 8/Server 2012 or later
- TPM Base Services enabled and running
- Administrator privileges for service installation

### Running Without TPM

If TPM is not available, the service will automatically fall back to `--no-tpm` mode. The installer will display a warning but will proceed with installation.

## Windows Firewall Configuration

The installer can automatically configure Windows Firewall rules for:
- **REST API:** Port 52014 (TCP, Inbound)
- **gRPC:** Port 52013 (TCP, Inbound)

### Firewall Profiles

Rules are created for:
- Domain networks
- Private networks

(Public network access is not enabled by default for security)

### Manual Firewall Configuration

If you skipped firewall configuration or need to modify rules:

**Using PowerShell:**
```powershell
# Add REST API rule
New-NetFirewallRule -DisplayName "TLLicenseManager REST API" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 52014 `
    -Action Allow `
    -Profile Domain,Private

# Add gRPC rule
New-NetFirewallRule -DisplayName "TLLicenseManager gRPC" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 52013 `
    -Action Allow `
    -Profile Domain,Private
```

**Using Windows Firewall GUI:**
```powershell
# Open Windows Firewall with Advanced Security
wf.msc
```

### View Existing Rules

```powershell
# List TLLicenseManager firewall rules
Get-NetFirewallRule -DisplayName "*TLLicenseManager*" | Format-Table DisplayName, Enabled, Direction, Action
```

### Remove Firewall Rules

```powershell
Remove-NetFirewallRule -DisplayName "TLLicenseManager REST API"
Remove-NetFirewallRule -DisplayName "TLLicenseManager gRPC"
```

## Troubleshooting

### Service Won't Start

1. **Check Event Viewer** for detailed error messages:
   ```powershell
   eventvwr.msc
   # Navigate to Windows Logs → Application
   ```

2. **Check service status:**
   ```powershell
   Get-Service -Name asperionLM | Format-List *
   ```

3. **Try starting manually with verbose output:**
   ```cmd
   C:\Path\To\TLLicenseManager.exe --rest-port 52014 --grpc-port 52013
   ```

### Common Issues

#### Missing Dependencies

Check for missing DLL files:
- Visual C++ Redistributables
- OpenSSL libraries
- Poco libraries

Install Visual C++ Redistributables:
- Download from Microsoft website
- Or include DLLs in the deployment folder

#### Port Already in Use

Check what's using the port:
```powershell
Get-NetTCPConnection -LocalPort 52014
```

Or use `netstat`:
```cmd
netstat -ano | findstr :52014
```

Kill the process if needed:
```powershell
Stop-Process -Id <PID> -Force
```

#### Permission Issues

Ensure the service is running with appropriate permissions:
- Check service account (should be Local System)
- Verify directory permissions in `C:\ProgramData\TrustedLicensing`
- TPM access requires elevated privileges

#### TPM Access Issues

1. **Check TPM status:**
   ```powershell
   Get-Tpm
   ```

2. **Verify TBS is running:**
   ```powershell
   Get-Service -Name TBS
   ```

3. **Check TPM ownership:**
   ```powershell
   # Open TPM Management
   tpm.msc
   ```

4. **Event Viewer TPM logs:**
   ```
   Applications and Services Logs → Microsoft → Windows → TPM-WMI
   ```

### Running Interactively for Debugging

Stop the service and run interactively:

```powershell
# Stop service
Stop-Service -Name asperionLM

# Run interactively (as Administrator)
cd C:\Path\To\Deployment
.\TLLicenseManager.exe --rest-port 52014 --grpc-port 52013
```

This allows you to see console output and debug issues.

## Administrator Privileges

The install script requires Administrator privileges. If you're not running as Administrator, the script will automatically:

1. Detect lack of privileges
2. Request elevation via UAC prompt
3. Re-launch itself with Administrator rights
4. Pass through all command-line parameters

You can also manually run as Administrator:

```powershell
# Right-click PowerShell → Run as Administrator
# Or use RunAs
Start-Process powershell.exe -Verb RunAs -ArgumentList "-File .\InstallTLLicenseManager.ps1"
```

## Execution Policy

If you encounter execution policy errors, you may need to adjust PowerShell execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Allow local scripts (current user)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single script
PowerShell -ExecutionPolicy Bypass -File .\InstallTLLicenseManager.ps1
```

## Uninstallation

Remove the service and optionally clean up data:

```powershell
.\InstallTLLicenseManager.ps1 -Remove
```

The uninstaller will:
- Stop the service if running
- Disable the service
- Remove service registration
- Prompt to remove firewall rules
- Ask about removing data directories

**Manual cleanup (if needed):**

```powershell
# Remove service (if script fails)
sc.exe delete asperionLM

# Remove firewall rules
Remove-NetFirewallRule -DisplayName "TLLicenseManager*"

# Remove data directories
Remove-Item -Path "C:\ProgramData\TrustedLicensing" -Recurse -Force
```

## Service Configuration File

After installation, the service is registered with these settings:

```
Service Name:    asperionLM
Display Name:    asperion Trusted LicenseManager
Binary Path:     "C:\Path\To\TLLicenseManager.exe" --rest-port 52014 --grpc-port 52013
Start Type:      Automatic
Account:         LocalSystem
Dependencies:    TBS (TPM Base Services)
```

View full configuration:

```powershell
Get-WmiObject Win32_Service -Filter "Name='asperionLM'" | Format-List *
```

## Integration with Windows Features

### Task Scheduler Integration

You can create scheduled tasks to interact with the service:

```powershell
# Example: Daily health check
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-Command Invoke-WebRequest http://localhost:52014/status"
$Trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName "LicenseManager Health Check" -Action $Action -Trigger $Trigger
```

### Performance Monitoring

Monitor service performance:

```powershell
# Get process info
Get-Process -Name TLLicenseManager

# Monitor with Performance Monitor
perfmon.msc
```

### Windows Admin Center

If you use Windows Admin Center, you can manage the service through the web interface at `https://localhost:6516`

## Comparison with Linux Scripts

These Windows scripts provide equivalent functionality to the Linux bash scripts:

| Windows | Linux | Purpose |
|---------|-------|---------|
| `CopyBuildOutput.ps1` | `copy-build-output.sh` | Copy build artifacts |
| `InstallTLLicenseManager.ps1` | `install-tllicensemanager.sh` | Install/remove service |
| Windows Service | systemd Service | Service management |
| TBS (TPM Base Services) | TPM device files | TPM access |
| Windows Firewall | UFW/firewalld | Firewall configuration |
| Event Viewer | journalctl | Log viewing |
| services.msc | systemctl | Service management UI |

## Best Practices

### Security

1. **Run with least privileges** - The service runs as LocalSystem for TPM access, but consider using a dedicated service account if TPM is not required
2. **Firewall rules** - Only enable for trusted networks (Domain/Private)
3. **Keep TPM firmware updated** - Check manufacturer for updates
4. **Monitor logs** - Regularly check Event Viewer for security events

### Maintenance

1. **Regular backups** - Backup `C:\ProgramData\TrustedLicensing\Persistence`
2. **Log rotation** - Monitor log file sizes in the Logs directory
3. **Windows Updates** - Keep Windows and TPM firmware updated
4. **Service health checks** - Implement monitoring of the REST API endpoint

### Deployment

1. **Test in staging** - Always test deployment in a non-production environment
2. **Document custom configurations** - Keep track of any custom ports or settings
3. **Automate deployment** - Consider using group policy or configuration management tools
4. **Version control** - Keep copies of working configurations

## Advanced Configuration

### Custom Service Account

To run the service with a custom account (instead of LocalSystem):

```powershell
# Create service account
$SecurePassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
New-LocalUser -Name "svc_asperionLM" -Password $SecurePassword -PasswordNeverExpires

# Grant TPM permissions (requires additional setup)
# Modify service account
sc.exe config asperionLM obj= ".\svc_asperionLM" password= "P@ssw0rd"
```

### Network Bindings

Configure the service to listen on specific network interfaces by modifying the configuration file.

### High Availability

For high availability scenarios:
- Deploy on multiple servers
- Use load balancer for REST API
- Implement health check endpoints
- Configure service clustering (if needed)

## Support and Resources

### Useful Commands Reference

```powershell
# Service Management
Get-Service asperionLM
Start-Service asperionLM
Stop-Service asperionLM
Restart-Service asperionLM

# Event Logs
Get-EventLog -LogName Application -Source asperionLM -Newest 50
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='asperionLM'}

# Firewall
Get-NetFirewallRule -DisplayName "*TLLicenseManager*"
Test-NetConnection -ComputerName localhost -Port 52014

# TPM
Get-Tpm
Get-TpmEndorsementKeyInfo
Get-Service TBS

# Process
Get-Process TLLicenseManager
Get-Process TLLicenseManager | Format-List *
```

### Log Locations

- **Service Events:** Event Viewer → Windows Logs → Application
- **Application Logs:** `C:\ProgramData\TrustedLicensing\Logs\`
- **Configuration:** `C:\ProgramData\TrustedLicensing\Config\`

### Documentation

- TPM documentation: `tpm.msc` → Help
- Windows Service documentation: `services.msc` → Help
- PowerShell help: `Get-Help <cmdlet-name> -Full`

## Example Deployment Workflow

Complete deployment workflow for a production environment:

```powershell
# 1. Build the project
cmake --preset win64-release
cmake --build out\build\win64-release --config Release

# 2. Copy build output
cd scripts\Windows
.\CopyBuildOutput.ps1 -Configuration Release

# 3. Review what will be installed
Get-ChildItem .\TLLicenseManager\

# 4. Install the service
.\InstallTLLicenseManager.ps1 -RestPort 52014 -GrpcPort 52013

# 5. Verify installation
Get-Service asperionLM
Test-NetConnection -ComputerName localhost -Port 52014

# 6. Check initial logs
Get-EventLog -LogName Application -Source asperionLM -Newest 10

# 7. Test REST API
Invoke-RestMethod -Uri http://localhost:52014/status
```

## Updates and Upgrades

To update the service to a new version:

```powershell
# 1. Stop the service
Stop-Service asperionLM

# 2. Backup current version
Copy-Item ".\TLLicenseManager" -Destination ".\TLLicenseManager.backup" -Recurse

# 3. Copy new version
.\CopyBuildOutput.ps1 -Configuration Release -Force

# 4. Start the service
Start-Service asperionLM

# 5. Verify
Get-Service asperionLM
Invoke-RestMethod -Uri http://localhost:52014/status
```

## License and Copyright

Refer to the main project documentation for license and copyright information.
