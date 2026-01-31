# Script to generate JSON mapping of copied files
# Maps destination files to their original source locations

$workspaceDir = $PSScriptRoot
$parentDir = Split-Path $workspaceDir -Parent
$destinationDir = Join-Path $workspaceDir "input"

# Define source directories
$sourceDirs = @(
    @{Name = "TL2"; Path = (Join-Path $parentDir "TL2")},
    @{Name = "TL2_dotnet"; Path = (Join-Path $parentDir "TL2_dotnet")},
    @{Name = "TLCloud"; Path = (Join-Path $parentDir "TLCloud")}
)

# Define file extensions to map
$extensions = @("*.md", "*.docx", "*.pdf", "*.ppt", "*.pptx")

# Define directories to ignore
$ignoreDirs = @("vcpkg_installed", "out")

# Create mapping array
$fileMapping = @()

# Process each source directory
foreach ($sourceInfo in $sourceDirs) {
    $sourceDir = $sourceInfo.Path
    $sourceName = $sourceInfo.Name
    
    if (Test-Path $sourceDir) {
        Write-Host "Processing: $sourceDir" -ForegroundColor Cyan
        
        foreach ($ext in $extensions) {
            $files = Get-ChildItem -Path $sourceDir -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
                
                # Skip if file is in ignored directory
                $shouldIgnore = $false
                foreach ($ignoreDir in $ignoreDirs) {
                    if ($relativePath -like "$ignoreDir*" -or $relativePath -like "*\$ignoreDir\*" -or $relativePath -like "*/$ignoreDir/*") {
                        $shouldIgnore = $true
                        break
                    }
                }
                
                if ($shouldIgnore) {
                    continue
                }
                
                $destPath = Join-Path $destinationDir $relativePath
                
                # Add to mapping
                $fileMapping += [PSCustomObject]@{
                    sourceRepository = $sourceName
                    originalPath = $file.FullName
                    relativePath = $relativePath
                    destinationPath = $destPath
                    fileType = $file.Extension.TrimStart('.')
                    fileName = $file.Name
                    lastModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                }
                
                Write-Host "  Mapped: $relativePath" -ForegroundColor Gray
            }
        }
    }
}

# Generate JSON
$jsonOutput = $fileMapping | ConvertTo-Json -Depth 10
$jsonPath = Join-Path $workspaceDir "file-mapping.json"
$jsonOutput | Out-File -FilePath $jsonPath -Encoding UTF8

# Display summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "File mapping generated!" -ForegroundColor Green
Write-Host "Total files mapped: $($fileMapping.Count)" -ForegroundColor Green
Write-Host "Output file: $jsonPath" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
