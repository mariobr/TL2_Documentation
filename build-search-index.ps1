# Build Search Index for TrustedLicensing Documentation Viewer
# This script crawls all markdown documents and builds a pre-computed search index

param(
    [string]$OutputFile = "search-index.json",
    [switch]$Verbose
)

Write-Host "Building search index for documentation..." -ForegroundColor Cyan

# Define directories to scan
$docDirectories = @(
    "TL2\_docs_dev",
    "TL2_dotnet\_docs_dev",
    "TLCloud",
    "Generated"
)

# Initialize index data structure
$indexData = @{
    documents = @()
    metadata = @{
        buildDate = (Get-Date).ToString("o")
        totalDocuments = 0
        version = "1.0"
    }
}

$docId = 0

# Function to extract headings from markdown
function Extract-Headings {
    param([string]$Content)
    
    $headings = @()
    $lines = $Content -split "`n"
    
    foreach ($line in $lines) {
        if ($line -match '^(#{1,6})\s+(.+)$') {
            $level = $matches[1].Length
            $text = $matches[2].Trim()
            $headings += @{
                level = $level
                text = $text
            }
        }
    }
    
    return $headings
}

# Function to extract first paragraph as summary
function Extract-Summary {
    param([string]$Content, [int]$MaxLength = 200)
    
    # Remove headings and get first meaningful paragraph
    $lines = $Content -split "`n" | Where-Object { 
        $_ -notmatch '^#' -and 
        $_ -notmatch '^```' -and 
        $_.Trim() -ne ''
    }
    
    $summary = ($lines | Select-Object -First 3) -join ' '
    $summary = $summary -replace '\[([^\]]+)\]\([^\)]+\)', '$1'  # Remove markdown links
    $summary = $summary -replace '[*_`]', ''  # Remove markdown formatting
    
    if ($summary.Length -gt $MaxLength) {
        $summary = $summary.Substring(0, $MaxLength) + "..."
    }
    
    return $summary
}

# Function to clean markdown for indexing
function Clean-MarkdownContent {
    param([string]$Content)
    
    # Remove code blocks
    $cleaned = $Content -replace '(?s)```.*?```', ''
    
    # Remove inline code
    $cleaned = $cleaned -replace '`[^`]+`', ''
    
    # Remove HTML tags
    $cleaned = $cleaned -replace '<[^>]+>', ''
    
    # Remove markdown links but keep text
    $cleaned = $cleaned -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    
    # Remove images
    $cleaned = $cleaned -replace '!\[([^\]]*)\]\([^\)]+\)', ''
    
    # Remove markdown formatting
    $cleaned = $cleaned -replace '[*_~]', ''
    
    # Remove extra whitespace
    $cleaned = $cleaned -replace '\s+', ' '
    
    return $cleaned.Trim()
}

# Scan each directory
foreach ($dir in $docDirectories) {
    $fullPath = Join-Path $PSScriptRoot $dir
    
    if (-not (Test-Path $fullPath)) {
        Write-Host "  Skipping $dir (not found)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  Scanning: $dir" -ForegroundColor Green
    
    # Find all markdown files
    $markdownFiles = Get-ChildItem -Path $fullPath -Filter "*.md" -Recurse -File
    
    foreach ($file in $markdownFiles) {
        $docId++
        
        try {
            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            
            if ([string]::IsNullOrWhiteSpace($content)) {
                continue
            }
            
            # Get relative path
            $relativePath = $file.FullName.Replace($PSScriptRoot + '\', '').Replace('\', '/')
            
            # Extract title (first heading or filename)
            $title = $file.BaseName
            if ($content -match '^#\s+(.+)$') {
                $title = $matches[1].Trim()
            }
            
            # Extract headings
            $headings = Extract-Headings -Content $content
            $headingText = ($headings | ForEach-Object { $_.text }) -join ' '
            
            # Extract summary
            $summary = Extract-Summary -Content $content
            
            # Clean content for full-text search
            $cleanedContent = Clean-MarkdownContent -Content $content
            
            # Determine category based on path
            $category = "Documentation"
            if ($relativePath -match '^Generated/') {
                $category = "Generated"
            } elseif ($relativePath -match '^TLCloud/') {
                $category = "TLCloud"
            } elseif ($relativePath -match '^TL2/') {
                $category = "TL2"
            } elseif ($relativePath -match '^TL2_dotnet/') {
                $category = "TL2_dotnet"
            }
            
            # Add to index
            $doc = @{
                id = $docId
                title = $title
                path = $relativePath
                category = $category
                summary = $summary
                headings = $headingText
                content = $cleanedContent
                size = $file.Length
                modified = $file.LastWriteTime.ToString("o")
            }
            
            $indexData.documents += $doc
            
            if ($Verbose) {
                Write-Host "    [$docId] $title" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "    Error processing $($file.Name): $_" -ForegroundColor Red
        }
    }
}

# Update metadata
$indexData.metadata.totalDocuments = $indexData.documents.Count

# Save index to JSON
$outputPath = Join-Path $PSScriptRoot $OutputFile
$indexData | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "Search index built successfully!" -ForegroundColor Green
Write-Host "  Total documents indexed: $($indexData.metadata.totalDocuments)" -ForegroundColor Cyan
Write-Host "  Output file: $outputPath" -ForegroundColor Cyan
Write-Host "  File size: $([math]::Round((Get-Item $outputPath).Length / 1KB, 2)) KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now use the search functionality in the documentation viewer." -ForegroundColor Yellow
