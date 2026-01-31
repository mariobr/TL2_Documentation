# vcpkg Installation Issues and Solutions

## Common Error: grpc Build Directory Access Denied

### Error Message
```
CMake Error at scripts/cmake/vcpkg_extract_source_archive.cmake:153 (file):
  file RENAME failed to rename
    D:/DEV/vcpkg/buildtrees/grpc/src/v1.60.0-2dcaca28c0.clean.tmp/grpc-1.60.0
  to
    D:/DEV/vcpkg/buildtrees/grpc/src/v1.60.0-2dcaca28c0.clean
  because: Access is denied.
```

### Root Cause
Windows file locks caused by:
- Antivirus/Windows Defender real-time scanning
- Windows Search Indexer
- File handles held by IDE or other processes
- Previous failed build leaving locked files

### Solutions

#### Solution 1: Clean Build Directory
```powershell
# Delete the locked grpc build directory
Remove-Item -Path "D:\DEV\vcpkg\buildtrees\grpc" -Recurse -Force -ErrorAction SilentlyContinue

# Retry installation
vcpkg install --triplet x64-windows-static
```

#### Solution 2: Close IDE and Processes
1. Close Visual Studio Code completely
2. Close any terminal windows running in the project
3. Wait 10-15 seconds for file handles to release
4. Reopen and retry installation

#### Solution 3: Add Windows Defender Exclusion (Recommended)
1. Open **Windows Security** → **Virus & threat protection**
2. Click **Manage settings**
3. Scroll to **Exclusions** → Click **Add or remove exclusions**
4. Add folder exclusion: `D:\DEV\vcpkg\buildtrees`
5. Optionally also exclude: `D:\DEV\vcpkg\downloads`

#### Solution 4: Run as Administrator
```powershell
# Run PowerShell as Administrator, then:
cd D:\DEV\TL2
D:\DEV\vcpkg\vcpkg.exe install --triplet x64-windows-static
```

#### Solution 5: Temporarily Disable Real-Time Protection
1. Open Windows Security → Virus & threat protection
2. Click **Manage settings**
3. Turn off **Real-time protection** temporarily
4. Run vcpkg install
5. Re-enable real-time protection after installation

### Prevention Tips

1. **Always exclude vcpkg build directories from antivirus**
   - Add to exclusions during initial setup
   - Significantly speeds up builds

2. **Use manifest mode for project-specific dependencies**
   - Create `vcpkg.json` in project root
   - Dependencies install to `vcpkg_installed/` locally
   - Better isolation and reproducibility

3. **Clean builds regularly**
   ```powershell
   # Clean all build trees
   vcpkg remove --outdated
   
   # Or clean specific package
   Remove-Item -Path "D:\DEV\vcpkg\buildtrees\<package-name>" -Recurse -Force
   ```

4. **Close unnecessary processes during large builds**
   - Close IDEs not actively in use
   - Close file explorers browsing vcpkg directories

## vcpkg Manifest Mode vs Classic Mode

### Manifest Mode (Recommended for Projects)
- Uses `vcpkg.json` in project root
- Installs to `<project>/vcpkg_installed/`
- Project-specific versions
- Automatic CMake integration via toolchain file

### Classic Mode (Global Installation)
- Manual installation: `vcpkg install <package>:x64-windows-static`
- Installs to `D:/DEV/vcpkg/installed/`
- Shared across all projects
- Requires manual version management

## Boost Package Components

When using Boost with vcpkg, the `boost-log` package provides both:
- `log` component
- `log_setup` component

**CMakeLists.txt example:**
```cmake
find_package(Boost 1.85.0 REQUIRED COMPONENTS log_setup log filesystem)
```

**vcpkg.json dependencies:**
```json
{
  "dependencies": [
    "boost-log",
    "boost-filesystem",
    "boost-property-tree"
  ]
}
```

Note: No need for separate `boost-log-setup` package - it's included in `boost-log`.

## Troubleshooting Commands

```powershell
# Check installed packages
vcpkg list

# Remove package
vcpkg remove <package>:x64-windows-static

# Update vcpkg itself
cd D:\DEV\vcpkg
git pull
.\bootstrap-vcpkg.bat

# Clean all build artifacts
Remove-Item -Path "D:\DEV\vcpkg\buildtrees\*" -Recurse -Force

# Verify triplet
vcpkg help triplet
```
