# Test Run Script - Build and test deployment package locally

$ErrorActionPreference = "Continue"

Write-Host "=== MiniLPA Web Test Run Script ===" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TestDir = Join-Path $PSScriptRoot "test-run"
$BackendPort = 8080

# Clean old test directory
if (Test-Path $TestDir) {
    Write-Host "Cleaning old test directory..." -ForegroundColor Yellow
    Remove-Item $TestDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TestDir "app") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TestDir "frontend") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TestDir "logs") | Out-Null

# Check Java environment
if (-not $env:JAVA_HOME) {
    Write-Host "Error: Please set JAVA_HOME environment variable (Java 21 required)" -ForegroundColor Red
    exit 1
}

Write-Host "Java Version:" -ForegroundColor Yellow
try {
    $javaVersion = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1
    Write-Host $javaVersion
} catch {
    Write-Host "Java is available"
}

Write-Host ""
Write-Host "1. Building backend service..." -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "web-backend")
& .\gradlew.bat clean bootJar --no-daemon | Out-Null
$BackendJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
if ($BackendJar) {
    Copy-Item $BackendJar.FullName (Join-Path $TestDir "app\minilpa-backend.jar") -Force
    Write-Host "   Backend JAR: $($BackendJar.Name)" -ForegroundColor Green
} else {
    Write-Host "   Error: Backend JAR not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Building local agent..." -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "local-agent")
& .\gradlew.bat clean build --no-daemon | Out-Null
$AgentJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
if ($AgentJar) {
    Copy-Item $AgentJar.FullName (Join-Path $TestDir "app\minilpa-agent.jar") -Force
    Write-Host "   Agent JAR: $($AgentJar.Name)" -ForegroundColor Green
} else {
    Write-Host "   Error: Agent JAR not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Building frontend..." -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "web-frontend")
if (-not (Test-Path "node_modules")) {
    Write-Host "   Installing dependencies..." -ForegroundColor Yellow
    npm install | Out-Null
}
npm run build | Out-Null
if (Test-Path "dist") {
    Copy-Item -Path "dist\*" -Destination (Join-Path $TestDir "frontend") -Recurse -Force
    Write-Host "   Frontend built successfully" -ForegroundColor Green
} else {
    Write-Host "   Error: Frontend build failed" -ForegroundColor Red
    exit 1
}

# Create test configuration
Write-Host ""
Write-Host "4. Creating test configuration..." -ForegroundColor Cyan
$configContent = "server:`n  port: $BackendPort`n`nspring:`n  application:`n    name: minilpa-web-backend`n`nlogging:`n  level:`n    root: INFO`n    moe.sekiu.minilpa: DEBUG`n  file:`n    name: $TestDir\logs\backend.log"
$configFile = Join-Path $TestDir "app\application.yml"
$configContent | Out-File -FilePath $configFile -Encoding UTF8 -NoNewline
[System.IO.File]::AppendAllText($configFile, "`n")

Write-Host ""
Write-Host "=== Build Completed ===" -ForegroundColor Green
Write-Host "Test directory: $TestDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Get-ChildItem $TestDir -Recurse -File | Select-Object FullName | Format-Table -AutoSize | Out-String | Write-Host

Write-Host ""
Write-Host "Starting backend service..." -ForegroundColor Cyan

# Start backend in background
$backendProcess = Start-Process -FilePath "$env:JAVA_HOME\bin\java.exe" `
    -ArgumentList "-jar", (Join-Path $TestDir "app\minilpa-backend.jar"), "--spring.config.location=$configFile" `
    -WorkingDirectory (Join-Path $TestDir "app") `
    -RedirectStandardOutput (Join-Path $TestDir "logs\backend-output.log") `
    -RedirectStandardError (Join-Path $TestDir "logs\backend-error.log") `
    -PassThru -WindowStyle Hidden

Write-Host "Backend process started (PID: $($backendProcess.Id))" -ForegroundColor Green
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow

# Wait for backend to start
$backendStarted = $false
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$BackendPort/api/devices/status" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $backendStarted = $true
            Write-Host "Backend service is running!" -ForegroundColor Green
            break
        }
    } catch {
        # Continue waiting
    }
    Write-Host "." -NoNewline -ForegroundColor Gray
}

Write-Host ""
if (-not $backendStarted) {
    Write-Host "Warning: Backend may not be fully started yet" -ForegroundColor Yellow
    Write-Host "Check logs: $TestDir\logs\" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Test Environment Ready ===" -ForegroundColor Green
Write-Host ""
Write-Host "Backend API: http://localhost:$BackendPort" -ForegroundColor Cyan
Write-Host "Frontend files: $TestDir\frontend" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test commands:" -ForegroundColor Yellow
Write-Host "  1. Test backend API:" -ForegroundColor White
Write-Host "     curl http://localhost:$BackendPort/api/devices/status" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Serve frontend (another terminal):" -ForegroundColor White
Write-Host "     cd $TestDir\frontend" -ForegroundColor Gray
Write-Host "     npx serve -p 3000" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Or open frontend directly:" -ForegroundColor White
Write-Host "     Start-Process `"$TestDir\frontend\index.html`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Stop backend: Stop-Process -Id $($backendProcess.Id)" -ForegroundColor Yellow
Write-Host "Or check process: Get-Process -Id $($backendProcess.Id)" -ForegroundColor Yellow
