# HTTP Server for M6-B Keyboard Tool
param(
    [int]$Port = 8080,
    [string]$AutoOpen = "true"
)

# Convert string to boolean
$autoOpenBool = $AutoOpen -eq "true" -or $AutoOpen -eq "1"

# Get current directory
$currentDir = Get-Location
$backupDir = Join-Path $currentDir "备份"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "[INFO] Created backup directory: $backupDir"
}

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host ""
    Write-Host "[OK] Server started successfully!"
    Write-Host ""
    
    # Open browser if auto-open is enabled
    if ($autoOpenBool) {
        Write-Host "[INFO] Opening browser..."
        Start-Process "http://localhost:$Port"
    }
    
    # Main server loop
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        $urlPath = $context.Request.Url.LocalPath
        
        # Handle backup API
        if ($urlPath -eq "/api/backup" -and $context.Request.HttpMethod -eq "POST") {
            try {
                $sourceFile = Join-Path $currentDir "index.html"
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupFile = Join-Path $backupDir "index_$timestamp.html"
                
                # Copy the file
                Copy-Item $sourceFile $backupFile
                
                # Prepare JSON response
                $result = @{
                    success = $true
                    filename = "index_$timestamp.html"
                    path = $backupFile
                }
                $jsonResponse = [System.Text.Encoding]::UTF8.GetBytes(($result | ConvertTo-Json))
                $response.ContentType = "application/json; charset=utf-8"
                $response.ContentLength64 = $jsonResponse.Length
                $response.OutputStream.Write($jsonResponse, 0, $jsonResponse.Length)
                Write-Host "[OK] Backup created: $backupFile"
            } catch {
                $result = @{
                    success = $false
                    error = $_.Exception.Message
                }
                $jsonResponse = [System.Text.Encoding]::UTF8.GetBytes(($result | ConvertTo-Json))
                $response.ContentType = "application/json; charset=utf-8"
                $response.ContentLength64 = $jsonResponse.Length
                $response.OutputStream.Write($jsonResponse, 0, $jsonResponse.Length)
                Write-Host "[ERROR] Backup failed:" $_.Exception.Message
            }
            $response.Close()
            continue
        }
        
        # Default to index.html for root path
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }
        
        $filePath = Join-Path $currentDir $urlPath
        
        if (Test-Path $filePath -PathType Leaf) {
            # Read file content
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            # Set content type based on file extension
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($extension) {
                ".html" { $response.ContentType = "text/html; charset=utf-8" }
                ".css" { $response.ContentType = "text/css; charset=utf-8" }
                ".js" { $response.ContentType = "application/javascript; charset=utf-8" }
                ".json" { $response.ContentType = "application/json; charset=utf-8" }
                ".ico" { $response.ContentType = "image/x-icon" }
                ".png" { $response.ContentType = "image/png" }
                ".jpg" { $response.ContentType = "image/jpeg" }
                ".gif" { $response.ContentType = "image/gif" }
                ".svg" { $response.ContentType = "image/svg+xml" }
                default { $response.ContentType = "application/octet-stream" }
            }
            
            $response.OutputStream.Write($content, 0, $content.Length)
        } else {
            # 404 Not Found
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 - File not found")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "[ERROR] Failed to start server:" $_.Exception.Message
    Write-Host "[ERROR] Make sure no other program is using port $Port"
} finally {
    if ($listener) {
        $listener.Stop()
    }
}