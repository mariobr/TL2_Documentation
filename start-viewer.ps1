# Rebuild Search Index and Start Viewer
# Convenient script to rebuild the search index and launch the documentation viewer

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Documentation Viewer Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build search index
Write-Host "[1/2] Building search index..." -ForegroundColor Yellow
& .\build-search-index.ps1

if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
    Write-Host "✓ Search index built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Search index build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Start viewer
Write-Host "[2/2] Starting documentation viewer..." -ForegroundColor Yellow
Write-Host ""

& .\Viewer\start-server.ps1
