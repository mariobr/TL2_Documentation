# Simple PowerShell HTTP Server for Documentation Viewer
# Start this script to serve the documentation viewer locally

param(
    [int]$Port = 8000
)

# Set document root to parent directory (TL2_Documentation) so we can access both Viewer and documents-available.json
$documentRoot = Split-Path $PSScriptRoot -Parent

function Invoke-DocumentationRefresh {
    param(
        [string]$DocumentRoot
    )

    Write-Host "Scanning for document updates..." -ForegroundColor Cyan

    $copyScript = Join-Path $DocumentRoot "copy-documents.ps1"
    if (Test-Path $copyScript) {
        try {
            & $copyScript -Scan -Copy
        }
        catch {
            Write-Host "Warning: copy-documents refresh failed: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Warning: copy-documents.ps1 not found" -ForegroundColor Yellow
    }

    $searchIndexScript = Join-Path $DocumentRoot "build-search-index.ps1"
    if (Test-Path $searchIndexScript) {
        try {
            & $searchIndexScript
        }
        catch {
            Write-Host "Warning: search index rebuild failed: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Warning: build-search-index.ps1 not found" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Process-ServerHotkeys {
    param(
        [ref]$StopRequested,
        [ref]$RefreshInProgress,
        [System.Net.HttpListener]$Http,
        [string]$DocumentRoot
    )

    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        $isCtrlModifier = ($key.Modifiers -band [System.ConsoleModifiers]::Control) -ne 0

        if ($key.Key -eq [System.ConsoleKey]::Escape -or ($isCtrlModifier -and $key.Key -eq [System.ConsoleKey]::C)) {
            $StopRequested.Value = $true
            if ($Http.IsListening) {
                $Http.Stop()
            }
            return
        }

        if (($key.Key -eq [System.ConsoleKey]::F5) -or ($isCtrlModifier -and $key.Key -eq [System.ConsoleKey]::R)) {
            if (-not $RefreshInProgress.Value) {
                $RefreshInProgress.Value = $true
                Write-Host ""
                Write-Host "Refresh requested (F5/Ctrl+R)..." -ForegroundColor Cyan
                Invoke-DocumentationRefresh -DocumentRoot $DocumentRoot
                Write-Host "Refresh completed. Waiting for requests..." -ForegroundColor Green
                Write-Host ""
                $RefreshInProgress.Value = $false
            }
        }
    }
}

# Run copy-documents scan to check for updates
Invoke-DocumentationRefresh -DocumentRoot $documentRoot

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Documentation Viewer Web Server" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Document Root: $documentRoot" -ForegroundColor Yellow
Write-Host "Viewer URL: http://localhost:$Port/Viewer/" -ForegroundColor Green
Write-Host ""
Write-Host "Press ESC or Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "Press F5 or Ctrl+R to rescan/copy and rebuild search index" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create HTTP listener
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:$Port/")

try {
    $http.Start()
    
    if ($http.IsListening) {
        Write-Host "✓ Server started successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Try to open browser
        $viewerUrl = "http://localhost:$Port/Viewer/"
        try {
            Start-Process $viewerUrl
            Write-Host "✓ Opening browser to $viewerUrl" -ForegroundColor Green
        }
        catch {
            Write-Host "! Could not auto-open browser. Please navigate to:" -ForegroundColor Yellow
            Write-Host "  $viewerUrl" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Waiting for requests..." -ForegroundColor Cyan
        Write-Host "Press ESC/Ctrl+C to stop, F5/Ctrl+R to refresh docs..." -ForegroundColor Gray
        Write-Host ""
        
        $stopRequested = [ref]$false
        $refreshInProgress = [ref]$false
        $treatControlCAsInputOriginal = $false
        $treatControlCConfigured = $false
        try {
            $treatControlCAsInputOriginal = [Console]::TreatControlCAsInput
            [Console]::TreatControlCAsInput = $true
            $treatControlCConfigured = $true
        }
        catch {
            Write-Host "Warning: Could not configure Ctrl+C input handling. Ctrl+C may use default interrupt behavior." -ForegroundColor Yellow
        }
        
        # Handle requests
        while ($http.IsListening -and -not $stopRequested.Value) {
            Process-ServerHotkeys -StopRequested $stopRequested -RefreshInProgress $refreshInProgress -Http $http -DocumentRoot $documentRoot

            if ($stopRequested.Value -or -not $http.IsListening) {
                break
            }

            try {
                $contextTask = $http.GetContextAsync()

                while (-not $contextTask.AsyncWaitHandle.WaitOne(100)) {
                    Process-ServerHotkeys -StopRequested $stopRequested -RefreshInProgress $refreshInProgress -Http $http -DocumentRoot $documentRoot
                    if ($stopRequested.Value -or -not $http.IsListening) {
                        break
                    }
                }

                if ($stopRequested.Value -or -not $http.IsListening) {
                    break
                }

                $context = $contextTask.GetAwaiter().GetResult()
                $request = $context.Request
                $response = $context.Response
            
                # Get requested path
                $path = $request.Url.LocalPath
                if ($path -eq '/' -or $path -eq '/Viewer' -or $path -eq '/Viewer/') {
                    $path = '/Viewer/index.html'
                }
                    
                # Log request
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "[$timestamp] $($request.HttpMethod) $path" -ForegroundColor Gray
                    
                # Handle API endpoint for Generated folder listing
                if ($path -eq '/api/generated-docs') {
                    try {
                        $generatedPath = Join-Path $documentRoot "Generated"
                        $docs = @{}
                            
                        if (Test-Path $generatedPath) {
                            Get-ChildItem -Path $generatedPath -Recurse -File | Where-Object {
                                $_.Extension -match '\.(md|pdf|docx|doc|ppt|pptx)$'
                            } | ForEach-Object {
                                $relativePath = $_.FullName.Substring($generatedPath.Length + 1) -replace '\\', '/'
                                $workspacePath = "Generated/$relativePath"
                                    
                                $docs[$workspacePath] = @{
                                    relativePath          = $relativePath
                                    fullPath              = $_.FullName
                                    repository            = "Generated"
                                    workspaceRelativePath = $workspacePath
                                    size                  = $_.Length
                                    lastModified          = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                                }
                            }
                        }
                            
                        $json = $docs | ConvertTo-Json -Depth 10 -Compress
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            
                        $response.ContentType = 'application/json; charset=utf-8'
                        $response.ContentLength64 = $buffer.Length
                        $response.StatusCode = 200
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $response.OutputStream.Close()
                            
                        Write-Host "  → 200 OK (Generated docs: $($docs.Count))" -ForegroundColor Green
                        continue
                    }
                    catch {
                        Write-Host "  → 500 Error: $_" -ForegroundColor Red
                        $response.StatusCode = 500
                        $response.Close()
                        continue
                    }
                }
                    
                $filePath = Join-Path $documentRoot $path.TrimStart('/')
                    
                # Check if file exists
                if (Test-Path $filePath -PathType Leaf) {
                    try {
                        # Read file
                        $content = [System.IO.File]::ReadAllBytes($filePath)
                            
                        # Set content type
                        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
                        $contentType = switch ($extension) {
                            '.html' { 'text/html; charset=utf-8' }
                            '.css' { 'text/css; charset=utf-8' }
                            '.js' { 'application/javascript; charset=utf-8' }
                            '.json' { 'application/json; charset=utf-8' }
                            '.png' { 'image/png' }
                            '.jpg' { 'image/jpeg' }
                            '.jpeg' { 'image/jpeg' }
                            '.gif' { 'image/gif' }
                            '.svg' { 'image/svg+xml' }
                            '.ico' { 'image/x-icon' }
                            '.pdf' { 'application/pdf' }
                            '.md' { 'text/markdown; charset=utf-8' }
                            '.txt' { 'text/plain; charset=utf-8' }
                            '.xml' { 'application/xml; charset=utf-8' }
                            default { 'application/octet-stream' }
                        }
                            
                        # Send response
                        $response.ContentType = $contentType
                        $response.ContentLength64 = $content.Length
                        $response.StatusCode = 200
                        $response.OutputStream.Write($content, 0, $content.Length)
                        $response.OutputStream.Close()
                            
                        Write-Host "  → 200 OK ($($content.Length) bytes)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "  → 500 Error: $_" -ForegroundColor Red
                        $response.StatusCode = 500
                        $response.Close()
                    }
                }
                else {
                    # File not found
                    Write-Host "  → 404 Not Found: $filePath" -ForegroundColor Yellow
                    $response.StatusCode = 404
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>404 Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
        h1 { color: #dc3545; }
        code { background: #f0f0f0; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>404 - File Not Found</h1>
    <p>The requested file was not found:</p>
    <code>$path</code>
    <hr>
    <p><small>TrustedLicensing Documentation Server</small></p>
</body>
</html>
"@
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $response.ContentType = 'text/html; charset=utf-8'
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $response.OutputStream.Close()
                }
            }
            catch {
                # If shutdown was requested, GetContext will throw when listener stops
                if ($stopRequested.Value) {
                    break
                }
                Write-Host "  → Error processing request: $_" -ForegroundColor Red
                try { $response.StatusCode = 500; $response.Close() } catch {}
            }
        }
        
        # Cleanup runspace
        if ($stopRequested.Value) {
            Write-Host ""
            Write-Host "Stop key pressed (ESC/Ctrl+C) - Stopping server..." -ForegroundColor Yellow
        }
        if ($treatControlCConfigured) {
            try {
                [Console]::TreatControlCAsInput = $treatControlCAsInputOriginal
            }
            catch {}
        }
    }
}
catch {
    Write-Host "Error starting server: $_" -ForegroundColor Red
    exit 1
}
finally {
    if ($http.IsListening) {
        $http.Stop()
        $http.Close()
        Write-Host ""
        Write-Host "Server stopped." -ForegroundColor Yellow
    }
}
