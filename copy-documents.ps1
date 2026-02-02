# Script to copy documentation files from parent directories and create file mappings
# Target extensions: .md, .docx, .pdf, .ppt, .pptx

param(
    [switch]$Copy,
    [switch]$Scan,
    [switch]$RemoveSources
)

# Track if Copy was explicitly passed
$CopyExplicitlyPassed = $PSBoundParameters.ContainsKey('Copy')

# Default to Copy mode to always sync newer files
if (-not $Copy -and -not $Scan -and -not $RemoveSources) {
    $Copy = $true
}

# Define workspace and parent directory
$workspaceDir = $PSScriptRoot
$parentDir = Split-Path $workspaceDir -Parent

# Define source directories
$sourceDirs = @(
    (Join-Path $parentDir "TL2"),
    (Join-Path $parentDir "TL2_dotnet"),
    (Join-Path $parentDir "TLCloud")
)

# Define target extensions
$extensions = @("*.md", "*.docx", "*.pdf", "*.ppt", "*.pptx", "*.plantuml", "*.mermaid", "*.mmd")

# Define ignored subdirectories (without leading slash)
$ignoreFolders = @("out", "vcpkg_installed", "bin", "obj", ".git", "node_modules", ".devcontainer",
                 "_Container", "_SBOM", "_Scripts", "_docs_local" )

# Define copy-only folders (files from these folders will be copied but never deleted from source)
$copyOnlyFolders = @("_vault", "_docs_dev", "_docs_public")

# Define ignored file patterns (files matching these patterns will be ignored)
$ignoreFiles = @("README.md")

# Define mapping output file
$mappingFile = Join-Path $workspaceDir "file-mapping.json"

# Track statistics
$totalCopied = 0
$totalSkipped = 0
$totalNew = 0
$totalUpdated = 0

# Load existing mapping if in scan or remove mode
$existingMapping = @{}
if (($Scan -or $RemoveSources) -and (Test-Path $mappingFile)) {
    try {
        $existingMappingJson = Get-Content -Path $mappingFile -Raw -Encoding UTF8
        $existingMapping = $existingMappingJson | ConvertFrom-Json -AsHashtable
        Write-Host "Loaded existing mapping with $($existingMapping.Count) files" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Warning: Could not load existing mapping file" -ForegroundColor Yellow
    }
}

# Create mapping structure
$mapping = @{}
$newFiles = @()
$updatedFiles = @()

