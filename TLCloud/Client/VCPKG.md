# Search
- https://vcpkg.io/en/packages.html

## Reinstall Problem
https://github.com/microsoft/vcpkg/issues/26346#issuecomment-1319244766


# CMAKE
## Linux
set (VCPKG_HOME "/DEV/vcpkg")
set(VCPKG_DISABLE_COMPILER_TRACKING ON)

# Preset
## Windows

```json
{
  "name": "windows-base",
  "hidden": true,
  "generator": "Visual Studio 17 2022",
  "binaryDir": "${sourceDir}/out/win/${presetName}",
  "installDir": "${sourceDir}/out/install/win/${presetName}",
  "cacheVariables": {
    "CMAKE_C_COMPILER": "cl.exe",
    "CMAKE_CXX_COMPILER": "cl.exe",
    "CMAKE_TOOLCHAIN_FILE": "D:/DEV/vcpkg/scripts/buildsystems/vcpkg.cmake",
    "VCPKG_TARGET_TRIPLET": "x64-windows-static",
    "VCPKG_HOST_TRIPLET": "x64-windows-static",
    "VCPKG_DISABLE_COMPILER_TRACKING" : "ON"
  },
  "condition": {
    "type": "equals",
    "lhs": "${hostSystemName}",
    "rhs": "Windows"
  }
},
```



# Package config
```json
{
    "name": "gayrpc",
    "version-string": "0.0.1",
    "dependencies": [
        {
            "name": "brynet",
            "version>=": "1.11.1#1"
        },
        {
            "name": "protobuf",
            "version>=": "3.15.8"
        },
        {
            "name": "folly"
        }
    ],
    "overrides": [
        {
            "name": "protobuf",
            "version": "3.5.1"
        },
        {
            "name": "brynet",
            "version": "1.11.1#1"
        },
        {
            "name": "folly",
            "version-string": "2019.10.21.00"
        }
    ],
    "builtin-baseline": "2b1f2ca96a0e4483f50ba605c4c6cc0243633c8d"
}
```
# Baseline

- To add an initial "builtin-baseline", use vcpkg x-update-baseline --add-initial-baseline. 
- To update baselines in a manifest, use vcpkg x-update-baseline. 
