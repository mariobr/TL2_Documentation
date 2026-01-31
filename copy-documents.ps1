# Script to copy documentation files from parent directories
# Target extensions: .md, .docx, .pdf, .ppt, .pptx

# Define workspace and parent directory
$workspaceDir = $PSScriptRoot
$parentDir = Split-Path $workspaceDir -Parent

# Define source directories
$sourceDirs = @(
    (Join-Path $parentDir "TL2"),
    (Join-Path $parentDir "TL2_dotnet"),
    (Join-Path $parentDir "TLCloud")
)

# Define destination directory
$destinationDir = Join-Path $workspaceDir "input"

# Create destination directory if it doesn't exist
if (-not (Test-Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    Write-Host "Created destination directory: $destinationDir" -ForegroundColor Green
}

# Define file extensions to copy
$extensions = @("*.md", "*.docx", "*.pdf", "*.ppt", "*.pptx", "*.drawio", "plantuml")

# Define directories to ignore
$ignoreDirs = @("vcpkg_installed", "out")

# Track statistics
$totalCopied = 0
$totalSkipped = 0

# Copy files from each source directory
foreach ($sourceDir in $sourceDirs) {
    if (Test-Path $sourceDir) {
        Write-Host "`nProcessing: $sourceDir" -ForegroundColor Cyan
        
        foreach ($ext in $extensions) {
            $files = Get-ChildItem -Path $sourceDir -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                try {
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
                        $totalSkipped++
                        continue
                    }
                    
                    $destPath = Join-Path $destinationDir $relativePath
                    $destFolder = Split-Path $destPath -Parent
                    
                    # Create subfolder structure in destination
                    if (-not (Test-Path $destFolder)) {
                        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
                    }
                    
                    # Copy file
                    Copy-Item -Path $file.FullName -Destination $destPath -Force
                    Write-Host "  Copied: $relativePath" -ForegroundColor Gray
                    $totalCopied++
                }
                catch {
                    Write-Host "  Error copying $($file.Name): $_" -ForegroundColor Red
                    $totalSkipped++
                }
            }
        }
    }
    else {
        Write-Host "`nWarning: Source directory not found: $sourceDir" -ForegroundColor Yellow
    }
}

# Display summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Copy operation completed!" -ForegroundColor Green
Write-Host "Total files copied: $totalCopied" -ForegroundColor Green
Write-Host "Total files skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host "Destination: $destinationDir" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
