# Simple PowerShell HTTP Server for Documentation Viewer
# Start this script to serve the documentation viewer locally

param(
    [int]$Port = 8000
)

# Set document root to parent directory (TL2_Documentation) so we can access both Viewer and documents-available.json
$documentRoot = Split-Path $PSScriptRoot -Parent

# Run copy-documents scan to check for updates
Write-Host "Scanning for document updates..." -ForegroundColor Cyan
$copyScript = Join-Path $documentRoot "copy-documents.ps1"
if (Test-Path $copyScript) {
    & $copyScript -Scan
    Write-Host ""
} else {
    Write-Host "Warning: copy-documents.ps1 not found" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Documentation Viewer Web Server" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Document Root: $documentRoot" -ForegroundColor Yellow
Write-Host "Viewer URL: http://localhost:$Port/Viewer/" -ForegroundColor Green
Write-Host ""
Write-Host "Press ESC to stop the server" -ForegroundColor Yellow
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
        } catch {
            Write-Host "! Could not auto-open browser. Please navigate to:" -ForegroundColor Yellow
            Write-Host "  $viewerUrl" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Waiting for requests..." -ForegroundColor Cyan
        Write-Host "Press ESC to stop..." -ForegroundColor Gray
        Write-Host ""
        
        # Create a runspace for ESC key monitoring
        $escPressed = [ref]$false
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("escPressed", $escPressed)
        $runspace.SessionStateProxy.SetVariable("http", $http)
        
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            param($escPressed, $http)
            while (-not $escPressed.Value) {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq 'Escape') {
                        $escPressed.Value = $true
                        # Stop the listener to unblock GetContext()
                        if ($http.IsListening) {
                            $http.Stop()
                        }
                        break
                    }
                }
                Start-Sleep -Milliseconds 100
            }
        }).AddArgument($escPressed).AddArgument($http) | Out-Null
        
        $asyncResult = $ps.BeginInvoke()
        
        # Handle requests
        while ($http.IsListening -and -not $escPressed.Value) {
            try {
                # Blocking call - waits for incoming request
                $context = $http.GetContext()
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
                                        relativePath = $relativePath
                                        fullPath = $_.FullName
                                        repository = "Generated"
                                        workspaceRelativePath = $workspacePath
                                        size = $_.Length
                                        lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
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
                                '.css'  { 'text/css; charset=utf-8' }
                                '.js'   { 'application/javascript; charset=utf-8' }
                                '.json' { 'application/json; charset=utf-8' }
                                '.png'  { 'image/png' }
                                '.jpg'  { 'image/jpeg' }
                                '.jpeg' { 'image/jpeg' }
                                '.gif'  { 'image/gif' }
                                '.svg'  { 'image/svg+xml' }
                                '.ico'  { 'image/x-icon' }
                                '.pdf'  { 'application/pdf' }
                                '.md'   { 'text/markdown; charset=utf-8' }
                                '.txt'  { 'text/plain; charset=utf-8' }
                                '.xml'  { 'application/xml; charset=utf-8' }
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
                # If ESC was pressed, GetContext will throw when listener stops
                if ($escPressed.Value) {
                    break
                }
                Write-Host "  → Error processing request: $_" -ForegroundColor Red
                try { $response.StatusCode = 500; $response.Close() } catch {}
            }
        }
        
        # Cleanup runspace
        if ($escPressed.Value) {
            Write-Host ""
            Write-Host "ESC pressed - Stopping server..." -ForegroundColor Yellow
        }
        $ps.Stop()
        $ps.Dispose()
        $runspace.Close()
        $runspace.Dispose()
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