# Handle remove sources mode
if ($RemoveSources) {
    if (-not (Test-Path $mappingFile)) {
        Write-Host "Error: No mapping file found. Run a scan or copy operation first." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Scanning for new files..." -ForegroundColor Cyan
    
    # First, scan for new files
    foreach ($sourceDir in $sourceDirs) {
        if (Test-Path $sourceDir) {
            $sourceDirName = Split-Path $sourceDir -Leaf
            
            foreach ($ext in $extensions) {
                $files = Get-ChildItem -Path $sourceDir -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
                
                foreach ($file in $files) {
                    # Calculate relative path
                    $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
                    $relativePathNormalized = $relativePath -replace '\\', '/'
                    
                    # Check if file is in an ignored folder
                    $shouldIgnore = $false
                    foreach ($ignoreFolder in $ignoreFolders) {
                        if ($relativePathNormalized -like "$ignoreFolder/*" -or $relativePathNormalized -like "*/$ignoreFolder/*") {
                            $shouldIgnore = $true
                            break
                        }
                    }
                    
                    if ($shouldIgnore) {
                        continue
                    }
                    
                    # Check if file matches ignored file patterns
                    $fileName = $file.Name
                    foreach ($ignorePattern in $ignoreFiles) {
                        if ($fileName -ilike $ignorePattern) {
                            $shouldIgnore = $true
                            break
                        }
                    }
                    
                    if ($shouldIgnore) {
                        continue
                    }
                    
                    $mappingPath = "$sourceDirName/$relativePathNormalized"
                    
                    # Check if file is new
                    if (-not $existingMapping.ContainsKey($mappingPath)) {
                        $totalNew++
                        Write-Host "  [NEW] $mappingPath" -ForegroundColor Green
                    }
                }
            }
        }
    }
    
    if ($totalNew -gt 0) {
        Write-Host "\nError: Cannot remove source files when new files are detected ($totalNew new files)." -ForegroundColor Red
        Write-Host "Please run with -Copy first to copy the new files." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "\nNo new files detected. Checking for source files that can be removed...\n" -ForegroundColor Green
    
    # Find source files that still exist
    $totalDeleted = 0
    $totalNotFound = 0
    $filesToProcess = @()
    
    # First pass: collect files that still exist
    foreach ($mappingPath in $existingMapping.Keys) {
        $entry = $existingMapping[$mappingPath]
        $sourcePath = $entry.source
        
        if (Test-Path $sourcePath) {
            $filesToProcess += @{
                MappingPath = $mappingPath
                SourcePath = $sourcePath
            }
        }
        else {
            $totalNotFound++
        }
    }
    
    $totalFiles = $filesToProcess.Count
    $currentFile = 0
    $totalCopyOnly = 0
    
    # Second pass: process each file with counter
    foreach ($fileInfo in $filesToProcess) {
        $currentFile++
        $remaining = $totalFiles - $currentFile + 1
        
        # Check if file is in a copy-only folder
        $isCopyOnly = $false
        $mappingPath = $fileInfo.MappingPath
        foreach ($copyOnlyFolder in $copyOnlyFolders) {
            if ($mappingPath -like "*/$copyOnlyFolder/*" -or $mappingPath -like "*\$copyOnlyFolder\*") {
                $isCopyOnly = $true
                break
            }
        }
        
        if ($isCopyOnly) {
            Write-Host "[$currentFile/$totalFiles] Found: $($fileInfo.MappingPath)" -ForegroundColor Cyan
            Write-Host "  Source: $($fileInfo.SourcePath)" -ForegroundColor Gray
            Write-Host "  [COPY-ONLY] This file is in a protected folder and will not be deleted" -ForegroundColor Magenta
            Write-Host ""
            $totalCopyOnly++
            continue
        }
        
        Write-Host "[$currentFile/$totalFiles] Found: $($fileInfo.MappingPath)" -ForegroundColor Cyan
        Write-Host "  Source: $($fileInfo.SourcePath)" -ForegroundColor Gray
        $response = Read-Host "  Delete this source file? [$remaining/$totalFiles remaining] (Y/N)"
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            try {
                Remove-Item -Path $fileInfo.SourcePath -Force
                Write-Host "  [DELETED] $($fileInfo.SourcePath)" -ForegroundColor Yellow
                $totalDeleted++
            }
            catch {
                Write-Host "  [ERROR] Failed to delete: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  [SKIPPED]" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Remove sources completed!" -ForegroundColor Cyan
    Write-Host "Total files in mapping: $($existingMapping.Count)" -ForegroundColor Cyan
    Write-Host "Files deleted: $totalDeleted" -ForegroundColor Red
    Write-Host "Copy-only files (protected): $totalCopyOnly" -ForegroundColor Magenta
    Write-Host "Files already removed: $totalNotFound" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    
    exit 0
}

# Scan or copy files from each source directory
foreach ($sourceDir in $sourceDirs) {
    if (Test-Path $sourceDir) {
        $actionVerb = if ($Scan) { "Scanning" } else { "Processing" }
        Write-Host "`n${actionVerb}: $sourceDir" -ForegroundColor Cyan
        $sourceDirName = Split-Path $sourceDir -Leaf
        
        foreach ($ext in $extensions) {
            $files = Get-ChildItem -Path $sourceDir -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                try {
                    # Calculate relative path
                    $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
                    $relativePathNormalized = $relativePath -replace '\\', '/'
                    
                    # Check if file is in an ignored folder
                    $shouldIgnore = $false
                    foreach ($ignoreFolder in $ignoreFolders) {
                        # Check if path starts with ignored folder or contains it as a subdirectory
                        if ($relativePathNormalized -like "$ignoreFolder/*" -or $relativePathNormalized -like "*/$ignoreFolder/*") {
                            $shouldIgnore = $true
                            break
                        }
                    }
                    
                    if ($shouldIgnore) {
                        continue
                    }
                    
                    # Check if file matches ignored file patterns
                    $fileName = $file.Name
                    foreach ($ignorePattern in $ignoreFiles) {
                        if ($fileName -ilike $ignorePattern) {
                            $shouldIgnore = $true
                            break
                        }
                    }
                    
                    if ($shouldIgnore) {
                        continue
                    }
                    
                    $mappingPath = "$sourceDirName/$relativePathNormalized"
                    $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
                    $relativePathNormalized = $relativePath -replace '\\', '/'
                    $mappingPath = "$sourceDirName/$relativePathNormalized"
                    $lastModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                    
                    # Check if file is new or updated (in scan mode)
                    if ($Scan) {
                        if (-not $existingMapping.ContainsKey($mappingPath)) {
                            $totalNew++
                            $newFiles += $mappingPath
                            Write-Host "  [NEW] $mappingPath" -ForegroundColor Green
                        }
                        elseif ($existingMapping[$mappingPath].lastModified -ne $lastModified) {
                            $totalUpdated++
                            $updatedFiles += $mappingPath
                            Write-Host "  [UPDATED] $mappingPath" -ForegroundColor Yellow
                        }
                    }
                    
                    # Copy file if in copy mode
                    if ($Copy) {
                        $destPath = Join-Path $workspaceDir "$sourceDirName\$relativePath"
                        $destFolder = Split-Path $destPath -Parent
                        
                        if (-not (Test-Path $destFolder)) {
                            New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
                        }
                        
                        Copy-Item -Path $file.FullName -Destination $destPath -Force
                        
                        # Check if file is in a copy-only folder and set as readonly
                        $isCopyOnly = $false
                        foreach ($copyOnlyFolder in $copyOnlyFolders) {
                            if ($mappingPath -like "*/$copyOnlyFolder/*" -or $mappingPath -like "*\$copyOnlyFolder\*") {
                                $isCopyOnly = $true
                                break
                            }
                        }
                        
                        if ($isCopyOnly) {
                            Set-ItemProperty -Path $destPath -Name IsReadOnly -Value $true
                            Write-Host "  Copied (readonly): $sourceDirName\$relativePath" -ForegroundColor Magenta
                        }
                        else {
                            Write-Host "  Copied: $sourceDirName\$relativePath" -ForegroundColor Gray
                        }
                        
                        $totalCopied++
                    }
                    
                    # Create mapping entry
                    $mapping[$mappingPath] = @{
                        source = $file.FullName
                        sourceRepository = $sourceDirName
                        relativePath = $relativePathNormalized
                        lastModified = $lastModified
                        destination = if ($Copy) { Join-Path $workspaceDir "$sourceDirName\$relativePath" } else { "" }
                    }
                }
                catch {
                    $action = if ($Copy) { "copying" } else { "scanning" }
                    Write-Host "  Error $action $($file.Name): $_" -ForegroundColor Red
                    $totalSkipped++
                }
            }
        }
    }
    else {
        Write-Host "`nWarning: Source directory not found: $sourceDir" -ForegroundColor Yellow
    }
}

# Handle scan mode results
if ($Scan) {
    # Write mapping to JSON file in scan mode
    $mappingJson = $mapping | ConvertTo-Json -Depth 10
    Set-Content -Path $mappingFile -Value $mappingJson -Encoding UTF8
    
    # Scan local workspace for available documents
    Write-Host "`nScanning local workspace for available documents..." -ForegroundColor Cyan
    $availableDocuments = @{}
    $localSourceDirs = @("TL2", "TL2_dotnet", "TLCloud")
    
    foreach ($localDir in $localSourceDirs) {
        $localPath = Join-Path $workspaceDir $localDir
        if (Test-Path $localPath) {
            foreach ($ext in $extensions) {
                $localFiles = Get-ChildItem -Path $localPath -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
                
                foreach ($localFile in $localFiles) {
                    $relPath = $localFile.FullName.Substring($localPath.Length + 1)
                    $relPathNormalized = $relPath -replace '\\', '/'
                    $docPath = "$localDir/$relPathNormalized"
                    $workspaceRelPath = $localFile.FullName.Substring($workspaceDir.Length + 1) -replace '\\', '/'
                    
                    $availableDocuments[$docPath] = @{
                        fullPath = $localFile.FullName
                        workspaceRelativePath = $workspaceRelPath
                        repository = $localDir
                        relativePath = $relPathNormalized
                        lastModified = $localFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        size = $localFile.Length
                    }
                }
            }
        }
    }
    
    # Write available documents to JSON
    $availableDocsFile = Join-Path $workspaceDir "documents-available.json"
    $availableDocsJson = $availableDocuments | ConvertTo-Json -Depth 10
    Set-Content -Path $availableDocsFile -Value $availableDocsJson -Encoding UTF8
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Scan completed!" -ForegroundColor Cyan
    Write-Host "Total files scanned: $($mapping.Count)" -ForegroundColor Cyan
    Write-Host "New files: $totalNew" -ForegroundColor Green
    Write-Host "Updated files: $totalUpdated" -ForegroundColor Yellow
    Write-Host "Skipped files: $totalSkipped" -ForegroundColor Gray
    Write-Host "Available documents in workspace: $($availableDocuments.Count)" -ForegroundColor Cyan
    Write-Host "Mapping file updated: $mappingFile" -ForegroundColor Cyan
    Write-Host "Available docs file: $availableDocsFile" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($totalNew -gt 0 -or $totalUpdated -gt 0) {
        Write-Host "`nChanges detected!" -ForegroundColor Yellow
        
        # Only prompt if Copy wasn't explicitly passed
        if (-not $CopyExplicitlyPassed) {
            $response = Read-Host "`nDo you want to copy the changed files? (Y/N)"
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host "`nRunning copy operation..." -ForegroundColor Green
                & $PSCommandPath -Copy
            }
            else {
                Write-Host "`nCopy skipped. Run with -Copy flag to copy files manually." -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "`nNo changes detected. All files are up to date." -ForegroundColor Green
    }
}
else {
    # Write mapping to JSON file in copy mode
    $mappingJson = $mapping | ConvertTo-Json -Depth 10
    Set-Content -Path $mappingFile -Value $mappingJson -Encoding UTF8
    
    # Display summary
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Copy and mapping operation completed!" -ForegroundColor Green
    Write-Host "Total files copied: $totalCopied" -ForegroundColor Green
    Write-Host "Total files skipped: $totalSkipped" -ForegroundColor Yellow
    Write-Host "Destination: $workspaceDir" -ForegroundColor Green
    Write-Host "Mapping file: $mappingFile" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
